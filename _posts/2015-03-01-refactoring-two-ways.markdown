---
layout: post
title: "Refactoring: Two Ways"
date: 2015-03-01T13:50:20-06:00
---

I've spent the last few posts talking about design heuristics. In this week's post I'm going to return to the Refactoring part of _Design is Refactoring_ by showing two approaches you can take when following Extract Class.

The first approach is dangerous, unpredictable and painful. The second approach is safe, guaranteed and painless. Surprisingly, it seems that most programmers follow the first approach.

<!--break-->

### Our Problem

Let's use Martin Fowler's example for Extract Class from _Refactoring_, translated from Java to Ruby.

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end
end
{% endhighlight ruby %}

Fowler applies Extract Class (and a few other refactorings) and ends up with:<sup>[\*](#values)</sup>

{% highlight ruby %}
class Person
  attr_accessor :name

  def telephone_number
    office_telephone.telephone_number
  end

  private

  def office_telephone
    TelephoneNumber.new
  end
end

class TelephoneNumber
  attr_accessor :area_code, :number

  def telephone_number
    "(#{area_code}) #{number}"
  end
end
{% endhighlight ruby %}

So, we know the beginning and end, but what are the steps in between?

### Approach One: The Hard Way

Step 1: Determine the change to make.

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end
end
{% endhighlight ruby %}

Having a bunch of attributes with the same prefix is a clear indicator of a class waiting for extraction.

Step 2: Do the whole thing at once.

{% highlight ruby %}
class Person
  attr_accessor :name

  def telephone_number
    TelephoneNumber.telephone_number
  end
end

class TelephonNumber
  def telephone_number
    "(#{area_code}] #{number}"
  end
end
{% endhighlight ruby %}

In one fell swoop I copy type out the new class, delete the old code and save it.

Step 3: Run the tests, see them fail.

Because I am not perfect (and neither are you, I'm guessing), this code does not work. Now I've found myself in a weird state. Which of my changes broke my application? I'm not sure, since I made a lot of changes at once.

Step 4: Fix the failures.

Since I'm not sure what change broke the code I have to slow way down. I read through the test stack traces and figure out where I messed up, then switch back to the code and make a fix. If my test suite provides excellent failure messages then this is only slightly painful, but it's always slow.

Step 5: Repeat Steps 3 and 4 until you either give up or beat the code into shape.

I pick my way through the failing tests and slowly get them all to pass. Depending on the size and complexity of the code I just extracted, this could take a few minutes, or hours, [or days](http://www.mayerdan.com/programming/2015/02/18/safer-refactoring-on-legacy-systems/). In some cases the morass of failing tests might be so bad that you just delete this branch and pretend the refactoring never happened.

### Approach Two: The Easy Way

Step 1: Determine the change to make.

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end
end
{% endhighlight ruby %}

We start off the same way. We look at the code and see that we want to extract a TelephoneNumber.

Step 2: Add a single change.

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end
end

class TelephoneNumber
end
{% endhighlight ruby %}

Step 3: Run your tests.

If they pass, congratulations! You haven't broken anything. If they fail, you know exactly what broke and can fix it.

Step 4: Repeat until you're done.

One change. Save. Run tests. Repeat. That's it.

I learned this approach from Katrina Owen, who calls it [Refactor Under Green](http://www.sitepoint.com/refactoring-workout-relentlessly-green/), but as she says herself, these steps are the same ones used by Fowler in _Refactoring_. Let's look at the steps he lists for Extract Class (emphasis mine):

1. Decide how to split the responsibilities
2. Create a new class
3. Make a link from the old class to the new class
4. Use Move Field on each field you want to move ('field' meaning attribute)
5. **Test after each move**
6. Use Move Method on each method you want to move
7. **Test after each move**

Following those steps, our refactorings would look like this. Note that we are saving and running tests between each example.

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end
end
{% endhighlight ruby %}

-------

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end
end

class TelephoneNumber
end
{% endhighlight ruby %}

-------

{% highlight ruby %}
class Person
  attr_accessor :name, :office_area_code, :office_number

  def telephone_number
    "(#{office_area_code}) #{office_number}"
  end

  def office_telephone
    TelephoneNumber.new
  end
end

class TelephoneNumber
end
{% endhighlight ruby %}

-------

{% highlight ruby %}
class Person
  attr_accessor :name, :office_number

  def telephone_number
    "(#{office_telephone.area_code}) #{office_number}"
  end

  def office_telephone
    TelephoneNumber.new
  end
end

class TelephoneNumber
  attr_accessor :area_code
end
{% endhighlight ruby %}

-------

{% highlight ruby %}
class Person
  attr_accessor :name

  def telephone_number
    office_telephone.telephone_number
    "(#{office_telephone.area_code}) #{office_telephone.number}"
  end

  def office_telephone
    TelephoneNumber.new
  end
end

class TelephoneNumber
  attr_accessor :area_code, :number

  def telephone_number
    "(#{area_code}) #{number}"
  end
end
{% endhighlight ruby %}

-------

{% highlight ruby %}
class Person
  attr_accessor :name

  def telephone_number
    office_telephone.telephone_number
  end

  private

  def office_telephone
    TelephoneNumber.new
  end
end

class TelephoneNumber
  attr_accessor :area_code, :number

  def telephone_number
    "(#{area_code}) #{number}"
  end
end
{% endhighlight ruby %}

That probably seems like a lot of steps. It may even strike you as excessive. But it's foolproof. It absolutely **can not** fail. If a test ever fails, you only have one change to undo to get back to a passing test suite.

It is entirely possible that you are smarter than everyone else and can do big refactorings without a safety net. But it is more likely that you should go read [the article on Dunning-Krueger](https://en.wikipedia.org/wiki/Dunning–Kruger_effect) again. Software is hard. Refactoring is hard. Make it easy on yourself.

In last week's newsletter I [talked about the Divergent Change smell](http://tinyletter.com/ianwhitney/letters/divergent-change-a-smell-by-any-other-name). This week I'll look at its Bizarro-world twin, Shotgun Surgery. You can [sign-up for the newsletter](http://tinyletter.com/ianwhitney/), check out [previous issues](http://tinyletter.com/ianwhitney/archive) or start preparing yourself for the start of Daylight Savings Time (yuck). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com

<a name='values'>\*</a> He doesn't address how the telephone number properties are set. Just assume they are, I guess.
