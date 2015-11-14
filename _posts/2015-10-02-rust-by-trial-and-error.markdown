---
layout: post
title: "Rust by Trial and Error"
date: 2015-10-02T13:02:22-05:00
author: Ian Whitney
---

At this year's [Rocky Mountain Ruby](http://rockymtnruby.com), I mentioned to [Steve Klabnik](http://www.steveklabnik.com) that I was trying (slowly) to learn [Rust](https://www.rust-lang.org). He encouraged me to blog about anything I managed to hack together, as the Rust community deserves the kind of enthusiastic blogging that so greatly helped the Ruby community. At the same conference a couple of people mentioned that they really liked my deep dives into [http://exercism.io](Exercism) problems.

So, let's give the people what they want by blogging about doing Exercism in Rust!

<!--break-->

I have no Rust experience beyond reading the first bit of of the [Rust book](https://doc.rust-lang.org/stable/book/), so expect the code in here to be terrible! The advantage of my awfulness, however, is that I'm going to move real slow. Trying to move fast just leads to inexplicable compiler errors.

The first Rust Exercism problem to tackle is the [leap year exercise](https://github.com/exercism/x-common/blob/master/leap.md). I've done this in Ruby and the solution is pretty straight forward. But in Rust I had no idea where to even begin. Thanks to the provided test suite I knew that I had to implement code like:

{% highlight rust %}
leap::is_leap_year(1996)
{% endhighlight%}

Actually implementing that? Not sure! I knew that Exercism provides example solutions in their repos, so I started by [stealing theirs](https://github.com/exercism/xrust/blob/master/leap/example.rs).

{% highlight rust %}
pub fn is_leap_year(year: i32) -> bool {
  let has_factor = |n| year % n == 0;
  has_factor(4) && (!has_factor(100) || has_factor(400))
}
{% endhighlight%}

What is even going on here? I worked it out line by line:

{% highlight rust%}
pub fn is_leap_year(year: i32) -> bool {
{% endhighlight%}

The test suite loads up our library (which is namespaced `leap`) and expects it to provide a function named `is_leap_year`. We make that work with the `pub fn is_leap_year` bit of this line. `fn is_leap_year` creates a function with the name `is_leap_year` and `pub` [makes it public](https://doc.rust-lang.org/stable/book/crates-and-modules.html#exporting-a-public-interface) so that it can be used elsewhere.

{% highlight rust%}
(year: i32)
{% endhighlight%}

This states that our function takes one parameter, `year` and that it must be a `i32`, which is [an integer](https://doc.rust-lang.org/stable/std/primitive.i32.html). Do you need a signed 32-bit integer to represent a year? No. But that's what the example code had, so let's go with it.

{% highlight rust%}
-> bool
{% endhighlight%}

Finally, this part says that our function will return a boolean.

If, like me, you've spent most of your time with Ruby, then the type-checking in code like `(year: i32) -> bool` may seem awkward. And it can be, especially when you're trying to learn. But it definitely has advantages, otherwise there wouldn't be a bunch of type-checked languages floating around. I don't know that we'll see those advantages in this post, but I'll get to them eventually.

{% highlight rust%}
  let has_factor = |n| year % n == 0;
{% endhighlight%}

This line was easier for me to understand once I translated it to Ruby

{% highlight rust %}
has_factor -> (n) { year.modulo(n) == 0 }
{% endhighlight%}

This code creates a lambda and gives it a name. The lambda returns true if `year.modulo(n)` is equal to 0, and false if it doesn't. The `let` is how Rust handles [variable bindings](https://doc.rust-lang.org/stable/book/variable-bindings.html).

With all those pieces in place,

{% highlight rust %}
has_factor(4) && (!has_factor(100) || has_factor(400))
{% endhighlight%}

is pretty straight forward. If your year is evenly divisible by 4 and it's either not evenly divisible by 100 **or** is evenly divisible by 400, then it's a leap year. This expression will always return a boolean, so we're satisfying the "return a boolean" part of our function declaration. Note that this line does not end with a semi-colon. Why? I'm not sure! It has to do with Rust being [expression oriented](https://doc.rust-lang.org/stable/book/functions.html#expressions-vs.-statements) and I don't really get that yet.

Ok! Our code works, our tests pass and I kind of understand what it's doing. Time to move on to the next exercise? No! Time to refactor! I don't know if our code is idiomatic Rust or not, but I certainly think it could be easier to understand. But since I don't know Rust, I don't actually know how to put my opinions into action&hellip;

I know that the first thing I want to do is to take that `has_factor` lambda and move it out of my `is_leap_year` function. It's currently trapped in there, of no use to anyone else.

Well, I know how to create a function, so&hellip;

{% highlight rust %}
pub fn is_leap_year(year: i32) -> bool {
  let has_factor = |n| year % n == 0;
  is_divisible_by_four(year) && (!has_factor(100) || has_factor(400))
}

pub fn is_divisible_by_four(num: i32) -> bool {
  num % 4 == 0
}
{% endhighlight%}

And that works. Miracles. I can extend this approach easily:

{% highlight rust %}
pub fn is_leap_year(year: i32) -> bool {
  is_divisible_by_four(year) && 
    (!is_divisible_by_100(year) || is_divisible_by_400(year))
}

pub fn is_divisible_by_four(num: i32) -> bool {
  num % 4 == 0
}

pub fn is_divisible_by_100(num: i32) -> bool {
  num % 100 == 0
}

pub fn is_divisible_by_400(num: i32) -> bool {
  num % 400 == 0
}
{% endhighlight%}

The hidden lambda is gone, but I now have 3 methods that know how to do the same thing, so let's dry that up by extracting their common knowledge into a new function.

{% highlight rust %}
pub fn is_leap_year(year: i32) -> bool {
  is_divisible_by_four(year) && 
    (!is_divisible_by_100(year) || is_divisible_by_400(year))
}

pub fn is_divisible_by_four(num: i32) -> bool {
  is_divisible_by(num, 4)
}

pub fn is_divisible_by_100(num: i32) -> bool {
  is_divisible_by(num, 100)
}

pub fn is_divisible_by_400(num: i32) -> bool {
  is_divisible_by(num, 400)
}

pub fn is_divisible_by(num: i32, factor: i32) -> bool {
  num % factor == 0
}
{% endhighlight%}

This may or may not be an improvement. I like that my new functions have descriptive names. I also like that, unlike the lambda, they are accessible outside of the `is_leap_year` function. But, being a Rubyist, I wonder where my classes are. The problem I'm trying to solve is about Years, but there's no clear "Year" concept in my code.

An [early section of the Rust book](https://doc.rust-lang.org/stable/book/dining-philosophers.html) describes how to extract and define concepts like Year by using [Structs](https://doc.rust-lang.org/stable/book/structs.html).

{% highlight rust %}
struct Year {
  ordinal: i32,
}

impl Year {
  fn new(ordinal: i32) -> Year {
    Year {
      ordinal: ordinal,
    }
  }
}
{% endhighlight%}

In Ruby this would look like:

{% highlight ruby %}
class Year
  attr_accessor :ordinal

  def initialize(ord)
    self.ordinal = ord
  end
end
{% endhighlight%}

In the lines

{% highlight rust %}
struct Year {
  ordinal: i32,
}
{% endhighlight%}

we create a Year struct, which the Rust docs describe as 'a way of creating complex data types'. But our Year is not complex, it only has one value, `ordinal`, which is still a 32-bit integer. Though Year may not be complex, using a struct lets me give me it a _name_, which I find to be more important. Thanks to struct, there's finally a 'Year' in all this code that's purportedly about Years.

In Ruby version of Year, I defined both _behavior_ and _attributes_ within the `class` block. But not in Rust. The `struct` block defined the attributes. This code:

{% highlight rust %}
impl Year {
  fn new(ordinal: i32) -> Year {
    Year {
      ordinal: ordinal,
    }
  }
}
{% endhighlight%}

defines behavior. We added the `new` method, which requires the now-familiar `i32` and returns a `Year`. Inside the method

{% highlight rust %}
Year {
  ordinal: ordinal,
}
{% endhighlight%}

this code creates a new Year struct and sets its `ordinal` value to the ordinal we've provided. We can execute the code like this:

{% highlight rust %}
let y = Year::new(1992);
println!("{}",y.ordinal);
{% endhighlight%}

Which would print 1992. Very exciting!

There's no requirement for us to write this `new` behavior. It's purely for convenience. If I removed the `impl` block from my code, I could still write:

{% highlight rust %}
let y = Year { ordinal: 1992 };
println!("{}", y.ordinal);
{% endhighlight%}

And it would work exactly the same. In the case of our simple Year, that code is tolerable. But using `new` is a big boon to readability and comprehensibility, so let's stick with it.

Our Year code doesn't do much. But we can use it and our Exercism tests still pass:

{% highlight rust %}
struct Year {
  ordinal: i32,
}

impl Year {
  fn new(ordinal: i32) -> Year {
    Year {
      ordinal: ordinal,
    }
  }
}

pub fn is_leap_year(year: i32) -> bool {
  let y = Year::new(year);
  is_divisible_by_four(y.ordinal) && 
    (!is_divisible_by_100(y.ordinal) || is_divisible_by_400(y.ordinal))
}

pub fn is_divisible_by_four(num: i32) -> bool {
  is_divisible_by(num, 4)
}

pub fn is_divisible_by_100(num: i32) -> bool {
  is_divisible_by(num, 100)
}

pub fn is_divisible_by_400(num: i32) -> bool {
  is_divisible_by(num, 400)
}

pub fn is_divisible_by(num: i32, factor: i32) -> bool {
  num % factor == 0
}
{% endhighlight%}

I think it would be nice if my Year could tell me if it is a leap year, instead of me having to pass the year's data off to some random functions. Reporting whether or not it's a leap year is new Year behavior. We implement it the same way as `new`.

{% highlight rust %}
impl Year {
  //unchanged `new` code

  fn is_leap(&self) -> bool {
    is_divisible_by_four(self.ordinal) && 
      (!is_divisible_by_100(self.ordinal) || is_divisible_by_400(self.ordinal))
  }
}
{% endhighlight%}

The function body looks familiar, but we have a new parameter: `&self`. If I wrote a method like this in Ruby, I could do:

{% highlight ruby %}
def is_leap?
  is_divisible_by_four?(self.ordinal) #....etc
end
{% endhighlight%}

In Ruby a instance method automatically has access to `self`. [Rust methods don't](https://doc.rust-lang.org/stable/book/method-syntax.html). I'm fuzzy on this point, but here's what I think is going on. In the Ruby code `year.is_leap?`, `year` is the receiver of the `is_leap?` method call. Inside the method the receiver can be accessed by using `self` (or leaving `self` off entirely, in most cases).

But because of Rust's focus on proper memory management, we have to tell the method how it's going to use the receiver so that it can properly handle the memory. Is it a reference, a value or a mutable reference. I'll be honest. I don't quite understand what that means. And I might be totally wrong about all of it! But `&self` is the most common way of providing self, so that's what I'm doing.

Now that Year has this behavior, we can change our `is_leap_year` function to use it.

{% highlight rust %}
pub fn is_leap_year(year: i32) -> bool {
  Year::new(year).is_leap()
}
{% endhighlight%}

Our `Year` design is pretty good! But our code still has these `is_divisible_by` methods hanging out at the top level. We interact with all of these methods exactly the same way, by passing an `ordinal`. We should extract an Ordinal and hang these methods off of it.

{% highlight rust %}
struct Ordinal {
  value: i32,
}

impl Ordinal {
  fn new(value: i32) -> Ordinal {
    Ordinal {
      value: value,
    }
  }

  fn is_divisible_by_four(&self) -> bool {
    self.is_divisible_by(4)
  }

  fn is_divisible_by_100(&self) -> bool {
    self.is_divisible_by(100)
  }

  fn is_divisible_by_400(&self) -> bool {
    self.is_divisible_by(400)
  }

  fn is_divisible_by(&self, factor: i32) -> bool {
    self.value % factor == 0
  }
}

{% endhighlight%}

This all looks pretty familiar. The one new bit of syntax is in our `is_divisible_by` method, which accepts two parameters: `&self` and a `factor`.

Now we can link our Year and Ordinal together by changing Year's definition and methods:

{% highlight rust %}
struct Year {
  ordinal: Ordinal,
}

impl Year {
  fn new(ordinal: i32) -> Year {
    Year {
      ordinal: Ordinal::new(ordinal),
    }
  }

  fn is_leap(&self) -> bool {
    self.ordinal.is_divisible_by_four() && (
      (!self.ordinal.is_divisible_by_100() || self.ordinal.is_divisible_by_400())
  }
}
{% endhighlight%}

We tell the Year struct that its ordinal is now an Ordinal. Then we change the implementation to follow suit. We've fully extracted our Year and Ordinal, and our code now looks like this:

{% highlight rust %}
struct Year {
  ordinal: Ordinal,
}

impl Year {
  fn new(ordinal: i32) -> Year {
    Year {
      ordinal: Ordinal::new(ordinal),
    }
  }

  fn is_leap(&self) -> bool {
    self.ordinal.is_divisible_by_four() &&
      (!self.ordinal.is_divisible_by_100() || self.ordinal.is_divisible_by_400())
  }
}

struct Ordinal {
  value: i32,
}

impl Ordinal {
  fn new(value: i32) -> Ordinal {
    Ordinal {
      value: value,
    }
  }

  fn is_divisible_by_four(&self) -> bool {
    self.is_divisible_by(4)
  }

  fn is_divisible_by_100(&self) -> bool {
    self.is_divisible_by(100)
  }

  fn is_divisible_by_400(&self) -> bool {
    self.is_divisible_by(400)
  }

  fn is_divisible_by(&self, factor: i32) -> bool {
    self.value % factor == 0
  }
}

pub fn is_leap_year(year: i32) -> bool {
  Year::new(year).is_leap()
}
{% endhighlight%}

In terms of Rust idioms and design, this code is probably pretty far from exemplary. But the process of writing it helped me learn a lot about Rust basics. Hopefully it helped you as well!

Now that my presentation for Rocky Mountain Ruby is done I can again focus my writing time on this site and my newsletter. You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/9).
