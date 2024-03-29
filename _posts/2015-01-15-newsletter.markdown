---
layout: post
title: "Who knew that squaring numbers could be so fraught?!"
date: 2015-01-15 12:35:35 -0600
author: Ian Whitney
---

There was no code in last week's newsletter. Let's get right to some code this week.

If you read [this week's post over at Design is Refactoring](http://designisrefactoring.com/2015/01/11/the-why-of-squares/), you'll probably remember that I decided that I was perfectly content with this code:

```ruby
class Squares
  attr_accessor :numbers

  def initialize(number)
    self.numbers = (1..number)
  end

  def square_of_sums
    (numbers.inject(0, :+)) ** 2
  end

  def sum_of_squares
    numbers.inject(0) do |ret, n|
      ret += n**2
    end
  end

  def difference
    square_of_sums - sum_of_squares
  end
end
```

When I shared this [on Reddit](https://www.reddit.com/r/ruby/comments/2s6ddd/the_intention_of_squares_design_is_refactoring/cnmwceg), someone had some suggestions. Implementing his/her suggestions are a useful way of finding some hidden gotchas.

The first suggestion was to switch 

```ruby
numbers.inject(0) do |ret, n|
  ret += n**2
end
```
to

```ruby
numbers.map { |n| n**2 }.sum
```

A lot of Ruby programmers, myself included, aren't always sure which methods are part of Ruby and which are part of Rails. `sum` is a Rails thing, so we can't actually use this code (the commentor does point this out, a few lines down). `sum` is just syntactic sugar on top of ActiveRecord::Calculations. Why ActiveRecord has a whole library for doing math is a question for another time.

We can excise the Rails code, though.

```ruby
numbers.map { |n| n**2 }.inject(&:+)
```

That works well enough. Those who are better with blocks in Ruby can likely come up with something more stylish.

So we've reduced this to one line. Better? Not for me. Blocks take mental effort and chaining them like this confuse me. But we've certainly improved our Ruby Golf score!

Which brings us to point number one. Small is great, understandable is better.

Let's take a look at the second suggestion:

> Heck, if you define Numeric#squared, it could be number.map(&:squared).sum

And the implementation for that would be something like this:


```ruby
class Numeric
  def squared
    self ** 2
  end
end

numbers.map(&:squared).inject(:+)
```

And that (aside from the double block thing) is pretty nice. Then we have to implement that sum_of_cubes thing. So we go back and:

```ruby
class Numeric
  def cubed
    self ** 3
  end
end

numbers.map(&:cubed).inject(:+)
```

Then someone asks about fourth powers, at which point you:

```ruby
class Numeric
  def squared
    power(2)
  end

  def cubed
    power(3)
  end

  def power(x)
    self ** x
  end
end
```

And now you have a one-liner that works on squares and cubes, but not anything higher, because [Symbol.to_proc](http://invisibleblocks.com/2008/03/28/ruby-facets-symbolto_proc-classto_proc/) doesn't take parameters.

```
numbers.map(&:squared) # works great!
numbers.map(&:cubed) # still cool!
numbers.map(&:power) # yer boned!
```

At which point you've just discovered the problem with syntactic sugar, sometimes it's syntactic salt. Man, I wish I'd come up with the term [Syntactic Salt](http://c2.com/cgi/wiki?SyntacticSalt). It's great.

Anyway. The point here is that convenience methods like this have to be implemented carefully. If you're putting sugar on a constrained set of methods, then you're probably fine. But if, like above, you're putting sugar on something that's possibly infinite, then you need to make sure that later expansions won't clash with your earlier code.

None of this is to crap on the person who was kind enough to comment on my Reddit post. Both his/her suggestions were good, but also hid some problems that might not be obvious at first glance.

By the way, that `power` method [already exists in the Standard Library](http://ruby-doc.org/stdlib-2.2.0/libdoc/bigdecimal/rdoc/BigDecimal.html#method-i-power). I had no idea.

Enough code, links.

First, [Pull Requests: How to Get and Give Good Feedback](https://www.kickstarter.com/backing-and-hacking/pull-requests-how-to-get-and-give-good-feedback) from the Kickstarter development blog. We are still figuring out a good pull request workflow in my team and the advice here is solid.

[When Edge Cases Poke Holes in Your Perfect Solution](http://www.justinweiss.com/blog/2015/01/13/when-edge-cases-poke-holes-in-your-perfect-solution/) is a nice essay on not being clever and to realize when your cleverness has failed.

Last, [Schmaltz](http://cooking.nytimes.com/recipes/1017056-schmaltz-roasted-brussels-sprouts) is delicious and everything about that recipe is making me hungry right now. Try more fats in your life!

Next week's post on Design is Refactoring will be all about polymorphism and Roman numerals. Tell you're friends. I'm sure they are just dying to know about that stuff!
