---
layout: post
title: "4 Simple Rules of Raindrops"
date: 2015-01-05T08:00:00-06:00
author: Ian Whitney
---

After solving the [Raindrops problem](https://github.com/exercism/x-common/blob/master/raindrops.md) in Exercism, I have this code:

```ruby
require 'prime'

class Raindrops
  def self.convert(number)
    factors = Prime.prime_division(number).map {|x| x[0]}
    ret = ""
    ret << "Pling" if factors.include?(3)
    ret << "Plang" if factors.include?(5)
    ret << "Plong" if factors.include?(7)
    ret.empty? ? number.to_s : ret
  end
end
```

When we call `Raindrops.convert(9)`, the noise made depends on the prime factors of 9. Yes, I had to look up what [prime factors are](http://www.mathsisfun.com/prime-factorization.html). Math is not my strong suit.

The code works, but then I decide to add two new features.

1. The ability to make different noises
2. The ability to have different noise-making criteria (i.e., even/odd instead of prime factors)

<!--break-->

Time to refactor! I don't want to just jump in and add the features. That way lies confusion. Instead, I want to keep the code's current functionality while changing its design until introducing the new features is trivial. [Kent Beck said this more succinctly](https://twitter.com/kentbeck/status/250733358307500032).

> For each desired change, make the change easy (warning: this may be hard), then make the easy change

In addition, I just finished re-reading Corey Haines' book [_Understanding the Four Simple Rules of Design_](https://leanpub.com/4rulesofsimpledesign); so as I refactor I want to make sure I improve the design of my code so that it follows those four rules:

- Tests Pass
- Express Intent
- No Duplication of knowledge
- Small

My tests pass, so I can skip rule 1. On to rule 2, "Express Intent", which this code doesn't do at all. What is the intent of:

- Getting the prime factors?
- The variable named 'ret'. What is ret?
- The final ternary statement?
- The magic numbers of 3, 5 and 7?

My first several refactorings are about clearing up the intent of this code. In some cases it is as simple as changing a variable name, in others I have to use patterns from _Refactoring_.

### Express Intent with Extract Class

```ruby
class Raindrops
  def self.convert(number)
    drops = DropCounts.new(number)
    #...
  end

end

class DropCounts
  include Enumerable

  def initialize(number)
    @members = Prime.prime_division(number).map(&:first)
  end

  def each &block
    @members.each{|member| block.call(member)}
  end
end
```

I'm trying to clarify this code by doing two things here, giving it a better name, and hiding the implementation in another class. In the mental model I'm applying to this code the noise is being made by the number of drops. The math behind figuring out that count is unimportant. This is a simple application of the Extract Class pattern (_Refactoring_, p. 149), plus a little Ruby syntax to make DropCounts work like an array.

This refactoring also shows a problem I run into throughout this code, the problem I'm trying to solve is really vague. Why does calling `Raindrops.convert(9)` mean that there are 3 'drops'? What does 9 represent and what I converting it from or to? I have no idea, but I have to stick with that interface because it was the one given to me by Exercism.

I then further clarify my intent by [renaming variables](https://github.com/IanWhitney/exercism_raindrops/commit/e4c232ec941f18469c02cf54607830d576485baa) and [extracting a Sound class](https://github.com/IanWhitney/exercism_raindrops/commit/f5cf5681745199cb8c3179ab34f4d3f32d36aaab). Now all the business logic (such at is is) exists outside of Raindrops.

```ruby
class Raindrops
  def self.convert(number)
    drops = DropCounts.new(number)
    sound = Sound.made_by(drops)
    sound.empty? ? number.to_s : sound
  end
end
```

### Remove Knowledge Duplication with Polymorphism

I'm starting to feel more comfortable with the intent of my code. But there's one thing at this point that's really bugging me:

```ruby
class Sound < String
  def initialize(drops)
    sound << "Pling" if drops.include?(3)
    sound << "Plang" if drops.include?(5)
    sound << "Plong" if drops.include?(7)
    super(sound)
  end
  #...
end
```

There's several problems here:

- The intent is unclear. What is the meaning of drops including a number?
- We still have magic numbers
- Doing the same thing 3 times seems like duplication

I say 'seems like' because in _Four Rules_, Haines identifies two kinds of duplication: knowledge and of structure. Duplication of structure is sections of code that look the same, but that do different things. Duplication of knowledge is sections of code that know the same thing. These three lines are clearly duplication of knowledge. They all know that they have to ask `drops.include?`. If we ever change that method name we'd have to change each line, a clear indicator of knowledge duplication.

We can fix all of these problems with Extract Class. Should `Sound` know what sounds are made by which magic numbers? We know that our upcoming feature will introduce new sounds and new magic numbers, which will be hard with this current code. We want to make that change easy, which we can do by extending our admittedly shaky mental model with a surface for the raindrops to hit.

```ruby
#...
class Raindrops
  def self.convert(number, surface: Bucket)
    drops = DropCounts.new(number)
    sound = Sound.made_by(drops, surface)
    sound.empty? ? number.to_s : sound
  end
end

class DropCounts
#...
end

class Sound < String
#...
  def initialize(drops, surface)
    drops.each do |drop|
      sound << surface.make_sound(drop)
    end
    super(sound)
  end
end

class Bucket
  def self.make_sound(times)
    case times
    when 3
      "Pling"
    when 5
      "Plang"
    when 7
      "Plong"
    else
      ""
    end
  end
end
```

Jim Gay introduced the idea of a surface when [we were discussing this exercise](https://gist.github.com/IanWhitney/6d8d777659896ff9e20d) and I am stealing it shamelessly.

This one commit has at least 3 different refactorings it it, which is a terrble job on my part. Normally I try to do one refactoring at a time. The refactorings are:

1. Extract Class
2. Introduce Parameter Object (_Refactoring_, p. 295)
3. Replace Conditional with Polymorphism (_Refactoring_, p. 255)

Extract Class is pretty clear. Before this commit we didn't have a Bucket, now we do. Introduce Parameter Object, if I'd done it correctly, would have looked something like this:

Before:

```ruby
class Raindrops
  def self.convert(number, surface = {3 => "Pling", 5 => "Plang", 7 =>"Plong"})
  ...
  end
end
```

After:

```ruby
class Raindrops
  def self.convert(number, surface = Bucket)
  ...
  end
end

class Bucket
...
end
```

But I skipped the intemediate step and went straght to passing in an object.

And it's a little hard to see Replace Conditional with Polymorphism because we never had the conditional. Imagine how the code would have looked with a Bucket and a Table surface but no polymorphism.

```
class Sound < String
#...
  def initialize(drops, surface)
    if surface.is_a?(Bucket)
      sound << "Pling" if drops.include?(3)
      sound << "Plang" if drops.include?(5)
      sound << "Plong" if drops.include?(7)
    elsif surface.is_a?(Table)
      sound << "Pink" if drops.include?(2)
      sound << "Pank" if drops.include?(8)
      sound << "Ponk" if drops.include?(100)
    #... and so on 
    end
  end
end
```

That's the conditional we replaced by introducing the Surface duck-type.

With that, we're nearly ready to implement our new features. Introducing a new surface is trivial, and we can use the same techniques to introduce new magic numbers. After a few more commits, we have:

```
require 'prime'

#Tests Pass
#Expresses Intent
#No Duplication (DRY)
#Small

class Raindrops
  def self.convert(drops, surface: Bucket, counter: RaindropCounts)
    SoundEffect.made_by(drops, surface, counter)
  end
end

class RaindropCounts
  include Enumerable

  def initialize(number)
    @members = Prime.prime_division(number).map(&:first)
  end

  def each &block
    @members.each{|member| block.call(member)}
  end
end

class SoundEffect < SimpleDelegator
  def self.made_by(substance, surface, counter)
    self.new(substance, surface, counter)
  end

  def initialize(substance, surface, counter)
    self.substance = substance
    self.surface = surface
    self.counter = counter
    __setobj__(make_sound)
  end

  private

  attr_accessor :substance, :surface, :counter

  def make_sound
    sound = counter.new(substance).each_with_object("") do |hit, s|
      s << surface.make_sound(hit)
    end
    sound.empty? ? substance.to_s : sound.to_s
  end
end

class Bucket
  def self.make_sound(hit_count)
    case hit_count
    when 3
      "Pling"
    when 5
      "Plang"
    when 7
      "Plong"
    else
      ""
    end
  end
end
```

I haven't done it here, but you could write another counter like `RaindropCounts` and have a new set of magic numbers.

All of the commits are [in the GitHub repo](https://github.com/IanWhitney/exercism_raindrops/commits/4rules), if you want to take a look.

### What happened to small?

You may have noticed that I never even discussed the 4th rule. There are a couple reasons for that. I find that iterating through rules 2 and 3 leaves you with small code. Also, this problem we were solving was pretty trivial, so there was never a reason for long classes. That `make_sound` method in Bucket might be too long, but I don't have a compelling reason to change it right now.

There are other problems still lingering in this code. That weird ternary is still there and it doesn't really explain why I return the 'substance' if the 'sound' is empty. I view this code, and some of the other weird bits, as vestiges of the intial problem we were trying to solve. If I was able to come up with a clearer mental model for the problem, then I'd be able to make this code more intention revealing.

### Wrap Up

That's a very quick introduction to refactoring code following the four rules of simple design. The rules are incredibly powerful and yet easy to understand. If you want to learn more, I happily recommend [Corey's book](https://leanpub.com/4rulesofsimpledesign). It's a very short book, but one I return to again and again.

I'm still figuring out the best way of writing these blog posts. If you have thoughts, send me a note on Twitter [@iwhitney](https://twitter.com/iwhitney/).

In addition to this site I'm publishing a weekly newsletter. It usually contains further thoughts on design along with links and ramblings about non-code things. [Signup is easy and free](http://tinyletter.com/ianwhitney/) and you can always checkout [previous newsletters](http://tinyletter.com/ianwhitney/archive).
