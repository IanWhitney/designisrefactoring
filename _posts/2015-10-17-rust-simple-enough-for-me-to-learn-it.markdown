---
layout: post
title: "Rust Simple Enough for Me to Learn It"
author: Ian Whitney
date: 2015-10-17T08:49:21-05:00
---

A couple of weeks ago [I dove into Rust and documented my attempts to solve an Exercism problem](http://designisrefactoring.com/2015/10/02/rust-by-trial-and-error/). That was pretty fun! But I also felt like I cheated a bit, since I started off with working code copied from the Exercism repo.

This time we're going to start without any working code, just the tests that Exercism provides. When learning a new language this can be **super daunting**! A new language puts us back at the ['Novice' level of the Dreyfus model](https://en.wikipedia.org/wiki/Dreyfus_model_of_skill_acquisition), where we want to follow recipes and exact instructions. A blank text editor offers no instructions, just an implacable empty maw.

But Rust offers some help, thanks to its type system. And we can help ourselves, by decomposing our large problem into a series of small problems. Let's hop in and see what we can learn!

<!--break-->

The next Exercism problem is [about anagrams](https://github.com/exercism/x-common/blob/master/anagram.md). And, as always, Exercism provides a bunch of tests that we need to get passing. The tests look like this:

{% highlight rust %}
fn test_detect_simple_anagram() {
  let inputs = ["tan", "stand", "at"];
  let outputs: Vec<&str> = vec!["tan"];
  assert_eq!(anagram::anagrams_for("ant", &inputs), outputs);
}
{% endhighlight %}

From that we can figure out that we need to write an `anagrams_for` function. It looks like it accepts a string and an array to our function which returns something that the test compares to:

{% highlight rust %}
  let outputs: Vec<&str> = vec!["tan"];
{% endhighlight %}

Whatever that is.

There's a lot going on here that I don't understand. I want to break this problem down into simpler components. My function needs to do two things:

- Accept a string and a collection of "inputs"
- Return a collection of the "inputs" that are anagrams of my source word

That's still too complex for me to reason about. Let's get simpler.

- I want a method that accepts a string and a collection

That's still not simple enough for me.

- I want a method that accepts a string

That's pretty simple! As a Dreyfus Novice I want to learn the simplest thing possible; any sort of complexity just makes my head swim at this point.

In Ruby I could write a method that accepts just Strings like so:

{% highlight ruby %}
def anagrams_for(source)
  fail unless source.is_a?(String)
  # exciting logic here!
end
{% endhighlight %}

Almost no Rubyist would type check like I'm doing here, but Rust requires functions to declare the types of things they expect. How do we tell a Rust function that it expects a string? In the last post we wrote a lot of functions that accepted `i32`s, but strings are new.

{% highlight rust %}
fn anagrams_for(source: ???) {
}
{% endhighlight %}

Like Ruby, [Rust has a String](https://doc.rust-lang.org/stable/book/strings.html). So this should work:

{% highlight rust %}
fn anagrams_for(source: String) {
}
{% endhighlight %}

That compiles, so I can't be _that_ wrong. I can try out my sweet new function by writing a `main` function and calling my `anagrams_for` function.

{% highlight rust %}
fn anagrams_for(source: String) {
}

fn main() {
  let s = "String!";
  anagrams_for(s);
}
{% endhighlight %}

And that gets us a big fat compiler error:

{% highlight rust %}
error: mismatched types:
expected `collections::string::String`,
found `&str`
{% endhighlight %}

`anagrams_for` says it accepts a String, but the compiler says we passed it a `&str`. What the hell is a `&str`?

The [String documentation](https://doc.rust-lang.org/stable/book/strings.html) starts with:

> Rust has two main types of strings: &str and String. Let’s talk about &str first. These are called ‘string slices’. String literals are of the type &'static str

Uh, ok. Whatever these 'string slices' are, they appear whenever we do this:

{% highlight rust %}
let s = "String!"; //s is of type &'static str
{% endhighlight %}

So `"String!"` is not of type String. It's a `&str` (or a `&'static str`, which I think is the same thing?). Since the types don't match, the code won't compile. Let's look at the String documentation again:

> Strings are commonly created by converting from a string slice using the to_string method.

We can show this off with two methods, one that accept String and the other &str.

{% highlight rust %}
fn anagrams_for_string(source: String) {
}

fn anagrams_for_str(source: &str) {
}

fn main() {
    let s = "String!"; //s: &'static str 
    anagrams_for_str(s); //works, since s is a &str
    anagrams_for_string(s.to_string()); //works, since we just cast s to be a String
}
{% endhighlight %}

And that compiles! This is great, but it leaves me with a choice -- should my function accept `&str` or `String`? The clue is in the test suite provided by Exercism:

{% highlight rust %}
anagram::anagrams_for("tan", &inputs);
{% endhighlight %}

The quotes around `"tan"` tell us that it's a `&str`. Finally, we have the first part of our `anagram::anagrams_for` method signature figured out.

{% highlight rust %}
fn anagrams_for(source: &str) {
}
{% endhighlight %}

But what if we didn't have a test telling us what type to use? Should we use `&str` or `String`?

I certainly don't have any hard and fast rules, since I know basically nothing about Rust. But here's what I think:

- If you're going to change the content of your string, use `String`.<br />
- If you're not, use `&str`.

The code `let s = "String!"` means that `s` is bound to the value "String!" for the entire runtime of the program (that's the `'static` bit of the type signature). It also means that `s` is immutable. `s` can never be anything but `"String!"`.

These guarantees about `s` mean that Rust can make the compiled code run faster and use less memory (I think?). But it also limits what you can do `s`, obviously.

But the `s` of `let s = "String!".to_string();` can be changed. More flexible, but the memory-management story becomes more complex. And since Rust does everything it can to keep you from making memory mistakes, this added complexity makes for slower code. Not much slower, admittedly. But the tradeoff is there.

After all that I (and hopefully you) have learned some useful things about Rust and strings. But our anagram function is not yet done, we still have to pass it a collection of words. And I haven't talked at all about the `&` symbol that keeps cropping up. All that and more next time when I continue the _thrilling adventure of_&hellip;writing a function in Rust!

Along with my writing here I share links and other Internet ephemera in my newsletter. You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/10).
