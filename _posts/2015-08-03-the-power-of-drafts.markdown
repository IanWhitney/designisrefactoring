---
layout: post
title: "The Power of Drafts"
date: 2015-08-03T19:46:41-05:00
author: Ian Whitney
---

How do you write code? I'm not asking about text editor, language or keyboard layout. I'm talking more about your process. Do you write a bunch of perfect code all at once? Or do you write some terrible code, which you rewrite into less-terrible code?

<!--break-->

I suspect that it's the latter. That's what I do, at least.  My process usually goes something like:

1. Start with a vague idea
2. Write some awful, ugly code
3. Use the knowledge I gained in step two to write some slightly better code
4. Repeat...forever

But a lot of blogs, books, videos, etc. presented code as a finished product, a fait accompli. A blog post about how to implement the Strategy pattern shows you a finished implementation. That book you bought about using Redis shows a finished Redis client. Maybe, sometimes, some examples of bad code are included, a quick guidepost pointing you away from one approach or another. But only rarely do you see the whole embarrassing-but-educational trudge from ugly code to something vaguely presentable.

It's easy to assume that the programmers behind these books/blogs/etc. are simply **better** than us. Gifted with the ability to write beautiful code without endless rewriting, to produce code that is *finished*. I know, and you hopefully know, that this is nonsense. But in case you're not sure, here's some sage insight from Ernest Hemingway.

> The first draft of anything is shit

This is a coarser way of phrasing the writers' mantra:

> Writing is Rewriting

Programming being 90% writing (and 10% arguing about text editors), it must follow the same rule, right? Naturally. I can attest that any code you see on this site, or in any of my repos, has been edited/re-edited/re-re-edited over and over. And most of it is still terrible.

But programming differs from writing in many ways, first of which is that we, unlike writers, can easily revisit and share all of our previous drafts.

Writers may have access to all of their rough drafts, but they almost never share them. Programmers, thanks to source control, are uniquely positioned to share their drafts. But if writers keep their rough drafts private, why should we share ours? If the programming books we read only talk about final product, and our customers only talk about final product, then what value is there in the code we have overwritten?

Well, for a start:

## We reveal our learning processes

As I become more familiar with a problem, my code changes to reflect that knowledge. By only sharing your 'finished' code, you can say "Look at this cool thing!", but by sharing your drafts you can say "Look at what I've learned!" I find that to be more rewarding to say and to read about.

## An open admission of our humanity

The Programmer-As-Rockstar nonsense is built on the myth of some coder writing a ton of perfect code the first time. To hell with that. Show off your mistakes, your bad code, your misunderstandings to reclaim the idea that programmers are nothing more than human.

## Help others learn

If you share a spectrum of flawed solutions to a problem, different solutions will resonate with different readers. One person will say, "Hey, my code looks like step 3!" and another will see their own work in step 4. And so on. More people can place themselves on the path that you have trod and see what lays ahead of and behind them.

And that path is neverending. Unlike books, most software has no final draft. If it is running, it is changing. It will never be finished. It will never be 'right'. You're always deploying a draft. Every time you learn more about what the code needs to do, you refactor it into a new draft, to a 'better' design that reflect what the code needs to be...for now.

In the next couple of blog posts I'll likely dive a little deeper into this topic. If you can attend [Rocky Mountain Ruby](http://rockymtnruby.com) this September 23-25, you can see me delivering a presentation on drafts, refactoring and design. I'm super excited, and only slightly terrified.

If you want to see more code in your coding blog, maybe check out the [free newsletter](http://tinyletter.com/ianwhitney/) where I'll soon be looking at Outside In vs Inside Out development and the effect it has on your code and tests. Check out [previous issues](http://tinyletter.com/ianwhitney/archive) for even more codez. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/6).
