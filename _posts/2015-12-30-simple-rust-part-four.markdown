---
layout: post
title: "Simple Rust, Part Four"
date: 2015-12-30T14:07:28-06:00
subtitle: "Iterators, References and Options"
author: "Ian Whitney"
---

This is it, the home stretch. In the 3 previous articles we've learned a lot about Rust (like [Strings](http://designisrefactoring.com/2015/10/17/rust-simple-enough-for-me-to-learn-it/), [Arrays](http://designisrefactoring.com/2015/11/13/simple-rust-part-two/) and [Lifetimes](http://designisrefactoring.com/2015/11/27/simple-rust-part-three/)), but we haven't actually written the code that started us down this path -- finding anagrams of words. Today we will write that code.

<!--break-->

Of our [11 tests](https://github.com/exercism/xrust/blob/09a6703b903b1d3facb693556d852b49afa79b3c/anagram/tests/anagram.rs) we have managed to get the first one passing. Just 10 more tests to go! Here's our next one:

{% highlight rust %}
fn test_detect_simple_anagram() {
    let inputs = ["tan", "stand", "at"];
    let outputs: Vec<&str> = vec!["tan"];
    assert_eq!(anagram::anagrams_for("ant", &inputs), outputs);
}
{% endhighlight %}

Our current function won't work, obviously. It only returns an empty vector:

{% highlight rust %}
pub fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
    return vec![];
}
{% endhighlight %}

Now, I have no idea how to do this in Rust. But I know how I would do it in Ruby, which is a good place to start.

{% highlight ruby %}
def same_word?(word, other)
  word == other
end

def same_letters?(word, other)
  word.chars.sort == other.chars.sort
end

def anagrams_for(source, inputs)
  inputs.reject { |input| same_word?(source, input) }
  .select { |input| same_letters?(source, input) }
end

puts anagrams_for("ant", ["tan", "stand", "at"])
#=> ["tan"]
{% endhighlight %}

I can use my working Ruby implementation like a [Rosetta Stone](https://en.wikipedia.org/wiki/Rosetta_Stone) to translate code I know how to write into a language that I'm still learning.

In the first line of my Ruby `anagrams_for`, I'm using `reject` to remove any input that is the same word as our source. "ant" is not an anagram of "ant" because they are the same word. Then I use `select` to gather up all the input words that have the exact same letters as our source. This relies on Ruby's Enumerable library and its support for closures.

Rust loves list-transformation functions like these, which it calls [Iterator Adaptors](https://doc.rust-lang.org/stable/book/iterators.html#iterator-adaptors). Another common name for them is [Higher Order Functions](https://en.wikipedia.org/wiki/Higher-order_function). Ruby's `select` and `reject` are examples of the [filter](https://en.wikipedia.org/wiki/Filter_%28higher-order_function%29) higher order function. Rust also offers filter, which it calls [filter](https://doc.rust-lang.org/stable/std/iter/struct.Filter.html). The `filter` documentation reads:

> An iterator that filters the elements of iter with predicate.

Ok. That *almost* makes sense. I know what a predicate is (though I just learned it recently). It's an expression that returns true or false. But what's `iter`? Let's go back to Ruby and see how it handles iteration.

In Ruby, you can iterate over anything that's enumerable:

{% highlight ruby %}
[1, 2, 3].each { |number| puts number }
#=> Prints out 1 2 3, each on its own line

(1..100).select { |x| x % 2 == 0 }
#=>  returns an array of the even numbers from 1 up through 100

{key: "value"}.inject([]) { |ret, element|  ret << [element[0], element[1]] }
#=> coverts the hash to the array [[:key, "value"]]
{% endhighlight %}

Arrays, hashes, ranges -- these are enumerable in Ruby so you can iterate over their elements and use Ruby's collection of higher order functions like `select`, `map` and `inject`.

Rust offers arrays, hashes and ranges as well. You can iterate over them&hellip;sometimes:

{% highlight rust %}
for num in 1..3 {
  println!("{}", num);
}
//=>1 2
//Rust, unlike Ruby, does not include the last element of a range
{% endhighlight %}

Notice my qualifying 'sometimes' above:

{% highlight rust %}
for num in [1, 2, 3] {
  println!("{}", num);
}
//=>error: the trait `core::iter::Iterator` is not implemented for the type `[_; 3]` [E0277]
//=>note: `[_; 3]` is not an iterator; maybe try calling `.iter()` or a similar method
{% endhighlight %}

The range `1..3` can be iterated over, but an array can not. Let's follow the error's advice and use `iter()`:

{% highlight rust %}
for num in [1, 2, 3].iter() {
  println!("{}", num);
}
//=>1 2 3
{% endhighlight %}

Great. Simply put, `iter()` takes a collection converts it into an Iterator; once you have an Iterator you can iterate over it and use all those fancy higher order functions, like `filter`.

Filter will make it easy for us to replicate the first part of my Ruby solution, rejecting all inputs that are duplicates of the source word.

{% rp_highlight rust %}
fn same_word(source: &str, input: &str) -> bool {
  input == source
}

fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
  inputs.iter().filter ( |&input| !same_word(input, source) )
}

fn main() {
  let inputs = ["tan", "ant"];
  let outputs: Vec<&str> = vec!["tan"];
  assert_eq!(anagrams_for("ant", &inputs), outputs);
}
{% endrp_highlight %}

Our filter uses the `same_word` function as its predicate. If the words are the same, we remove the input. If not, we keep the input. Running this gives us the error:

```
(expected struct `collections::vec::Vec`,
    found struct `core::iter::Filter`) [E0308]
```

We've told Rust that `anagrams_for` returns a `Vec`, but it's returning a `Filter`. Weird.

This is because Rust's iterators are lazy. Our call to filter doesn't actually do the filtering until we try to gather up the results. Ruby's [Enumerator](http://blog.carbonfive.com/2012/10/02/enumerator-rubys-versatile-iterator/) works similarly, as does its [lazy enumerable](http://railsware.com/blog/2012/03/13/ruby-2-0-enumerablelazy/). Rust calls its result-gathering functions [Consumers](https://doc.rust-lang.org/book/iterators.html#consumers). Since we want to collect the results of our filter, we use the `collect` consumer. And, as the documentation points out, we have to tell collect what type we want to get back. Our function promises to return a `Vec<&str>`, so let's have collect give us one of those:

{% rp_highlight rust gist_id=300a74679625aa39d6ef %}
fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
  inputs.iter().filter ( |&input| !same_word(input, source) ).collect::<Vec<&str>>()
}
{% endrp_highlight %}

