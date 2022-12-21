---
layout: post
title: "Divergent Change, a smell by any other name"
date: 2015-02-26 12:35:35 -0600
author: Ian Whitney
---

Divergent Change, a smell by any other name

Welcome to issue 10 of the newsletter. It's always nice to reach a meaningless milestone!

This week we continue our trek through _Refactoring_'s Code Smell list with **Divergent Change**:

> Divergent change occurs when one class is commonly changed in different ways for different reasons.

This is just another way of identifying classes that violate the Single Responsibility Principle. If you find yourself changing the same class to implement totally different things, then that class has too many responsibilities.

In Rails projects the `User` class tends to accumulate far too many responsibilities. It's become the God Example of [God Objects](http://en.wikipedia.org/wiki/God_object).

```ruby
class User
  def full_name
    "#{first_name} #{last_name}"
  end

  def authorized?(action)
    is_admin?
  end
end
```

Here a User both knows how to display a full name *and* how to authorize actions. If you want to change either of these things, you need to change the User class.

The fix, as it so frequently is, is Extract Class. Which class do you extract? Why not both of them?


```Ruby
class UserPresenter < SimpleDelegator
  def full_name
    "#{first_name} #{last_name}"
  end
end

class ActionAuthorizer
  def authorized?(action, user)
    user.is_admin?
  end
end

class User
  # nothing here?
end
```

Now when you remember that full names can include salutations or middle initials, you have one class to change. And when you implement a better way of authorizing actions, you have one class to change.

There's an argument to be made for not extracting these methods. After all, they 'feel' like they belong to Users, right? Users have a full_name and users need to be authorized before we let them do destructive things.

This is, I think, a reflection of our tendency to base objects on real world things. Users are people, and people have full names. People are authorized to do things, and so on. Real world things are a complex web of responsibilities, behaviors and attributes. Why try to model that rat's nest into a single class? Keep it simple, unlike the real world.

I talked a little more about SRP in a previous [Design is Refactoring post](http://designisrefactoring.com/2015/02/01/robot-you-have-one-job/), in case you missed it.

Links? Yes, Links.

Much of my week has been spent working with the [Repository pattern](http://www.martinfowler.com/eaaCatalog/repository.html). Here are a couple of blog posts that I found useful. [Adam Hawkins](http://hawkins.io/2013/10/implementing_the_repository_pattern/) gave a great breakdown a couple of years back. And [Kamil Lelonek](https://medium.com/@KamilLelonek/why-is-your-rails-application-still-coupled-to-activerecord-efe34d657c91) wrote a nice post just a month ago. And I've watched this Jim Weirich presentation on [Decoupling from Rails](https://www.youtube.com/watch?v=tg5RFeSfBM4) at least 3 times.

Thanks to all the illnessess sweeping through my team we've been spending a lot of time working from home. This week we started using [tmate](http://tmate.io) which is a dead simple way to share a command line with a remote pair. We've even started using it when both people are in the office, so that we can work around that one weird guy who uses Dvorak (that's me, by the way).

For a non-programmy pick I'm going to hesitantly suggest [The Legend of Korra](http://www.nick.com/legend-of-korra/), the sequel/grown-up-version of Avatar: The Last Airbender. I had a bunch of friends who were big Avatar fans, but I could never get into it; mostly because the seasons were too long. 23 episodes per year resulted in a mix of Important Episodes and a bunch of filler. Korra trims the seasons down to a more manageable 13 episodes. I've only watched a few episodes so far, but I'm enjoying it. If you have Amazon Prime, you can watch the first two seasons for free.

Until next time, true receivers.
