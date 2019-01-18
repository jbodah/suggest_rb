# Suggest

tells you which method does the thing you want to do

## Installation

```
gem install suggest_rb
```

## Usage

```rb
require 'suggest'

# Object#what_returns? tells you which method returns the value
[1,2,3].what_returns? 1
=> [:first, :min]

# You can also specify the args you want that method to take
[1,2,3].what_returns? [1], args: [1]
=> [:sample, :first, :take, :grep, :min]

# By default, it only returns methods that don't mutate the object
[1,2,3].what_returns? [1], args: [1], allow_mutation: true
=> [:sample, :first, :take, :shift, :grep, :min]

# It works on several core modules including String
"HELLO".what_returns? "hello"
=> [:downcase, :swapcase]

# You can also specify a block that you want the method to accept
[1,2,3,4].what_returns?({true => [2,4], false => [1,3]}) { |n| n % 2 == 0 }
=> [:group_by]

# Object#what_mutates? tells you which method changes the object to the desired state
[1,2,3].what_mutates? [2, 3]
=> [:shift]

# You can also match on the return value
[1,2,3].what_mutates? [2, 3], returns: 1
=> [:shift]

[1,2,3].what_mutates? [2, 3], returns: 2
=> []

# You can specify which args to pass to the method
[1,2,3].what_mutates? [3], args: [2]
=> [:shift]

# It also works on a bunch of core modules
"HELLO".what_mutates? "hello"
=> [:swapcase!, :downcase!]

# And you can give it a block as well
[1,2,3,4].what_mutates? [2,4] { |n| n % 2 == 0 }
=> [:select!, :keep_if]
```

## Note to Self

Snippet to use in `bin/console` for finding methods for blacklisting:

```
Suggest::SUGGEST_MODS.flat_map { |k| [k].product(k.instance_methods) }.select { |k, v| v == :rand }.map { |k, v| k.instance_method(v).owner }.uniq
```