Now we're sure to compile, right? By now you should know that every time I ask this question the answer is, "No."

```
error: the trait `core::iter::FromIterator<&&str>` is not implemented for the type `collections::vec::Vec<&str>`
```

Hell. What this is saying is that collect can't give me a `Vec<&str>` because I've given it a iterator that contains `&&str`.

`&&str`?  Or should I say `&&str`??. Where did that second `&` come from?

The short answer is that `iter()` borrows each element in inputs. Inputs was full of `&str`, which became `&&str` when they were borrowed by `iter()` (and `&&&str` if they are borrowed a 3rd time. I don't think there's a limit to how many times you can re-borrow something). Herman Radtke's blog post [Effectively Using Iterators In Rust](http://hermanradtke.com/2015/06/22/effectively-using-iterators-in-rust.html) dives into this topic, if you want more details.

We can fix our code by changing it to collect the right type, or we can also tell `collect` to figure out the type itself:

{% rp_highlight rust gist_id=039b149600fbfabf5bed %}
fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
  inputs.iter().filter ( |&input| !same_word(input, source) ).collect::<Vec<_>>()
}
{% endrp_highlight %}

The `_` is a 'type placeholder', which allows us to leave out the type of elements our vector will contain and let Rust determine it for us.

The type placeholder is nice, but it just gets us a new error. Our vector is still full of `&&str` elements, and our function says it returns a `Vec<&str>`. That's a no go. We need a way to return `Vec<&str>`.

I've been using the words 'reference' and 'borrow' pretty interchangeably without defining what's going on. There's a good reason for that -- I don't understand what's going on. But let me take a stab at it:

If I write:

{% highlight rust %}
let x = "hello";
{% endhighlight %}

Then x is a `&str`. I read that as "x is borrowing a str", or "x holds a reference to a str". Somewhere in memory is the actual `str`, and our variable `x` is holding a reference to that location.

If we then borrow x again:

{% highlight rust %}
let x = "hello";
let y = &x;
{% endhighlight %}

Then `y` is a `&&str`. Or, "y holds a reference to a reference to a str."

Rust offers a way to get at the thing we are referencing -- the entirely un-googleable `*` operator.

{% highlight rust %}
let x = "hello";
//x is the type &str

let y = &x
//y is the type &&str

let z = *y
//z is the type &str
{% endhighlight %}

As far as I can tell `*` is not well documented in the Rust book. It's mentioned in the [References and Borrowing](https://doc.rust-lang.org/book/references-and-borrowing.html#mut-references) section with the almost throwaway sentence:

> You'll also notice we added an asterisk (*) in front of y, making it *y, this is because y is an &mut reference. **You'll also need to use them for accessing the contents of a reference as well.**

Emphasis mine. I dunno, maybe I'm off base, but this sounds pretty important. It's certainly important to us right now. We have a vector full of references to references, and we want to get a vector of just the original references:

{% rp_highlight rust gist_id=30f7d172160840e63a9d %}
fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
  let references =  inputs.iter().filter ( |&input| !same_word(input, source) ).collect::<Vec<_>>();

  let mut different_words = Vec::new();

  for reference in references {
    different_words.push(*reference);
  }

  different_words
}
{% endrp_highlight %}

We create a new mutable vector and fill it with the `&str` references from our filtered collection. We then return that vector, and our code compiles!

