require "test_helper"

class SuggestTest < Minitest::Spec
  describe "#what_returns?" do
    it "works for Arrays" do
      assert_includes [1,2,3].what_returns?(1), :first
      assert_includes [1,2,3].what_returns?(1), :min
    end

    it "doesn't return methods that mutate" do
      refute_includes [1,2,3].what_returns?([1], args: [1]), :shift
      assert_includes [1,2,3].what_returns?([1], args: [1]), :take
    end

    it "can be told to allow mutation" do
      assert_includes [1,2,3].what_returns?([1], args: [1], allow_mutation: true), :shift
      assert_includes [1,2,3].what_returns?([1], args: [1], allow_mutation: true), :take
    end

    it "works on Strings" do
      assert_includes "HELLO".what_returns?("hello"), :downcase
      refute_includes "HELLO".what_returns?("hello"), :downcase!

      assert_includes "HELLO".what_returns?("hello", allow_mutation: true), :downcase
      assert_includes "HELLO".what_returns?("hello", allow_mutation: true), :downcase!
    end

    it "works on block expressions" do
      rv = [1,2,3,4].what_returns?({true => [2,4], false => [1,3]}) { |n| n % 2 == 0 }
      assert_includes rv, :group_by
    end

    it "doesn't return inconsistent methods" do
      rv = [1].what_returns?(1)
      refute_includes rv, :sample

      rv = [1].what_returns?([1])
      refute_includes rv, :shuffle
    end

    it "returns a private method of arity -2" do
      rv = Set.new([1]).what_returns? Set.new([1]), args: [[1]]
      refute_includes rv, :flatten_merge

      rv = Set.new([1]).what_returns? Set.new([1]), args: [[1]], allow_not_public: true
      assert_includes rv, :flatten_merge
    end

    it "allows dynamic convertion of anything to suggestable" do
      rv = NotYetSuggestable.new.what_returns?(42)
      refute_includes rv, :foo

      Suggest.suggestable!(NotYetSuggestable)
      rv = NotYetSuggestable.new.what_returns?(42)
      assert_includes rv, :foo

      assert_raises ArgumentError do
        Suggest.suggestable!(NotSuggestable)
      end
    end

    it "given a lambda, yields to the lambda to see if result is equal" do
      rv = [1,2,3].what_returns? -> (thing) { thing.to_s == "1" }
      assert_includes rv, :first
    end
  end

  describe "#what_mutates?" do
    it "returns methods that mutate" do
      assert_includes [1,2,3].what_mutates?([2, 3]), :shift
    end

    it "can check return values" do
      assert_includes [1,2,3].what_mutates?([2, 3], returns: 1), :shift
    end

    it "can be passed args" do
      assert_includes [1,2,3].what_mutates?([3], args: [2]), :shift
    end

    it "works on Strings" do
      assert_includes "HELLO".what_mutates?("hello"), :downcase!
    end

    it "works on block expressions" do
      rv = [1,2,3,4].what_mutates?([2,4]) { |n| n % 2 == 0 }
      assert_includes rv, :select!
    end

    it "doesn't return inconsistent methods" do
      rv = [1].what_mutates?([1])
      refute_includes rv, :shuffle!
    end
  end

  describe "suggestable_methods" do
    it "skips scary methods" do
      scary = [
        :taint,
        :untaint,
        :freeze,
        :trust,
        :untrust,
        /method_added/,
        /variable/,
        /method/,
        :clone,
        :dup,
      ]

      scary.each do |s|
        found = Suggest.suggestable_methods.find { |_klass, name| s === name }
        assert_nil found, "didn't expect #{found.inspect}"
      end
    end
  end
end
