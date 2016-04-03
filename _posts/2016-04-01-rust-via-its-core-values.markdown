---
layout: post
title: "Rust via its Core Values"
date: 2016-04-01T11:21:05-05:00
author: "Ian Whitney"
---

I have a couple of ideas about learning programming languages.

The first is that we do it wrong. I'm sure you've experienced this. You try learning a new language and can't quite see how it all works. Why do I use this syntax here and some other syntax over here? We get frustrated by all the weird bits and go back to a language we know.

I think we do a bad job of learning languages because of how we think about languages. Think back to the last time you discussed a new language. Someone mentioned a new language and then someone else asked about the language's speed, syntax or web framework of choice.

This is similar to how we talk about cars. Hear about that new Ford Bratwurst? How fast is it? Can I drive it through a lake?

When we talk about languages this way, we make them sound interchangeable. Like cars. I know how to drive a Toyota Hamhock, so I should be able to drive a Ford Bratwurst, no problem. Only the speed and the dashboard vary, right?

But imagine what a PHP car would look like, now imagine how different the Lisp car would be. Moving from one to the other involves a lot more than learning which knob controls the heater.

<!--break-->

Cars are interchangeable because they all solve the same problem; and we've settled on what is the best way to solve that problem. But programming languages all solve different problems, and they each express their own philosophy about how to solve that problem.

A language's syntax & speed are expressions of its core values. For example, Ruby famously values Developer Happiness and that value has impacted Ruby's features. Java has placed a huge value in backwards compatibility and that has impacted Java's features.

So, my second idea about learning a programming language is this. We can learn a language better by learning it through its core values. If we can anchor our understanding in *why* a language works the way it does, it will be easier to learn the *how*

With that, let's look at Rust's core values:

Rust defines its three goals as

- Speed
- Memory Safety
- Concurrency

Let's set aside concurrency for now and focus on Rust's top two goals. Speed and Memory Safety.

A digression. When Rust says it values "memory safety", it is saying that it will not crash with a segmentation fault. This will be familiar to you if you've worked with C or C++, but if (like me) you've avoided those languages then this may be a new idea. Imagine the following situations

- You try to use the 5th element of a 2-element array
- You try to call a method on Nil
- Two functions mutate a variable at the same time, leaving it an uncertain state

In Ruby you might get an exception, but in a language like C you'll get something worse. Maybe your program crashes. Maybe it executes some random code and your little C program opens a giant security bug that a virus exploits. Oops.

When Rust says 'memory safety' it's saying you can't cause this type of bug.

Ruby also protects you from segmentation fault errors. But to do so it uses a garbage collector. This is great, but it has a big impact on your program's speed.

Ah, but Rust has a core value of speed. To enforce that core value, Rust does not have a garbage collector. Management of memory is the programmer's responsibility. Wait, what about all those terrible bugs I just mentioned?! Because Rust values Speed, it makes me manage memory. But if Rust's second Core Value is memory safety, then why would it let me manage memory?!

There's a clear tension between these core values. With that in mind, let's learn some Rust!

{% rp_highlight rust %}
fn main() {
  let x = 1;
  println!("{}", x);
}
{% endrp_highlight %}

This is about as simple a program as you can get in Rust.

If you want to guarantee memory safety, one way of doing that is to prevent data from changing.

Thus, everything in Rust is immutable by default.

{% rp_highlight rust %}
fn main() {
  let x = 1;
  x = x + 1;
  println!("{}", x);
}
//<anon>:3:3: 3:12 error: re-assignment of immutable variable `x` [E0384]
{% endrp_highlight %}

Of course, Rust developers also wants people to write programs in Rust. So we can declare things to be mutable if we really need to.

{% rp_highlight rust %}
fn main() {
  let mut x = 1;
  x = x + 1;
  println!("{}", x);
}
//2
{% endrp_highlight %}

The `mut` keyword lets us explicitly say "this value is mutable." Explicitness is the fourth core value of Rust. Ironically, I don't see that "Explicitness" is ever explicitly stated as a goal of Rust. But, given the choice between implicitness and explicitness, Rust usually chooses explicitness.

But if I can mutate data, doesn't that introduce problems? One of Rust's core values is memory safety. Mutation and memory safety would seem to be mutually exclusive goals.

{% highlight rust %}
fn main() {
  let mut x = 1;
  //I pass x off to something that deletes the data from memory
  println!("{}", x); //and my program blows up
}
{% endhighlight %}

