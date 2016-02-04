---
layout: post
title: "Factories"
date: 2016-02-03T15:14:05-06:00
subtitle: "From Simple to Ridiculous"
author: "Ian Whitney"
---

Recently I helped organize some [Sandi Metz](http://www.sandimetz.com/) training at the University of Minnesota. It was great and I highly recommend you bring Sandi to your place of employment or that you attend one of her public courses.

During class we discussed [factory methods](https://en.wikipedia.org/wiki/Factory_method_pattern) and the different ways of implementing them. But we didn't have enough time time to dive in to the options. I told my classmates that I would write something up, so here it is -- a guided tour of factories from the simple to the ridiculous!

<!--break-->

We have some code that returns a campus name based upon its abbreviation.

{% highlight ruby %}
class CampusDetails
  def campus_name(abbreviation)
    case abbreviation
    when "UMNTC"
      "University of Minnesota Twin Cities"
    when "UMNMO" 
      "University of Minnesota Morris"
    else
      "Unknown Campus"
    end
  end
end
{% endhighlight %}

That code works but it has a couple of smells. First, it's got a giant case statement. Second, it's obsessed with the string primitive of the campus abbreviation. But if there's no reason to change this code you might be happy leaving it as is.

Let's introduce a reason to change this code.

In addition to the campus' abbreviation we want to know the campus' mascot name. We might end up with code like this:

{% highlight ruby %}
class CampusDetails
  def campus_name(abbreviation)
    case abbreviation
    when "UMNTC"
      "University of Minnesota Twin Cities"
    when "UMNMO" 
      "University of Minnesota Morris"
    else
      "Unknown Campus"
    end
  end

  def campus_mascot(abbreviation)
    case abbreviation
    when "UMNTC"
      "Gopher"
    when "UMNMO" 
      "Cougar"
    else
      "Unknown Mascot"
    end
  end
end
{% endhighlight %}

And now we have two duplicate case statements and two methods that obsess about the abbreviation string. What we want here is a factory; a way to create an object from the abbreviation and to have that logic live in only one location.

A simple first pass at a factory is to create a little private method inside the class you're working with:

{% highlight ruby %}
class CampusDetails
  def campus_name(abbreviation)
    build_campus(abbreviation).name
  end

  def campus_mascot(abbreviation)
    build_campus(abbreviation).mascot
  end

  private

  def build_campus(abbreviation)
    case abbreviation
    when "UMNTC"
      UMNTC.new
    when "UMNMO"
      UMNMO.new
    else
      UnknownCampus.new
    end
  end
end

class UMNTC
  def name 
    "University of Minnesota Twin Cities"
  def

  def mascot
    "Gopher"
  end
end

class UMNMO
  def name 
    "University of Minnesota Morris"
  def

  def mascot
    "Cougar"
  end
end

class UnknownCampus
  def name 
    "Unknown Campus"
  def

  def mascot
    "Unknown Mascot"
  end
end
{% endhighlight %}

We've isolated our case statement to one method and we've created a trio of simple objects that provide the behavior we want. Are we done? Well, maybe. What problems are there in this code? There's still a case statement, which I'm not a fan of. But since it's isolated in a private method I'm not that concerned.

Then along comes a new campus -- University of Minnesota Crookston (mascot: Golden Eagle). We add it to our collection of classes:

{% highlight ruby %}
# previous code sample is unchanged

class UMNCR
  def name 
    "University of Minnesota Crookston"
  def

  def mascot
    "Golden Eagle"
  end
end
{% endhighlight %}

Easy! But wait. When we use the "UMNCR" abbreviation we get back an UnknownCampus. What happened? We forgot to tell our factory method about the new class.

Our factory method is nice but it requires that we change it every time we add a new campus. What should be a simple change -- add a new campus -- requires changes in two different places. This is [Shotgun Surgery](https://en.wikipedia.org/wiki/Shotgun_surgery). Let's refactor our factory to solve this problem before we introduce Crookston.

We're pretty sure that all University of Minnesota campus classes will start with UMN. Maybe we can take advantage of that:

{% highlight ruby %}
class CampusDetails
  # this stuff is unchanged
  private

  def build_campus(abbreviation)
    begin
      # abbreviation[-2,2] gets the last two characters of the abbreviation string
      Object.const_get("UMN#{abbreviation[-2,2]}")
    rescue
      UnknownCampus
    end.new
  end
end
{% endhighlight %}

That works. If we pass it an abbreviation that matches with a known class it will return a new instance of that class. Otherwise we'll get a new instance of UnknownCampus. And when we add the UMNCR class the factory just works without any changes.

Then someone decides to add a class for University of Minnesota Rochester. Rochester's an odd part of the UMN system; it's technically part of the Twin Cities campus, except when it's not. To highlight that oddness the programmer calls the class UMNTCRO. And when our factory tries to build a campus for "UMNTCRO" it fails and returns a UnknownCampus instead. Our factory relied on a naming convention and Rochester breaks that convention.

What if we had a way to show that all these classes were related? Then our factory could use that relationship to figure out which one to build. Since Ruby is so thoroughly object-oriented we do have this tool -- inheritance!

All of our classes are specialized versions of a Campus concept and if we reflect that with inheritance we can take advantage of some Ruby niceties to help our factory be more flexible.

{% highlight ruby %}
class Campus
  def name
    raise NotImplementedError
  end

  def mascot
    raise NotImplementedError
  end
end

class UMNTC < Campus
  # the internals are unchanged from the last example
end

class UMNMO < Campus
  # the internals are unchanged from the last example
end

class UMNCR < Campus
  # the internals are unchanged from the last example
end

class UnknownCampus < Campus
  # the internals are unchanged from the last example
end
{% endhighlight %}

After we refactor to inheritance, we can add this monkey patch

{% highlight ruby %}
class Class
  def subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
{% endhighlight %}

This uses Ruby's built in [`ObjectSpace` module](http://ruby-doc.org/core-2.3.0/ObjectSpace.html) to discover every subclass of a class. Now every class can tell us its subclasses.

{% highlight ruby %}
puts Campus.subclasses
#=> [UMNTC, UMNMO, UMNCR, UnknownCampus]
{% endhighlight %}

This is nice but it doesn't help us yet. Our factory has a way to find all of the Campus classes but no way of knowing which one it should build. We can fix this by adding a method to each of our Campus classes.

{% highlight ruby %}
class Campus
  def self.handles?(_)
    false
  end
end

class UMNTC < Campus
  def self.handles?(abbreviation)
    abbreviation == "UMNTC"
  end
end

class UMNMO < Campus
  def self.handles?(abbreviation)
    abbreviation == "UMNMO"
  end
end

class UMNCR < Campus
  def self.handles?(abbreviation)
    abbreviation == "UMNCR"
  end
end

class UnknownCampus < Campus
  def self.handles?(_)
    true
  end
end

UMNCR.handles?("UMNCR")
#=> true

UMNCR.handles?("UMNTC")
#=> false

{% endhighlight %}

Now our Campus classes can tell our factory which one it should build, we just have to ask if it handles our abbreviation.

{% highlight ruby %}
class CampusDetails
  # this stuff is unchanged
  private

  def build_campus(abbreviation)
    Campus.subclasses.detect { |campus_class| campus_class.handles?(abbreviation)}.new
  end
end
{% endhighlight %}

The [`detect` method](http://ruby-doc.org/core-2.3.0/Enumerable.html#method-i-detect) iterates through the subclasses and returns the first class that says it can handle our abbreviation. With this change we can easily add UMNTCRO without having to further change our factory:

{% highlight ruby %}
class UMNTCRO < Campus
  def self.handles?(abbreviation)
    abbreviation == "UMNTCRO"
  end

  def name
    "University of Minnesota Rochester"
  end

  def mascot
    "Raptor"
  end
end
{% endhighlight %}

This probably works. I say probably because it relies on classes being loaded in the right order. Remember that `UnknownCampus` says it handles _everything_. If it's not the last class in your array of subclasses your factory is going to fail some of the time.

For example, if `UnknownCampus` gets loaded before `UMNTCRO` then `Campus.subclasses` will look like this:

{% highlight ruby %}
puts Campus.subclasses
#=> [UMNTC, UMNMO, UMNCR, UnknownCampus, UMNTCRO]
{% endhighlight %}

And `detect` will return the first class that says it handles the abbreviation. So if you ask your factory to build a campus with the abbreviation "UMNTCRO", it will return an UnknownCampus. Because it asked UnknownCampus first and UnknownCampus said "Sure! I handle that!"

We can get around this a few different ways. One is to take UnknownCampus out of the hierarchy and delete its `handles?` method.

{% highlight ruby %}
class UnknownCampus
  def name 
    "Unknown Campus"
  def

  def mascot
    "Unknown Mascot"
  end
end
{% endhighlight %}

This means that `UnknownCampus` no longer appears in the collection of `Campus` subclasses. We then use the almost-never-seen behavior of using a default with `detect`

{% highlight ruby %}
class CampusDetails
  # this stuff is unchanged
  private

  def build_campus(abbreviation)
    Campus.subclasses.detect(->{UnknownCampus.new}) { |campus_class| campus_class.handles?(abbreviation)}.new
  end
end
{% endhighlight %}

It's possible that behavior is never used because it looks goofy as hell. If you provide a Proc or lambda to `detect` it will be called if your block returns nil. So, if no `Campus` subclass says it can handle your abbreviation you'll get an UnknownCampus instance.

Syntactic oddness aside this solves our load order problem. So let's leave it be.

Our factory is pretty good at this point, right? As long as programmers remember to have new campuses inherit from `Campus` and define the `handles?` method everything should just work.

And then someone decides to implement "College in the Schools" which teaches college level classes in high schools. It's kind of like a `Campus`&hellip;kind of.

{% highlight ruby %}
class CollegeInTheSchools < Campus
  def self.handles?(abbreviation)
    abbreviation = "CITS"
  end

  def name
    "College in the Schools"
  end

  def mascot
    # No mascot.
    ""
  end
end
{% endhighlight %}

There are a bunch of other ways in which this class is not Campus-like, but I'll leave those to your imagination. The relevant point here is that our inheritance approach can break down. `CollegeInTheSchools` is campus-like enough to satisfy our factory (since it responds to both `name` and `mascot`), but it's not campus-like enough that it should inherit from our `Campus` class. However our factory demands that all campus-like classes inherit from `Campus`.

This is a pickle.

Instead of inheritance what if classes that were 'campus-like' could register themselves as 'campus-like'? A simple approach would be to store a list of campus-like classes in a coniguration file:

{% highlight ruby %}
CAMPUS_LIKE = [UMNTC, UMNRO, UMNMO, UMNTCRO, CampusInTheSchools]
{% endhighlight %}

and then our factory could find the right 'campus-like' class:

{% highlight ruby %}
class CampusDetails
  # this stuff is unchanged
  private

  def build_campus(abbreviation)
    CAMPUS_LIKE.detect(->{UnknownCampus.new}) { |campus_class| campus_class.handles?(abbreviation)}.new
  end
end
{% endhighlight %}

This works but it re-introduces a problem we had back at the beginning. If we add a new class we have to remember to add it to the list of 'campus-like' things. We're back at Shotgun Surgery.

What if each class were responsible for reporting itself as 'campus-like'? It'd look something like this:

{% highlight ruby %}
class UMNTC
  # everything else is unchanged

  def self.campus_like?
    true
  end
end
#The other classes have the same method, so there's no reason to include them.
{% endhighlight %}

Then we could change `CAMPUS_LIKE` to be a bit more dynamic:

{% highlight ruby %}
CAMPUS_LIKE = ObjectSpace.each_object(Class).select do |klass| 
  klass.respond_to?(:campus_like?) && klass.campus_like?
end
{% endhighlight %}

With this change our `CAMPUS_LIKE` constant is populated with every class that claims to be campus-like. The name of these classes is irrelavant, the ancesntors of these classes is irrelevant. The only thing that matters is that the class says it's campus-like.

This approach is not foolproof, obviously. If we add a new class is added that should be campus-like but forget to implement the method, our factory will never build our new class. Alternatively, we could claim that a class is campus-like when it is not and our factory will return invalid objects. It doesn't matter which factory you pick, there is always a way to screw it up.

Possibly worse, this factory also has the downside of being utterly baffling to newcomers to this code. Whatever its faults, the case statement we started off with was easy to understand. And compare that to the code we have now:

{% highlight ruby %}
class UMNTC
  def self.campus_like?
    true
  end

  def self.handles?(abbreviation)
    abbreviation = "UMNTC"
  end

  def name 
    "University of Minnesota Twin Cities"
  def

  def mascot
    "Gopher"
  end
end

class UMNMO
  def self.campus_like?
    true
  end

  def self.handles?(abbreviation)
    abbreviation = "UMNMO"
  end

  def name 
    "University of Minnesota Morris"
  def

  def mascot
    "Cougar"
  end
end

class UMNCR
  def self.campus_like?
    true
  end

  def self.handles?(abbreviation)
    abbreviation = "UMNCR"
  end

  def name 
    "University of Minnesota Crookston"
  def

  def mascot
    "Golden Eagle"
  end
end

class UMNTCRO
  def self.campus_like?
    true
  end

  def self.handles?(abbreviation)
    abbreviation = "UMNTCRO"
  end

  def name 
    "University of Minnesota Rochester"
  def

  def mascot
    "Raptor"
  end
end

class CollegeInTheSchools
  def self.campus_like?
    true
  end

  def self.handles?(abbreviation)
    abbreviation = "CITS"
  end

  def name
    "College in the Schools"
  end

  def mascot
    ""
  end
end

class UnknownCampus
  def name 
    "Unknown Campus"
  def

  def mascot
    "Unknown Mascot"
  end
end

CAMPUS_LIKE = ObjectSpace.each_object(Class).select do |klass| 
  klass.respond_to?(:campus_like?) && klass.campus_like?
end

class CampusDetails
  def campus_name(abbreviation)
    build_campus(abbreviation).name
  end

  def campus_mascot(abbreviation)
    build_campus(abbreviation).mascot
  end

  private

  def build_campus(abbreviation)
    CAMPUS_LIKE.detect(->{UnknownCampus.new}) { |campus_class| campus_class.handles?(abbreviation)}.new
  end
end
{% endhighlight %}

I think someone new to this code would be justified in cursing. But there are cases where a factory like this (or one [even more abstract](https://gist.github.com/IanWhitney/99605705aa25f154333d)) are _exactly_ what you need. Are you working with a huge code base with tons of classes and factories? Do you have lots of classes that satisfy lots of different roles? Then this sort of abstraction might be perfect for you. Are you dealing with classes that almost never change and a factory that never needs to know about new collaborators? Then this abstraction is overkill.

That's the lesson of abstraction, really. There's not a level of abstraction that's universally *wrong*, it's always context dependent. You have to find the level that's right for your code and your programmers.

If you want to read more about Rust, Ruby, Refactoring and other things that start with R (and maybe other letters), maybe check out my totally free newsletter. You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/15).
