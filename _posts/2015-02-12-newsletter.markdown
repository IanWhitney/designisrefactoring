---
layout: post
title: "Extracting Classes and the Large Class Smell"
date: 2015-02-12 12:35:35 -0600
author: Ian Whitney
---

Extracting Classes and the Large Class Smell

[Last week we looked at the Long Method smell](http://tinyletter.com/ianwhitney/letters/how-long-is-a-method). This week we scale up and examine the **Large Class** smell. Why are methods long but classes are large? Fowler and Beck do not say. What they do say is:

> When a class is trying to do too much, it often shows up as too many instance variables...duplicated code cannot be far behind.

Also:

> As with a class with too many instance variables, a class with too much code is a prime breeding ground for duplicated code, chaos and death.

Maybe a bit over-dramatic, but the point is clear. A class is too large if it has too much code. Or if it has too many instance variable. It doesn't matter why your class is large, the fixes are the same: Extract Class and Extract Subclass.

Let's start with an example to show off Extract Class:

```
class ValueMatcher
  attr_reader :value

  def match?(target)
    value == target.public_send(attribute).to_s.upcase
  end

  def value=(x)
    @value = x.to_s.upcase
  end
end

> v = ValueMatcher.new
> v.value("hi!")
> x = OpenStruct.new
> x.value = "hi!"
> v.match?(x) 
#=> true
```

At 8 lines it's hard to call this a Large Class. But yet it's still ready for us to extract a class. I didn't notice this myself; my co-worker pointed out this extraction to me. So thanks to him!

This class duplicates the knowledge of how we convert strings to make them comparable. In both the `value` setter and the `match?` code, it uses `to_s.upcase`. We can extract that!

```
class StringCompare
  def self.match?(initial, other)
    convert(initial) == convert(other)
  end

  private
  def self.convert(value)
    value.to_s.upcase
  end
end

class ValueMatcher
  attr_accessor :value

  def match?(target)
    StringCompare.match?(target.public_send(attribute), value)
  end
end
```

Using the same example, what does a class ready for Extract Subclass look like?

```
class ValueMatcher
  def match?(target)
    if value.respond_to(:each)
      ArrayCompare.match?(target.public_send(attribute), value)
    else
      StringCompare.match?(target.public_send(attribute), value)
    end
  end
end
```

Making decisions based on an object's type is a sign that you can extract a subclass

```
class ArrayMatcher < ValueMatcher
  def match?(target)
    ArrayCompare.match?(target.public_send(attribute), value)
  end
end

class StringMatcher < ValueMatcher
  def match?(target)
    StringCompare.match?(target.public_send(attribute), value)
  end
end
```

Of course, all of [the caveats about inheritance](http://www.neotericdesign.com/blog/2012/4/the-story-of-inheritance) should be heeded when extracting subclasses.

Like with Long Method, there's no unbreakable rule about how long your class should be. 100 lines? Sure! 300 lines? Sounds dubious, but maybe it makes sense in your case. For me the best rule to follow is the [Single Responsibility Principle](http://designisrefactoring.com/2015/02/01/robot-you-have-one-job/). Be vigilant about following SRP and your classes can't help but be short.

Links!

A weird technical tidbit that my team just discovered, you can [use cron to run a job after your server reboots](http://www.techpository.com/?page_id=1685). Maybe this is common knowledge, but we were all quite pleased to learn about it.

Staying on the server side, we are moving all of our server configuration to [Ansible](https://github.com/ansible/ansible). After playing with [Chef](https://www.chef.io/) for a while we realized our needs and its goals did not overlap. But Ansible has been working well for us and it was much easier to learn.

My non-coding suggestion of the week are the westerns of [Sergio Leone](http://www.imdb.com/name/nm0001466/), particularly _The Good, the Bad and the Ugly_ and _Once Upon a Time in the West_. At 3 hours they require a time commitment, but I never regret spending an evening with either of these movies. Both are gorgeous, thoughtful, rewarding and fun. If you've seen those, then you can't go wrong with the rest of the Leone catalog.

It might be a running gag by this point, but maybe next week's Design is Refactoring post really will be about polymorphism!
