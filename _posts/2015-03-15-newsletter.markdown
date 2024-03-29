---
layout: post
title: "Shotgun Surgery, a pretty exciting name something so tedious"
date: 2015-03-15 12:35:35 -0600
author: Ian Whitney
---

Shotgun Surgery, a pretty exciting name something so tedious

Shotgun Surgery! Sure sounds exciting. More exciting than its mirror-world twin, 'Divergent Change', which has a real snoozer of a name in comparison.
As always, let's start off with Fowler & Beck's definition of this code smell:

> Every time you make a kind of change, you have to make a lot of changes to a lot of different classes

In Divergent Change we changed one class for many types of changes; In Shotgun Surgery the roles are reversed -- one type of change leads to changes in many classes.
It's easy enough to illustrate:

```ruby
class Mailer
  def body(recipient)
    "Welcome to the club, #{name(recipient)}!"
  end

  def name(recipient)
    "#{recipient.first_name} #{recipient.last_name}"
  end
end

class FriendNudge
  def body(new_member)
    "Hey, #{name(new_member)} says you're friends!"
  end

  def name(new_member)
    "#{new_member.first_name} #{new_member.last_name}"
  end
end
```

In our soon-to-be-successful social app, we send an email welcoming new members and we then "Nudge" all of the new member's possible friends.

Should we ever want to change how we display a person's name, we have to change both classes. Clearly, there is a concept here that needs to be consolidated in one place. The solution is, surprise surprise, Extract Class.

That's a very simple example of Shotgun Surgery. Maybe you'll see something like that in your own code...but that example code is pretty terrible, so you probably won't.

However, maybe your app has code like this?

```ruby
class Member < ActiveRecord::Base
  named_scope :active, :conditions => #...
  named_scope :inactive, :conditions => #...
end

class Messages < ActiveRecord::Base
  named_scope :read, :conditions => #...
  named_scope :unread, :conditions => #...
end
```

If you have a Rails 2 app then that probably looks familiar. And if you've ever had to migrate a Rails 2 app to Rails 3.1, then you know what happens next.

```ruby
class Member < ActiveRecord::Base
  scope :active, -> { where(...) }
  scope :inactive, -> { where(...) }
end

class Messages < ActiveRecord::Base
  scope :read, -> { where(...) }
  scope :unread, -> { where(...) }
end

```

One change to a Rails API method and you're suddenly changing every file in /app/models. Shotgun Surgery at its worst.

I pick on Rails because I've had to do that 2.x to 3 migration more times than I care to remember. But the above example is true of literally every external library you include in your project. Use a Faraday method throughout your app? Hope it doesn't change! Love calling that sweet Paperclip macro? Oh, didn't you hear, that's been deprecated.

These external dependencies help you make your application, but they are not your application. As their code weaves its way into yours, you will find yourself bound to their API. Then upgrades become painful exercises in Shotgun Surgery. The solution for this is to extract that code from yours, wrap it adapters and isolate it. Then when you want to upgrade, you only have to change one file. Put that shotgun away.

I say that as if it is easy. But it's not, obviously. If it were then I wouldn't have an app still on Rails 2.3.

And with that bit of grim realism out of the way, let's talk links.

Two book suggestions to start off. First, [Growing Object Orient Software, Guided by Tests](http://www.growing-object-oriented-software.com/) is all about writing those adapters that prevent dependencies from freezing your application code in time. Second, [Confident Ruby](http://www.confidentruby.com/) is a fantastic collection of patterns for improving timid code. I return to both books frequently.

And last, some music. I am one of those programmers that uses headphones and music to block out people around me, but I find that music choice is tricky. I can easily destroy my focus with the wrong choice. I have had a lot of success listening to soundtracks for silent films, such as [Alloy Orchestra](http://www.alloyorchestra.com/) -- particularly their _Metropolis_ soundtrack. And while most of their releases aren't for films, the works of [Cinematic Orchestra](http://www.cinematicorchestra.com/) also work quite well for me.

Until next time, true receivers.
