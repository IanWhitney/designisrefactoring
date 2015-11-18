---
layout: post
title: "Simple Rust, Part Two"
date: 2015-11-13T22:26:14-06:00
subtitle: "Arrays, Memory and the &"
author: Ian Whitney
---

[Last time](http://designisrefactoring.com/2015/10/17/rust-simple-enough-for-me-to-learn-it/) we wrote half of our `anagrams_for` function signature. We looked at the different ways we can declare a string, and how to decide which type our function would accept. Exciting!

We have one more parameter to handle, though. The tests we have from Exercism have us calling `anagrams_for` like this:

{% highlight rust %}
  let inputs = ["tan", "stand", "at"];
  anagram::anagrams_for("ant", &inputs)
{% endhighlight%}

And our current `anagrams_for` accepts just the "ant" part of that.

{% highlight rust %}
fn anagrams_for(s: &str) {
  //Amazing logic TBD
}
{% endhighlight%}

We have two problems to solve:

- What is `inputs` type?
- What is that `&` that keeps showing up?

Turns out these two things have much in common, and they reveal an important part of Rust's memory management story. More excitement awaits!

<!--break-->

### What is `inputs` type?

A Rubyist like myself looks at the line

{% highlight rust %}
let inputs = ["tan", "stand", "at"];
{% endhighlight%}

And says, "Well, obviously `inputs` is an Array." Of course, in the last article I also said that `"ant"` was obviously a String, which it wasn't. My track record isn't great.

Remember that we chose `&str` over `String` because the latter was mutable and we didn't need the overhead that comes with mutability.

In Rust, the [Array](https://doc.rust-lang.org/stable/book/primitive-types.html#arrays) primitive is immutable. And our `anagrams_for` function won't have to mutate `inputs`.  Since there's no reason to mutate `inputs` let's make it immutable and call it an Array.

You may be wondering why the clearly-named `String` primitive is mutable, while the similarly-clearly-named `Array` primitive is immutable. I have no idea. I'm sure there's a great reason for it.

Yes, there are mutable collections, but I'll get into them later. They aren't relevant right now.

Anyway, now that we know our `inputs` parameter will be an Array, we can finish our function's type signature, right?

{% highlight rust %}
fn anagrams_for(s: &str, inputs: Array) {
  //Amazing logic TBD
}

fn main() {
  let inputs = ["tan", "stand", "at"];
  anagrams_for("ant", inputs);
}
{% endhighlight%}

This nets us a nice compiler error: `error: use of undeclared type name Array`

The [Array documentation](https://doc.rust-lang.org/stable/book/primitive-types.html#arrays) shows us the error of our ways. There is no one Array type. Instead, when we create an Array its type is its elements' type and their number. This is easier to see with some examples:

{% highlight rust %}
let number_array = [1, 2];
//number_array contains 2 i32s, so has the type [i32; 2];

let str_array = ["String"];
// str_array contains 1 &str, so has the type [&str; 1]
{% endhighlight%}

Knowing that, we could adjust our `anagrams_for` signature to

{% highlight rust %}
fn anagrams_for(s: &str, inputs: [&str; 3])
{% endhighlight%}

And our code compiles! Success. Well, a limited form of success as our function now only accepts Arrays with 3 string elements. If we try:

{% highlight rust %}
anagrams_for("tan", ["a", "b", "c", "d"]);
{% endhighlight%}

We get a compiler error: `(expected an array with a fixed size of 3 elements, found one with 4 elements)`

Our `anagrams_for` function must work with Arrays of any size, so we have to take a different approach. My first instinct is to try leaving out the size.

{% highlight rust %}
fn anagrams_for(s: &str, inputs: [&str]) {
  //Amazing logic TBD
}

fn main() {
  let inputs = ["tan", "stand", "at"];
  anagrams_for("ant", inputs);
}
{% endhighlight%}

First we get a warning: `[&str] does not have a constant size known at compile-time all local variables must have a statically known size`

Then we get an error: `mismatched types: expected [&str], found [&str; 3]`

There is a solution. But before we discover it, we must first dig into that `&` symbol that keeps popping up.

### What is that `&` that keeps showing up?

We've seen `&` show up a lot. It's part of `&str` and it's in the test provided by Exercism:

{% highlight rust %}
anagram::anagrams_for("ant", &inputs)
{% endhighlight%}

But our most recent code leaves it out:

{% highlight rust %}
anagrams_for("ant", inputs);
{% endhighlight%}

The difference between these two pieces of code (as I understand it) is that `&inputs` is [Borrowed](https://doc.rust-lang.org/stable/book/references-and-borrowing.html) by `anagrams_for` while `inputs` is [Owned](https://doc.rust-lang.org/stable/book/ownership.html) by `anagrams_for`

I'm still struggling through learning these concepts, so I'm bound to get some of this wrong. But my understanding is as follows:

When our function owns the array, the array's data is copied to a second location in memory.

When our function borrows the array, the array is not copied. Instead, the function gets a reference to the location where the array's data is stored.

One of Rust's main goals is memory safety. Think about how Rust is going to approach these two situations when it comes to memory. When Rust is going to copy data, it has to set aside memory at compilation. That means Rust has to know exactly how much memory to set aside. In this code:

{% highlight rust %}
fn anagrams_for(s: &str, inputs: [&str; 3])
{% endhighlight%}

Rust can say "Oh, I need to set aside enough space for an array that contains 3 `str`". But this code:

{% highlight rust %}
fn anagrams_for(s: &str, inputs: [&str])
{% endhighlight%}

Doesn't tell Rust how much memory to set aside for copying. Hence that warning about, "all local variables must have a statically known size" and our program's subsequent failure.

So, if we want to have our function accept arrays of arbitrary size, it must borrow them. Again, if we knew what we were looking for, the code from Exercism would have shown us the way.

{% highlight rust %}
let inputs = ["tan", "stand", "at"];
anagram::anagrams_for("ant", &inputs)
{% endhighlight%}

That `&inputs` says that we are borrowing `inputs` to the function. Therefore our function must also borrow:

{% highlight rust %}
fn anagrams_for(s: &str, inputs: &[&str]) {
  //Amazing logic TBD
}

fn main() {
  let inputs = ["tan", "stand", "at"];
  anagrams_for("ant", &inputs);
}
{% endhighlight%}

This compiles! Neat. We've finished our entire method signature while learning something about `&` and borrowing in the process.

But I'm still a little confused. Why does `&str` always contain a `&`? Rust's [documentation comes to my rescue again](https://doc.rust-lang.org/stable/std/primitive.str.html)

> Rust's str type is one of the core primitive types of the language. &str is the borrowed string type.

When I write code like:

{% highlight rust %}
let s = "String";
{% endhighlight%}

`s` has the type `&str`, meaning it's just borrowing data that is owned by a `str` somewhere deeper in the system, probably beyond my reach. I can't take ownership of something I'm just borrowing, nor can I give ownership to someone else. So code like this:

{% highlight rust %}
fn take_ownership(s: str) {
  //do stuff
}

fn main() {
  let borrowed_str = "you don't own me!";
  take_ownership(borrowed_str);
}
{% endhighlight%}

Blows up with the same mismatched type error we got before. `borrowed_str` is a `&str`, and `take_ownership` only wants a `str`. We have to play nice and borrow what we can't own.

{% highlight rust %}
fn borrow(s: &str) {
  //do stuff
}

fn main() {
  let borrowed_str = "you don't own me!";
  borrow(&borrowed_str);
}
{% endhighlight%}

Ok. That is quite enough Rust for this post. We still need to write the actual logic in `anagrams_for`, but that will have to wait for another day. I am heading to [RubyConf](http://rubyconf.org) this weekend, and I expect to talk quite a lot about that (and maybe some Rust) in my newsletter. Newsletter? Yes. You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/11).
