---
layout: post
title: "So Long, Value Object. Hello, Reference"
date: 2015-05-11T07:47:21-05:00
author: Ian Whitney
---

Maybe after my [last post](http://designisrefactoring.com/2015/04/26/organizing-data-replace-data-value-with-object/) you refactored your code and introduced a bunch of Value objects. And now, perhaps, the bloom is off the rose and you are realizing that Value objects were not the right solution. Value objects can be great, in the right situation. But in the wrong situation, of which there are many, Value objects are trouble. As immutable representations of simple data, Value objects can be powerful tools, but they aren't the block you build an application with.

<!--break-->

Fowler, intentionally I'm sure, set a bit of a trap in "Replace Data Value With Object" when he created a Value object out of the application's Customer class. I can't imagine a less likely Value object than a Customer. What business thinks so little of their Customers that they represent them with such an intentionally limited class? It's only a matter of time until another refactoring is necessary: Change Value to Reference.

What is a Reference? Well, it's a Reference Object. Wait...what is a Reference Object? Maybe this is a term familiar to you, but it was foreign to me. Fowler describes it as "things like customer or account...you use the object identity test to determine if they are equal." In our previous code, the Value version of Customer looked like this:

{% highlight ruby %}
class ValueCustomer
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

ValueCustomer.new(name: "Ian Whitney") == ValueCustomer.new(name: "Ian Whitney")
#=> true
{% endhighlight ruby %}

Equality was determined by comparing two instances' names. A Reference version of customer might look like:

{% highlight ruby %}
class ReferenceCustomer
  attr_reader :name

  def initialize(name:)
    self.name = name
  end

  private

  attr_writer :name
end
ReferenceCustomer.new(name: "Ian Whitney") == ReferenceCustomer.new(name: "Ian Whitney")
#=> false
{% endhighlight ruby %}

Instead of overriding the equality comparison, we use Ruby's default `==` method, which compares the instances' `object_id`s. And we find that no two ReferenceCustomers we instantiate are ever equal.

{% highlight ruby %}
ReferenceCustomer.new(name: "Ian Whitney").object_id
#=> 70324666486140
ReferenceCustomer.new(name: "Ian Whitney").object_id
#=> 70324666532820
{% endhighlight ruby %}

Also, unlike Value objects, Reference objects are mutable. So we can add a method that allows us to change a Customer's name.

{% highlight ruby %}
class ReferenceCustomer
  attr_reader :name

  def initialize(name:)
    self.name = name
  end

  def change_name_to(new_name)
    self.name = new_name
  end

  private

  attr_writer :name
end
ReferenceCustomer.new(name: "Ian Whitney").change_name_to("Mr. Stinkypants")
{% endhighlight ruby %}

Being able to update our Customers seems great, but being unable to compare Customers seems of dubious value. However, this is definitely the road Fowler wants us to follow. Let's roll with it and see where it goes.

Now that we know what a Reference object is we can follow the steps of the Replace Value with Reference pattern. First is "Replace constructor with Factory Method".

The constructor we're replacing is in Order:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self.customer = Customer.new(name: customer_name)
  end
{% endhighlight ruby %}

"Replace Constructor with Factory Method" is a pattern in _Refactoring_ (page 304, if you've got a copy at hand). I'm going to skip the steps of that pattern and go straight to the end:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self.customer = Customer.create(customer_name)
  end
end

class Customer
  private_class_method :new
  attr_reader :name

  def self.create(name)
    new(name)
  end

  def change_name_to(new_name)
    self.name = new_name
  end

  private

  attr_writer :name

  def initialize(name)
    self.name = name
  end
end
{% endhighlight ruby %}

Two big changes to dig into. First, Order is now using the `Customer.create` factory method. Second, in Customer we've forced all instantiation to go through `create`. The `private_class_method :new` line prevents the use of `Customer.new` (well, mostly. This is still Ruby after all). The logic behind this change is simple enough: if you're going to put object creation logic in a custom method, then make sure that everyone uses that method.

Privatizing the initializer isn't something I've seen very often in Ruby, but it lines up nicely with [Declarative Builders](http://programming.ianwhitney.com/blog/2014/04/13/4-simple-rules-and-declarative-builders/), which I wrote about a year ago. And [the technique does crop up in real projects as well](https://github.com/rails/rails/blob/9e84c0096f2c8ec27cf354ac2817cc49cbbcb783/actionmailer/lib/action_mailer/base.rb#L439), so it's useful to know.

But, we still haven't solved the equality weirdness from earlier:

{% highlight ruby %}
Customer.create("Ian Whitney") == Customer.create("Ian Whitney")
#=>false
{% endhighlight ruby %}

Fowler tackles this in steps two and three:

- Decide what object is responsible for providing access
- Decide whether the objects are pre-created or created on the fly

He uses Customer to provide access to a collection of pre-created Customer instances.

{% highlight ruby %}
class Customer
  private_class_method :new
  attr_reader :name

  def self.create(name)
    store.detect { |c| c.name == name }
  end

  def change_name_to(new_name)
    self.name = new_name
  end

  private

  attr_writer :name

  def self.load_customers
    [
      new("Ian Whitney")
    ]
  end

  def self.store
    @store ||= load_customers
  end

  def initialize(name)
    self.name = name
  end
end

x = Customer.create("Ian Whitney")
#=> #<Customer:0x007fa470830da8 @name="Ian Whitney">
y = Customer.create("Ian Whitney")
#=> #<Customer:0x007fa470830da8 @name="Ian Whitney">

x == y
#=> true
{% endhighlight ruby %}

And that solves the equality problem, though the name of the `create` method is now a little odd since we're not creating anything. A simple renaming fixes the problem:

{% highlight ruby %}
class Order
  def initialize(customer_name:)
    self.customer = Customer.get_by_name(customer_name)
  end
end

class Customer
  private_class_method :new
  attr_reader :name

  def self.get_by_name(name)
    store.detect { |c| c.name == name }
  end
  #...
end
{% endhighlight ruby %}

Is this a solution that you expect to see in your code? I don't know about you, but I don't expect my Customer class to pre-load a bunch of Customer instances so that it can store them in an Class-level instance variable.

But, if you swap out "Class-level instance variable" for "Relational database", then this code looks pretty familiar:

{% highlight ruby %}
class Customer << ActiveRecord::Base
end

x = Customer.find_by_name("Ian Whitney")
y = Customer.find_by_name("Ian Whitney")
x == y
#=> true
{% endhighlight ruby %}

In Fowler's example, Customer knows how to retrieve instances of itself from the store and -- with a couple more methods -- it could also know how to put new instances into the store. If you retrieve the same customer twice, your two instances will be equal. The ActiveRecord version has the exact same knowledge and abilities<sup>[\*](#fn1)</sup><a name='fn1_return'></a>, though the implementation of those abilities is in code that you probably don't look at that often. I know I don't.

The two implementations offer the same features, but they suffer from the same drawback as well -- mutation. In ActiveRecord you could be dealing with a database record that has changed out from underneath you. In Fowler's internal-store approach, another user of Customer could change the object you're using. Like I said earlier, Reference objects, unlike Value objects, are mutable. Fowler is pretty clear about this:

> you want to give it some changeable data and ensure that the changes ripple to everyone referring to the object.

If your goal is for that 'ripple' to be instant then Fowler's implementation is clearly superior to the ActiveRecord approach.

{% highlight ruby %}
x = ActiveRecordCustomer.find_by_name("Ian Whitney")
y = ActiveRecordCustomer.find_by_name("Ian Whitney")
x.change_name_to = "Sir Ian Whitney"
x.save
y.name
#=> "Ian Whitney"
y.reload
y.name
#=> "Sir Ian Whitney"
{% endhighlight ruby %}

But with the internal store of object references:

{% highlight ruby %}
x = InternalStoreCustomer.create("Ian Whitney")
y = InternalStoreCustomer.create("Ian Whitney")
x.change_name_to = "Sir Ian Whitney"
y.name
#=> "Sir Ian Whitney"
{% endhighlight ruby %}

Which just reflects the value of using references to objects in memory instead of data in a database. Obviously this approach won't work in all situations. You probably can't store your entire application database in memory. But in the right situations, it's very helpful.

In the end, where and how you choose to store the reference objects is an implementation detail. It's not really the point of this refactoring. Instead, the point is how you can give your classes even more powerful collaborators. In the beginning, [Customer was just a string](http://designisrefactoring.com/2015/04/26/organizing-data-replace-data-value-with-object/), then it became a useful-but-limited Value object; now, as a Reference object, it's far more powerful and (possibly) error prone. Which solution is the _right_ one depends on your needs.

You may also need to [sign up for my free newsletter](http://tinyletter.com/ianwhitney/), in which I usually talk about code smells and assorted nonsense. Check out [previous issues](http://tinyletter.com/ianwhitney/archive) if you want to catch up on my previous ramblings. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/3).

<a name='fn1'>\*</a> Well, not exactly. In our internal-store implementation the object_id of `x` and `y` will be the same. In the ActiveRecord version they will be different. ActiveRecord defines equality by comparing the `id` values of the two objects. [back](#fn1_return)
