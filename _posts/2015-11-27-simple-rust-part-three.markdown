---
layout: post
title: "Simple Rust, Part Three"
date: 2015-11-27T13:37:28-06:00
subtitle: "Vectors, Mutations, Macros and Lifetimes"
author: Ian Whitney
---

[Previously](http://designisrefactoring.com/2015/11/13/simple-rust-part-two/), we looked at how our function will use Arrays and whether or not it will own or borrow its inputs. Our code currently looks like this:

{% highlight rust %}
fn anagrams_for(s: &str, inputs: &[&str]) {
  //Amazing logic TBD
}
{% endhighlight %}

We're still trying to get tests like these to pass:

{% highlight rust %}
fn test_detect_simple_anagram() {
  let inputs = ["tan", "stand", "at"];
  let outputs: Vec<&str> = vec!["tan"];
  assert_eq!(anagram::anagrams_for("ant", &inputs), outputs);
}
{% endhighlight %}

The test asserts that `outputs` is equal to what our `anagrams_for` function returns. But our function currently returns nothing. And while the `ouptputs` syntax has a few familiar aspects, there's a lot of new code as well: `Vec`, `vec!` and those angle brackets in `<&str>`. What's going on here?

<!--break-->

### Vectors, the mutable array

Let's start with `Vec`. In the [last post](http://designisrefactoring.com/2015/11/13/simple-rust-part-two/) we looked at Array, which suited our needs because it is immutable. I mentioned that there were also mutable arrays, and here they are -- Vectors, or Vec for short.

Remember that when we write an array like this:

{% highlight rust %}
let an_array = ["tan", "stand", "at"];
{% endhighlight %}

it doesn't have the type of `Array`. Instead its type is `[&str,3]`, the combination of the type and number of its elements.

The number of elements a Vector contains can vary. But, just like Arrays, they can only contain elements of the same type. So, if we want to create a new Vector we have to declare what type of elements we're going to put in there. That's what the angle brackets are for. If you leave them off, you can run into problems:

{% highlight rust %}
fn main() {
  let str_vector = Vec::new();
}
{% endhighlight %}

will not compile. Instead you get the error

```
Unable to infer enough type information about `_`; type annotations or generic parameter binding required
```

`: Vec<&str>` is a type annotation. We use annotations when the Rust compiler can't guess what our type will be.

With our type annotation in place, we can then assign a new Vector to our variable with the function `Vec::new()`

{% highlight rust %}
let str_vector: Vec<&str> = Vec::new();
{% endhighlight %}

`str_vector` is empty, though. We can use the push function to push data on to the end of our vector.

{% highlight rust %}
let str_vector: Vec<&str> = Vec::new();
str_vector.push("4");
//=> cannot borrow immutable local variable `str_vec` as mutable
{% endhighlight %}

Well, the compiler didn't care for that at all. Yes, vectors are mutable, but we also have to declare that our variable is mutable. For this we use the `mut` keyword:

{% highlight rust %}
let mut str_vector: Vec<&str> = Vec::new();
str_vector.push("4");
{% endhighlight %}

This works. The first line, if you translate it to English, would read "Create a mutable variable named str_vector, with the type of Vec<&str> and set it to a new, empty vector.

You may have noticed that this is super tedious! With an Array we get straight to the point:

{% highlight rust %}
let arrays_are_easy = ["1", "2", "3"];
{% endhighlight %}

One line of code and our array is ready. Compare that to creating a similar vector:

{% highlight rust %}
let mut vectors_are_hard: Vec<&str> = Vec::new();
vectors_are_hard.push("1");
vectors_are_hard.push("2");
vectors_are_hard.push("3");
{% endhighlight %}

The Rust team doesn't like tedious code any more than you do, which is why they offer a way to remove repetitive syntax -- Macros. All Macros end with `!`, such as `vec!`. `println!`, which appears in a lot of my code examples, is another one.

If you are familiar with Ruby, then you've probably heard code like this referred to as a Macro.

{% highlight ruby %}
class Person < ActiveRecord::Base
  has_many :names
  # Is this a Macro?
end
{% endhighlight %}

But it's not, really. It's just a call to a class method. An macro is a piece of code that either generates more code or that gets converted into different code. Neither of those things happen in that Ruby code.

Over the years people have tried [different](http://rubymacros.com) [ways](http://ola-bini.blogspot.com/2006/09/three-ways-to-add-ruby-macros.html) of adding true macros to Ruby, but the approaches are...baroque. Ruby doesn't support actual macros, and Matz doesn't seem excited about the idea. At the [2015 RubyConf](https://www.youtube.com/watch?v=LE0g2TUsJ4U) he was jokingly asked about the implementing macros and he guaranteed they were not showing up anytime soon. Or ever.

`vec!` is a nice introduction to Rust macros, as it shows off how they can simplify tedious boilerplate. These two code blocks are identical:

{% highlight rust %}
let mut tedious_vector: Vec<&str> = Vec::new();
tedious_vector.push("tan");
tedious_vector.push("stand");
tedious_vector.push("at");
{% endhighlight %}

{% highlight rust %}
let mut macro_vector = vec!["tan", "stand", "at"];
{% endhighlight %}

It is not surprising that the [Rust Book](https://doc.rust-lang.org/stable/book/vectors.html) doesn't even mention the tedious syntax when introducing Vectors. Everyone uses the macro syntax.

The test has one more thing to teach us:

{% highlight rust %}
assert_eq!(anagram::anagrams_for("ant", &inputs), outputs);
{% endhighlight %}

Compares `outputs` which we know to be a `Vec<&str>` to the data returned by our `anagrams_for` function. This means we know that our function must also return a `Vec<&str>`. See, strong, statically-typed languages can be useful!

I think we've learned about all we can about the types our function needs to accept and return. We should have enough to pass the first of Exercism's tests:

{% highlight rust %}
fn test_no_matches() {
  let inputs = ["hello", "world", "zombies", "pants"];
  let outputs: Vec<&str> = vec![];
  assert_eq!(anagram::anagrams_for("diaper", &inputs), outputs);
}
{% endhighlight %}

Well, that's got to be easy. Our function only has to return an empty vector!

{% highlight rust %}
fn anagrams_for(source: &str, inputs: &[&str]) -> Vec<&str> {
    return vec![];
}
{% endhighlight %}

We run our tests, expecting success.

```
error: missing lifetime specifier [E0106]
```

What. The. Hell.

### Rust Lifetimes

I have no idea why that code doesn't work. But Rust's compiler offers some help.

```
run `rustc --explain E0106` to see a detailed explanation
this function's return type contains a borrowed value, but the signature does not say whether it is borrowed from `source` or one of `inputs`'s 2 elided lifetimes
```

I'm not entirely sure what that means. But that's why we're on this voyage of discovery, right? To learn!

Running `rustc --explain E0106` is not especially helpful. It talks a lot about "lifetimes" but doesn't explain what they are. It does, however, point us to the [Lifetime section](https://doc.rust-lang.org/stable/book/lifetimes.html) of the Rust book.

Lifetimes, the book says, are the third part of Rust's "ownership system". They follows Ownership and Borrowing, which we discussed last post. So, we should be well prepared to understand Lifetimes.

Maybe.

Perhaps you're ready to understand them, but I was not. If you google "Rust lifetimes" you'll find a lot of blog articles trying to explain what they are and what they do. And if you're familiar with other non-garbage-collected languages, then those articles might be clear to you. But as a Rubyist, I found lifetimes to be baffling. After enough reading and eye-crossing, they started to make a tiny amount of sense to me, but it took me a lot of time and effort.

So, let me take you on a journey into my understanding of Rust lifetimes. I'm going to do this slowly, since slowly is the only way I was able to learn any of this.

Let's start with something very, very basic. A function that returns a string:

{% highlight rust %}
fn return_string() -> &str {
  return "Hi!";
}

fn main() {
  let x = return_string();
}
{% endhighlight %}

This code looks simple enough, but it fails to compile, giving us the exact same error we saw before: E0106

The error goes on:

> this function's return type contains a borrowed value, but there is no value for it to be borrowed from

Interesting! What this tells me is that if a function returns a borrowed value (`&str`), then it must accept a borrowed value in its parameters. Why? I think it all comes down to what everything comes down to in Rust -- memory. Take a look at this code:

{% highlight rust %}
fn main() {
  let x;

  {
    let y = "A string"
    x = &y;
  }

  println!("{}",x);
}
{% endhighlight %}

Again, seems simple enough but it won't compile. You get the error "y does not live long enough."

In all my Rust ramblings I haven't talked much about scope, probably because I don't fully understand it. But, at a high level, anything within curly-braces is a scope. And when a scope ends, Rust cleans up memory used by that scope. And if that cleanup is going to make your program break, then Rust won't compile. Some comments will hopefully make this more clear.

{% highlight rust %}
fn main() {
  let x; //x comes into scope

  { // a new scope begins
    let y = "A string" //y comes into scope
    x = &y; //x borrows y's referenc
  } //uh oh, y is destroyed here but x is still borrowing its reference

  println!("{}",x);
}
{% endhighlight %}

When I said that curly braces start a new scope, I meant all curly braces. From what I can tell, there's no difference between the curly braces in these two examples and, say, the curly braces that surround a function.

{% highlight rust %}
fn return_borrowed_value() -> &str { //a new scope begins
  let y = "A string"; //y comes into scope
  return y; //x borrows y's reference
} //uh oh, y is destroyed here but x is still borrowing its reference

fn main() {
  let x; //x comes into scope
  x = return_borrowed_value(); //x is trying to borrow something that's been destroyed
  println!("{}", x);
}
//=> E0106
{% endhighlight %}

Hence, if a function returns something borrowed, it must accept a borrowed parameter. This way Rust knows that the reference will exist outside of the function's scope. (I don't think this is strictly true, but it's true enough)

{% highlight rust %}
fn return_borrowed_value(s: &str) -> &str { //a new scope begins
  return s;
} //s is destroyed, but it was a reference to something that exists outside this function anyway. no big deal.

fn main() {
  let x = "Hi!"; //x comes into scope
  x = return_borrowed_value(x); //x borrows its reference to the function, then receieves that borrow back.
  println!("{}", x);
}
//=> "Hi!"
{% endhighlight %}

But our function accepts borrowed parameters, so why won't it compile? The answer is still memory. In a one-arity function like in the previous example, Rust doesn't have to guess which borrowed parameter to return -- there's one option. But if a function borrows two parameters, Rust does have to guess. And if we force Rust to guess, it refuses to compile. Rust is not a fan of guessing. We need to explicitly tell Rust which reference our function will return.

Enter Rust Lifetimes!

A lifetime is a way for us to declare how long a borrowed reference can last. As the [Rust Book](https://doc.rust-lang.org/stable/book/lifetimes.html#lifetimes) says, lifetimes help Rust prevent deadly situations like this:

> - I acquire a handle to some kind of resource.
> - I lend you a reference to the resource.
> - I decide I'm done with the resource, and deallocate it, while you still have your reference.
> - You decide to use the resource.

Every time we borrow a reference, Rust assigns it a lifetime. We haven't seen them until now because their lifetimes were unambiguous, so Rust never bothered to tell us about them. But the lifetimes of references in our two-arity function is ambiguous, so we have to tell Rust what to do.

Lifetime names look like `<'a>`. The exact name doesn't matter much. The examples I've seen are single characters, but I can see a value in using longer names. If you feel like typing more, you can give your lifetimes names like `<'my_so_called_life>`.

When we declare a function, we can name its lifetime:

{% highlight rust %}
fn facts_of_life<'a>
{% endhighlight %}

This says that our function has one lifetime and it's called 'a'. Also, you may think "Hey, we used angle brackets in Vectors too. There's a reason for that! But I won't get to it today.

We then declare what lifetime applies to our parameters

{% highlight rust %}
fn facts_of_life<'a> (s: &'a str)
{% endhighlight %}

`&'a str` is the same as `&str`, only we've given our reference an explicit lifetime. "I am borrowing this str for the lifetime a".

Then we declare the lifetime of our return value, saying that it must live at least as long as our input:

{% highlight rust %}
fn facts_of_life<'a> (s: &'a str) -> &'a str
{% endhighlight %}

With two parameters, we can declare 2 lifetimes.

{% highlight rust %}
fn facts_of_life<'a, 'b> (s: &'a str, s2: &'b str) -> &'a str
{% endhighlight %}

Or we can stick with just one:

{% highlight rust %}
fn facts_of_life<'a> (s: &'a str, s2: &'a str) -> &'a str
{% endhighlight %}

We don't even have to give both inputs a lifetime

{% highlight rust %}
fn facts_of_life<'a> (s: &'a str, s2: &str) -> &'a str
{% endhighlight %}

Though when we do that we have to return `s`. Trying to return `s2` results in an error, because it's not part of the `'a` lifetime.

I find this last approach the most helpful, actually. If one of our two inputs has a lifetime, then we know which input our function will return without even looking at the body of our function.

Lifetimes apply to references, not ownership:

{% highlight rust %}
// No lifetimes necessary for a function that owns its inputs
fn facts_of_life(s: String, s2: [String]) -> &str

// Or for a function that returns something that isn't borrowed
fn facts_of_life(source: &str, inputs: &[&str]) -> String
{% endhighlight %}

Let's apply our new knowledge to `anagrams_for`. Before our detour into lifetimes, our non-compiling code looked like this:

{% highlight rust %}
fn anagrams_for(source: &str, inputs: &[&str]) -> Vec<&str> {
    vec![];
}
{% endhighlight %}

We know we're not going to return `source`. We're going to take anagrams out of `inputs` and put them in the `Vec` that we return. So our lifetime could look like 

{% highlight rust %}
fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
    vec![];
}
{% endhighlight %}

To translate that into English, our function has a lifetime 'a'. The references inside of `inputs` and our return have the same lifetime, so need to live for at least as long as this function's scope. And we're saying that the values returned in our Vec will reference the values in `inputs`. Let's run that test again.

```
test result: ok. 1 passed; 0 failed; 10 ignored; 0 measured
```

Success!

Sure, there are still 10 tests to go. But we are on our way. And we've tackled one of Rust's most confusing features -- Lifetimes. Steve Klabnik, writer of the Rust documentation, wrote a great post about the "[Language strangeness budget](http://words.steveklabnik.com/the-language-strangeness-budget)".

> If you include no new features, then there's no incentive to use your language. If you include too many, not enough people may be willing to invest the time to give it a try

I don't know if lifetimes are unique to Rust, but I think they consume a significant part of its strangeness budget. And if we can understand them, I don't think we have anything to fear. Hopefully&hellip;

If you want to read more about Lifetimes, here are the resources I found most helpful:

- [Lifetimes](https://doc.rust-lang.org/stable/book/lifetimes.html) in the Rust Book
- [Lifetimes](http://rustbyexample.com/scope/lifetime.html) in Rust By Example
- [What needs to be explained about lifetimes](https://users.rust-lang.org/t/what-needs-to-be-explained-about-lifetime-parameters/291/7) in the Rust forum
  - That thread links to a bunch of other useful discussions
- [There is a time in your life...](https://users.rust-lang.org/t/there-is-a-time-in-your-life-when-you-have-to-understand-lifetimes/1941) also on the Rust forum
- [Rust ownership the hard way](http://chrismorgan.info/blog/rust-ownership-the-hard-way.html)
- [Understanding lifetime in Rust](https://mobiarch.wordpress.com/2015/06/29/understanding-lifetime-in-rust-part-i/)

-----

Next time we'll finish implementing `anagrams_for`, I promise. If all this talk about memory management has you longing for the simple ways of a garbage-collected language, may I suggest subscribing to my newsletter? The last issue contained many links to RubyConf talks, and I plan to link to my favorite RubyConf talks in the next issue. One of them even dives into how the garbage collector works! You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/13).
