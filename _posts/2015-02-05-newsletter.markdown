---
layout: post
title: "How Long is a Method?"
date: 2015-02-05 12:35:35 -0600
author: Ian Whitney
---

How Long is a Method?

Next up in the Catalog of Smells is **Long Method**, which would seem to be straightforward enough but leads to a surprising amount of bickering. Let's start with the Fowler & Beck definition:

> The object programs that live best and longest are those with short methods...the longer a procedure is, the harder it is to understand...whenever we feel the need to comment something, we write a method instead...they key here is not method length but the semantic difference between what the method does and how it does it.

So in their own definition, Fowler and Beck kind of discard their own name. Yes, the smell is called Long Method, but the "key is not method length." But by calling it Long Method they started 16 years of people asking the same question, "Exactly how many lines is too long? 7? It's 7, right?"

It's like they accidentally wrote the setup to a joke from the '70s TV show Match Game.

Gene Rayburn: My Uncle Method is so long&hellip;<br />
Audience: HOW LONG IS HE?

Sandi Metz has felt the heat of this question as well. Eventually enough people asked her that she, reluctantly, came up with [a set of 'rules'](http://robots.thoughtbot.com/sandi-metz-rules-for-developers). Mostly (if I recall the [episode of Ruby Rogues](http://devchat.tv/ruby-rogues/087-rr-book-clubpractical-object-oriented-design-in-ruby-with-sandi-metz) correctly) to stop people from asking her the question.

Most of the answers I've heard to the question of "how long is too long?" lie somewhere between 3 and 7. Depends on who you ask.

But if, as Fowler and Beck suggest, length is not the definition of a Long Method, then how do we define a Long Method smell?

Let's take a look at some methods that meet the 3-7 line 'standard' and decide if they are appropriately small.

I don't count the syntactic boilerplate, so this is just 3 lines
```ruby
def withdraw(amount)
  if amount <= balance && balance_is_positive && account_in_good_standing && cash_on_hand && (amount < daily_withdrawl_limit || daily_withdrawl_limit_overridden)
    balance = (balance - amount)
  end
end
```

And here's a 1-liner. 5, if you expand the ternary to an if/then
```ruby
def transform(transform_type)
  transform_type == 7 ? :inverse : :obverse
end
```

And another one liner
```ruby
def final_profit(gross)
  ((gross * 2) / conversion_factor) - necessary_bribes - (etsy_fees * 1.3) + (incoming_bribes - (gross * skim))
end
```

If we go by line count, none of these methods are long. But do you think that any of them pass the heuristics suggested by Fowler & Beck?

- Don't need comments to explain what's going on
- Distance between method's intent and implementation is small

In the `withdraw` method, I don't feel like a comment is necessary. All the various booleans it checking are clearly named. But the distance my mind has to travel to get from the start of that if statement to the actual implementation is huge.

The `transform` method's implementation is direct, but I have no sense of intent. Comments to explain these magic numbers and vague symbols seems necessary.

`final_profit` has a bunch of clearly named modifiers, but a confusing implementation. I can not keep all of that in my head.

You can't judge a Long Method by the space it takes on the screen. You have to judge by how much space it takes up _in your head_.

Links!

Towards the end of [this week's post on the Single Responsibility Principle](http://designisrefactoring.com/2015/02/01/robot-you-have-one-job/) I made an observation about how your testing framework will influence your implementation. This [article on strict MiniTest mocking](http://www.jefferydurand.com/ruby/rails/testing/minitest/poro/mock_stub/2014/11/22/poro-mock-stub.html) shows a simple example of using mocks in a testing framework that isn't super-supportive of mocking.

Aaron 'Tenderlove' Patterson did a nice write-up of his experience [with MiniTest and Rspec](http://tenderlovemaking.com/2015/01/23/my-experience-with-minitest-and-rspec.html). He doesn't really get into mocks and stubs, which are the meat of the matter for me. But he has a lot of great observations about 'magic' and test refactoring.

If you have a membership to the Ruby Rogues Parley, there has been a [good discussion of Aaron's post](http://parley.rubyrogues.com/t/tenderloves-take-on-rspec-vs-minitest/3020). And if you don't have a membership, might I suggest spending some time listening to the [Ruby Rogues](http://devchat.tv/ruby-rogues/). After poring through their back catalog, maybe you'll want to join Parley. It's a bargain at $10 a year.

For the non-code link of the week, I'll share the TV show that helped me survive my 3 days of viral strep, [The Venture Bros.](http://www.adultswim.com/videos/the-venture-bros). Not just my favorite animated show, _Venture Bros_ is my favorite show. I rewatch the whole series from time to time and am always delighted. Seasons one and two are on Netflix, you can probably find everything else on YouTube. Like the similarly detail-oriented _Arrested Development_ it can be a baffling show if you haven't watched the earlier episodes, so I suggest starting from the beginning.

It seems likely that next week's Design is Refactoring post will actually be about polymorphism! But, as always, I won't know until I get around to writing the thing.
