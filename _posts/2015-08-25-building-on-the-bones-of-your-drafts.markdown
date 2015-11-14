---
layout: post
title: "Building on the bones of your drafts"
date: 2015-08-25T20:06:47-05:00
author: Ian Whitney
---

In my [last post](http://designisrefactoring.com/2015/08/03/the-power-of-drafts/) I talked about how our rough drafts have the power to reveal our humanity and our learning processes. But I never talked about how we actually _improve_ our code, how we can build on our flawed early implementations and make them better.

Just as a writer doesn't randomly change words and call the result a Second Draft, we can't improve our code by just randomly tweaking things and pushing it to GitHub. Your commit log can be endlessly long and the code might still be a First Draft. So, how do we actually move from First Draft to Second? How do we build upon the bones of our drafts, each new layer better than the ones beneath?

<!--break-->

I quickly mentioned a process in my last post, but didn't discuss it in any depth. Here it is again:

1. Start with a vague idea
2. Write some awful, ugly code
3. Use the knowledge I gained in step two to write some slightly better code
4. Repeat...forever

Step 3 could easily be renamed "Refactor!" but I've found that word can be misunderstood. For this process to work -- for your code to actually improve --  refactoring has to be done correctly. Your knowledge of the system has to change, and that new knowledge has to be applied to your code.

Let's look at a silly example:

I have an app that lets people manage their lemur collections. Lemurs (or their owners) get bored of names pretty quickly, so they want to be able to rename all of their lemurs at once using randomly picked names. We follow the normal TDD workflow, writing some tests and then some code:

```
def lemur_renamer(lemurs)
  lemurs.each do |x|
    x.update_name(LemurNames.a_lemur_name)
  end
end
```

We've done Red and Green, now it's time to Refactor! With our current knowledge of the system, what can we change here?

```
def lemur_renamer(lemurs)
  lemurs.each { |lemur| lemur.update_name(LemurNames.random) }
end
```

We've renamed the useless variable `x` to the descriptive `lemur` and renamed the incorrect `a_lemur_name` to the more accurate `random`. And we altered the code to use a more idiomatic block instead of `do/end`.

All of these changes are good. But none of them are refactoring. No new knowledge of how the code should work was introduced, and no aspect of the code's design was changed.

And this is **fine**. Seriously.

The problem is not that we didn't refactor. We had no reason to refactor. In writing the code we didn't discover anything new about that code or what it needed to do. Actually refactoring at this point is jumping the gun, guessing at what the future will bring.

The problem, if anything, is that the Red-Green-Refactor process might be misnamed in cases like this. It would be be better if we thought of it as "Red-Green-Ok, did you find a functional problem in your code? Refactor. Otherwise, do some cleanup."

But that's not nearly as catchy.

Time passes and we get a request from the users of lemr.io (yes, someone already owns that domain). Some lemur owners want to be able to define their own sets of names to use when renaming their lemurs.

Now we have new knowledge about our system. Now we can refactor.

```
def lemur_renamer(lemurs, names = LemurNames)
  lemurs.each { |lemur| lemur.update_name(names.random) }
end
```

The collection of names is now something we can override. But if we don't the default collection is used. There are other ways to do this, but the actual refactoring is not the point here. The point is the process:

1. We wrote some code.
2. We **didn't** refactor it.
3. We gained new knowledge about the system.
4. We refactored the code to reflect our new knowledge.

And after all of that, finally, we've moved our code from First Draft to Second. We have built upon the bones of our draft and improved our code.

---

As with the last post, this post came out of a presentation I'm writing for [Rocky Mountain Ruby](http://rockymtnruby.com). I'd love to see you there! Tweet or email at me if you'll be at the conference or just want to hang out in Boulder.

Writing the presentation has curtailed my blogging and newsletter-ing a bit; sorry about that. You can read [previous newsletters](http://tinyletter.com/ianwhitney/archive), or [sign up for free](http://tinyletter.com/ianwhitney/). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/7).
