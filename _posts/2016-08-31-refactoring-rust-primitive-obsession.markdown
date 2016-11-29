---
layout: post
title: "Refactoring Rust: Primitive Obsession"
date: 2016-08-31T15:55:51-05:00
subtitle: "Fast smelly code is still smelly"
author: "Ian Whitney"
---

Thanks to their small, focused nature problems in [Exercism](http://exercism.io) tend to focus on language primitives. Transform this string into a different string, manipulate this number, etc. In the `bob` exercise students [return a string based upon a string input](https://github.com/exercism/xrust/blob/717a20fd2ee34ad5c49904dca2726da07f133733/exercises/bob/example.rs). And in `leap` students [return a boolean based on an integer input](https://github.com/exercism/xrust/blob/717a20fd2ee34ad5c49904dca2726da07f133733/exercises/leap/tests/leap.rs).

Students tend to rely on primitives when solving these problems. The example solutions [for `bob`](https://github.com/exercism/xrust/blob/717a20fd2ee34ad5c49904dca2726da07f133733/exercises/bob/example.rs) and [for `leap`](https://github.com/exercism/xrust/blob/717a20fd2ee34ad5c49904dca2726da07f133733/exercises/leap/example.rs) are indicative. They accept primitive input, use primitives to solve the problem and return primitive results.

This is, in short, [primitive obsession](http://c2.com/cgi/wiki?PrimitiveObsession). And for people just starting to learn Rust (or any language) primitive obsession is fine. Beginners on the [Dreyfus model](https://en.wikipedia.org/wiki/Dreyfus_model_of_skill_acquisition) aren't yet modeling domains or complex concepts; they are still learning the techniques these problems exercise: syntax, primitives, control flow, etc.

But as students progress through the exercises their skills will evolve and they'll be able ponder maintainability and design. The question will arise -- how do I write _good_ Rust code?

<!--break-->

I certainly don't have the answers to that question, and in the Rust track we're barely starting to think about how to help students answer that question. Should exercises actively discourage certain code smells, like Primitive Obsession? What would that discouragement even look like? But the discussion has led me to start thinking about what code smells look like in Rust and how we can apply standard [_Refactoring_](http://martinfowler.com/books/refactoring.html) patterns to remove them.

As always, this is easier to understand with an example. Let's look at Primitive Obsession in one of the most recent additions to the Rust exercise track: Bracket Push.

The problem is straight-forward: return `true` if the brackets in a string are balanced (all open brackets are closed in the correct order), and return `false` if they are not. There are a few different ways of solving it; I started with the following:

{% rp_highlight rust %}
pub fn are_balanced(input: String) -> bool {
    let mut unmatched_brackets: Vec<char> = Vec::new();

    for current_bracket in input.chars() {
        if let Some(most_recent_unmatched) = unmatched_brackets.pop() {
            let is_matched = match (most_recent_unmatched, current_bracket) {
                ('[', ']') => true,
                ('{', '}') => true,
                ('(', ')') => true,
                _ => false,
            };
            if !is_matched {
                unmatched_brackets.push(most_recent_unmatched);
                unmatched_brackets.push(current_bracket);
            }
        } else {
            unmatched_brackets.push(current_bracket);
        }
    }

    unmatched_brackets.is_empty()
}

fn main() {
    assert!(are_balanced("{[]}".to_string()));
    assert!(!are_balanced("[{]}".to_string()));
}
{% endrp_highlight %}

There are better ways to structure the logic, sure. But set that aside for a minute and let's focus on the primitives. In the above code I count five of them:

- String\*
- char
- boolean
- Vector\*
- Tuple

\* The Rust book doesn't list these in the [Primitive types](https://doc.rust-lang.org/book/primitive-types.html) section, but I'm fine with thinking of them as primitives. It's a fuzzy line.

The `are_balanced` function must accept a string and return a boolean to satisfy the tests. But inside the `are_balanced` function we can do whatever we want, and yet what I chose to do was use a bunch of primitives.

The primitives inside the function have satisfied all of the criteria of the Primitive Obsession smell: they were easy for me to use and they passed the tests. However, they obscured my code's intent and made it hard to change. I tried to provide some useful variable names but I still find that I have to read the entire function, slowly, before I understand what it's doing. This is not code that is easy to understand; and poorly understood code is rarely well maintained code.

So, let's fix it! Checking with Martin Fowler the official fix for Primitive Obsession is to replace the primitive with an object. Well, Rust doesn't have objects so we can't do that. But Rust still gives us all the tools we need to refactor away these primitives -- Structs and Traits will do most of the heavy lifting. If we replace our primitives with structs and traits that model the domain we will improve our code's clarity and maintainability. Where to start? Since the first primitive our function deals with is the String, let's start there.

We're not going to change the test, because refactoring should not change the behavior of existing code. Our function will still accept a string, but we can convert it to domain-specific Struct inside the function.

What should we call this Struct? Naming is hard, as always. Since it contains a bunch of brackets let's just call it `Brackets` for now. Maybe a better name will occur to us later. `Brackets` will start off containing our input string.

```rust
struct Brackets {
  input: String,
};
```

How do we create our `Brackets` inside `are_balanced`?. We could do this:

```rust
pub fn are_balanced(input: String) -> bool {
  let brackets = Brackets { input: input };
  //...
```

And that's...OK. But it's not idiomatic. We're trying to convert a String to a Brackets and Rust has a standard way to convert types -- the [`From` trait](https://doc.rust-lang.org/std/convert/trait.From.html). You may have seen this trait before in the commonly used `String::from(....)` function. But you can implement `From` for any type!

```rust
struct Brackets {
  input: String,
};

impl From<String> for Brackets {
  fn from(input: String) -> Self {
    Brackets { input: input }
  }
}
```

Wait! That's pretty much exactly the same thing we did in the last example. What's the benefit of implementing `From`? First, we're both following a Rust idiom and establishing a example for our code. And this example will guide us if (read: when) we want to create a Brackets from something else? A vector? A &str? Time will tell, but we've already established the protocol to follow whatever happens.

All of this is good...but it doesn't help us. Our code still relies on the behavior of a string primitive:

```rust
pub fn are_balanced(input: String) -> bool {
    //..
    for current_bracket in input.chars() {
    //..
    }
}
```

Our `Brackets` doesn't implement `chars()`. We can make it do so:

```rust
use std::str::Chars;
impl Brackets {
  fn brackets(&self) -> Chars {
    self.input.chars()
  }
}
```

That feels unsound to me, though I can't put a finger on why. I suspect this shortcut will come back and bite us later. Let's be a little more thorough and idiomatic.

[`chars` returns an iterator](https://doc.rust-lang.org/std/primitive.str.html#method.chars) and -- just like the `From` trait and type conversion -- Rust has a standard way of adding iterators to your Structs, [`IntoIterator`](https://doc.rust-lang.org/core/iter/trait.IntoIterator.html)

```rust
impl IntoIterator for Brackets {
  type Item = char;
  type IntoIter = ::std::vec::IntoIter<char>;

  fn into_iter(self) -> Self::IntoIter {
    self.input.chars().collect::<Vec<char>>().into_iter()
  }
}
// Note: I mostly copied this code from The Book; there may be a better way of implementing this Trait for Brackets.
// Update: Ms2ger showed me how to implement this without a vector:
//   https://github.com/IanWhitney/designisrefactoring/pull/22#discussion_r77125688
```

With this done, we can use `Brackets` throughout `are_balanced`

{% rp_highlight rust %}
struct Brackets {
    input: String,
}

impl From<String> for Brackets {
    fn from(input: String) -> Self {
        Brackets { input: input }
    }
}

impl IntoIterator for Brackets {
    type Item = char;
    type IntoIter = ::std::vec::IntoIter<char>;

    fn into_iter(self) -> Self::IntoIter {
        self.input.chars().collect::<Vec<char>>().into_iter()
    }
}

pub fn are_balanced(input: String) -> bool {
    let brackets = Brackets::from(input);
    let mut unmatched_brackets: Vec<char> = Vec::new();

    for current_bracket in brackets.into_iter() {
        if let Some(most_recent_unmatched) = unmatched_brackets.pop() {
            let is_matched = match (most_recent_unmatched, current_bracket) {
                ('[', ']') => true,
                ('{', '}') => true,
                ('(', ')') => true,
                _ => false,
            };
            if !is_matched {
                unmatched_brackets.push(most_recent_unmatched);
                unmatched_brackets.push(current_bracket);
            }
        } else {
            unmatched_brackets.push(current_bracket);
        }
    }

    unmatched_brackets.is_empty()
}

fn main() {
    assert!(are_balanced("{[]}".to_string()));
    assert!(!are_balanced("[{]}".to_string()));
}
{% endrp_highlight %}

By implementing a Struct and two traits we've:

- Given a name to our previously-nameless String
- Introduced an idiomatic way of creating our Brackets
- Used idiomatic Rust to show that `Brackets` can be iterated
- Made our code longer

No doubt about it, our code is longer. But it also more clearly illustrates what it's doing, and I'm OK with that tradeoff.

That's enough for now. Of our original list of five primitives there remain 3 that I would like to remove. Next time we'll tackle the Tuple.

If you want to comment, question, complain, &c. then you can do so [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or by [leaving comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/22).
