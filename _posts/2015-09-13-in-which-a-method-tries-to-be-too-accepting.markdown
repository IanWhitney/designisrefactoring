---
layout: post
title: "In which a method tries to be too accepting"
date: 2015-09-13T14:06:40-05:00
---

I frequently write methods like this:

```ruby
def watch_magicians(magicians)
  magicians.collect { |magician| magician.magical_phrase }
end

a_bunch_of_magicians = [copperfield, blane, maskelyne]
watch_magicians(a_bunch_of_magicians)
```

Invariably I then need to watch a single magician, which I can only do like so

```ruby
watch_magicians([ricky_jay])
```

Which seems unnecessary in a language like Ruby. If I were using type-checked language then I would be required to pass an array into `watch_magicians`. But no such requirement exists in Ruby, so why shouldn't I be able to write code like this?

```ruby
watch_magicians(jillete)
# or
watch_magicians(nil)
```

<!--break-->

This is why the splat operator `*` exists, right? Let's play with a little demonstration method.

```ruby
def demo(*items)
  puts items
end

demo(1)
#=> [1]
# Yay!

demo(nil)
#=> [nil]
# Ooops

demo([1,2])
#=> [[1, 2]]
# Uh...
```

The second example will blow up when we try to do anything with nil, and the third example needs to be flattened before it's useful. Using splat this way won't help.

You could use splat outside of the method, like this:

```ruby
no_items = *nil
#=> []
1_item = *1
#=> [1]
2_items = *[1,2]
#=> [1,2]

demo(no_items)
#=> []
demo(1_item)
#=> [1]
demo(2_items)
#=> [1,2]
```

That works, but it doesn't really solve the problem I started with. Using splat in this way is just casting values to arrays before I call the method. I want to be able to pass non-arrays to the method and have it still work.

For our next attempt, we use `to_a` to convert our parameter to an array

```ruby
def demo(items)
  items.to_a.each { |item| puts item }
end
```

But this means that everything we pass into `demo` now has to support `to_a`

```ruby
demo(1)
#=> undefined method `to_a' for 1:Fixnum
```

So, that's not great.

What if we create a new array?

```ruby
def demo(items)
  Array.new(items).each { |item| puts item }
end
```

`Array.new` [does not work that way](http://ruby-doc.org/core-2.2.3/Array.html#method-c-new), though:

```ruby
Array.new(1)
#=> [nil]
Array.new(nil)
#=> no implicit conversion from nil to integer
```

So, that's worse. 

Avdi Grimm's excellent book [_Confident Ruby_](http://www.confidentruby.com) offers a better approach, [`Kernel.Array`](http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-Array):

```ruby
puts Array(1)
#=> [1]

puts Array(nil)
#=> []

puts Array([1,2])
#=> [1,2]
```

In our demonstration method:

```ruby
def demo(items)
  Array(items).each { |item| puts item }
end

demo(nil)
#=> []

demo(1)
1
=> [1]

demo([1,2])
1
2
=> [1, 2]
```

Great! Let's use that in our real code:

```ruby
def watch_magicians(magicians = nil)
  Array(magicians).collect { |magician| magician.magical_phrase }
end
```

Of course we have tests for this method. And they use a little test double Struct:

```ruby
Magician = Struct.new(:magical_phrase)

describe "watch_magicians" do
  it "works with one magician" do
    magician = Magician.new("Alakazam!")
    expect(watch_magicians(magician)).to include("Alakazam!")
  end

  it "works with a collection of magicians" do
    magician1 = Magician.new("Alakazam!")
    magician2 = Magician.new("Shazam")
    returned = watch_magicians([magician1, magician2])
    expect(returned).to include("Alakazam!")
    expect(returned).to include("Shazam")
  end

  it "works with no magicians" do
    expect(watch_magicians).to be_empty
  end
end
```

Confident in our work, we run our tests. 2 of the 3 pass, but for the "one magician" test we get:

```ruby
NoMethodError: undefined method `magical_phrase' for "Alakazam!":String
```

The hell?

Let's look at the [docs for Kernel.Array](http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-Array).

> Returns arg as an Array.
> First tries to call to_ary on arg, then to_a.

In our test with a single magician we call `Array` on a single Magician struct. Does one of those respond to `to_ary`?

```ruby
Magician.new("Alakazam!").respond_to?(:to_ary)
#=> false
```

Nope. How about `to_a`

```ruby
Magician.new("Alakazam!").respond_to?(:to_a)
#=> true
```

And what [does that do](http://ruby-doc.org/core-2.2.3/Struct.html#method-i-to_a)?

> Returns the values for this struct as an Array.

```ruby
Magician.new("Alakazam!").to_a
#=> ["Alakazam!"]
```

Well. That's unexpected.

The slightly deeper lesson to learn is that `Kernel.Array` is great, until you pass it something that responds to `to_ary` or `to_a` in an unexpected way.

The design lesson is that making methods that can handle _any_ input is probably a waste of time and a likely source of bugs.

The final lesson, the real lesson, is that flexibility like Ruby's is a double-edged sword. As powerful, and fun and fantastic as dynamic typing is, it can cut you in goofy ways. When your programmer friends start raving about how awesome strong typing is, it's because they never have to worry about weirdness like this.

Maybe I should re-double my efforts to learn Haskell.

> side note -- the apparently undocumented behavior of `Kernel.Array` when an object doesn't respond to **either** `to_ary` or `to_a` is to simply return that object as the only element of a new array. So the integer `1`, which doesn't respond to either of those methods, is returned as `[1]` by `Kernel.Array`)

The quick lesson here, the one you can use to show off your sweet Ruby knowledge amongst your friends, is that Struct has a surprising implementation of `to_a`.

