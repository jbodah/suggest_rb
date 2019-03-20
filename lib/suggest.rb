require "suggest/version"
require "set"

module Suggest
  SUGGEST_MODS = Set.new([
    Array,
    BasicObject,
    Comparable,
    Complex,
    Enumerable,
    FalseClass,
    Float,
    Hash,
    Integer,
    Math,
    NilClass,
    Numeric,
    Range,
    Regexp,
    Regexp,
    Set,
    String,
    Struct,
    Symbol,
    Time,
    TrueClass,
  ])

  UNSAFE_WITH_BLOCK = Set.new([
    [Array, :cycle],
    [Enumerable, :cycle]
  ])

  INCONSISTENT = Set.new([
    [Array, :sample],
    [Array, :shuffle],
    [Array, :shuffle!]
  ])

  TOO_COMPLICATED = Set.new([
    [String, :freeze],
    [Set, :freeze],
    [Set, :taint],
    [Set, :untaint],
    [Numeric, :singleton_method_added],
    [Numeric, :clone],
    [Numeric, :dup],
  ])

  SELECTOR = ->(m) do
    SUGGEST_MODS.include?(m.owner) &&
      !INCONSISTENT.include?([m.owner, m.name]) &&
      !TOO_COMPLICATED.include?([m.owner, m.name])
  end

  module Mixin
    def what_returns?(expected, args: [], allow_mutation: false, allow_not_public: false, &block)
      methods.map(&method(:method)).select(&SELECTOR).select do |m|
        arity = m.arity
        next unless arity < 0 || arity == args.count

        post = clone

        next if block && UNSAFE_WITH_BLOCK.include?([m.owner, m.name])
        result = post.__send__(allow_not_public ? :send : :public_send, m.name, *args, &block) rescue next

        next unless allow_mutation || self == post

        if expected.is_a?(Proc) && expected.lambda?
          expected.call(result) rescue false
        else
          Suggest.eq?(result, expected)
        end
      end.map(&:name)
    end

    def what_mutates?(expected, args: [], allow_not_public: false, **opts, &block)
      methods.map(&method(:method)).select(&SELECTOR).select do |m|
        arity = m.arity
        next unless arity < 0 || arity == args.count

        post = clone

        next if block && UNSAFE_WITH_BLOCK.include?([m.owner, m.name])
        result = post.__send__(allow_not_public ? :send : :public_send, m.name, *args, &block) rescue next

        next if opts.key?(:returns) && !Suggest.eq?(result, opts[:returns])

        Suggest.eq?(post, expected)
      end.map(&:name)
    end
  end

  def self.eq?(result, expected)
    result.is_a?(expected.class) && result == expected
  end

  def self.suggestable!(mod, **corrections) # unsafe_with_block: [], inconsistent: [], too_complicated: []
    raise ArgumentError.new("Must support smart comparison (implement «#{mod}#==»)") if mod.instance_method(:==).owner == BasicObject

    SUGGEST_MODS << mod
    %w[unsafe_with_block inconsistent too_complicated].each do |correction|
      c = Suggest.const_get(correction.upcase)
      [mod].product(corrections.fetch(correction, [])).each(&c.method(:<<))
    end
    mod.include(Suggest::Mixin) unless mod.ancestors.include?(Suggest::Mixin)
  end

  def self.suggestable_methods
    SUGGEST_MODS.each_with_object([]) do |mod, candidates|
      owned_methods = mod.instance_methods.select { |m| mod.instance_method(m).owner == mod }
      next if owned_methods.none?
      candidates += [mod].product(owned_methods)
    end.reject do |m|
      INCONSISTENT.include?(m) || TOO_COMPLICATED.include?(m)
    end
  end
end

Suggest::SUGGEST_MODS.each do |mod|
  mod.include(Suggest::Mixin) unless mod.ancestors.include?(Suggest::Mixin)
end
