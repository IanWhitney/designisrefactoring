---
layout: post
title: "The Intention of Squares"
date: 2015-01-11T12:57:44-06:00
author: Ian Whitney
---

Let's start off with some code. This solves the [Squares exercise](https://github.com/exercism/x-common/blob/master/difference-of-squares.yml) on [Exercism](http://exercism.io).

{% highlight ruby %}
class Squares
  attr_accessor :number

  def initialize(number)
    self.number = number
  end

  def square_of_sums
    ((1..number).to_a.inject(0, :+)) ** 2
  end

  def sum_of_squares
    (1..number).to_a.inject(0) do |ret, n|
      ret += n**2
    end
  end

  def difference
    square_of_sums - sum_of_squares
  end
end
{% endhighlight %}

And let's hit it with some refactoring techniques that we covered in [last week's post](/2015/01/05/4-simple-rules-of-raindrops/): Extract Class and Extract Method. I'm going to speed through some of these things like a TV chef so that we can get to the point.

<!--break-->

- Extract a `Nums` class to handle the creation of the number enumerator [(commit)](https://github.com/IanWhitney/exercism_squares/blob/7c90271c0c3ad0feec3578dcbe183bcebc26789f/squares.rb)
- Extract a `calculate` method to remove duplication between our two methods [(commit)](https://github.com/IanWhitney/exercism_squares/blob/9b61d9ff1d0f36f4933ebaee40efee2021c37a3f/squares.rb)
- Extract a `Calculator` module since that logic doesn't seem right in Squares [(commit)](https://github.com/IanWhitney/exercism_squares/blob/6a018e54e09bf2a9cfb91513f1b16076809fbfcd/squares.rb)
- Extract a different `calculate` method to remove duplicate Calculator use [(commit)](https://github.com/IanWhitney/exercism_squares/blob/f671852d1d8bd618939d70a04da257d16b7596e2/squares.rb)

And, if we look at this cake that I made earlier, you'll see:

{% highlight ruby %}
class Squares
  attr_accessor :numbers

  def initialize(number)
    self.numbers = Nums.new(number)
  end

  def square_of_sums
    (calculate { |ret, n| ret += n }) **  2
  end

  def sum_of_squares
    (calculate { |ret, n| ret += n ** 2 })
  end

  def difference
    square_of_sums - sum_of_squares
  end

  private

  def calculate(&blk)
    Calculator.calculate(numbers, 0, &blk)
  end
end

class Nums
  include Enumerable

  def initialize(number)
    @members = (1..number).to_a
  end

  def each &block
    @members.each{|member| block.call(member)}
  end
end

module Calculator
  def self.calculate(numbers, start)
    numbers.inject(start) do |ret, n|
      yield(ret, n)
    end
  end
end
{% endhighlight %}

And does this cake taste delicious? No. It is a terrible cake. Warning: do not eat this terrible, terrible cake.

I think the design of this code is now worse. But is it really? There's no one gold standard for measuring the design of code; but since we just talked about the 4 Rules, I'll start by seeing how this code fares by that metric.

- Do the tests pass?
  - Yes.
- Does the code express intent? 
  - I don't think any of the changes I made improved the expressiveness of this code.
- Is there duplication of knowledge?
  - Not any I can see.
- Is the code small? 
  - Well, it's longer than it was. But each method is super small.

Failing the 2nd rule is a big problem, as improving the expressiveness of code is the best driver for improving the design.

Let's try another approach, [Sandi Metz's TRUE test](http://zassmin.com/post/81997862646/some-terms-from-sandi-metzs-practical). I'm going to dig into TRUE in a later post, but for now I'll just list her criteria.

- Transparent: It is easy for me to see what this does and the effect of a change
- Reasonable: A change takes effort reasonable for its complexity
- Usable: This can be used in other contexts
- Exemplary: You want others copying this style

Note that all of Sandi's criteria are about _modifying_ the code. Each point talks about the effort and effect of changes to your existing code. You can't look at a piece of static code and say whether or not it is TRUE; you have to think in the context of code maintenance, which is when design is most important.

I don't find this code to be very transparent. Passing a block from method to method to module requires a lot of effort to think about. And I don't see how it is more reasonable than my first solution. Implementing a new feature -- say, `sum_of_cubes` -- takes as much effort now as it did before. It's hard to extend it to use in other contexts. And, if it fails the first three criteria, I also don't want others copying this style.

And, finally, let's look at the code using my metric: the better designed the code, the more widely it can be used. Meaning that if only I'm going to use the code, then the design only has to satisfy me. But if it's going to be used by my whole team, then they all need to be able to understand/use/modify it. And if I'm going to share it with the world, then the design needs to meet an even higher standard.

By this heuristic the code fares similarly. This code doesn't do much and making it do more isn't any easier than my initial implementation. Overall, the mental effort involved in figuring what it does is higher than the value of the work it does for you.

So, three metrics and three thumbs down. I think I can safely say that this code is not well designed.

But! I applied all the same techniques I used last week! How could Extract Class and Extract Method fail me?

They didn't fail me, I failed them by using them without intention.

Refactoring techniques are not design tools; you can not just apply them and expect Good Design to magically appear. Instead, refactoring patterns are tools that you use to build a design with intention. If I take two pieces of wood and blindly bang a nail into them, I'll end up with a junky pile of wood. But if I say, "I want to build a bench, and I want it to look like this drawing. I need to start by nailing these two pieces together" then I am using my tools with intent and the result will be better. Well, I'm still terrible when it comes to carpentry, so I wouldn't trust any bench I build. But you get the point.

In these refactorings I never had a reason behind any of my changes. I never thought about what new feature I wanted to implement or what problem with the code I wanted to solve. Instead I just applied the refactoring tools mechanically, without intention. And the resulting code reflects that.

Before changing your code, ask yourself two simple questions: why are you making the change and what is the benefit<sup>[\*](#fn1)</sup>. Let's look at my commits:

1. [Extract Nums Class](https://github.com/IanWhitney/exercism_squares/commit/7c90271c0c3ad0feec3578dcbe183bcebc26789f)
- Why? To encapsulate the behavior of building an array.
- Benefit? Hmm. Remove some duplicate code, I guess.
2. [Extract Calculate Method](https://github.com/IanWhitney/exercism_squares/commit/9b61d9ff1d0f36f4933ebaee40efee2021c37a3f)
- Why? That code looks kinda similar.
- Benefit? I can claim to be DRY. Also, I get to look cool by using blocks.
3. [Extract Calculator Class](https://github.com/IanWhitney/exercism_squares/commit/6a018e54e09bf2a9cfb91513f1b16076809fbfcd)
- Why? Calculation isn't the responsibility of Squares
- Benefit? Other classes could use Calculator
4. [Remove duplicate Calculator calls](https://github.com/IanWhitney/exercism_squares/commit/f671852d1d8bd618939d70a04da257d16b7596e2)
- Why? Duplication bad!
- Benefit? DRY good!

None of those commits has particularly good justification. The third is probably the best, as it introduces a module that other classes could use. But those classes don't exist yet, and using Calculator isn't any easier than just calling `inject`, so it's a flimsy commit at best.

So, how would I refactor this code with intention? I wouldn't. There's no reason for it to change right now. And if someone were to ask me to implement that `sum_of_cubes` method I mentioned earlier, here's what I would do.

{% highlight ruby %}
def sum_of_cubes
  (1..number).to_a.inject(0) do |ret, n|
    ret += n**3
  end
end
{% endhighlight %}

Yes, there's duplication in there. But it's mostly duplication of structure. I still don't see a concept in this code that refactoring and design can make more clear. Maybe future requests will highlight a concept that needs extraction and clarification. But not yet.

Actually, I take that back. I will make two changes:

{% highlight ruby %}
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
{% endhighlight %}

We never used number except to make a range, might as just make the range on instantiation. And I'll remove the pointless `to_a` calls. Ranges support inject, which I forgot because I am dumb.

If you want to read more about how dumb I am, check out the [most recent newsletter](http://tinyletter.com/ianwhitney/letters/practice-and-being-dumb). Want that newsletter delivered to you weekly? [Sign-up is easy and free](http://tinyletter.com/ianwhitney/) and you can always checkout [previous newsletters](http://tinyletter.com/ianwhitney/archive).

<a name='fn1'>\*</a> Then, when you make the change, put the answers to these questions in your commit message. Future You will be thankful.
