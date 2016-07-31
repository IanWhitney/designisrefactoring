---
layout: post
title: "Exercism Shouldn't Make You Cry"
date: 2016-07-09T12:39:04-05:00
author: Ian Whitney
---

## The Problem

For the past few months I've been contributing to [Exercism.io](http://exercism.io), mostly by expanding the [Rust track](http://exercism.io/languages/rust) and helping to standardize the problems across languages. It's fun, and I think the recent upswing in contributors to Exercism has helped the site significantly.

Case in point: an Exercism student, smarter than myself, did an awesome thing and submitted [an issue](https://github.com/exercism/xrust/issues/126).

Submitting an issue may not seem like much. "Salty Randos" ([as Justin Searls calls them](http://confreaks.tv/videos/railsconf2016-rspec-and-rails-5)) submit issues all the time, right? But this issue was different. The student was honestly confessing that the Anagram problem that was too hard for beginners. That, like I said, is an awesome thing. Programmers (well, all people, probably) don't like to say, "This is too hard". Especially when the thing that's too hard is a toy programming problem meant to help you learn.

What made this issue all the more pressing for me was that I *knew* about the problem. I'd just forgotten. I began learning Rust with the [leap year](http://designisrefactoring.com/2015/10/02/rust-by-trial-and-error/) problem, which was fun. So I continued on to Anagram.

Where I hit a massive wall.

<!--break-->

The wall was so huge that it took me four blog posts ([one](http://designisrefactoring.com/2015/10/17/rust-simple-enough-for-me-to-learn-it/), [two](http://designisrefactoring.com/2015/11/13/simple-rust-part-two/), [three](http://designisrefactoring.com/2015/11/27/simple-rust-part-three/), [four](http://designisrefactoring.com/2015/12/30/simple-rust-part-four/)) and two months to climb it.

I later joked at a presentation that "[Lifetimes](https://doc.rust-lang.org/book/lifetimes.html) made me cry". Which may or may not be literally true.

And yet [Anagram](http://exercism.io/exercises/rust/anagram/readme) was the *3rd problem* in the Rust track. Right after [Hello World](http://exercism.io/exercises/rust/hello-world/readme) and [Leap Year](http://exercism.io/exercises/rust/leap/readme).

Imagine learning to drive in the same way. First they show you how to turn the car on, then they show you how to remove the parking brake, then it's straight to parallel parking on a busy street during rush hour!

This isn't a good way to learn.

Yet, for reasons that I can't explain it never occurred to me that I could change this. Like I've pointed out many times on this site, I'm pretty dumb.

Once this student reminded me how hard Anagram was, I could see evidence of it everywhere. Roughly 1/3 of the students that started the Rust track did not progress past the Anagram exercise. We were asking them to leap a chasm. And they, rightfully, left.

Those that did stay had some wildly divergent solutions. Some variation is normal but these solutions had the look of desperation. Students just trying whatever code they could find to get these tests to pass. I know that I did the same thing -- trying any function I could find in the docs, hoping to unlock the mystery.

And these were people familiar with coding. Most people learning Rust are learning it as a 2nd (or 3rd, 4th, etc.) language. They weren't stuck because they didn't know what an `if` loop was, they were stuck because they had to grasp Rust's [strangeness budget](http://words.steveklabnik.com/the-language-strangeness-budget) all at once.

Our problem ordering was driving many of our students to either give up or brute-force their way through a wall. Neither of these are good.

Let this be a lesson: if you have a problem, open an issue! With the issue staring us in the face, we knew we had to fix it. But how? We could just move Anagram later in the track, but how would we know we hadn't introduced some new roadblock?

## The Solution

I have a kid in pre-kindergarten and her teacher talks a lot about 'laddering', giving kids tasks that are just slightly beyond their current skills. This encourages steady progress without the frustration that comes from working on a task too difficult for them. Ask my kid to write her full name and she's engaged. Ask her to write a "Antidisestablishmentarianism" in cursive and she'll shut down.

So we had to ladder our exercises; thankfully we had tools that made this job easier.

Each exercise in Exercism has an example solution ([here's anagram's](https://github.com/exercism/xrust/commits/master/exercises/anagram/example.rs)), allowing me to quickly compile a list of concepts required to solve each problem. I could also judge the problem's complexity by looking at code length, general nastiness, etc. From there I split the exercises into 4 groups:

- Requires concepts common in many programming languages
- Requires uncommon concepts
- Requires Rust-specific concepts
- Requires combinations of all previous concepts

There's some art to this. An example solution may use a technique, but will students? For example, the [difference of squares](https://github.com/exercism/xrust/blob/04b665e989b578c4e46ff100b1b0a00d5df9bb0d/exercises/difference-of-squares/example.rs) example uses higher-order functions, but students don't have to do the same. In cases like this I expect that feedback from other students, or reviewing other solutions, will show students different (maybe better) approaches.

But in other cases Rust's strong and static typing will force -- or strongly encourage -- students to use certain techniques. It is possible to solve Anagram without getting into lifetimes, but the tests definitely push you towards them and most solutions I've seen use them. And while implementing [Robot Simulator](https://github.com/exercism/xrust/pull/146), we tried two different sets of tests; one would force students to implement immutable robots, hile the other would require the robots be mutable. Unless students change the tests (which they can do, by the way), they are often required to use certain aspects of Rust in order to pass those tests.

After applying my art and science, the four problem groups looked like this:

### Section One: Introduction

The first section contains the sort of stuff you expect when learning any programming languages: conditionals, booleans, looping and some higher-order functions (these were once weird but I now think of `fold`, `map` and the like to be very common. That may be my years of Ruby speaking).

If you look at other language tracks in Exercism you'll see that many of them offer these problems first. This is not accidental; problems like these are a great way to gain familiarity with a new language.

### Section Two: Getting Rusty

Once students get through those introductory exercises they enter the "Getting Rusty" section, where problems begin to use more Rust-specific features. [`Result`](http://doc.rust-lang.org/book/error-handling.html#the-result-type) and [`Option`](http://doc.rust-lang.org/book/error-handling.html#the-option-type) (not unique to Rust, but still not exactly common), the [entry API](http://doc.rust-lang.org/std/collections/struct.HashMap.html#method.entry), [`while let`](http://doc.rust-lang.org/book/if-let.html#while-let), [traits](http://doc.rust-lang.org/book/traits.html) and [generics](http://doc.rust-lang.org/book/generics.html). Some of these ideas may be familiar to programmers experienced with strong, static typing, but the Rust implementations will be new to them. And for programmers (like myself) coming from an OO background most of these problems will introduce something entirely new.

But only one new thing. Hopefully. We tried to stick to our "Ladder" approach and order the problems so that they only introduce one brand new thing. Take [Nucleotide Count](http://exercism.io/exercises/rust/nucleotide-count/readme), for example. Solutions will probably use:

- `entry` API
- `filter`
- `match`

But, thanks to the list I compiled, we could see that students had probably already used `filter` and `match` in earlier problems. Only the `entry` API should be new.

Where possible we strung together 2 or 3 problems that focused on the same concept. `Option` is introduced in `hexadecimal` and is immediately followed another `Option` problem, `grade-school`.

### Section Three: Rust Gets Strange

With the Rust groundwork laid we move into the exercises that pay the cost of Rust's strangeness budget. Right now these exercises all feature lifetimes. Anagram -- previously the track's 3rd problem --  became our 23rd and our introduction to lifetimes.

After Anagram there are two more problems that use lifetimes, each with their own unique wrinkles. This should help cement lifetime usage into the minds of students.

As we add more problems to the Rust track I'm hoping to increase the number of problems in the "Rust Strangeness" section. Box types would be perfect. Maybe something that requires a function to return a closure. But this can get tricky, for reasons I'll get to is a second.

### Section Four: Putting it all Together

These problems don't necessarily require additional Rust knowledge, but they do require complex solutions. I put problems here if the example code gave me a headache. Like the [Forth](https://github.com/petertseng/xrust/blob/059def624a2a1a35520f5c4047d4ad451961b057/exercises/forth/example.rs) exercise. I can puzzle out what's going on in there, but it takes me a while.

## The Plan

As the Rust track expands we need to focus on two things:

- Placing new exercises in the right spot
- Filling in gaps in our learning curve

When someone submits a PR for a new exercise we discuss what techniques the solution will require and place it correctly (hopefully). And it's not just us making these decisions --  we try to get the Rust and Exercism community involved. [My Twitter](https://twitter.com/iwhitney) account isn't the most popular but my pleas for help are usually signal-boosted by [@rustlang](https://twitter.com/rustlang), [@exercism_io](https://twitter.com/exercism_io) and others.

Once the problem is implemented we look for signs that people are having problems such as we saw with Anagram -- a large drop in successful solutions or solutions that don't show an understanding of the underlying concepts.

Filling in the gaps is trickier. As I mentioned earlier, I want some exercises that help people (including myself!) learn about the Box type. First, we have to find an already-defined Exercism exercise that naturally lends itself to using Boxes. Failing that, we have to write the exercise from scratch ourselves. I'd rather not shoehorn Box into code where it doesn't belong; that can give students the wrong idea about when to use Boxes. This is a problem we're not yet sure how to solve.

New exercise are not the only thing we need to keep our eye on, though. As Exercism evolves we occasionally need to revisit and update existing problems. For example, we're currently [improving our implementation of the Tournament problem](https://github.com/exercism/xrust/pull/152) (thanks in part to [another excellent issue opened by a student](https://github.com/exercism/xrust/issues/122)). These changes removed some complexity, so we moved the problem to earlier in the track.

## The Big Summary

The Rust track in Exercism should no longer make you cry. But if it does, [we want to hear about it](https://github.com/exercism/xrust/issues). The problem's not yours, it's ours.
