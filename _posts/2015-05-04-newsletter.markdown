---
layout: post
title: "Not Very Much About Primitives"
date: 2015-05-04 12:35:35 -0600
author: Ian Whitney
---

Not Very Much About Primitives

According to the schedule I should be sending out a newsletter about the Primitive Obsession smell. But that newsletter would be a near-exact copy of last week's blog post [Replace Data Value with Object](http://designisrefactoring.com/2015/04/26/organizing-data-replace-data-value-with-object/), since the smell Fowler & Beck are talking about is the same smell that is fixed by that refactoring pattern. If find yourself passing around a lot of primitives (e.g., integers, strings, etc.), then extract those suckers into objects. End of story.

Instead of talking about Primitive Obsession, I'm hoping I have something interesting to say about the kinds of knowledge you need to refactor effectively. Will it be interesting? I make no promises.

Recently I started learning Haskell. And while I've been able to write some Haskell code that works (mostly), I find that I have no idea how to refactor it.

Refactoring, I'm finding, requires two different types of knowledge. First, you have to learn how to spot problems. For this you can use intuition, code smells, design heuristics like SOLID, and so on.

Once you spot the problems, that's when you use the second type of knowledge: how to write code.

The two types of knowledge don't really overlap. The first is largely applicable across languages. Bad variable names, overlong methods (or functions), etc. -- these can plague code in almost any language. So I can look at my Haskell code and say, "Gee, that function is doing way too much."

But the next step, actually refactoring the code, requires you to actually know the language you're working in. Yes, I need to break that function into smaller functions. But...how do I do that again? Yes, my code is clearly duplicating knowledge. But all my attempts to extract it lead to a compiler error. And so on.

All of this is to say something that everyone probably already knows: you're going to write terrible code for a while when you learn a new language. That's fine. Everyone is a beginner when they start a new language.

More links than you probably require:

It seems only appropriate to link to the [Refactoring Haskell](https://wiki.haskell.org/Refactoring) page on the Haskell wiki.

Tom Stuart wrote a really excellent [examination of type systems and what might be coming to Ruby 3](http://codon.com/consider-static-typing).

I found the Tom Stuart article thanks to a Sandi Metz tweet; Sandi also gave a very well received presentation at this year's RailsConf: [Nothing is Something](http://confreaks.tv/videos/railsconf2015-nothing-is-something) about dealing with Null.

Null is one of the reasons I started looking at Haskell, after hearing some interviews with the author of [Maybe Haskell](https://gumroad.com/l/maybe-haskell) about the language's Maybe data type. Haskell, unlike Ruby, requires you to handle nulls explicitly. I have not yet finished the book, but I'm finding it a good companion to my other Haskell guides.

Also related to RailsConf, fellow U of MN employee Marcus Peterson [wrote about his trip to this year's RailsConf](http://tech.popdata.org/railsconf-2015-wrap-up/). Lots of links to good talks in there.

As I am trying to learn about a new language, the Ruby Rogues episode [on limerence](http://devchat.tv/ruby-rogues/204-rr-limerence-with-dave-thomas) hit home for me. Limerence, if you're unfamiliar with the word (as I was) is the weird obsession people develop when first falling in love. With a person, normally. But there are interesting comparisons to be made to programmers' relationships with languages and tools.

Next week there will be another blog post where I'll dig into another pattern in the Organizing Data section of _Refactoring_.

If there are changes/topics/etc. you'd like to see, please Reply, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/3).

Until next time, true receivers.
