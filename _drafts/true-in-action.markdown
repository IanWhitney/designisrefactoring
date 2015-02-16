---
layout: post
title: "TRUE in Action"
---

[Last week](http://designisrefactoring.com/2015/02/08/introducing-sandi-metz-true/) I introduced [Sandi Metz](http://www.sandimetz.com)'s TRUE heuristic and promised that this week we'd see in in action<sup>[\*](#action)</sup>. Let's jump right in.

Sandi, along with [Katrina Owen](https://twitter.com/kytrinyx), are working on a [book about OO Design based on the "99 Bottles of Beer" song](http://signup.99bottlesbook.com). If that coding problem is good enough for them, then it's good enough for me! Exercism offers it as [one of their problems](https://github.com/exercism/x-common/blob/master/beer-song.yml) as well, so we already have [a working test suite](https://github.com/exercism/xruby/blob/master/beer-song/beer_song_test.rb).

Just hacking code together, I ended up with this solution. 

{% highlight ruby %}
class BeerSong
  def verses(first_verse, last_verse)
    verses = (last_verse..first_verse).to_a.reverse
    verses.inject("") {|ret, n| ret += "#{verse(n)}\n" }
  end

  def verse(number)
    if number == 2
      "#{number} bottles of beer on the wall, #{number} bottles of beer.\n" +
      "Take one down and pass it around, #{number - 1} bottle of beer on the wall.\n"
    elsif number == 1
      "#{number} bottle of beer on the wall, #{number} bottle of beer.\n" +
      "Take it down and pass it around, no more bottles of beer on the wall.\n"
    elsif number == 0
      "No more bottles of beer on the wall, no more bottles of beer.\n" +
      "Go to the store and buy some more, 99 bottles of beer on the wall.\n"
    else
      "#{number} bottles of beer on the wall, #{number} bottles of beer.\n" +
      "Take one down and pass it around, #{number - 1} bottles of beer on the wall.\n"
    end
  end

  def sing
    verses(99,0)
  end
end
{% endhighlight %}

Now that our tests pass we can ask, how TRUE is our code? That will be easier to discuss in the context of some new features:

- California is clamoring for Beer Song as a Service (BSaaS), but they want it about wine
- Also, they will get more wine from the cellar, not the store
- Because wine is stronger, the full song should start with 20 bottles, not 99

### Transparent

#### It is easy to see the code's function and the effect of a change

`sing` is pretty transparent. `verses` has a bit of rigmarole to handle Ruby's ranges only being ascending, not descending. But it's idiomatic enough that I think it's understandable. The `verse` method isn't as transparent as I'd like. Its if/elsif/else structure uses some magic numbers and also makes it hard to see the differences between the cases. But it's clear enough what is going on there.

Is the code we need to change to implement these features transparent to us? I think so. In a new `WineSong` class we'd change all instances of the word "beer" to "wine" and we need to change the special "no bottles" verse to say that they go to the cellar
Then we'd change `sing` need to call `verses(20,0)`.

But then, oops, we see that the 99 is *also* in the special "no bottles" verse, so we have to change it there. So maybe that change is not as transparent as we thought.

### Reasonable

#### The effort to make a change reflects its complexity

We can judge reasonableness using the same feature requests. All of these features are very low-complexity changes. Do they all take the same amount of effort? Not really. The cellar wording requires us to change a couple of words, easy. Going from 99 verses to 20 The verse count requires a change to a method and to the wording, so was a little tougher. But changing "beer" to "wine" requires us to change the code in 12 places. Yes, you can use Find and Replace (or your tool of choice) to make that change in one command. But you still end up changing the code in 12 places for a one word change. That seems excessive.

So, for the changes we want to make, our code is not entirely Reasonable. Let's just note that for now and move on.

### Usable

#### The code can be used in other contexts

This one is pretty clear. We have code that works in a Beer context, but it requires multiple changes to work in a Wine context. The only unchanged code is the `verses` method. The other two methods in BeerSong needed changes to work in the Wine context. This code is not very Usable.

### Exemplary

#### The code serves as an example for future code

Let's look at our WineSong code.

{% highlight ruby %}
class WineSong
  def verses(first_verse, last_verse)
    verses = (last_verse..first_verse).to_a.reverse
    verses.inject("") {|ret, n| ret += "#{verse(n)}\n" }
  end

  def verse(number)
    if number == 2
      "#{number} bottles of wine on the wall, #{number} bottles of wine.\n" +
      "Take one down and pass it around, #{number - 1} bottle of wine on the wall.\n"
    elsif number == 1
      "#{number} bottle of wine on the wall, #{number} bottle of wine.\n" +
      "Take it down and pass it around, no more bottles of wine on the wall.\n"
    elsif number == 0
      "No more bottles of wine on the wall, no more bottles of wine.\n" +
      "Go to the cellar and bring up some more, 20 bottles of wine on the wall.\n"
    else
      "#{number} bottles of wine on the wall, #{number} bottles of wine.\n" +
      "Take one down and pass it around, #{number - 1} bottles of wine on the wall.\n"
    end
  end

  def sing
    verses(20,0)
  end
end
{% endhighlight ruby %}

Because of the way BeerSong was structured we had to duplicate 95% of it in order to implement WineSong. Now imagine we implement TeaSong and MonsterEnergyDrinkSong, etc. This code will be copied each time. That is not exemplary.

My code is kind of transparent, kind of reasonable, not usable and not exemplary. What is the next step? Like [we did with the 4 Rules](http://designisrefactoring.com/2015/01/05/4-simple-rules-of-raindrops/), let's just start at the beginning and try to improve our code.

The big problem we had with Transparent was that changing the `sing` method revealed an unexpected necessary change in the `verse` method. Let's fix that.

{% highlight ruby %}
class BeerSong
  MAX_BOTTLES = 99
  MIN_BOTTLES = 0
  #...

  def verse(number)
    #...
    elsif number == MIN_BOTTLES
      "No more bottles of beer on the wall, no more bottles of beer.\n" +
      "Go to the store and buy some more, #{MAX_BOTTLES} bottles of beer on the wall.\n"
    #...
  end

  def sing
    verses(MAX_BOTTLES, MIN_BOTTLES)
  end
end
{% endhighlight ruby %}

I don't tend to use constants, but it works here and solves our Transparency problem. If we use this code to create a WineSong then we won't be surprised by the final verse of the song.

That change also fixes one of our Reasonable problems, that we had to change the verse method to handle the starting number of wine bottles. We're left with just one: changing 'beer' to 'wine' requires 12 code changes. We can follow the same pattern to fix this.

{% highlight ruby %}
class BeerSong
  MAX_BOTTLES = 99
  MIN_BOTTLES = 0
  DRINK = 'beer'
  #...

  def verse(number)
    #...
    elsif number == MIN_BOTTLES
      "No more bottles of #{DRINK} on the wall, no more bottles of #{DRINK}.\n" +
      "Go to the store and buy some more, #{MAX_BOTTLES} bottles of #{DRINK} on the wall.\n"
    #...
  end

  def sing
    verses(MAX_BOTTLES, MIN_BOTTLES)
  end
end
{% endhighlight ruby %}

And while we're at it, let's take the same approach to the cellar/store problem

{% highlight ruby %}
class BeerSong
  MAX_BOTTLES = 99
  MIN_BOTTLES = 0
  DRINK = 'beer'
  SUPPLIER = 'store'
  REFRESH_VERB = 'buy'
  #...

  def verse(number)
    #...
    elsif number == MIN_BOTTLES
      "No more bottles of #{DRINK} on the wall, no more bottles of #{DRINK}.\n" + 
      "Go to the #{SUPPLIER} and #{REFRESH_VERB} some more, #{MAX_BOTTLES} bottles of #{DRINK} on the wall.\n"
    #...
  end

  def sing
    verses(MAX_BOTTLES, MIN_BOTTLES)
  end
end
{% endhighlight ruby %}

After taking the simplest possible approach to make our code more reasonable, our BeerSong now looks like:

{% highlight ruby %}
class BeerSong
  MAX_BOTTLES = 99
  MIN_BOTTLES = 0
  DRINK = 'beer'
  SUPPLIER = 'store'
  REFRESH_VERB = 'buy'

  def verses(first_verse, last_verse)
    verses = (last_verse..first_verse).to_a.reverse
    verses.inject("") {|ret, n| ret += "#{verse(n)}\n" }
  end

  def verse(number)
    if number == 2
      "#{number} bottles of #{DRINK} on the wall, #{number} bottles of #{DRINK}.\n" + 
      "Take one down and pass it around, #{number - 1} bottle of #{DRINK} on the wall.\n"
    elsif number == 1
      "#{number} bottle of #{DRINK} on the wall, #{number} bottle of #{DRINK}.\n" + 
      "Take it down and pass it around, no more bottles of #{DRINK} on the wall.\n"
    elsif number == MIN_BOTTLES
      "No more bottles of #{DRINK} on the wall, no more bottles of #{DRINK}.\n" + 
      "Go to the #{SUPPLIER} and #{REFRESH_VERB} more, #{MAX_BOTTLES} bottles of #{DRINK} on the wall.\n"
    else
      "#{number} bottles of #{DRINK} on the wall, #{number} bottles of #{DRINK}.\n" + 
      "Take one down and pass it around, #{number - 1} bottles of #{DRINK} on the wall.\n"
    end
  end

  def sing
    verses(MAX_BOTTLES, MIN_BOTTLES)
  end
end
{% endhighlight ruby %}

We've worked our way through **T** and **R**, but is our code more **U**sable as a result? Remember that our usability problem was that we had to clone this entire class in order to make a WineSong. Is that still the case? Well, maybe we could do this:

{% highlight ruby %}
class WineSong < BeerSong
  MAX_BOTTLES = 20
  MIN_BOTTLES = 0
  DRINK = 'wine'
  SUPPLIER = 'cellar'
  REFRESH_VERB = 'bring up'
end
{% endhighlight ruby %}

We can't actually do that, though. Redefining constants is both a bad idea and justifiably [trickier](http://stackoverflow.com/questions/3375360/how-to-redefine-a-ruby-constant-without-warning). But the fact that we have isolated just these few differences between our Beer and WineSongs shows us that we're on the right Usability track, we just need to try a better solution.

Before we try another solution, I'll tell you a little secret: Sandi's "Usable" metric is just a stealthy way of saying "Open/Closed Principle". Code that is "usable in other contexts" is code that is "open to extension". I've covered the [Open/Closed Principle](http://designisrefactoring.com/2015/01/25/romans-and-the-open-closed-principle/) before and how to refactor our code so that it follows OCP:

1. Find the code that makes it hard to implement your new feature
2. Refactor your existing code to remove that difficulty.

We've already done the first step and found the five variables that prevent us from easily implementing WineSong. Let's move on to the second step. If we have variable that need to change between types, then some Extract Class and Inheritance could work.

{% highlight ruby %}
class DrinkingSong
  def verses(first_verse, last_verse)
    verses = (last_verse..first_verse).to_a.reverse
    verses.inject("") {|ret, n| ret += "#{verse(n)}\n" }
  end

  def verse(number)
    if number == 2
      "#{number} bottles of #{drink} on the wall, #{number} bottles of #{drink}.\n" + 
      "Take one down and pass it around, #{number - 1} bottle of #{drink} on the wall.\n"
    elsif number == 1
      "#{number} bottle of #{drink} on the wall, #{number} bottle of #{drink}.\n" + 
      "Take it down and pass it around, no more bottles of #{drink} on the wall.\n"
    elsif number == min_bottles
      "No more bottles of #{drink} on the wall, no more bottles of #{drink}.\n" + 
      "Go to the #{supplier} and #{refresh_verb} more, #{max_bottles} bottles of #{drink} on the wall.\n"
    else
      "#{number} bottles of #{drink} on the wall, #{number} bottles of #{drink}.\n" + 
      "Take one down and pass it around, #{number - 1} bottles of #{drink} on the wall.\n"
    end
  end

  def sing
    verses(max_bottles, min_bottles)
  end
end

class BeerSong < DrinkingSong
  def max_bottles
    99
  end

  def min_bottles
    0
  end

  def drink
    "beer"
  end

  def supplier
    "store"
  end

  def refresh_verb
    "buy some"
  end
end
{% endhighlight ruby %}

Or maybe you want something more Factory-like.<sup>[\*](#factory)</sup>

{% highlight ruby %}
class DrinkingSong
  attr_accessor :max_bottles, :min_bottles, :drink, :supplier, :refresh_verb

  def initialize(configuration)
    self.max_bottles = configuration.max_bottles
    self.min_bottles = configuration.min_bottles
    self.drink = configuration.drink
    self.supplier = configuration.supplier
    self.refresh_verb = configuration.refresh_verb
  end
  # 
  # verse, verses and sing method are here, unchanged from the previous example
end

class SongFactory
  def self.build(configuration)
    DrinkingSong.new(configuration)
  end
end

class BeerSong < SimpleDelegator
  def initialize
    __setobj__ (SongFactory.build(config))
  end

  def config
    OpenStruct.new(
      max_bottles: 99,
      min_bottles: 0,
      drink: 'beer',
      supplier: 'store',
      refresh_verb: 'buy'
    )
  end
end

class WineSong < SimpleDelegator
  def initialize
    __setobj__ (SongFactory.build(config))
  end

  def config
    OpenStruct.new(
      max_bottles: 20,
      min_bottles: 0,
      drink: 'wine',
      supplier: 'cellar',
      refresh_verb: 'bring up'
    )
  end
end
{% endhighlight ruby %}

And now we've separated the algorithm of the song from its configuration, meaning that the DrinkingSong can be used in any drinking context (well, anything that comes in bottles; though that dependency would be easy to extract).

We can check **U** off our list and look at **E**xemplary. When I looked at the initial version of this code, I said it was Unexemplary because any additional songs required a nearly-exact copy of the BeerSong class. But, hey, we just solved that problem! There might be some things we want to tweak with our new solution, but it raises far fewer alarms than our old code. I would be ok with the factory-like solution being used for MonsterEnergyDrinkSong, or whatever other song comes our way.

There's still one outstanding problem -- the if/elsif/else-happy `verse` method with and its duplication that we noticed earlier. As we saw when we used [Open/Closed](http://designisrefactoring.com/2015/01/25/romans-and-the-open-closed-principle/), code that doesn't cause problems doesn't get refactored. Right now nothing is compelling me to change this method, so I haven't. There certainly seems to be a lot of duplication in `verse`, but later features might reveal that this is [Incidental Duplication](http://confreaks.tv/videos/rubyconf2010-maintaining-balance-while-reducing-duplication), not duplication of knowledge. More likely, it will reveal the opposite. Point is, it doesn't matter right now, so let's quit before we make the code worse.

You do not have to wait to find out what this week's newsletter will be about, I'll just tell you; I'll be talking about one of the most prevalent code smells in the Ruby-verse -- Long Parameter List. You can [sign-up for the newsletter](http://tinyletter.com/ianwhitney/), check out [previous issues](http://tinyletter.com/ianwhitney/archive) or go sledding/surfing (depending on hemisphere). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com

<a name='action'>\*</a> I also promised slightly-dirty nursery rhymes, which I ended up not writing about.

<a name='factory'>\*</a> This may not be an official factory, I need to spend more time with the Patterns book.
