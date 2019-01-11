require "suggest/version"
require "set"

module Suggest
  SUGGEST_MODS = Set.new([Array, Enumerable, String, Hash, Regexp, Integer])
  UNSAFE = Set.new([Array.instance_method(:cycle)])

  module Mixin
    def what_returns?(expected, args: [], allow_mutation: false)
      block = Proc.new if block_given?

      applicable_methods = self.methods.map(&method(:method)).select { |m| SUGGEST_MODS.include?(m.owner) }

      applicable_methods.select do |m|
        arity = m.arity
        next unless arity == -1 || arity == args.count

        post = clone
        if block
          next if UNSAFE.include?(m.unbind)
          result = post.public_send(m.name, *args, &block) rescue next
        else
          result = post.public_send(m.name, *args) rescue next
        end

        next unless allow_mutation || self == post

        Suggest.eq?(result, expected)
      end.map(&:name)
    end

    def what_mutates?(expected, opts = {})
      args = opts[:args] || []
      block = Proc.new if block_given?

      applicable_methods = self.methods.map(&method(:method)).select { |m| SUGGEST_MODS.include?(m.owner) }

      applicable_methods.select do |m|
        arity = m.arity
        next unless arity == -1 || arity == args.count

        post = clone
        if block
          next if UNSAFE.include?(m.unbind)
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
end

Object.include(Suggest::Mixin)
