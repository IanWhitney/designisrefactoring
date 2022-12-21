---
layout: post
title: "Code Smells and Integration Tests, Pt. 2"
date: 2015-06-29 12:35:35 -0600
author: Ian Whitney
---

Code Smells and Integration Tests, Pt. 2

In the last newsletter, I talked about how an integration test hid some nasty code complexity that surprised us when we decided to add some unit tests.

Later, my friend and follow Minnesota Rubyist Tony Collen pointed out that [my tests were "missing something"](https://twitter.com/tcollen/status/610815792775475201) and suggested I talk about "why the integration test is brittle that way."

Tony may be asking me to answer a more specific point but I'm going to treat his question as a general one: how did that integration test hide so many problems?

The answer, for me, is not a technical one, rather it is one of process. It is about knowing what your tests provide, and what they take away.

But first, a quick terminology shift. What I've been calling an 'integration' test is probably better referred to as a 'feature' test. The line between the two is fuzzy, but I'd describe a feature test as one that tests the behavior of a single feature in the whole application stack. A integration test can be narrower, exercising the collaboration between two (or more) components of your application, or between your application and an external system.

Feature tests work at the outer edge of your application, and their goal is to make sure only that your application works. They, very intentionally, do not know *how* your application works. They can tell you almost nothing about the design because they know nothing about your code beyond its outer edge.

Feature tests are obviously hugely useful. Who doesn't want to know that their application works? But, by focusing on them, you lose the ability to improve your application's design.

This is the process problem we had with our code. We had written this part of it with only feature-test coverage; a combination of feature and unit tests, with the feature tests proving that things work and the unit tests driving design, would have resulted in better code.

Let's take a simple example and develop it both ways. We want code to retrieve a CSV file from a URL and then tell us how many columns it has. In both of our approaches we start with a feature test.

```
it "gets a csv from url and tells me how many columns" do
  test_file_path = "localhost:3000/fixtures/test.csv"
  expect(FileInfo.new(test_file_path).column_count).to eq(70)
end
```

In our Feature-Only approach, we then implement the code and our only goal is to get this test passing. We do so\*:

```
class FileInfo
  def new(uri)
    self.uri = uri
    get_file
  end

  def column_count
    file.first.headers.count
  end

  private

  attr_reader :uri, :file

  def uri=(x)
    @uri = URI.parse(x)
  end

  def get_file
    @file = CSV.parse(uri.read, headers: true)
  end
end
```

Our test green, we move on.

In the Feature and Unit approach, we start writing unit tests for FileInfo and design problems become apparent immediately. Oh, I need to mock out the File class just to get my test working? Problem. And CSV? Double problem. There are multiple ways of solving these problems and the fix you pick isn't relevant to this example. What matters is that the design of your code is improving because unit tests force you to confront your own design.

In the Feature-Only approach these design problems are hidden from you, waiting to spring out and slow you down when you go back to implement that 'one simple change'

That may not be what Tony was looking for, but that's what I've got for you on this vacation-shortened week. Want me to tackle a different aspect of brittle tests and design? Or how I'd refactor the above code to a better design? Reply to this email, or look at the final line of the newsletter for various ways of contacting me.

\* Yes, there are many better ways of doing this.

A collection of time-wasting links

I'm just returning from a week of vacation, so my links have nothing to do with code. We all need time off.

The first one may only be of use to those of you who live in or near Duluth, but if you do consider yourself lucky. You can eat at the [Northern Waters Smoke Haus](http://www.northernwaterssmokehaus.com). Yes, they do mail-order, but only of their (very delicious) smoked meats. What they won't deliver are their amazing sandwiches. I particularly loved the Sitka Sushi, though everything we tried (and we tried a lot) was fantastic.

Second, I spent a lot of my free evenings playing [Invisible, Inc.](http://www.invisibleincgame.com) a turn-based game of stealth and cyber-espionage. I am straight-up terrible at this game, but I still enjoy it. Thankfully, it accommodates my utter lack of skill by offering fine-grained control over the game's difficulty and by rewarding my frequent failures with new characters and abilities. It's the rare very hard game that is still welcoming to new players.

Third, I find it hard to believe that I have not linked to [The Flop House](http://www.flophousepodcast.com), my favorite podcast. Every two weeks three friends (two of whom write for the Daily Show) watch a bad movie and then talk about it. Bad movie podcasts are a dime a dozen, but The Flop House has been at it for longer than most and their charming banter combined with their frequent insane digressions (such as [Cat on a Hot TinTin Roof](https://www.youtube.com/watch?v=qqxwgRHp07o)) put it at the top of my podcast list.

Fourth, [The Secret History of Hollywood](http://www.attaboyclarence.com/the-secret-history-of-hollywood/) podcast is for the more obsessive movie fan. Alex's episode on Universal horror films runs an iPod-busting 7 hours. But what a wonderful, entertaining 7 hours they are (or I think they are, I'm only about 3 hours in). The effort and care that goes into this show is evident and I'm really enjoying it.

If there are changes/topics/etc. you'd like to see, please reply to this email, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/6).

Until next time, true receivers.
