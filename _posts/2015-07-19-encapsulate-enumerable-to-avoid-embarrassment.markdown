---
layout: post
title: "Encapsulate Enumerable to Avoid Embarrassment"
date: 2015-07-19T20:59:49-05:00
author: Ian Whitney
---

Vacations and work pulled me away from this blog for a bit, though I did manage to get [a few newsletters out](http://tinyletter.com/ianwhitney/archive). But vacation time is over (for now) and it's time to hop back into the Organizing Data section of _Refactoring_.

This week it's [_Encapsulate Collection_](http://refactoring.com/catalog/encapsulateCollection.html), which is full of great ideas. But its implementation is very Java-focused, heavy with reference to the [Java Collections Framework](https://en.wikipedia.org/wiki/Java_collections_framework). So, unlike past posts, I'm not going to focus as much on Fowler's text, but rather the spirit of it when applied to Ruby and its Enumerables.

<!--break-->

Let's start with our example -- code to handle work being sent through a job queue. There are a variety of `Worker` classes. A `Dispatcher` class uses the collection `Workers` to decide which `Worker` will do the work.

```ruby
class Dispatcher
  def perform(job)
    find_worker.new.execute(job)
  end

  def find_worker
    Workers.all.detect { |w| #logic that finds the correct worker class }
  end
end

class Workers
  def self.all
    @@workers ||= []
  end
end

class Worker
  def execute(_)
    raise NotImplementedError
  end

  def self.enable
    Workers.all << self
  end

  def self.disable
    Workers.all.delete(self)
  end
end

class EmailWorker < Worker
  def execute(job)
    # does work
  end
end

class SmsWorker < Worker
  def execute(job)
    # does work
  end
end

SmsWorker.enable
EmailWorker.enable
```

And that is reasonable. Maybe the `@@` class variable puts some people off, but I don't particularly mind them. It's not perfect code, but it works.


And then someone (maybe you!) adds some code with `Workers.all.clear` and your entire application breaks. Hard to do any work when you have no workers.

What happened here? Let's start with code that called `Workers.all`

```
# from Dispatcher
Workers.all.detect { |w| #logic that returns the correct worker class }

# from Worker
Workers.all << self
# ...
Workers.all.delete(self)
```

None of `Workers` clients ever actually dealt with `Workers`. They all dealt with the return value of `all`, and they **knew** it was an array. The `Workers` API didn't just allow this, it encouraged it by providing no other methods.

Not only do the clients know about the array, they also have direct access to change its state. Nothing prevents `Workers.all.clear`, as you just learned.

If you're collecting code smells I'd say this is a potent mix of Primitive Obsession and Demeter violations -- `Workers` existed as nothing more than an alias for Array, and its API forced clients to reach into its internals and muck around with a class variable. The fix is to encapsulate that array so that the implementation is totally off limits, forcing all client code to work with `Workers`, not with its guts.

Instead of exposing our array to the entire application, let's encapsulate it and hide the implementation behind a reasonable API.

Before we change any existing code, we will add new code to handle the behaviors that clients want `Workers` to have.

- Add a worker to the collection
- Remove a worker from the collection
- Find a worker that meets a predicate

We create matching methods: `add`, `remove` and `where`

```
class Workers
  def self.all
    @@workers ||= []
  end

  def self.add(x)
    all << x
  end

  def self.remove(x)
    all.delete(x)
  end

  def self.where(b)
    all.detect {|x| b.call(x) }
  end
end
```

There's likely a better way to implement `where`, but that is beside the point. With our new API in place we can change our client code, one at a time.

```
class Worker
#...
  def self.enable
    #Workers.all << self
    Workers.add(self)
  end
#...
end
```

Then

```
class Worker
#...
  def self.disable
    #Workers.all.delete(self)
    Workers.remove(self)
  end
#...
end
```

Finally

```
class Dispatcher
  def perform(job)
    find_worker.new.execute(job)
  end

  def find_worker
    #Workers.all.detect { |w| #logic that returns the correct worker class }
    Workers.where(lambda{ |w| #logic! })
  end
end
```

With each step we make one tiny change and re-run our tests. Once everything is working, remove the old code. Then make `all` private.

```
class Workers
  def self.all
    @@workers ||= []
  end
  private_class_method :all
  #...
end
```

Now clients of Workers use Workers' API, not its implementation. And if you do decide to switch from an Array to a Hash (or a Set), you only have to change `Workers`, not every class that uses it.

Arrays are great, and Ruby's Enumerable library is super great. But they are implementation details. If you find that your entire app knows about and is obsessed with these implementation details, hide them away. Encapsulating and hiding implementation is why we have classes, so don't be shy about using them.

I'm hoping to be less shy in the near future, returning to writing these posts and a bi-weekly newsletter that you can [sign up for](http://tinyletter.com/ianwhitney/). No cost, no awkward ads for SquareSpace or whatever company is currently disrupting the mattress market. Check out [previous issues](http://tinyletter.com/ianwhitney/archive) if you want to the sort of nonsense I get up to. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/5).