Rust adheres to its core values and introduces an idea. Ownership. In Rust, each value can only have one owner. And the bit of memory that owner is holding on to is freed after that owner goes out of scope.

Let's see that in action:

{% rp_highlight rust %}
fn main() {
  let original_owner = String::from("Hello");
  let new_owner = original_owner;
  println!("{}", original_owner);
}
//<anon>:4:18: 4:32 error: use of moved value: `original_owner` [E0382]
{% endrp_highlight %}

The verbose "String::from" syntax gives us a string we can actually own. We then give that ownership to the new owner. And at this point original_owner now owns...nothing. Our string can only have one owner.

Through ownership, Rust can start to uphold its value of memory safety. If a value can only have one owner, then we can't ever have a situation where two owners try to change the data simultaneously. And we can't ever try to refer to a value that some other owner destroyed.

Earlier I said that values were destroyed when they fell out of scope. So far we've only had one scope, our main function. Most programs have more than one scope. In Rust scopes are delineated by curly braces.

{% rp_highlight rust %}
fn main() {
  let first_scope = String::from("Hello");

  {
    let second_scope = String::from("Goodbye");
  }

  println!("{}", second_scope);
}
//<anon>:8:18: 8:30 error: unresolved name `second_scope` [E0425]
{% endrp_highlight %}

When our inner scope ends, second_scope is destroyed. We can no longer access it.

This is another core part of Rust's memory safety. If we don't allow access to data that is out of scope, then we are certain that we're not going to try to refer to something that we've destroyed. The compiler won't let us.

Thanks to memory safety, we now understand some interesting things about Rust

- Values can only have one owner
- Values are destroyed when they leave scope

Let's try to do something useful in Rust. Or as useful as can fit in this post. I want a function that tells me if two strings are the same length.

First, functions. We declare them just like our main function:

{% rp_highlight rust %}
fn same_length() {
}

fn main() {
  same_length();
}
{% endrp_highlight %}

Our same_length function will need to accept two parameters, a source string and a other string to compare against.

{% rp_highlight rust %}
fn same_length(s1, s2) {
}

fn main() {
  let source = String::from("Hello");
  let other = String::from("Hi");

  println!("{}", same_length(source, other));
}
//<anon>:1:18: 1:19 error: expected one of `:` or `@`, found `,`
{% endrp_highlight %}

Rust loves explicitness. So we can't declare a function without stating what kind of data we're going to pass into it. Rust uses strong, static typing in its function signatures. This way the compiler can ensure we're using our functions correctly, preventing exploding programs. Explicit typing also lets us easily see what a function accepts. Our function only accepts Strings, so we declare that.

{% rp_highlight rust %}
fn same_length(s1: String, s2: String) {
}

fn main() {
  let source = String::from("Hello");
  let other = String::from("Hi");

  println!("{}", same_length(source, other));
}
//<anon>:8:18: 8:44 error: the trait `core::fmt::Display` is not implemented for the type `()` [E0277]
{% endrp_highlight %}

Most of Rust's compiler messages are helpful. This one, maybe not so much. What it's telling us is that our function is returning nothing, `()` and that can't print nothing. So our function should return...something. A boolean seems appropriate. Let's just return false for now.

{% rp_highlight rust %}
fn same_length(s1: String, s2: String) {
  false
}

fn main() {
  let source = String::from("Hello");
  let other = String::from("Hi");

  println!("{}", same_length(source, other));
}
//<anon>:2:3: 2:8 error: mismatched types:
//expected `()`,
//found `bool`
{% endrp_highlight %}

Explicitness again. Not only do functions have to declare what they accept, they have to declare the type of the object that they return. We return a `bool`

{% rp_highlight rust %}
#[allow(unused_variables)]
fn same_length(s1: String, s2: String) -> bool {
  false
}

fn main() {
  let source = String::from("Hello");
  let other = String::from("Hi");

  println!("{}", same_length(source, other));
}
//false
{% endrp_highlight %}

Cool. That compiles. Let's do an actual comparison. Strings have a `len()` function that returns their length:

{% rp_highlight rust %}
fn same_length(s1: String, s2: String) -> bool {
  s1.len() == s2.len()
}

fn main() {
  let source = String::from("Hello");
  let other = String::from("Hi");

  println!("{}", same_length(source, other));
}
//false
{% endrp_highlight %}

