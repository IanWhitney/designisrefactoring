---
layout: post
title: "Exercism: The Gigasecond Exercise"
date: 2014-06-09 13:39:49 -0500
comments: true
categories: 
---

[The Readme](https://github.com/IanWhitney/exercism_problems/blob/master/ruby/gigasecond/README.md)

[The Test Suite](https://github.com/IanWhitney/exercism_problems/blob/91b270965142f1ad3466bc44ee9dde37f6602858/ruby/gigasecond/gigasecond_test.rb)

Honestly, as the tests are written there's not much to dig into here. Nearly every first pass at this code looks something like mine:

```ruby
class Gigasecond
  def initialize(start_date)
    self.start_date = start_date
  end

  def date
    start_date + 11574 #number of days in a gigasecond
  end

  private
  attr_accessor :start_date
end
```

Some people convert the Date to Time and then add 1 billion seconds to it, but the concept is the same. Ruby already has good date operators; there's no reason to reinvent the wheel.

So, this works and is totally readable. We could probably just leave it at that. But then I wouldn't get to type a rambling blog post. That's no fun. Let's dig deeper.

The test suite only includes Date objects. Even though we know that Ruby has other ways of representing time, let's set that aside for now and assume we're only going to get Dates.

```ruby
require 'delegate'
class Gigasecond < SimpleDelegator
  def date
    __getobj__ + 11574 #number of days in a gigasecond
  end
end
```

With this our tests still pass and we've saved a few lines of code. That tiny refactoring done, we revisit the problem of Time and DateTime, Ruby's other classes for representing dates.

As written, this code will work with Date and DateTime, as they both use the same implementation for the + operator. They add **days**. But Time's + operator adds **seconds**.

```ruby
d = Date.today
#=> #<Date: 2014-06-09 ((2456818j,0s,0n),+0s,2299161j)>
d + 1
#=> #<Date: 2014-06-10 ((2456819j,0s,0n),+0s,2299161j)>

#######

dt = DateTime.now
#=> #<DateTime: 2014-06-09T13:46:20-05:00 ((2456818j,67580s,427220000n),-18000s,2299161j)>
dt + 1
#=> #<DateTime: 2014-06-10T13:46:20-05:00 ((2456819j,67580s,427220000n),-18000s,2299161j)>

#######

t = Time.now
#=> 2014-06-09 13:46:37 -0500
t + 1
#=> 2014-06-09 13:46:38 -0500
```

So, if we want to support Time, we'll have to handle that difference. Of course we want to support Time! But let's make sure Date works first:

```
rubyrequire 'delegate'
class Gigasecond < SimpleDelegator
  def date
    __getobj__.gigaseconds_since
  end
end

class Date
  def gigaseconds_since
    self + 11574
  end
end
```

The `gigaseconds_since` method naming follows the convention of [Date helpers in Rails](http://api.rubyonrails.org/classes/Date.html). Ruby doesn't have helper methods like this, but I figured people would be familiar with the Ralis methods, so I stuck to similar naming.

I don't have to implement DateTime because it inherits from Date. So now I just need to add Time support. Easy peasy.

```ruby
class Time
  def gigaseconds_since
    self + 1_000_000_000
  end
end
```

It was about here when I looked at the initial test suite and realized that it didn't exercise DateTime or Time objects. Also, I think its use of static dates is a liability. Random dates in the tests might find weird edge cases. So I wrote a test like the following for Time, Date and DateTime:

```ruby
def test_date
  1000.times do |x|
    random_date = Time.at(rand * Time.now.to_i).to_date
    expected = random_date + 11574

    gs = Gigasecond.new(random_date)
    assert_equal expected, gs.date
    assert_equal expected, random_date.gigaseconds_since(1)
  end
end
```

This test makes sure my Gigasecond.new syntax works, as well as checking the gigaseconds_since syntax. And, sure, why not run it 1000 times? These 3000 tests still pass in 0.1 seconds, so I'm not concerned with how ridiculous it looks. If there is some weird date that breaks my implementation, this approach is more likely to find it. But, yes, it's ridiculous. I'm not ashamed.

Now we can easily tell people what Time/DateTime/Date is 1 gigasecond after the Time/DateTime/Etc. they provide. But why just **1** gigasecond? Who doesn't immediately start thinking about 2, 3, 1000 gigaseconds? Only people with no joy in their hearts, that's who.

The Rails `_since` methods that I copied accept parameters. `Time.now.hours_since(5)` will return a Time 5 hours in the future. So let's take that same approach.

```ruby
class Date
  def gigaseconds_since(multiple)
    self + (11574 * multiple)
  end
end

class Time
  def gigaseconds_since(multiple)
    self + ((10**9) * multiple)
  end
end
```

And we hardcode the Gigasecond implementation to always use just 1 lowly gigasecond.

```ruby
class Gigasecond < SimpleDelegator
  def date
    __getobj__.gigaseconds_since(1)
  end
end
```

Now we have to change our tests. First we need to show that the Date/Time implementation can use any number of gigaseconds, and we should show that Gigasecond is just an alias for `gigaseconds_since(1)`

```ruby
def test_gigasecond_wraps_date_methods
  random_date = Minitest::Mock.new
  gs = Gigasecond.new(random_date)
  random_date.expect(:gigaseconds_since, 1) { true }
  gs.date
end

def test_date
  1000.times do |x|
    random_date = Time.at(rand * Time.now.to_i).to_date
    random_gigaseconds = rand(1000)
    expected = random_date + (10**9 * random_gigaseconds / (24 * 60 * 60))

    assert_equal expected, random_date.gigaseconds_since(random_gigaseconds)
  end
end

### similar tests for DateTime and Time

```

Now it's time to tackle a problem that's been lingering in the bacground, the [Magic Numbers](http://en.wikipedia.org/wiki/Magic_number_\(programming\)). What is the meaning of 11574? What is 10\*\*9? What is 24 * 60 * 60?

In the context of the code these numbers aren't that hard to figure out. But if we can reduce cognitive overhead, we should. We can inspiration from Rails again and look at the methods [it adds to Numeric](http://api.rubyonrails.org/classes/Numeric.html).

```ruby
t = Time.now
#=> 2014-06-09 15:43:14 -0500
t + 1.hour
#=> 2014-06-09 16:43:14 -0500
```

Methods like `hour` return a [Duration](http://api.rubyonrails.org/classes/ActiveSupport/Duration.html) instance, which is probably more than we need. We can keep this pretty simple.

```ruby
class Date
  SECONDS_PER_DAY = 86400
  def gigaseconds_since(multiple)
    self + (multiple.gigaseconds / SECONDS_PER_DAY)
  end
end

class Time
  def gigaseconds_since(multiple)
    self + multiple.gigaseconds
  end
end

class Numeric
  def gigaseconds
    self * 1_000_000_000
  end
  alias :gigasecond :gigaseconds
end
```

The simplicity of our approach forces us to use the SECONDS_PER_DAY constant. The gigaseconds method will only return seconds and we need to convert it to days. We could do the math in the method, but a named constant helps us remember what 86400 means.

If we had implemented something like `Duration` we could have added a handy `to_days` methods as a way around this problem. But, as it is, I don't think that extra code is worth the effort.

An as-yet undiscussed side-effect of the changes we've made is that we can now work with fractional gigaseconds. `Time.now.gigaseconds_since(1.33)` will work. It worked in earlier implementations as well, but we could have easily broken the functionality had we monkey patched `Integer` instead of `Numeric`.

And that's that. Well. Almost. I was happy with this code until I realized that I'd left myself a surprise:

```ruby
d = Gigasecond.new(Date.today)
#=> #<Date: 2014-06-09 ((2456818j,0s,0n),+0s,2299161j)>
irb(main):011:0> d.date
#=> #<Date: 2046-02-15 ((2468392j,0s,0n),+0s,2299161j)>
irb(main):012:0> d.to_time
#=> 2014-06-09 00:00:00 -0500
```

So `date` gives me a date 32 years in the future, but `to_time` gives me today. That's the little bomb I planted for myself when I used SimpleDelegator, which happily forwards any method it doesn't know about to the object I instantiated it with.

Delegation only hurts us, so let's go back to a simpler approach.

```ruby
class Gigasecond
  def initialize(start_date)
    self.start_date = start_date
  end

  def date
    start_date.gigaseconds_since(1)
  end

  private

  attr_accessor :start_date
end
```

Put everything together and here's the final implementation:

```ruby
require 'delegate'
class Gigasecond
  def initialize(start_date)
    self.start_date = start_date
  end

  def date
    start_date.gigaseconds_since(1)
  end

  private

  attr_accessor :start_date
end

class Date
  SECONDS_PER_DAY = 86400
  def gigaseconds_since(multiple)
    self + (multiple.gigaseconds / SECONDS_PER_DAY)
  end
end

class Time
  def gigaseconds_since(multiple)
    self + multiple.gigaseconds
  end
end

class Numeric
  def gigaseconds
    self * 1_000_000_000
  end
  alias :gigasecond :gigaseconds
end
```
### Summary

And that's how you take a dead-simple problem and talk about it for 1000+ words. For the problem as stated, the initial implementation is just fine. In my quick survey of the solutions on Exercism, nearly everyone does it exactly that way. But that doesn't mean you have to leave it there. That code solves only one problem, how to add 1 gigasecond to a Date. If you were a client of that code, would you be surprised that it was so limited? I would. 

There's certainly an argument to be made for [YAGNI](http://en.wikipedia.org/wiki/You_aren't_gonna_need_it). No one has asked for time, or for multiple gigaseconds, so why bother? But I'd argue that the initial implmenation was unfinished. It was like finding a huge cookbook that only contained a single recipe, "How to make toast."  We're not so much adding unnecessary features as we are adding the implementation that I would expect if I used this code. The final version more fully completes the gigasecond functionality so that you don't have to keep rewriting it to handle new features. An extra hour's worth of work at the beginning might save you a ton of time down the road.
