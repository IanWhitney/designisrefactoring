---
layout: post
title: "Closures in Ruby"
description: ""
category: 
tags: []
---
I've been working my way through [a presentation](http://innig.net/software/ruby/closures-in-ruby) that my friend [Paul Cantrell](https://github.com/pcantrell) made to [Ruby.MN](http://ruby.mn/) a few years ago. It's a great run-down of closures/blocks/procs/lambdas in Ruby. What are the differences between them, how do they work, what are the pitfalls, etc.

<!--more-->

He concludes by writing a lisp-like Fibonacci generator which introduced
me to this great piece of syntax:

    >> a = [1,[2,[3]]]
    >> car,cdr = a
    >> car
      => 1
    >> cdr
      => [2,[3]]
    >> a
      => [1,[2,[3]]]

That was new to me. I would have written it more verbosely:

    >> car = a.shift
    >> cdr = a
    >> car
      => 1
    >> cdr
      => [2,[3]]
    >> a
      => [2,[3]]

But I probably would have ended up cloning `a`, since shift would alter
it. Paul's approach leaves `a` untouched.

I recommend reading through Paul's presentation. It's enlightening. He
highlights several weird things in Ruby 1.8.7, but since you shouldn't
be using 1.8.7, those are mostly historical curiosities. I've run the
code with both 1.9.3 and 2.0.0 and their output is exactly the same.
    
