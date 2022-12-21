---
layout: post
title: "Exercism.io nitpicking, introduction"
date: 2014-05-28 08:23:15 -0500
comments: true
categories: 
---
You may be familiar with [exercism.io](http://exercism.io/). If not, they do a pretty good job of describing their goals:

> Exercism provides a space to think deeply about simple, expressive, and readable code, and experiment and discuss what good looks like.

After joining, you can pick what languages you want to work in. Then you get exercises in those languages, usually just a Readme and a test suite. Then you implement code that passes the tests. When you finish coding, you push your files to Exercism and people who have done the same exercise get to 'nitpick' your work. Again, Exercism does a great job explaining [how to nitpick](http://exercism.io/help/nitpick)

Nitpicking is the killer feature of Exercsim. In most cases the exercises are not brain-busting challenges. If you want those, check out [Euler](https://projecteuler.net/problem=465). The problems are simple enough that I can get the Ruby ones passing in a short amount of time -- though this was not true of the Elixir problems, as I barely know Elixir. The goal of Exercism is not to prove what a great coder you are, but to try to make you a more 'expressive and readable' coder.

And, of course, your code is always expressive and readable to you, right? You're the one that wrote it, so I would hope that you know what it's doing. But when you get a nitpick that asks why you'e doing some crazy RegEx expression when you could just use `downcase`, that's when you learn. On the flip side, nitpicking the exercises of others is illuminating. First, it helps me learn the difficult skill of providing constructive feedback instead of just saying "No, do it this way." And I learn quite a bit from other programmers' implementations. Like the `chars` method. Didn't even know this existed.

```ruby
"xyz".chars
#=> ['x','y','z']
```

Neat!

The power of nitpicking makes it all the more frustrating that no one does it. There are reasons for that, highest probably being:

- Most programmers like writing code more than reviewing someone else's code.
- Most solutions are really similar, making nitpicking kind of repetitive.
- Exercism allows people to go to the next exercise before nitpicking or being nitpicked.

I know that Katrina is aware of this problem and trying to solve it, but it's tricky. The current default solution would be to 'gamify' it, which I jokingly suggested to her. This joke did not go over well. So don't expect "Exercism achiement unlocked!" badges any time soon.

I'm trying to help by doing some nitpicking as I have free time. Another approach I'm going to try is to nitpick my code (alongside the most common solutions) right here on my site. This will let me go a little more in depth.
