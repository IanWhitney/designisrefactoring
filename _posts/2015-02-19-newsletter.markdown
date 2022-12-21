---
layout: post
title: "Sneaky Long Parameters, Hiding in the Hashes"
date: 2015-02-19 12:35:35 -0600
author: Ian Whitney
---

Sneaky Long Parameters, hiding in the Hashes

First off, welcome to all new readers. Enough of you have joined in the past two weeks that I feel I should restate the central premise of this whole endeavor: I have no idea what I'm doing. I talked about this in an earlier newsletter [about practice](http://tinyletter.com/ianwhitney/letters/practice-and-being-dumb), should you want to read more about how I am dumb.

That done, let's get into the next code smell from Fowler & Beck's list: Long Parameter List.

> Long parameter lists are hard to understand, because they become inconsistent and difficult to use, and because you are forever changing them as you need more data.

Honestly, I think this is largely accepted as a given. At least in the Ruby community. This is driven by testing, I suspect. Brittle tests that require extensive changes every time you change the parameters in your method? No thanks! I only rarely see methods with an [arity](https://en.wikipedia.org/wiki/Arity) greater than 3.

In fact, I see a lot of methods with an arity of 1 or 2. They look like this

```
def be_awesome(options = {})
  foo = options[:bar]
  baz = options.fetch(:bat, false)
  #... etc, for many many lines
end
```

Who knows how many parameters are hiding in `options`. Yes, even with arity 1 a method can still have Long Parameter List. Yes, using a hash saves you the trouble of remembering the exact order of your parameters. And it lets you choose what to do with missing parameters. But on the other hand, a hash isn't that different from an elevator in a spooky story -- [there's always room for one more](http://www.snopes.com/horrors/ghosts/onemore.asp).

And each parameter you stick in there is totally hidden. I can't look at the signature for that method and tell what parameters are required, which are optional or even what's allowed. And the complexity only increases if your method accepts [**two** parameter hashes](http://apidock.com/rails/ActionView/Helpers/DateHelper/date_select).

Long Parameter List usually points to an unidentified collaborator. If you haven't looked at [this week's _Design is Refactoring_ post](http://designisrefactoring.com/2015/02/16/true-in-action/), the final code solution shows one fix to this problem: extract those parameters out to to an object. I only went so far as extracting out the configuration to an OpenStruct, but you could go as far as moving config into its own independent class. You probably should, since OpenStruct responds to everything, which sometimes introduces weird surprises.

My approach most closely matches the [Introduce Parameter Object](http://refactoring.com/catalog/introduceParameterObject.html) pattern in _Refactoring_ (p. 295). I took all of the parameters, bundled them into their own object and simply passed the object to the method. But that's not the only way to solve the problem. I could have solved my beer problem this way:

```
class BeerSong < SimpleDelegator
  def initialize
    __setobj__ (SongFactory.build(self))
  end

  def max_bottles
    99
  end

  def min_bottles
    0
  end
  #...and so on
end
```

This approach is the [Preserve Whole Object](http://refactoring.com/catalog/preserveWholeObject.html) pattern (p. 288). Instead of passing in a new object with the parameter methods, I've added the parameter methods to myself and can just pass myself in.

There's even a third fix to Long Parameter List, [Replace Parameter with Method](http://refactoring.com/catalog/replaceParameterWithMethod.html) (p. 292). If my BeerSong code did:

```
class BeerSong
  def initialize
    SongFactory.new(self, drink_name)
  end

  def drink_name
    self.class.to_s.sub("Song","")
  end
end

class SongFactory
  def initialize(song, drink_name)
    @song = song
    @drink_name = drink_name
  end
end
```

There's no good reason to pass `drink_name` as a parameter. In Replace Parameter with Method, we'd change the code to:

```
class BeerSong
  def initialize
    SongFactory.new(self)
  end
end

class SongFactory
  def initialize(song)
    @song = song
    @drink_name = @song.drink_name
  end
end
```

Short parameter lists! Good for you, good for your code, good for anyone who has to work with your code. Think about it, won't you?

Links?

Nope. I wish I had exciting links for you this week, but I do not. I think 3 different plagues have visited my house in the last week, so I have not been finding the fun links that I normally would.

Until next time, true receivers.
