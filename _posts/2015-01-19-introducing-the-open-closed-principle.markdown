---
layout: post
title: "An Introduction to the Open/Closed Principle"
date: 2015-01-19T20:02:30-06:00
---
In [last week's newsletter](http://tinyletter.com/ianwhitney/letters/who-knew-that-squaring-numbers-could-be-so-fraught) I said that I'd be talking about polymorphism this week. I was wrong about that. Instead, we're going to talk about the [Open Closed Principle (OCP)](https://en.wikipedia.org/wiki/Open/closed_principle). We're also not going to get to an [Exercism](http://exercism.io/) problem this week. I'm want to really illustrate OCP<sup>[\*](#ocp)</sup> this week and next week we'll use it on an Exercism problem.

Before getting into the code, I'm going to try to clearly state the OCP<sup>[\*](#ocp)</sup>. The way I've heard it goes something like:

> Your code should be open to extension but closed to modification.

Another way of saying that is:

> Adding new features should not require any changes to your existing features.

But what does that mean in practice? Let's start with a simple example:

```
class Person
  attr_accessor :email

  def enroll
    Newsletter.add(Person.email)
  end
end
```

Does this code conform to OCP<sup>[\*](#ocp)</sup>? Just like Sandi Metz's TRUE heuristic in [last week's post](http://designisrefactoring.com/2015/01/11/the-why-of-squares/), we can't judge by looking at static code. We have to judge in the context of adding new functionality. If we wanted to add a method to display a Person's name then this code wouldn't have to change, making it Open/Closed.

But if we add a new newsletter that people can enroll in, then this code is not Open/Closed. If we followed the principle and didn't change any of our existing code, we'd have to add the new method like this:

```
class Person
  attr_accessor :email

  def enroll
    Newsletter.add(email)
  end

  def enroll_vip
    VIPNewsletter.add(email)
  end

  def enroll_all
    enroll
    enroll_vip
  end
end
```

And that's obviously not a road we want to go down. How do we improve the design of this code so that is Open/Closed to the functionality we want to add? The above implementation is very helpful in figuring our our next steps. We have two methods: `enroll` and `enroll_vip` that are nearly identical. If we can extract out the difference between those two methods, then we can implement a single solution that is Open/Closed to adding new newsletters.

Once we see that, the implementation is easy:

```
class Person
  attr_accessor :email

  def enroll(newsletter = Newsletter)
    newsletter.add(email)
  end
end
```

By giving the newsletter parameter a default value of `Newsletter` we don't have to change any existing clients of this code. But as we add new code, we can pass in the `VIPNewsletter` or `SecretNewsletter` or whatever we want.

The steps we just took are a simple, repeatable mechanism for improving the design of your code and following the Open/Closed principle. Just follow the steps:

- Find a new feature to implement
- Implement it without changing any existing code
- Extract out the difference between your new code and the existing code
- Repeat as needed

This procedure comes with another benefit: __your code never breaks__. Let's go through the above steps in finer detail and show why that's true.

### Step 0: Initial Code

Here's our starting code again:

```
class Person
  attr_accessor :email

  def enroll
    Newsletter.add(email)
  end
end
```

And let's say there's a test:

```
class PersonTest
  it "adds the email to the newsletter" do
    expect(Newsletter).to receieve(:add).with(@person.email)
  end
end
```

We get the feature request, "We're adding a new VIP Newsletter that people can enroll in." We look at this code and determine that we can not implement that feature without changing the `enroll` method. So we try creating a new method.

### Step 1: Implement New Method

```
class Person
  attr_accessor :email

  def enroll
    Newsletter.add(email)
  end

  def enroll_vip
    VIPNewsletter.add(email)
  end
end
```

And we follow the same testing approach:

```
class PersonTest
  describe "enroll" do
    it "adds the email to the newsletter" do
      expect(Newsletter).to receieve(:add).with(@person.email)
    end
  end

  describe "enroll_vip" do
    it "adds the email to the vip newsletter" do
      expect(VIPNewsletter).to receieve(:add).with(@person.email)
    end
  end
end
```

During that process our existing code and tests didn't break because we never changed the `enroll` method.

### Step 2: Refactor

Now that the design problem that prevents `enroll` from being Open/Closed is clear, we can refactor our code. We do so cautiously.

```
class Person
  attr_accessor :email

  def enroll
    Newsletter.add(email)
  end

  def enroll(newsletter = Newsletter)
    newsletter.add(email)
  end

  def enroll_vip
    VIPNewsletter.add(email)
  end
end
```

The refactoring we did here is Add Parameter (_Refactoring_, p. 275). It's a pretty easy one, but if you look at the steps that Fowler suggests, they are very cautious:

1. Look for places where the method is implemented, to be sure to get all of them.
2. Declare a new method with the added parameter.
3. Verify the code. (compile, tests, etc.)
4. Change the old method to call the new one.
5. Verify the code.
6. Change all clients of the old method.
7. Remove the old method.
8. Verify the code.

In our example, we've overridden our old implementation with the new one. We can then run the tests and verify that things work. They do, so we can continue:

```
class Person
  attr_accessor :email

  def enroll(newsletter = Newsletter)
    newsletter.add(email)
  end

  def enroll_vip
    enroll(VIPNewsletter)
  end
end
```

Verify again and everything still works. At this point we can finish up by tweaking our new test

```
class PersonTest
  #...
  describe "enroll_vip" do
    it "adds the email to the vip newsletter" do
      expect(VIPNewsletter).to receieve(:add).with(@person.email)
      @person.enroll(VIPNewsletter)
    end
  end
end
```

Then delete the `enroll_vip` method.

```
class Person
  attr_accessor :email

  def enroll(newsletter = Newsletter)
    newsletter.add(email)
  end
end
```

Now we can sneakily enroll people into any newsletter we want! And, while adding the feature our tests never broke and we never ended up in that awful state of a half-finished feature surrounded by a pile of tests that will pass again *soon*.

Obviously the above change was simple. With more complex changes you want to be more cautious. After you see the refactoring you need to do, remove the new feature. Then refactor the code until it is Open/Closed to the new feature you want to add.

Meeting the Open/Closed Principle depends entirely on the features you need to add. Our current code is Open/Closed to any email-based newsletter. But if a person wanted to enroll to a text message newsletter that was delivered to a phone number, then our existing code would not be Open/Closed to that change. There is no such thing as code that is _always_ Open/Closed. If there was then the world would need far fewer programmers.

A small fraction of the world's many programmers read my weekly newsletter. You can too! [Sign-up is easy and free](http://tinyletter.com/ianwhitney/) and you can always checkout [previous newsletters](http://tinyletter.com/ianwhitney/archive). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com

<a name='ocp'>\*</a> [Yeah, you know me!](http://genius.com/Naughty-by-nature-opp-lyrics)
