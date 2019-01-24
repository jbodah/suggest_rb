require "bundler/setup"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "suggest"

require "minitest/autorun"
require "minitest/spec"
require "minitest/pride"

class NotYetSuggestable
  def foo
    42
  end

  def ==(other)
    other.is_a?(NotYetSuggestable) && other.foo == foo
  end
end

class NotSuggestable; end
