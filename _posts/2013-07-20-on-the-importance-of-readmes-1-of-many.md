---
layout: post
title: "On the importance of Readmes (1 of many)"
description: ""
category: 
tags: []
---
Earlier this week I was trying to get an [Ember site](https://github.com/IanWhitney/flophouse_ember) to pull data from a
[Rails site](http://theflophouserecommends.herokuapp.com/) via JSON. This meant I got to learn all about JSONP, which
was interesting enough, but not the point of this post.

<!--more-->

I needed to get my Rails site to serve stuff up in JSONP, so I did what
I always do, go to [rubygems](http://rubygems.org/) and start searching.
The most downloaded gem was [rack-jsonp](https://github.com/crohr/rack-jsonp), which has [this for its
readme](https://github.com/crohr/rack-jsonp/blob/5ae95ef45090bc2db38de460b16caec0bffaed9c/README.rdoc)

So I used a different gem. Here's [its readme](https://github.com/robertodecurnex/rack-jsonp-middleware/blob/4edc3d5026851e3a7fd578db2d0d84fd43ebced5/README.md). It even has a [github.io page](http://robertodecurnex.github.io/rack-jsonp-middleware/) that's just the readme, but with some fancier styling.

The readme isn't a work of art anything, but it exists. And it tells me
what I need to know:

- How to configure the gem
- How to get a JSONP response

I'm sure the other gem is great and simple to use, etc. etc.. But one gem author
took 10 minutes to write the Readme and another didn't. Which one of
these would you want to use?