Now that we can remove inputs that match our source word, we have to find inputs that are anagrams of our source word. In my Ruby solution, I converted the word to an array of letters with `chars` and then sorted the letters alphabetically with `sort`:

{% highlight ruby %}
"tan".chars
#=> ["t", "a", "n"]

"tan".chars.sort
#=> ["a", "n", "t"]
{% endhighlight %}

I can then compare the sorted array of input characters to the sorted array of source characters.

We can do the same thing in Rust. The code looks familiar.

{% rp_highlight rust %}
fn same_word(source: &str, input: &str) -> bool {
  input == source
}

fn same_letters(source: &str, input: &str) -> bool {
  let mut input_letters = input.chars().collect::<Vec<_>>();
  let mut source_letters = source.chars().collect::<Vec<_>>();
  input_letters.sort();
  source_letters.sort();
  input_letters == source_letters
}

fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
  let references = inputs
  .iter()
  .filter ( |&input| !same_word(input, source) )
  .filter ( |&input| same_letters(input, source) )
  .collect::<Vec<_>>();

  let mut anagrams = Vec::new();

  for reference in references {
    anagrams.push(*reference);
  }

  anagrams
}

fn main() {
  let inputs = ["tan", "ant"];
  let outputs: Vec<&str> = vec!["tan"];
  assert_eq!(anagrams_for("ant", &inputs), outputs);
}
{% endrp_highlight %}

In `same_letters` we use `chars()` to convert our source and input to an iterable collection of characters, which we then `collect`. We then sort those collections and compare them. This looks an awful lot like my Ruby example. Though in Rust, unlike Ruby, the `sort()` function sorts the receiver in place, it does not return the sorted collection.

If we run this code against our test suite, nearly everything passes. Some tests cover upper-case characters, but the fix for case insensitivity isn't that interesting so I'm going to skip it. If you want to see my solution, it's [over here](https://play.rust-lang.org/?gist=a26910dd7393d6649565&version=stable).

Our tests pass, but I'm not happy with the code. I understand why I have to dereference everything, but that code seems totally irrelevant to what the `anagrams_for` function is doing. It exists to make the compiler happy.

When I [complained about this on Twitter](https://twitter.com/iwhitney/status/675166825626386436), the [Rusting Rubyist](https://medium.com/@mfpiccolo/a-rubyist-rusting-db6e7e9c8f36#.gbt820vek) Mike Piccolo pointed me towards the [`filter_map`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.filter_map) function. Its description is:

> Creates an iterator that both filters and maps elements. If the specified function returns None, the element is skipped. Otherwise the option is unwrapped and the new value is yielded.

'Unwrapping' is kind of a weird word, and not one we've come across yet. There's actually a lot of complexity here, which I'm going to entirely skip. The relevant thing we need to know is that I can stick a reference in the type `Some` and when I 'unwrap' it I get my reference back. So:

{% highlight rust %}
let x = "Hello";
let y = Some(x).unwrap();
//y has the type &str
println!("{}", y)
//=> Hello
{% endhighlight %}

`Some`'s partner in crime is `None`. You always see the two of them together. Taken together they are the ["Option" or "Optional" type](https://doc.rust-lang.org/stable/book/error-handling.html#the-option-type). If an expression can return something or nothing, you'll see code like this:

{% highlight rust %}
if x.erratic_function() {
  Some(x)
} else {
  None
}
{% endhighlight %}

When you deal with the result of this expression you write code that checks, "Did I get Some or None?" and behave appropriately.

Though it's not about Rust, I found the book [Maybe Haskell](https://gumroad.com/l/maybe-haskell) to be a great introduction to the concepts behind Some and None  It can be a hard concept to wrap your head around, though once you do the value it provides is immense.

Knowing that background, the `filter_map` description makes more sense. It:

- filters an iterator's elements, just like `filter`
- The filter uses a function that returns Some or None
  - If None, the element is removed
  - If Some, the *reference* is returned

Let's see what our `anagrams_for` function would look like if it used `filter_map`

{% rp_highlight rust gist_id=d3cf98c5197cdaaecbb3 %}
fn anagrams_for<'a>(source: &str, inputs: &[&'a str]) -> Vec<&'a str> {
  inputs.iter()
        .filter ( |&input| !same_word(input, source) )
        .filter_map ( |&input|
          if same_letters(input, source) {
            Some(input)
          } else {
            None
          }
        )
        .collect::<Vec<_>>()
}
{% endrp_highlight %}

2 lines shorter. More importantly, I find this easier to understand. The result of `filter_map` is what we want to return, no need to loop and dereference a bunch of references.

And that's it! Not only do we have a working anagram finder, but we (hopefully) know a lot more about Rust that when we started. There's a lot (a *lot*) more to Rust than we've covered here, but this is where I'm going to stop for now. The next post on this site will return to the topic of Refactoring, and will be the first in a series of posts on Practicing Refactoring.

If you want to read more about Rust, Ruby, Refactoring and other things that start with R (and maybe other letters), maybe check out my totally free newsletter. You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/14).