Great. Let's do two comparisons!

{% rp_highlight rust %}
fn same_length(s1: String, s2: String) -> bool {
  s1.len() == s2.len()
}

fn main() {
  let source = String::from("Hello");
  let other = String::from("Hi");
  let other2 = String::from("Hola!");

  println!("{}", same_length(source, other));
  println!("{}", same_length(source, other2));
}
//<anon>:11:30: 11:36 error: use of moved value: `source` [E0382]
{% endrp_highlight %}

Remember the rules? Only one owner allowed. And when you reach the end of a curly brace the values are destroyed. When we call `same_length` we give it ownership of our values, and when it's done those values are destroyed. Comments make this a little easier to see.

{% rp_highlight rust %}
fn same_length(s1: String, s2: String) -> bool {
  s1.len() == s2.len()
}

fn main() {
  let source = String::from("Hello"); //source owns "Hello"
  let other = String::from("Hi"); //other owns "Hi"
  let other2 = String::from("Hola!"); //other2 owns "Hola!

  println!("{}", same_length(source, other)); 
  //We just gave `same_length` ownership of source and other, 
  //and they were destroyed when that function ended

  println!("{}", same_length(source, other2)); 
  //source no longer owns anything
}
//<anon>:11:30: 11:36 error: use of moved value: `source` [E0382]
{% endrp_highlight %}

This seems pretty limiting. It's nice that Rust values memory safety so highly, but does it have to value it so highly?

Rust ignores our griping and sticks to its core values by introducing Borrowing. A value can only have one owner, but any number of borrowers. Borrowing in Rust uses the `&` symbol.

{% rp_highlight rust %}
#[allow(unused_variables)]
fn main() {
  let original_owner = String::from("Hello");
  let new_borrower = &original_owner;
  println!("{}", original_owner);
}
//Hello
{% endrp_highlight %}

Earlier in this talk we tried to do the same thing but with transferring ownership. That failed. But with borrowing it succeeds. We can use the same approach with our function:

{% rp_highlight rust %}
fn same_length(s1: &String, s2: &String) -> bool {
  s1.len() == s2.len()
}

fn main() {
  let source = String::from("Hello"); //source owns "Hello"
  let other = String::from("Hi"); //other owns "Hi"
  let other2 = String::from("Hola!"); //other2 owns "Hola!"

  println!("{}", same_length(&source, &other)); 
  //We just borrowed source and other to same_length, so nothing is destroyed

  println!("{}", same_length(&source, &other2));
  //We can borrow source again!
}
//false
//true
{% endrp_highlight %}

We explicitly borrow our data to the function, which explicitly says it only accepts borrowed things. When `same_length` finishes it stops borrowing the value, but the value is not destroyed.

But wait, doesn't this break the memory safety Core Value that ownership solved? Won't code like this lead to disaster?

{% rp_highlight rust %}
fn main() {
  let mut x = String::from("Hi!");
  let y = &x;
  y.truncate(0);
  // Oh noes! Truncate deletes our string!
}
{% endrp_highlight %}

Well, no. Rust's Core Value of memory safety leads to the following rules:

- There can only be one owner
- You can borrow a value as many times as you want, but those borrows are immutable

Run the above code yourself and you'll see the result. 

```
<anon>:4:3: 4:4 error: cannot borrow immutable borrowed content `*y` as mutable
```

With those two rules Rust solidifies its core value of memory safety and it does so without sacrificing speed. All of these rules are checked at compile time, leaving run time speed unaffected.

This is a very high-level introduction to borrowing and memory. Rust offers a lot of interesting tools, but they can be complex to describe. What I've found is that as long as I keep Rust's core values in mind, I can usually figure out why it works the way it works.

If the theories I started off this talk with are right, this introduction to borrowing wasn't totally baffling. And you hopefully understand it more thoroughly than if I'd just said "Rust lets you borrow stuff, just remember to always use the & and you'll be fine." Hopefully.

Learning a new language is hard. It's got that goofy syntax, that weird way of handling line terminators, and so on. But it's powerful, too. Learning how that language thinks increases the breadth of your thought. Learning how that language sees the world widens your view of the world. But this only works if we see languages not as interchangeable piles of syntax, but as expressions of principles. Learning a language through its core values not only makes it easier to learn that language, but it increases your empathy with that language.

Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/19).
