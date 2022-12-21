---
layout: post
title: "Code Smells and Integration Tests"
date: 2015-06-15 12:35:35 -0600
author: Ian Whitney
---

Code Smells and Integration Tests

As is probably the case with most of you, I learned about testing by using Rails. So the first tests I wrote were Unit tests (rather, what Rails calls unit tests). Over the years I've moved to a faster, more isolated testing style than I learned in Rails. I definitely lean heavily towards the Mockist sensibility.

But I've recently become a fan of end-to-end integration tests. Something that tests a whole feature in the application, without any stubbing or mocking. In some cases, on projects that are simple enough, I've found that a small collection of end-to-end tests are almost all I need. And by small, I mean very small. And by simple, I mean very simple. As soon as a change leads to any sort of unexpected side effect, the code is too big to be covered by just integration tests.

However, my team has also found that integration tests can hide code complexity that will bite you come refactoring time. We had some code that looked kind of like this:

```
class Query
  def initialize(configuration)
    self.configuration = configuration
  end

  def run
    RawData.parse(
      request.results
    ).to_json
  end

  private

  def request
    RequestFactory.new(configuration)
  end
end
```

Seems simple enough. This code was only tested with integration tests. The tests passed, the code worked, no problems. While adding a new feature we realized the complexity was getting too high and decided it was time to add some unit tests. And all of our tests had boiler plate like this:

```
 request_double = instance_double("Request")
 results_double = Object.new
 parsed_double  = Object.new
 expect(RequestFactory).to receive(:new).with(configuration_double).and_return(request_double)
 allow(request_double).to receive(:results).and_return(results_double)
 expect(RawData).to receive(:parse).with(results_double).and_return(parsed_double)
 allow(parsed_double).to receive(:to_json).and_return("{}")
 expect(Query.new(configuration_double).run).to eq("{}")
```

1 test, 7 lines of mocking and stubbing collaborators. The above, I think, is why people develop a dour opinion of mocking. All we've done here is reproduce, laboriously, the implementation of our code.

If we ask, "Does the code work?" our integration tests say, "Yes!" But our unit tests look kind of panicked and avoid answering the question. Why did this code, which seems reasonable at first glance, get so hard to test? In order to see why, let's take those nice small methods and line them up to see what happens when we actually call `run`:

```
def run
  RawData.parse(RequestFactory.new(configuration).results).to_json
end
```

That makes the smell easier for me to see. We are clearly doing too much in this method. Furthermore, we're doing that work with dependencies that are hard to override in our tests. Everything is locked away, forcing us to stub and mock through the whole chain of method calls. As for how we fixed it, that's for another time. This newsletter is already too long.

But not too long for links!

Honestly, I'm not a big fan of Git rebasing. It just doesn't work for how my team uses commits. But it works for a lot of teams. So maybe you're interested in how to [automate your rebasing](https://robots.thoughtbot.com/autosquashing-git-commits).

Another Thoughtbot-created, Git-related post: [Implementing a Strong Code-Review Culture](https://www.youtube.com/watch?v=PJjmw9TRB7s) by Derek Prior (co host of [Bikeshed](http://bikeshed.fm/)), makes a lot of points that I, hopefully, have been making part of my code review practice.

[Improving your Craft with Static Analysis](http://www.infragistics.com/community/blogs/erikdietrich/archive/2015/05/18/improving-your-craft-with-static-analysis.aspx) is a post that I saw in Justin Weiss's Twitter. We've been using [Rubocop](https://github.com/bbatsov/rubocop) in some projects and I think it has helped. I've had to spend a fair amount of time tweaking the Rubocop config to match our style (single-quotes, Rubocop, really?), but I'm hopeful that the investment will pay off.

If there are changes/topics/etc. you'd like to see, please reply to this email, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/5).

Until next time, true receivers.
