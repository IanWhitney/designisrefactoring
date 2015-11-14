---
layout: post
title: "Introducing Sandi Metz's TRUE"
date: 2015-02-08T20:01:01-06:00
author: Ian Whitney
---

In previous posts I've mentioned [Sandi Metz](http://www.sandimetz.com/)'s **TRUE** heuristic for judging code quality, but I've never delivered on my promise to really dive into it. This week I'll finally start that dive.

TRUE is an acronym that stands for:

- Transparent
- Reasonable
- Usable
- Exemplary

If code meets those four criteria then it is well designed. Let's dig into each element and find out what they mean.

<!--break-->

### Transparent

#### It is easy to see the code's function and the effect of a change

These two methods do the same thing:

Opaque

{% highlight ruby %}
def ex(x)
  Account.transform(x * REQ_A).monkey_kick(:2, self)
end
{% endhighlight %}

Transparent

{% highlight ruby %}
def extend(number_of_months)
  modified_month_count = number_of_months * loyalty_bonus

  Account.extend_subscription(modified_month_count)

  notify_accounting({action: extension, user: self})
end
{% endhighlight %}

The opaque method has all the hallmarks of hard-to-understand code. Magic numbers, methods named after jokes, constants with useless names. 

The transparent method, while not the Best Method Ever, is at least understandable. You can see the effect of changing `loyalty_bonus` for example. You can see that you are telling accounting about a change, instead of wondering what the heck a monkey kick is.

-----

### Reasonable

#### A change takes effort reasonable for its complexity

Again, two methods that do the same thing:

Unreasonable

{% highlight ruby %}
def full_name
  salutation = gender == "M" ? "Mr" : "Ms"
  "#{salutation} #{first_name} #{last_name}"
end
{% endhighlight %}

Reasonable

{% highlight ruby %}
def full_name(salutation: basic_salutation)
  "#{salutation} #{first_name} #{last_name}"
end

def basic_salutation
  salutation = gender == "M" ? "Mr" : "Ms"
end
{% endhighlight %}

Changing a salutation should be easy. But changing it in the Unreasonable method would require you to alter a ternary to something worse.  In the reasonable method you can pass in any salutation you want or use the basic salutation.

-----

### Usable

#### The code can be used in other contexts

Unusuable

{% highlight ruby %}
def square_number(number)
  number ** 2
end
{% endhighlight %}

Usable

{% highlight ruby %}
class Numeric
  def power(x)
    self ** x
  end
end
{% endhighlight %}

`square_number` is syntactic sugar that can only do one thing. Great if you need to square a bunch of numbers, I guess, but unusable beyond that. `power` will work in greater number of contexts.

-----

### Exemplary

#### The code serves as an example of the kind of code you want


Unworthy

{% highlight ruby %}
class Array
  def first
    self.reverse[1]
  end
end
{% endhighlight %}


Exemplary

{% highlight ruby %}
class MyWeirdList
  include Enumerable

  def second_from_last
    collection[-2]
  end
  alias :first :second_from_last

  def collection
    @collection ||= []
  end
end
{% endhighlight %}

Contrived? Sure. But google "monkey patch Array" and marvel at the weird stuff people want to patch into to Array. In the unworthy example we have globally changed the behavior of the `first` method. We don't want people taking this code as an example and continuing the tradition.

At least the exemplary example contains the damage to this one class. I'd much rather see this approach than the first one.

### Using TRUE

Here's what I said when I first introduced TRUE

> Note that all of Sandi’s criteria are about *modifying* the code. Each point talks about the effort and effect of changes to your existing code. You can’t look at a piece of static code and say whether or not it is TRUE; you have to think in the context of code maintenance, which is when design is most important.

Which, thinking about it more, isn't exactly correct. You can look at static code and judge its TRUEness. My opaque code example above is opaque whether or not I need to change it. I can make a choice when coding to write exemplary methods that are not tightly-bound to a single problem. You should try to write TRUE code now, but you might find out that you missed the mark when it comes time to change the code.

Next week we're going to write some code and then refactor it using the TRUE heuristic. All so we can write some slightly-dirty rhymes.

My newsletter is not dirty, but it is quite smelly. [Last week was the second entry in the Catalog of Smells: Long Method](http://tinyletter.com/ianwhitney/letters/how-long-is-a-method). This week we'll add a new smell to our collection. You can [sign-up for the newsletter](http://tinyletter.com/ianwhitney/), check out [previous issues](http://tinyletter.com/ianwhitney/archive) or enjoy a nice beverage of your choice. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com
