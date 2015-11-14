---
layout: post
title: "Robot, You Have One Job"
date: 2015-02-01T13:34:09-06:00
author: Ian Whitney
---
Here's a little glimpse behind the _Design is Refactoring_ curtain--I have no idea what I'm doing. There's no grand plan of "First I'll introduce this concept, then expand on it, then build in complexity and then **voilà** my beautiful creation will be revealed to all!"

Instead, my usual approach is to start a new [Exercism.io](http://exercism.io/) problem, solve it in a terrible way (terrible code being my default) and then stare at it for a long time until I figure out some design concept I can illustrate with it.

<!--break-->

After I implemented a solution for [this week's problem](https://github.com/exercism/x-common/blob/master/robot-name.md), I was left with:

{% highlight ruby %}
class Robot
  def name
    @name ||= (('a'..'z').to_a + ('A'..'Z').to_a).sample(2).join + rand.to_s[2,3]
  end

  def reset
    self.name = nil
  end

  private

  attr_writer :name
end
{% endhighlight %}

And that doesn't offer up a ton of refactoring options. Yes, you could break the name components into smaller methods, like they do in the [example solution](https://github.com/exercism/xruby/blob/master/robot-name/example.rb). But I think that's actually a case of over-extraction. Your `prefix` and `suffix` methods are never going to be called independently. They are always called together, so you should keep their logic together.

So&hellip;not much to talk about here. But there is that "Bonus Points" part of the problem that asks us to ensure that all names are unique. And there's a little throwaway at the end, "Feel free to introduce additional tests."

An implementation is easy enough with class instance variables and Ruby's `Set` library:

{% highlight ruby %}
require 'set'
class Robot
  def self.assigned_names
    @@assigned_names ||= Set.new
  end

  def name
    @name ||= generate_name
  end

  def reset
    self.name = nil
  end

  private

  attr_writer :name

  def new_name
    ('A'..'Z').to_a.sample(2).join + rand.to_s[2,3]
  end

  def generate_name
    temp_name = new_name
    until self.class.assigned_names.add?(temp_name)
      temp_name = new_name
    end
    temp_name
  end
end
{% endhighlight %}

Seriously, [spend some time reading about Set](http://www.ruby-doc.org/stdlib-2.2.0/libdoc/set/rdoc/Set.html). I love it. The [add? method](http://www.ruby-doc.org/stdlib-2.2.0/libdoc/set/rdoc/Set.html#method-i-add-3F) returns nil if the element is already in the set, otherwise it adds the element and returns the set. We can use it like ActiveRecord's `save?`.

Looking at that code, I'm pretty confident that it works. At least I don't see any obvious problems. It'd blow up if we ever exhausted every name combination, but that's not really our problem right now. 

But how do I test it? Seriously. This code can not be tested in any reasonable way. I thought of three options:

1. Build a set of all name combinations, save one. Force that nearly-complete set into ``@@assigned_names`` and then assert that a new robot has the one remaining available name.
2. Write a test that loops 676,000 times (once for each possible name) and makes sure that each robot gets a unique name.
3. Stub `Set.new` and `new_name` to return stubs that exercise the behavior I want.

Good god, those are terrible. If forced, I would chose the third. But it still requires me to crack open this class and muck about with its internals. That's never a good idea.

And now I have a design problem to solve!

The root problem here can be found quickly by applying the Single Responsibility Principle, which recently got [a great write up by Elizabeth Engleman](http://blog.8thlight.com/elizabeth-engelman/2015/01/22/single-responsibility-principle-why-does-it-matter.html). Let's use the approach she suggests and describe what `Robot` does.

It manages the state of a Robot's name<br />
**And** generates the name<br />
**And** persists the names of all Robots

There's your problem, right there. The Robot should have one job and it currently has three<sup>[\*](#one)</sup>. The solution is a double dose of Extract Class. Name generation is easy:

{% highlight ruby %}
class NameGenerator < SimpleDelegator
  def self.build
    self.new(('A'..'Z').to_a.sample(2).join + rand.to_s[2,3])
  end
end
{% endhighlight %}

Using a [declarative builder](http://programming.ianwhitney.com/blog/2014/04/13/4-simple-rules-and-declarative-builders/) on top of SimpleDelegator lets us return a string while still having clear names.

Name persistence is almost as simple

{% highlight ruby %}
require 'set'
class NamePersistence
  def self.add(name)
    collection.add?(name)
  end

  def self.clear!
    @@collection = nil
  end

  private

  def self.collection
    @@collection ||= Set.new
  end
end
{% endhighlight %}

I also could have used SimpleDelegator here, but for whatever reason I don't tend to do that with enumerables. Instead I just make a simple class that wraps around the enumerable collection. The one new method here is `clear!` which wipes all persisted names. I only need that for my testing; it's never used by the Robot at all. I would not be surprised if there are better solutions to this problem, but this approach worked for me this time.

After the extraction, what does our `Robot` look like?

{% highlight ruby %}
class Robot
  def initialize(persistence: NamePersistence, generator: NameGenerator)
    self.persistence = persistence
    self.generator = generator
  end

  def name
    @name ||= generate_name
  end

  def reset
    self.name = nil
  end

  private

  attr_writer :name
  attr_accessor :persistence, :generator

  def generate_name
    temp_name = generator.build
    until persistence.add(temp_name)
      temp_name = generator.build
    end
    temp_name
  end
end
{% endhighlight %}

The `generate_name` method is still a bit funky, but now it only interacts with collaborators I inject. So the Robot's responsibilities are now:

- Maintain state of my name, using the provided collaborators

You can push this code farther, like Rails does with macros such as [validates_uniqueness_of](http://apidock.com/rails/ActiveRecord/Validations/ClassMethods/validates_uniqueness_of), but I'm not going to bother with this example. Instead of refactoring this further, let's take a look at how our test suite ended up.

On top of the tests I had to add for the two new classes, I also had to add some tests to make sure our Robot uses its new collaborators correctly:

{% highlight ruby %}
def test_name_is_added_to_persistence
  @persistence = MiniTest::Mock.new
  @persistence.expect :add, true, [NameGenerator]
  Robot.new(persistence: @persistence).name
  assert @persistence.verify
end

def test_name_is_created_by_namegenerator
  @generator = MiniTest::Mock.new
  @generator.expect :build, "AB123"
  robot = Robot.new(generator: @generator)
  assert_equal "AB123", robot.name
  assert @generator.verify
end
{% endhighlight %}

And using a stand-in for the name generator we can also test the uniqueness behavior:

{% highlight ruby %}
class NameGeneratorDouble
  @@names = %w(AB123 AB123 ZZ789)
  def self.build
    @@names.shift
  end
end

def test_names_are_unique
  @generator = NameGeneratorDouble
  robot = Robot.new(generator: @generator)
  assert_equal "AB123", robot.name

  robot = Robot.new(generator: @generator)
  assert_equal "ZZ789", robot.name
end
{% endhighlight %}

My testing approach here was altered by only using MiniTest::Mock. If I had been using [Mocha](http://gofreerange.com/mocha/docs/) or [Rspec](http://rspec.info/), I would have had different options, which in turn would change my implementation. The effect a testing framework has on the resulting code is interesting and deserves further exploration. But not today. Like the Robot, this post should have just one job.

My newsletter's job this week is to continue the Catalog of Smells that I started in [last week's newsletter](http://tinyletter.com/ianwhitney/letters/a-catalog-of-smells). You can [sign-up for the newsletter](http://tinyletter.com/ianwhitney/), check out [previous issues](http://tinyletter.com/ianwhitney/archive) or do neither of those things. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com

<a name='one'>\*</a> Is name generation really a separate responsibility? For the purposes of this feature, I think it is. If I leave name generation within `Robot` then it is hard to manipulate that name generator during testing. It's the tests that are telling me to move name generation outside of Robot. It's almost the _Tests_ are _driving_ the _design_!
