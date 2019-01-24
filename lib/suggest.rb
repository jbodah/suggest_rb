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

  module Mixin
    def what_returns?(expected, args: [], allow_mutation: false, allow_not_public: false, &block)
      methods.map(&method(:method)).select do |m|
        SUGGEST_MODS.include?(m.owner) &&
          !INCONSISTENT.include?([m.owner, m.name]) &&
          !TOO_COMPLICATED.include?([m.owner, m.name])
      end.select do |m|
        arity = m.arity
        next unless arity == -1 || arity == args.count

        post = clone
        if block
          next if UNSAFE_WITH_BLOCK.include?([m.owner, m.name])
          result = post.public_send(m.name, *args, &block) rescue next
        else
          result = post.public_send(m.name, *args) rescue next
        end

        next unless allow_mutation || self == post

        Suggest.eq?(result, expected)
      end.map(&:name)
    end

    def what_mutates?(expected, args: [], allow_not_public: false, **opts, &block)
      methods.map(&method(:method)).select do |m|
        SUGGEST_MODS.include?(m.owner) &&
          !INCONSISTENT.include?([m.owner, m.name]) &&
          !TOO_COMPLICATED.include?([m.owner, m.name])
      end.select do |m|
        arity = m.arity
        next unless arity == -1 || arity == args.count

        post = clone
        if block
          next if UNSAFE_WITH_BLOCK.include?([m.owner, m.name])
          result = post.public_send(m.name, *args, &block) rescue next
        else
          result = post.public_send(m.name, *args) rescue next
        end

        if opts.key?(:returns)
          next unless Suggest.eq?(result, opts[:returns])
        end

        Suggest.eq?(post, expected)
      end.map(&:name)
    end
  end

  def self.eq?(result, expected)
    result.is_a?(expected.class) && result == expected
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

Object.include(Suggest::Mixin)
