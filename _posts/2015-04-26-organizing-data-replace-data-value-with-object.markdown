---
layout: post
title: "Organizing Data: Replace Data Value With Object"
date: 2015-04-26T11:43:58-05:00
author: Ian Whitney
---

A busy few weeks as [my employer](http://www.umn.edu) finished their extensive upgrade of their PeopleSoft installation. With that done, let's get back to talking about refactoring.

My [last post](http://designisrefactoring.com/2015/03/29/organizing-data-self-encapsulation/) kicked off my walkthrough of the Organizing Data patterns. This week we'll move on to the 2nd part of that series: Replace Data Value With Object. Fowler's code example for this pattern illustrates the problem well:

<!--break-->

{% highlight ruby %}
class Order
  def initialize(customer)
    self.customer = customer
  end

  def customer_name
    customer
  end

  private

  attr_accessor :customer
end

Order.new("Ian Whitney").customer_name
#=> "Ian Whitney"
{% endhighlight %}

The "Data Value" we want to replace here is the string we assign to our customer attribute. Why? Because it is almost entirely useless. We've all written code like this, especially as we are designing some new feature. But this code becomes a hindrance almost as soon as you write it. If you're writing a client of this code, do you know why you're passing some person's name into the initializer? Within the code itself, is there anything of interest you can do with the string?

With Ruby's named parameters you can solve the first problem:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self.customer = customer_name
  end

  def customer_name
    customer
  end

  private

  attr_accessor :customer
end

Order.new(customer_name: "Ian Whitney").customer_name
#=> "Ian Whitney
{% endhighlight ruby %}

But that syntactic nicety doesn't help the Order instance do anything of use with a string. We're using a language that makes it easy for us to create new classes, so let's make a class. Essentially this pattern is a near-exact copy of Extract Class with one little twist. Let's break the refactoring into two steps, since we know that [slow is steady and steady is fast](http://designisrefactoring.com/2015/03/01/refactoring-two-ways/).

## Step One:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self.customer = customer_name
  end

  def customer_name
    customer
  end

  private

  attr_accessor :customer
end

class Customer
  attr_reader :name

  def initialize(name:)
    self.name = name
  end

  private

  attr_writer :name
end
Order.new(customer_name: "Ian Whitney").customer_name
{% endhighlight ruby %}

## Step Two:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self.customer = Customer.new(name: customer_name)
  end

  def customer_name
    customer.name
  end

  private

  attr_accessor :customer
end

class Customer
  attr_reader :name

  def initialize(name:)
    self.name = name
  end

  private

  attr_writer :name
end
Order.new(customer_name: "Ian Whitney").customer_name
#=> "Ian Whitney"
{% endhighlight ruby %}

The twist here is that we create the Customer inside of Order not outside, like this:

{% highlight ruby %}
class Order
  attr_reader :customer

  def initialize(customer:)
    self.customer = customer
  end
  #...
end
Order.new(Customer.new(name: "Ian Whitney")).customer.name
{% endhighlight ruby %}

And that might seem odd to you. It certainly seems odd to me, mostly because I find that the approach of creating a Customer outside of Order is easier to test. We're certainly creating a hidden dependency between Order and Customer, and that might surprise us later.

Fowler does this because he is replacing a "Data Value" with a "[Value Object](http://martinfowler.com/bliki/ValueObject.html)", which (if you're like me) is probably a term you've heard a bunch but haven't fully investigated. So let's investigate! A Value Object is a:

> small object such as a Money or date range object...their notion of equality isn't based on identity, instead two value objects are equal if all their fields are equal

Simple enough:

{% highlight ruby %}
class Customer
  attr_reader :name

  def initialize(name:)
    self.name = name
  end

  def ==(other)
    name == other.name
  end
  alias_method :eql?, :==

  private

  attr_writer :name
end

Customer.new(name: "Ian Whitney") == Customer.new(name: "Ian Whitney")
#=> true
{% endhighlight ruby %}

But Fowler continues:

> value objects should be entirely immutable

There are lots of ways you can [fake immutability](https://duckduckgo.com/?q=immutable%20ruby) in Ruby, but true immutability is probably impossible. We could [use a bunch of gems](http://www.sitepoint.com/functional-programming-ruby-value-objects/) to get us close, but all of these [won't actually make your value objects immutable](http://apidock.com/ruby/Object/instance_variable_set) (that documentation makes me laugh every single time).

Back to the original question, why does Fowler create a Customer inside of Order? Imagine we weren't using Ruby and didn't have the ability to modify everything at will. In that language we would have no way to access the Customer object inside of Order. We couldn't, say, accidentally change the customer's name to "Mr. Stinkypants." The only way to change the Customer would be to create a new Order.

But we're in Ruby, so no matter what you do your code is one [`instance_variable_set`](http://ruby-doc.org/core-2.2.2/Object.html#method-i-instance_variable_set) away from Mr. Stinkypants.

Should you take that aspect of Ruby into account when doing this refactoring? I think that depends on the project and your style. For my code, which is almost always used by a small number of programmers, I usually create Customer outside of Order. It's clearer what is going on and it allows for more flexibility. And the risk of someone passing in a non-customer object or mutating my code is low.

But projects with a ton of users, or ones that maintain a strict demarcation between Public and Private APIs, will take a different approach and do something like:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self._customer = Customer.new(name: customer_name)
  end
{% endhighlight ruby %}

Where the underscore indicates that they'd rather you not mess around with this variable, please. In Ruby, asking nicely is about the best you can do.

You don't have to ask nicely to [sign up for my free newsletter](http://tinyletter.com/ianwhitney/). I'll be sending out a new issue next week, talking about code smells and other randomness. Checking out [previous issues](http://tinyletter.com/ianwhitney/archive) if you want to catch up on my previous ramblings. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/2).
