---
layout: post
title: "Making OO theories concrete"
date: 2015-01-22 12:35:35 -0600
author: Ian Whitney
---

This week's post was all about the [Open/Closed Principle](http://designisrefactoring.com/2015/01/19/introducing-the-open-closed-principle/). Like a lot of OO principles, Open/Closed is something that most programmers have heard of but that remains a fuzzy theory. It's there in a mental attic with Liskov, Dependency Injection and the Template pattern.

The problem, I think, is that it is difficult to think of our code in theoretical terms. It's not theoretical at all. It's so concrete that we have full-time jobs that involve changing it constantly. So when we implement a new feature and it is hard, we don't usually think, "This is hard because this code violates Liskov." Or, conversely, when it's easy, we don't think "Open/Closed Principle saves the day!"

If you practice coding with these principles in mind then they become less theoretical and you can see the benefits they bring. Or don't bring, as the case may be. <a href="https://en.wikipedia.org/wiki/Kata_(programming)">Kata</a> are a perfect place to practice implementing these principles in concrete code. A good kata is hard enough to make you work, but yet still simple enough that you can focus on testing a single technique.

My first stop for kata is [http://exercism.io/](http://exercism.io/), which is probably not a surprise. I link to that site at least once a week. But they have done an excellent job of providing a wide range of programming problems in a huge variety of languages.

But, regardless of what kata you try or where you get it, you should give yourself a goal beyond just getting the code to work. Maybe you want to really practice writing code that follows OCP. Or maybe you want to try [East Orientation](http://saturnflyer.com/blog/jim/2014/12/23/enforcing-encapsulation-with-east-oriented-code/). Or trying the limitations you might see at a [Code Retreat](http://coderetreat.org/facilitating/activity-catalog). Just like you need to [refactor with intention](http://designisrefactoring.com/2015/01/11/the-why-of-squares/), you should also practice with intention.

Link time!

[Just use double-quoted strings](http://viget.com/extend/just-use-double-quoted-ruby-strings). String quotes have been a weird bone of contention in Ruby for a surprisingly long time. I settled on double-quotes a while ago, mostly because I got sick of having to change single quotes to doubles when I needed to do string interpolation. If your app is slow, it is not because of your string quotes.

[Code Reviews at Harvest](http://techtime.getharvest.com/blog/code-reviews-at-harvest). Another link about this excellent process. A lot of people have been talking about PRs lately, for some reason. Harvest's approach is more formal than my team's, which makes sense considering their size.

Last week's food shout-out was for animal fats. This week I'll go the opposite direction and pick vegan recipes from Isa Chandra Moskowitz, especially the recipes that use star anise, like [this one](http://www.vegkitchen.com/recipes/curried-peanut-sauce-bowl-with-tofu-kale/). Star anise smells amazing and tastes even better.

Next week's post on Design is Refactoring will be a continuation of the Open/Closed Principle. This time applied to a problem from Exercism. It gives a whole new meaning to contrived code, but I think it will be fun.
