---
layout: post
title: "Data Clumps in My Lawn"
date: 2015-04-06 12:35:35 -0600
author: Ian Whitney
---

Data Clumps

Spring is hesitantly springing here in Minneapolis, which is a time of _unique_ smells. If you live in a cold climate you may know what I mean. That funky odor of hard-frozen ground returning to life. It is a time of big strides forward -- it's so warm and sunny today! -- but frequent strides backward -- tomorrow will be grey and snowy. Such is spring, and such is programming.

Our smell this week is Data Clumps. As per Fowler & Beck:

> Often you'll see the same three or four data items together in lots of places: fields in a couple of classes, parameters in many method signatures. Bunches of data that hang around together really ought to be made into their own object.

The Venn diagram overlap between Data Clumps and the Janus-faced [Shotgun Surgery](http://tinyletter.com/ianwhitney/letters/shotgun-surgery-a-pretty-exciting-name-something-so-tedious)/[Divergent Change](http://tinyletter.com/ianwhitney/letters/divergent-change-a-smell-by-any-other-name) is high. They all tackle the same idea: put stuff together that is going to change for the same reason.

A common example of data clumping, which I first saw in [Avdi Grimm](http://about.avdi.org/)'s excellent book [_Confident Ruby_](http://www.confidentruby.com/), is the coordinate.

```ruby
class MapGrid
  def add_point(x: x, y: y)
    @points << [x, y]
  end
end
```

`x` and `y` will always be passed around together. They clearly represent a single idea, which Avdi called a Point:

```ruby
class Point
  attr_accessor x, y

  def intialize(x, y)
    self.x = x
    self.y = y
  end
end

class MapGrid
  def add_point(a_point)
    @points << [a_point.x, a_point.y]
  end
end

MapGrid.new.add_point(Point.new(1,2))
```

And that's a very clear example of a data clump and how to fix it with Extract Class. Not much more to say about that.

A less clear example is a common pattern in the Rails world: cleaning up views and controllers with [Presenters](http://blog.jayfields.com/2007/03/rails-presenter-pattern.html) (or [View Objects](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/), depending on where you learned about the idea). Let's say we have a Rails view like this:

```erb
<h1>Hello <%= @user.name %>!</h1>
<h3>You have <% @notifications.count %> new messages</h3>
```

Like `x` and `y` and Point, this view will always need a `user` and a `notificiation`. Views aren't classes like Point or MapGrid, but they have parameters all the same. You can think of your views as a class if that helps make it clearer:

```
class UserView
  attr_accessor :user, :notifications

  def initialize(user, notifications)
    self.user = user
    self.notifications = notifications
  end

  def to_s
  <<-OUTPUT
    <h1>Hello #{user.name}!</h1>
    <h3>You have #{notifications.count} new messages</h3>
  OUTPUT
  end
end
```

If we're always clumping `user` and `notifications`, then maybe we should combine them in a class:

```ruby
class UserPresenter
  attr_accessor :user, :notifications

  def initialize(user, notifications)
    self.user = user
    self.notifications = notifications
  end
end
```

And pass that to the view, instead of the two instance variables.

Link time. AKA, the time I finally close all these browser tabs that I've had open for 2 weeks.

Do you use `tail -f` to watch log activity? I certainly do. [This article on how 'less' is a better tool](http://www.brianstorti.com/stop-using-tail/) was super helpful for me.

While I'm not sure I agree with Adam Hawkins' conclusions in his article [On Ruby](http://hawkins.io/2015/03/on-ruby/), it was still an interesting read. And it pointed me to his [Lift](https://github.com/ahawkins/lift) gem, which I think I'll be using soon. And Marcus Schirp's [Concord](https://github.com/mbj/concord) gem, for which I can also see some immediate uses.

I whined a bit on Twitter about some unexpected roadbumps in my attempts to learn Haskell and Peter Swan leapt in to [help me out](https://twitter.com/pdswanII/status/580206789054107648). The [Learn Haskell](https://github.com/bitemyapp/learnhaskell) guide in particular has been very useful. Thanks, Peter!

For a non-programming link, the [De La Soul Kickstarter](https://www.kickstarter.com/projects/1519102394/de-la-souls-new-album) has been on my mind a lot this week. I can go on at great length about De La, but I'll save you from that and just say that no band has been more important to me. This was not a kickstarter where I thought, "What's the minimum I can give to get the reward I want?". Instead I was trying to figure out the maximum I could feasibly give. And I was heartened to see that they blew through their fundraising goal in just one day.

Next week there will be another blog post, likely about the refactoring patterns Change Value to Reference and Change Reference to Value. Unless I decide to write about something else. Don't try to control me, world!

If there are changes/topics/etc. you'd like to see, please Reply, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/2).

Until next time, true receivers.
