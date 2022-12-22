---
layout: post
title: "Refactoring Rust: Primitive Obsession 2"
subtitle: "Tuple Boogaloo"
date: 2016-11-28T20:08:23-06:00
author: "Ian Whitney"
---

I did not expect it to take me four months to write this post but life is weird. Since it has been so long you may want to go back and read [Part One](http://designisrefactoring.com/2016/08/31/refactoring-rust-primitive-obsession/) of this series. When you're ready we'll move on to our next Primitive Obsession target, the tuple.

<!--break-->

Currently our code looks like:

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

Before we get started on the next refactoring I want to make two quick digressions. First, I'm not satisfied with our test suite. Our code handles `(` and `)` brackets but our tests don't cover them. Let's add a couple of tests:

```rust
fn main() {
    assert!(are_balanced("{[]}".to_string()));
    assert!(are_balanced("{([])}".to_string()));
    assert!(!are_balanced("[{]}".to_string()));
    assert!(!are_balanced("{([]}".to_string()));
}
```

I run my code and all tests pass so everything is fine.

Second, let's talk about when you would do the refactorings covered in these posts. Our initial code passed our tests so why change it? As I see it there are only 3 reasons to change code:

1. It has a bug
2. Its functionality needs to change
3. It looks ugly

Options 1 and 2 are straightforward -- your code needs to do something different than it's currently doing so some changes are necessary. But option 3? If you're changing code only because of aesthetics then there are probably better ways to spend your time. The mere presence of a code smell is not enough motivation to change the code; you might refactor away the smell only to find later that you've introduced the wrong abstraction forcing you to change everything again.

If you're unsure about when to change code I suggest spending some time [reading](http://www.sandimetz.com) and [watching](http://confreaks.tv/search?utf8=✓&query=metz&commit=go) the works of Sandi Metz. Sandi offers very pragmatic approaches to handling code smells and refactoring. Most of her work is focused on Ruby and object oriented design but I've found everything to be equally applicable to languages like Rust.

In my articles, contrary to my own advice, I am changing code purely for aesthetic reasons. This is because I want to illustrate the techniques I use to remove smells so that others can use them when they change code for legitimate reasons.

Ok, digressions done. Let's change some code.

At the end of last time I said we would next tackle the tuple primitive. Why the tuple? Because it is currently our most-used primitive (appearing in 4 different lines) and I think it contains an important concept that should be extracted and named. Let's look at our tuple:

```rust
let is_matched = match (most_recent_unmatched, current_bracket) {
    ('[', ']') => true,
    ('{', '}') => true,
    ('(', ')') => true,
    _ => false,
};
```

Three of these lines are nearly identical -- each of them returns true if the tuple contains the right `chars`. There's clearly some similarity here but it's not exact duplication, otherwise we'd only have one line returning `true`.

We have two concepts in this code, the parts that are identical (returning `true`) and the parts that vary (the different tuples). Our code will be clearer if we can extract and name these concepts. But what are they? Naming things is hard as always. But it can be easier if we think about what we would have to do if we wanted to change this code so that it also checked for the pair of `<` and `>`. What would we have to change?

```rust
let is_matched = match (most_recent_unmatched, current_bracket) {
    ('[', ']') => true,
    ('{', '}') => true,
    ('(', ')') => true,
    ('<', '>') => true,
    _ => false,
};
```

As mentioned, this one line change adds two concepts:

- the tuple of `('<', '>')`
- that this tuple should return `true`

We can give these two concepts names:

- A pair of two brackets could be called `BracketPair`
- A `BracketPair` will return if it `is_closed()`
  - so a pair of '<' and '>' will return `true` while a pair of '<' and '}' would return `false`.

Now that we know the names of what what we want to extract we can set about extracting them. Slowly.

Why slowly? Because I want our tests to pass throughout this refactoring. We're not going to make a big change in one fell swoop -- something which would surely lead to compiler errors, puzzled looks, and cursing. Instead we're going to introduce the new code slowly, running our tests after every change. I again point to Sandi Metz's (and Katrina Owens') work in [_99 Bottles of OOP_](http://www.sandimetz.com/99bottles) for a great description of the value of taking tiny steps while refactoring.

Because I'm taking tiny steps I'm only going to show the code I'm changing. Assume that the rest of the code is unchanged. Let's start by introducing our new Struct.

```rust
struct BracketPair {}
```

Then I save and compile. This struct isn't being used yet and couldn't do anything useful even if we did try to use it. But compiling tells us that our code still works as expected. If it did not, we would know the exact location of the error and could return to a passing test suite with a single undo.  Everything is fine, though, so we move forward and implement `is_closed()`

```rust
impl BracketPair {
  fn is_closed(&self) -> bool {
    false
  }
}
```

Save and compile. Slightly more code this time but still nothing complex. Our `BracketPair` instances can now tell us if they are closed. That they will never return `true` is beside the point right now. We'll get there.

How will we create a `BracketPair`? Currently the concept is represented by two chars in a tuple; let's stick with that. First we change our Struct:

```rust
struct BracketPair {
  pair: (char, char)
}
```

Save and compile. You know the drill. Now we can add code that allows us to create a `BracketPair` `from` a tuple. We established this idiom in the previous article and there's no reason to break from convention here:

```rust
impl From<(char, char)> for BracketPair {
  fn from(pair: (char, char)) -> Self {
    BracketPair { pair: pair }
  }
}
```

We can now create `BracketPair`s and we can ask them if they are closed (though they give us the wrong answer). We're at a point where we can wire this code into our existing code to see if any weirdness appears.

```rust
let is_matched = BracketPair::from((most_recent_unmatched, current_bracket)).is_closed();

let is_matched = match (most_recent_unmatched, current_bracket) {
    ('[', ']') => true,
    ('{', '}') => true,
    ('(', ')') => true,
    _ => false,
};
```

Yes we're immediately re-binding `is_matched` and throwing away the value returned by `BracketPair`. Our goal here is not to make sure the code is entirely correct (it's not) but to make sure we haven't broken anything in an unexpected way. This compiles and our tests pass so everything is good. Now to make `is_closed()` work as we expect...which is really easy as it's a near duplicate of the code we already had:

```rust
impl BracketPair {
  fn is_closed(&self) -> bool {
    match (self.pair.0, self.pair.1) {
      ('[', ']') => true,
      ('{', '}') => true,
      ('(', ')') => true,
      _ => false,
  }
}
```

Save and compile. Tests pass so we can now remove the old `match` statement:

```rust
if let Some(most_recent_unmatched) = unmatched_brackets.pop() {
  let is_matched = BracketPair::from((most_recent_unmatched, current_bracket)).is_closed();

  if !is_matched {
    unmatched_brackets.push(most_recent_unmatched);
    unmatched_brackets.push(current_bracket);
  }
} else {
  unmatched_brackets.push(current_bracket);
}
```

Save and compile. Tests pass meaning we've now fully extracted that logic into `BracketPair`. And, since it's easy, let's remove the `is_matched` temporary variable:

```rust
if let Some(most_recent_unmatched) = unmatched_brackets.pop() {
  if !BracketPair::from((most_recent_unmatched, current_bracket)).is_closed() {
    unmatched_brackets.push(most_recent_unmatched);
    unmatched_brackets.push(current_bracket);
  }
} else {
  unmatched_brackets.push(current_bracket);
}
```

As we're removing unnecessary lines we can turn our two `push` calls into a single [`extend`](https://doc.rust-lang.org/std/iter/trait.Extend.html)

```rust
if let Some(most_recent_unmatched) = unmatched_brackets.pop() {
  if !BracketPair::from((most_recent_unmatched, current_bracket)).is_closed() {
    unmatched_brackets.extend(&[most_recent_unmatched, current_bracket]);
  }
} else {
  unmatched_brackets.push(current_bracket);
}
```

Save and compile. Done. Whew! There were a lot of steps there but they were all _very small_ steps. If any of them had failed we only would have had to undo one change to return to a passing test suite.

As the code keeps getting longer I won't put it all here. Check it out in the [Rust playground](https://play.rust-lang.org/?gist=8bad61c5793b9fa4573dbf0ea1d06400&version=stable&backtrace=0). This is a good, though maybe unsatisfactory, stopping point. We've finished our extraction but the tuple continues to exist in our code. Instead of getting bummed about that let's look on the bright side. We've:

- Introduced a concept important to this domain: `BracketPair`
- Allowed `BracketPair` to say if it is closed or not
- Separated the concerns of checking individual brackets from checking a large string

If we need to add a new bracket pair (there are a [bunch of them](https://en.wikipedia.org/wiki/Bracket)) we still need to add a line to `BracketPair`, but I believe that is an improvement over adding it to `is_balanced`.

But maybe, just maybe, there's more we can do about that Tuple. Next time we'll try to eradicate it once and for all!

If you want to comment, question, complain, &c. then you can do so [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or by [leaving comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/23).
