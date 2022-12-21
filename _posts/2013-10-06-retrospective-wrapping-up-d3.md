---
layout: post
title: "Visualization Retrospective: Wrapping up D3"
description: "A brief discussion of wrapping the D3 library in a
namespaced JavaScript module"
category: 
tags: []
---
We just wrapped up a project that featured several patterns I'm very
interested in:

- Client-generated visualizations
- Ember.js
- Rails as a API-only, no views

<!--more-->

The goal of the project was to release a tool that would let those who
schedule college classes see when other classes are being scheduled. The
schedulers could then use that data to schedule classes that confilct
with as few other classes as possible.

As the application ended up being 3 fairly distinct layers, I'm going to
split up these retrospective posts similarly. I'll start with the code I
worked on the most, the visualization library.

### Starting with D3

Once we got the client to agree that IE8 would not be supported, using
[D3](http://d3js.org) as our visualization tool made perfect sense. It's
powerful, fast and widely used. If we'd had to support IE8 than we would
have had to look elsewhere, as D3 generates SVG graphics, which are
unsupported by IE8.

I got the task of prototyping visualizations in D3 and learning its
syntax, as none of us had used it before. I quickly settled on using a
heat-map visualization, like [this
one](http://bl.ocks.org/tjdecke/5558084).

D3 syntax can be challenging when you first come to it, but I found it
easier to focus on learning about just this one visualization: how is it
generated, what parameters does it take, how can I maniuplate it. There
are a ton of D3 features, 90% of which I didn't need for this project.
So by focusing on the features I did need, I made the learning curve
more manageable.

Soon enough I had a [demonstration visualization](https://github.umn.edu/whit0694/le_heatmap_demo/raw/master/examples/example.png) that got buy in from the team. It was far from perfect, but it showed us the way.

### Wrapping It

As the heat map code developed, I began to think about how the web
application, which was being written in Ember, would interact with it.
Most projects we found simply have Ember directly interact with D3. But I decided to avoid that for a couple of reasons:

- The visualization would likely be reused in other applications
- Decreasing coupling would allow us to switch visualization libraries
  in case D3 isn't what we want.

So, the goal became to wrap the visualization creation and update code with
an API. It would accept a data structure and some configuration options
and totally hide D3 from Ember.

This gave me an added benefit, testability. I didn't want to test D3,
because all I'd be doing is asserting that D3 works as advertised,
something its own test suite should be doing. But testing a wrapper made
sense, and those tests would serve as documentation of how the
visualization api worked.

This sort of modular JavaScript approach is new to me, so it took some
reasearch. [Learning JavaScript Design Patterns](http://addyosmani.com/resources/essentialjsdesignpatterns/book/) was a huge (and free) help to me, especially the section on the [Revealing Module Pattern](http://addyosmani.com/resources/essentialjsdesignpatterns/book/#revealingmodulepatternjavascript), which is more or less what I followed.

Testing was done in [Jasmine](http://pivotal.github.io/jasmine/) which
was ok. I don't care for how it handles test doubles (or 'spies' as it
calls them). I found the syntax for mocking and expectations to be
particularly weird. But it is fast and it integrated well with the code
I was working on. I want to try other testing frameworks to see if the
syntax is easier to wrangle. But maybe that syntax problem is intrinsic
to JavaScript.

### The Final Product

And at the end of this I ended up with a modular visualization library that is
totally separate from Ember and ready to be dropped into any project
that might need it.\* All the project needs to know about are three simple
methods:

    viz = Visualization.HeatMap.new(dom_node, [data objects], {configuration});
    viz.update([data objects]);
    viz.destroy();

The final visualization came a long way from my early demo:

  ![Visualization Demo](/assets/images/final_heat_map.png)

And from that you can pretty easily see what you'd expect to see,
college classes clustered around the prime times of Tuesday/Thursday and
no one taking classes on Friday.

And that's it. Well, almost. It turns out that integrating all of this
with Ember is tricker than you'd think. But that's another post.

\* I want to put more code in this retrospective and link to the final
project on GitHub, but as of right now it is not public. Once I can make
it public, I'll share the code here.
