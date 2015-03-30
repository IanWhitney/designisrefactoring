---
layout: post
title: "Organizing Data: Self Encapsulation"
date: 2015-03-29T22:08:39-05:00
---

True to [my promise](http://designisrefactoring.com/2015/03/15/conditionals-style-and-design/) we won't be talking about Bob or conditionals this week. I am as excited about this as you are! Instead I'm going to turn to a section of _Refactoring_ that always intrigues me and that I haven't discussed much so far: Organizing Data.

As you might have guessed this section discusses patterns about, well, organizing data. At 16 patterns it is the biggest section of the book, which makes sense; programming is almost nothing but organizing data. I probably won't discuss all 16 patterns, but I'll certainly cover a lot of them. There's a lot of good stuff ahead! I hope!

<!--break-->

I'm going to start off the first pattern of the section, which also seems to be the most lightweight: Self Encapsulate Field. I picked this one not because it's anything earth-shattering, but because code that doesn't do it drives me a little bit crazy. 

As an example, here's some code that surely looks familiar.

{% highlight ruby %}
class Person
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  def full_name
    "#{@first_name} #{@last_name}"
  end
end
{% endhighlight %}

That's an example of Direct Variable Access. It has no getters or setters, just instance variables that you access directly.

More common is this, which comes from the [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide#attr_family):

{% highlight ruby %}
class Person
  attr_reader :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
{% endhighlight %}

I call that Mixed Variable Access. You set instance variables directly, but use getters for reading their values.

After applying Self Encapsulation you wouldn't touch instance variables at all:

{% highlight ruby %}
class Person
  attr_reader :first_name, :last_name

  def initialize(first_name, last_name)
    self.first_name = first_name
    self.last_name = last_name
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  attr_writer :first_name, :last_name
end
{% endhighlight %}

This is a minor refactoring but I bet a lot of people will have strong opinions about it. Fowler says as much, "Debates between the two [approaches] can be heated." More than one person has seen me do this and said, "Wait, what?"

Self Encapsulation offers a surprising number of advantages, though. What if we introduce a sub-class of Person to represent medical doctors. With any of the examples above we could implement a Doctor's first name as:

{% highlight ruby %}
class Doctor < Person
  def full_name
    "Dr. #{super}"
  end
end

Doctor.new("Marcus", "Welby").full_name
#=> "Dr. Marcus Welby"
{% endhighlight %}

So far, so good.

Then, later, you add a getter for `first_name` in Person. Maybe you have to work around some capitalization problems.

{% highlight ruby %}
class Person
  def first_name
    @first_name.capitalize
  end
end
{% endhighlight %}

Now your direct access code looks like this:

{% highlight ruby %}
class Person
  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  def full_name
    "#{@first_name} #{@last_name}"
  end

  def first_name
    @first_name.capitalize
  end
end

class Doctor < Person
  def full_name
    "Dr. #{super}"
  end
end

Doctor.new("marcus", "Welby").full_name
#=> "Dr. Marcus Welby"
{% endhighlight %}

Because you are human you have created a `first_name` getter and yet you are still using the instance variable `@first_name` in `full_name`. Their implementations differ and you find yourself in Bug Town. Note that I'm making a big assumption here: that you are human. I know! This might be crazy. But play along with me. You didn't create this bug this because you are dumb, or because you are a bad programmer, this is just a simple mistake that humans make.

The Mixed Variable Access method protects you from this bit of humanity. Since you're using the getter method from the beginning, you don't have to worry about introducing a getter later. After implementing Doctor, our Mixed Access code looks like this:

{% highlight ruby %}
class Person
  attr_reader :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def first_name
    @first_name.capitalize
  end
end

class Doctor < Person
  def full_name
    "Dr. #{super}"
  end
end

Doctor.new("marcus", "Welby").full_name
#=> "Dr. Marcus Welby"
{% endhighlight %}

As your code deals with more and more people you find more problems. Doctors have taken to entering their last name in the database with the suffix, ", MD" so that it gets displayed an "Dr. Marcus Welby, MD". Your bosses decide all Doctors should have their names displayed in this format.

So, you fix the problem by changing how the full name is displayed and forcibly removing the now-unnecessary input.

{% highlight ruby %}
class Doctor < Person
  def last_name=(x)
    @last_name = x.delete(", MD")
  end

  def full_name
    "Dr. #{super}, MD"
  end
end

Doctor.new("marcus", "Welby, MD").full_name
#=>  "Dr. Marcus Welby, MD, MD"
{% endhighlight %}

Well, that didn't work. Again, our pesky fallibility has prevented us from being perfect. The Person initialize method, which Doctor inherits, doesn't use the `last_name` setter. It's still setting the instance variable. We curse ourselves, fix the problem and move on.

Simple oversights introduced bugs into both Direct Access and Mixed Access. However, the fully Self Encapsulated version of the code hasn't experienced any bugs so far. We've been able to implement these features without any hassles at all.

{% highlight ruby %}
class Person
  attr_reader :last_name

  def initialize(first_name, last_name)
    self.first_name = first_name
    self.last_name = last_name
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def first_name
    @first_name.capitalize
  end

  private

  attr_writer :first_name, :last_name
end

class Doctor < Person
  def last_name=(x)
    @last_name = x.delete(", MD")
  end

  def full_name
    "Dr. #{super}, MD"
  end
end

Doctor.new("marcus", "Welby, MD").full_name
#=>  "Dr. Marcus Welby, MD"
{% endhighlight %}

With Direct Access we kicked ourselves for being dumb. With Mixed Access we cursed our fallibility. But with Self Encapsulation we've been happy and content! Our initial decision to add those few extra characters has saved our ego a lot of bruises.

Self Encapsulation isn't complex or flashy. It requires almost no explanation, unlike many of the patterns in _Refactoring_. It doesn't lend itself to [sweet presentations](http://confreaks.tv/search?utf8=✓&query=patterns+design&commit=go). But it does do one very important thing: save you from yourself. Based on my own code, that's the one person I know I need to be saved from.

Save yourself from my mistakes by [signing up for my free newsletter](http://tinyletter.com/ianwhitney/), checking out [previous issues](http://tinyletter.com/ianwhitney/archive) or practicing for the Seder. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/1).
