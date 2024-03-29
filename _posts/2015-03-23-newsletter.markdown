---
layout: post
title: "Feature Envy -- A Smell is a Smell is a Smell"
date: 2015-03-23 12:35:35 -0600
author: Ian Whitney
---

Feature Envy

Welcome to all you people who are receiving this newsletter for the first time, which is more than half of you. Enjoy!

When there's a large number of new readers I feel the need to restate my core belief: I have no idea what I am doing! I'm in no way trying to present myself as an expert. I'm trying to learn, just like everyone else. I encourage and welcome comments about my hopefully-helpful ramblings. You can reply to this email, or you can [tweet](https://twitter.com/iwhitney) or you can [comment on GitHub](https://github.com/IanWhitney/newsletter/pull/1).

Before I dive into this week's smell, one more quick digression. If you search the web for descriptions of refactoring patterns or code smells, you'll probably find the Sourcemaking site. All of the text on there is copied, word-for-word, from Martin Fowler's books [without acknowledgment or permission](https://twitter.com/martinfowler/status/578938542468018176).

Sourcemaking can take a flying leap.

Now to the business at hand, Feature Envy. Here's Fowler & Beck's definition:

> A classic smell is a method that seems more interested in a class other than the one it actually is in. The most common focus of the envy is the data...a method that invokes half-a-dozen getting methods on another object to calculate some value.

Examples always help me understand these descriptions better:

```ruby
class Survey
  attr_accessor :person

  def deliver
    if person.email?
      Email.new(person.email, body: self)
    else
      MailLabel.new(name: person.name, street: person.street_address, state: person.state, zip: person.zip)
    end
  end
  #...
end
```

Now, let's say that the API of Person changes. Instead of the US-centric ZIP we change the method to `postal_code`. We'd have to change this method as well. And that's an example of [Shotgun Surgery](http://tinyletter.com/ianwhitney/letters/shotgun-surgery-a-pretty-exciting-name-something-so-tedious), isn't it?

How would you describe Survey's job? I'd probably say something like:

> Generates a survey and creates a method for delivery.

Which shows a violation of [Single Responsibility Principle](http://designisrefactoring.com/2015/02/01/robot-you-have-one-job/), right? So what is the problem here, Feature Envy, Shotgun Surgery or SRP? All of the above.

Code Smells aren't distinct things. As I dig into them I find that they are a lot of clever names to describe the same two basic problems:

1. Your have duplicated too much knowledge
2. Your responsibilities are unclear

Feature Envy is another way of describing those 2 fundamental problems. It's a method that oversteps its responsibilities and, frequently, duplicates knowledge.

```ruby
class Survey
  attr_accessor :person

  def deliver
    Mailcarrier.new.deliver(self, person)
  end
end

class Mailcarrier
  def deliver(content, recipent)
    self.content = content
    recpient.receive(self)
  end

  def send_via_email_to(address)
    #...
  end

  def send_via_snailmail_to(address)
    #...
  end
end

class Person
  def receive(deliverer)
    if email?
      deliverer.send_via_email_to(email)
    else
      deliverer.send_via_snailmail_to(postal_address)
    end
  end
end
```

That's a half-assed refactoring at best, but you can start to see the lines of responsibility more clearly. And Survey no longer has to change whenever Person does.

That all these code smells boil down to similar problems is not to dismiss the value of smells. The names of smells give us something to hang on to and a common ground for discussion. It's much like programming. You can write an entire application in one giant file, without classes and without methods. Hell, you could write the whole thing in binary if you want. The organization and naming exists to make code easier to discuss and share.

I'm trying to make these newsletters less rambly, so that I can concentrate all my rambly-ness in the blog posts. Instead of discussing Feature Envy more, let's get to the links. These folks are more interesting than me anyways.

Aja Hammerly has been doing short, sweet blog posts about Ruby tidbits she learns. The most recent on was [about hashes and set](http://thagomizer.com/blog/2015/03/13/til-hash-edition.html). I love using [Set](http://ruby-doc.org/stdlib-2.2.1/libdoc/set/rdoc/Set.html), so it's no surprise that I like this post.

I just discovered the [Reading Rails posts](http://www.monkeyandcrow.com/series/reading_rails/) that Adam Anderson is writing. They are excellent. With each version I feel like Rails becomes more and more of a magic black box. By reading and analyzing its code we can not only understand what it's doing, but how to use it better. And, sometimes, we discover code that takes away just a small bit of our sanity.

That sanity joke was a forced segue into the world of Cthulhu. This week I started two two Lovecraftian games: [Eldritch Horror](https://www.fantasyflightgames.com/en/products/eldritch-horror/), a board game from Fantasy Flight and [Horror on the Orient Express](http://www.chaosium.com/horror-on-the-orient-express/) and epic and much-loved campaign for the Call of Cthulhu roll playing game. At 3-4 hours, Eldritch Horror takes a fairly long time for a board game, but it's a fun, engaging and co-operative race against the Earth's likely destruction. And you can play with anywhere from 1 to 8 players, which makes it very flexible. I enjoyed it a lot more than the best known Cthulhu board game, Arkham Horror, which I find to be excessively slow and complex.

Ok, that's it for the first newsletter written under my new publishing schedule. If there are changes/topics/etc. you'd like to see, please Reply, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/1). Next week will be a full rambly blog post.

Until next time, true receivers.
