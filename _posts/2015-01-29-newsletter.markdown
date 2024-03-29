---
layout: post
title: "A Catalog of Smells"
date: 2015-01-29 12:35:35 -0600
author: Ian Whitney
---

A Catalog of Smells

Early on in _Refactoring_ is a chapter by Fowler and Kent Beck about code smells. Beck apparently coined the phrase earlier, but I think _Refactoring_ is what brought it to prominence. But while Fowler & Beck do a good job of cataloging the smells, they didn't illustrate them with code samples. I thought it would be useful to discuss  the Fowler & Beck smells and alongside samples. So, consider this the first in a series.

Duplicated Code (_Refactoring_, p.76) is the first smell Fowler & Beck list, which only makes sense as it's also one of the smells programmers see most often. It's also one of the most misunderstood. And Fowler & Beck don't help clarify things with their 2nd sentence:

> If you see the same __code structure__ in more than one place you can be sure that your program will be better if you find a way to unify them.

Removing code duplication is also one of the 4 Rules of Simple Design (also partly authored by Kent Beck). In his book _The 4 Rules of Simple Design_, Corey Haines phrases the rule differently:

> Every __piece of knowledge__ should have one and only one representation.

The emphasis is those quotes is mine, to highlight the very different type of duplication they highlight: structure versus knowledge. Let's get to that example and hopefully show off what I mean.

```ruby
class Person
  def change_password
    if email.any?
      send_email && log_change
    else
      ask_for_email && send_email
    end
  end

  def add_friend
    if email.any?
      send_email
    else
      ask_for_email && send_email
    end
  end
end
```

There's some clear duplication in this code. Let's combine those two `if` statements into one with Extract Method.

```ruby
class Person
  def change_password
    notify(change_password, true)
  end

  def add_friend
    notify(new_friend)
  end

  private

  def notify(type, log = false )
    if email.any?
      send_email(type) 
      log_change if log
    else
      ask_for_email && send_email(type)
    end
  end
end
```

I've extracted the structural duplication, but I don't know that I've made the code better. I have a `notify` method that takes an unexplained boolean in one call, but not the other. And if I ever want to change `add_friend` so that it emails 2 people, then I run into a problem of accidentally stepping on the behavior of `change_password`.

What I missed in my rush to remove a duplicate _structure_ was a chance to clarify and refine the _knowledge_ in my system. I clearly need a class (or more) responsible for managing and sending emails.

```ruby
class Person
  def change_password
    MailBuilder.new({type: change_password, log_sending: true}).send
  end

  def add_friend
    MailBuilder.new({type: new_friend, log_sending: false}).send
  end
end
```

And if you now use Extract Method on those duplicate MailBuilder calls?

```ruby
class Person
  def change_password
    send_mail({type: change_password, log_sending: true})
  end

  def add_friend
    send_mail({type: new_friend, log_sending: false})
  end

  private

  def send_mail(options)
    MailBuilder.new(options).send
  end
end
```

You get the benefit of isolating the knowledge of MailBuilder and its `send` method to just one place, which isn't a bad thing. But it might be a little bit of overkill. Depends on how many different mail-sending methods, I think.

Link-o-rama.

A double-dose of Pull Request links. GitHub offers "[How to Write the Perfect Pull Request](https://github.com/blog/1943-how-to-write-the-perfect-pull-request)" and Atlassian countered one day later with "[A Better Pull Request](https://developer.atlassian.com/blog/2015/01/a-better-pull-request/)". 
Sticking with the false duplication theme, the titles sound almost identical, but the posts are actually totally different. GitHub's is about the social act of making a pull request. How to write one, how to handle feedback, why you should use emoji, etc. Atlassian's is a more technical discussion of how to best merge branches. The difference between the two companies seems perfectly illustrated by these two posts.

On the 8th Light blog, Elizabeth Engelman offers [a great illustration of the Single Responsibility Principle](http://blog.8thlight.com/elizabeth-engelman/2015/01/22/single-responsibility-principle-why-does-it-matter.html), which is a topic I'm sure I'll get into on Design Is Refactoring. Eventually.

Non-code link of the weeks is to the [Velo Orange blog](http://velo-orange.blogspot.com/). VO is a small maker of gorgeous bikes, and they also make a variety of excellent bike parts, should you not be able to afford one of their full bikes. When I get a chance to update my current bike I have my eyes on these [sweet fenders](http://store.velo-orange.com/index.php/vo-snakeskin-fender-50mm-fenders-700c.html), probably with some leather mud flaps.

Next week's post on Design is Refactoring will hopefully be the polymorphism post that I promised a few weeks back. Or maybe it won't. I've been puzzling over my Exercism problem for the week and I'm not yet sure what principle it will best illustrate. Once I see what kind of terrible code I write I'll have a better idea.
