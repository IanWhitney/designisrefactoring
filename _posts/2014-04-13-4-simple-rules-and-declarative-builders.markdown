---
layout: post
title: 4 Simple Rules and Declarative Builders
date: 2014-04-13 13:16:10 +0000
comments: false
categories: 

---
Earlier this week I bought [4 Rules of Simple Design](http://articles.coreyhaines.com/posts/i-wrote-a-book/) by Corey Haines, a short but interesting discussion of the [Four Rules](http://c2.com/cgi/wiki?XpSimplicityRules) that came out of Extreme Programming. The book is grounded in Corey's vast experience and in the code he's seen people write at [Coderetreat](http://coderetreat.org/). It's a quick but meaty read. There's a lot of knowledge in the ~65 pages of content.

<!-- more -->

In a section on testing, Haines says:

> In fact, over time I've developed a guideline for myself that external callers can't actually use the base constructor for an object. Put another way: the outside world can't use new to instantiate an object with an expectation of a specific state. Instead, there must be an explicitly named factory method on the class to create an object in a specific, valid state.

I'm not sure factory is the right word here. My (admittedly incomplete) understanding is that a factory is a class that builds another class. But in the case he's talking about we're using a class' method to build an instance of the same class, which I think is the Builder pattern.

Pattern pedantry aside, I tried putting this advice into practice this week and found it quite pleasing. Here's some old code. This is from a rake task that kicks off a data processing job. This job can be configured, but in this case we're using the default configuration.

```ruby
namespace :etl do
  task :fill_queue => :environment do
    queue_filler = Etl::QueueFiller.new
    queue_filler.run
  end
end
```

And here's the code afterward:

```ruby
namespace :etl do
  task :fill_queue => :environment do
    Etl::QueueFiller.add_all_students
  end
end
```

And there's a similar task that adds just some students instead of all. Before:

```ruby
namespace :etl do
  task :add_students, [:student_ids] => :environment do |t, args|
    Etl::QueueFiller.new.add_students(student_ids)
  end
end
```

After

```ruby
namespace :etl do
  task :add_students, [:student_ids] => :environment do |t, args|
    Etl::QueueFiller.add_students(student_ids)
  end
end
```

Minor changes, but observe how much easier this is to read. In the original examples, what value was there to `new`? None, as far as I can tell. All it did was return an instance that had the method I wanted. So if `new` has no value in this context, let's remove it. And we're left with a declarative statement that says exactly what I want.

In these cases I'm never working with the returned object. But I stuck with Haines' advice throughout this entire refactoring, using it for creating objects I did work with. Deeper down in the application is the idea of a Queue Event, which we use for tracking when and why data was added to our work queue. Again, this can be configured or there is a default option.

```ruby
class QueueEvent
  def self.default
    self.create_for_type("all_active_undergrads")
  end

  def self.for(type)
    self.create_for_type(type)
  end


  private

  def self.create_for_type(type)
    self.new(type: type)
  end
end

event = QueueEvent.default
event = QueueEvent.for('transfer_credits')
```

`for` may not be the best name here. Something more descriptive would be better. `QueueEvent.for_type`, maybe. Or, since there's a limited number of Event types, I could probably just create explicit builders for all of them: `QueueEvent.transfer_credits` or `QueueEvent.registration_update`. Etc. Though I can see the maintenance of that being a pain. And the urge to replace these explicit builders with a bit of `method_missing` magic is ever present. Though I think it should be resisted. It's too easy for `method_missing` to suprise and confuse other developers (or yourself) months down the road.

After trying out Corey's advice, I don't know that I'd stop using `new` all-together. Sometimes you just want a new instance of a class. But I can certainly see the value of having explict builders that give you objects in specific states. And the resulting code can be far easier to read.