---
layout: post
title: "Exercism: The Hamming Exercise"
date: 2014-06-02 20:59:02 -0500
comments: true
categories: 
---

[The Readme](https://github.com/IanWhitney/exercism_problems/blob/master/ruby/hamming/README.md)

[The Test Suite](https://github.com/IanWhitney/exercism_problems/blob/master/ruby/hamming/hamming_test.rb)

We need to find the differences between two strings. But those strings are also very array-like; as in, "On this DNA strand there's a G at the first position." And Ruby already has a lot of nice syntax for comparing arrays. So I started thinking about this problem as one with an array-focused solution. 

I also thought about the Ruby [Set library](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/set/rdoc/Set.html), but that won't work because Sets want unique objects, so a "G" in the first position and a "G" in the 8th position would be squished down to just one "G".

```ruby
strand = %w(g a t t a g)
=> ["g", "a", "t", "t", "a", "g"]
strand.to_set
=> #<Set: {"g", "a", "t"}>
```

That won't work.

So, following my standard approach, I did the easiest fastest thing that got the tests passing. And it looked [like this](https://github.com/IanWhitney/exercism_problems/blob/7adb6742b0397e7d1fc043227bc33c27e107a605/ruby/hamming/hamming.rb)

```ruby
class Hamming
  def self.compute(a,b)
    a = a.chars
    b = b.chars
    max = (a.count < b.count) ? a.count : b.count
    a = a[0,max]
    b = b[0,max]
    y = a.zip(b)
    y.inject(0) {|ret, h| ret += 1 if h.first != h.last; ret}
  end
end
```

Oh, yeah, that's nasty. The duplicate logic; the weird, meaningless sorting and trimming of arrays; the block that takes a few seconds to puzzle out. It's rough stuff.

But, it passed my tests, and that's all I wanted. With tests green, I can refactor. And refactor I did! [Removing the array trimming](https://github.com/IanWhitney/exercism_problems/blob/498d03c4bf56b089ac58f32fa97ebdc5b9485170/ruby/hamming/hamming.rb) was an easy fix. Then I began to [pull out Strand behaviors](https://github.com/IanWhitney/exercism_problems/blob/8d5d0e35caaa2c1cf6fcc2f2523faea06a6b3d0e/ruby/hamming/hamming.rb)

```ruby
class Strand
  include Enumerable

  attr_accessor :collection

  def self.parse(strand_string)
    self.new(strand_string)
  end

  def initialize(strand_string)
    self.collection = strand_string.chars
  end

  def each(&block)
    collection.each(&block)
  end
end
```

Like I said, I quickly thought of a Strand as being array-ish. So `Strand` has a way of parsing a string into an array and then acts as a thin wrapper around the array.

But if an array for each Strand is good, then surely one more array must be better! After noticing the behaviors that required two Strands, I decided to contain that logic [in a `Strands` object](https://github.com/IanWhitney/exercism_problems/blob/9114fc505295d0c92001724752a1626c770bb19a/ruby/hamming/hamming.rb).

This was a mistake. And even when I tried to [make it better](https://github.com/IanWhitney/exercism_problems/blob/5db492443c0a0afa14d3e4a897b8610c6a35ecb0/ruby/hamming/hamming.rb) it was still a mistake. The `compute` method became nedlessly complex and tied to its knowledge of both Strand and Strands. Time to ditch this and revisit how I originally wanted to solve this problem.

I was initially drawn to a Strand as an array, largely because of Ruby's implementation of array subtraction/diffing/etc. The Ruby implementaition of subtraction doesn't work for Hamming, but I still liked that syntax. In my perfect world, this would work:

```ruby
hamming_differences = Strand.parse('GAT') - Strand.parse('AAT')
```

Your own desires are a *great* design tool. This is the syntax you want to see? Write code that makes it happen. Don't know how? Learn!

So I ditched Strands. As I say in [the commit](https://github.com/IanWhitney/exercism_problems/commit/abdc637793a6e9f08daa81e4abed644572413fe8):

> Strands didn't really give me anything beyond a way to manipulate two Strand objects. It seemed unecessary if I could have a Strand know how to do the maniuplation. Like, if I want to add 1 + 2, I don't have an Integers object that does the math, the Integer object knows how to do it.

And, after I googled "[What the hell is Hamming?](http://en.wikipedia.org/wiki/Hamming_distance)" and discovered that it is a very generic idea used all the time, I also decide to separate the Hamming logic in such a way that I can add it to any class.

```ruby
class Hamming
  def self.compute(a,b)
    (Strand.parse(a) - Strand.parse(b)).count
  end
end

module Hammable
  def -(other)
    sorted = [self,other].sort_by { |x| x.count }
    combined = sorted.first.zip(sorted.last)
    x = combined.select {|strand_set| strand_set.first != strand_set.last}
    self.class.new(x)
  end
end

class Strand
  include Enumerable
  include Hammable

  def self.parse(strand_string)
    self.new(strand_string.chars)
  end

  def initialize(strand_array)
    self.collection = Array(strand_array)
  end

  def each(&block)
    collection.each(&block)
  end

  private

  attr_accessor :collection
end
```

Now I have a `Hammable` module I can add to whatever. The `-` method implementaiton is ugly, but it works. 

I started to doubt the wisdom of overriding the array `-` method. It is probably a really dumb idea. Imagine the unexepcted surprises. Want to subtract two normal arrays, it works one way. Subtract two hammable arrays and it's totally different. Yikes! And if you had one hammable and one normal array, the behavior would change depending on the order you used. Terrible. So a better approach is to define a new method, say `hamming_difference` 

```ruby
Strand.parse(a).hamming_difference(Strand.parse(b))
```

It's a better idea, but it's not anywhere as nice to read. Oh, well. Sometimes we can't have everything we want.

And there's the question of what type of object it should return. Right now it will return a `Strand` as it was called by a `Strand`. But a better approach might be to have it return a `HammingDifference` object (itself just a thin wrapper around an array).

```ruby
module Hammable
  def hamming_difference(other)
    sorted = [self,other].sort_by { |x| x.count }
    combined = sorted.first.zip(sorted.last)
    x = combined.select {|strand_set| strand_set.first != strand_set.last}
    HammingDifference.new(x)
  end
end

class HammingDifference < SimpleDelegator; end
```

But what does that give us? Is there an appreciable difference between Hamming and HammingDifference? If so, I'm not seeing it. So now, maybe after all this code re-arranging, we should move the Hamming logic back under `Hamming`.

```ruby
class Hamming
  def self.compute(a, b, type = Strand)
    self.new(a, b, type).count
  end

  def initialize(a, b, type)
    self.one = type.parse(a)
    self.two = type.parse(b)
  end

  def count
    difference.count
  end

  def difference
    one.zip(two).select {|pair| Comparison.different?(pair)}
  end

  class Comparison
    def self.different?(couple)
      couple.first != couple.last &&
      !couple.last.nil? &&
      !couple.first.nil?
    end
  end

  private

  attr_accessor :one, :two
end

require 'delegate'
class Strand < SimpleDelegator
  def self.parse(strand_string)
    self.new(strand_string.chars)
  end
end
```

And finally, maybe, I'm ok with the code. Well, the attributes inside of `Hamming` are badly named, but that's minor. `compute` has become a declarative builder method that instantiates an instance of `Hamming` and call's the instance's `count` method. 

Gone is `Hammable`, since its logic now lives in `Hamming`. We no longer have to mix that code into `Strand`, though we do now have to tell what kind of objects `Hamming` should create. I've defaulted it to `Strand` here, but `Hamming` could easily work with other strings we want to find the Hamming distance of.

`Comparison` lives inside of the `Hamming` namespace, which looks a little weird. Why not just have `difference?` be a method in `Hamming`? Well, I wanted to encapsulate the logic of what constitutes a difference between two strands: both strands have to have a letter and those letters have to be different from one another. And to encapsulate the logic inside of a `Hamming` method seemed weird. Because somewhere in the code we'nd end up calling `self.different?(pair)` and that wasn't a method I wanted a `Hamming` instance to have. For some reason. Even I'm a little unclear on why I didn't like it. Further proof that code design is frequently more an art that a science.

### Summary

I think the code here is more reasonable than my work on the Bob problem. There's less cleverness for cleverness' sake. `Hamming` works easily with `Strand` objects, but can work with other objects. The code is simple enough to understand. I can see this implementation being one that I'd be happy to work with.

Possible dowsides are that the array manipulation will make this slow. I'm sure there's a much better algorithm out there for figuring out the hamming distance. But Exercism isn't about performance tuning, so I'm not going to worry about that.
