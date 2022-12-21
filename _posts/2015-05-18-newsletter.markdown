---
layout: post
title: "In which conditionals make a stealthy return"
date: 2015-05-18 12:35:35 -0600
author: Ian Whitney
---

Switch Statements

This week's code smell is another one that I've already talked about at great length: Switch Statements. I'm not sure why Fowler & Beck chose to call this smell Switch Statements as they could have gone with the simpler and more comprehensive name of **Conditionals**. Because that's all Switch Statements are -- a syntactically different way of writing an *if*.

```ruby
if obj.is_a?(Person)
  # do this
elsif obj.is_a?(Pet)
  # do that
else
  # do nothing
end

case obj.class
when Person
  # do this
when Pet
  # do that
else
  # do nothing
end
```

Same thing. There might be times where you prefer one syntax over another, but the underlying logic is the same. I almost never use case, mostly because I dislike the [suggested indentation](https://github.com/bbatsov/ruby-style-guide#indent-when-to-case). A little thing, I know, but true.

For whatever reason Fowler and Beck focus this smell on switch/case statements in code, without mentioning the similarity to all other conditional structures. Maybe they assumed their readers already knew that. Or maybe, like me, they just really dislike case indentation.

Their main complaint about switch statements is that of duplication. Once you find yourself writing a conditional, you'll probably write that exact same conditional elsewhere in your code. And whatever knowledge that conditional contains is now duplicating itself across your code base.

They don't mention the complexity that can come from conditionals, which is one of my main beefs with them. The mental cost involved in parsing through any non-trivial conditional statement should not be discounted. Nested `case` statements have been known to lead to temporary insanity. And bugs. Lots and lots of bugs.

The fix that Fowler and Beck suggest is the normal fix for conditionals: Polymorphism. I always find that word to be a roadblock, as it suggests the fix is more complex than it actually is. Let's hop into a concrete example that shows off the ease with which you can get rid of switch statements.

My team maintains a Rails app that uses single table inheritance. Simply put, we have a Fee model and models that inherit from Fee: Course, Tuition, Term. These three subclasses are concrete types of fees you might pay when taking classes at the University. The app is used to manage these fees, so it has lots of views for entry and display of different types of fees. The 'show.html.erb' file looks like this:

```erb
<% if fee.is_a?(Fee::Tuition) %>
  <!-- displaying Tuition fee data -->
<% elsif fee.is_a?(Fee::Term) %>
  <!-- displaying Term fee data -->
<% elsif fee.is_a?(Fee::Course) %>
  <!-- displaying Course fee data -->
<% else %>
  <!-- display nothing -->
<% end %>
```

Which, as already mentioned, is just a switch statement

```erb
<% 
case fee.class
when Fee::Tuition 
%>
  <!-- displaying Tuition fee data -->
<% 
when Fee::Term 
%>
  .... And so on
```

Replacing this code with polymorphism is a matter of letting the object inheritance do all the work. A simple first step is to add a method to Fee:

```ruby
class Fee < ActiveRecord::Base
  def partial_path
    "fees/#{self.class.to_s.demodulize}"
  end
end
```

This follows the convention of the [ActiveModel `to_partial_path` method](https://github.com/rails/rails/blob/dc8773b19f61af2ba818d66923fc65e17bad6c20/activemodel/lib/active_model/conversion.rb#L57). There's certainly an argument to be made against Fee knowing about the organization of the file system, but I think this is a fine place to start.

This method will return "fees/tuition" when called on a Tuition fee and "fees/course" for a Course fee. So we now move all of our fee templates into sub-folders. The Tuition 'show' code becomes the '\_show' partial in 'app/views/fees/tuition/', and so on.

Then change our 'show.html.erb' file in 'app/views/fees' to:

```erb
<%= render partial "#{@fee.partial_path}/show" %>
```

And our conditional is gone. Polymorphism in action.

Some non-polymorphic links:

I put out a call on Twitter for stress testing tools and got a bunch of good replies. [Apache AB](https://httpd.apache.org/docs/2.2/programs/ab.html), [Siege](http://linux.die.net/man/1/siege) and [JMeter](https://jmeter.apache.org/) all seemed totally up to the task, but I ended up using [loader.io](https://loader.io/) and it quickly gave me all the information I was looking for. Now I apparently need to learn a lot more about server configuration.

Speaking of performance, Justin Weiss wrote a nice article ["Speed up ActiveRecord with a little tweaking"](http://blog.codeship.com/speed-up-activerecord/) that has some great tips on, well, speeding up ActiveRecord. I'm especially looking forward to trying the [activerecord-import](https://github.com/zdennis/activerecord-import) gem in an app that does a huge amount of data importing.

I think I forgot a non-programming link in the last newsletter, so this time I'll give you two. First, I read [this metafilter post](http://www.metafilter.com/149570/CONFOUND-THOSE-DOVER-BOYS) about this [lesser-known Looney Tunes cartoon](https://www.youtube.com/watch?v=dpOPyjmB8SI). The cartoon wasn't my thing but by following the links I learned about [smears](http://animationsmears.tumblr.com/post/5219971074/dan-backslide-he-slides) and [multiples](http://animationsmears.tumblr.com/post/32329524865/the-dover-boys-at-pimento-university-1942), which I found super interesting. An aspect of cartoons that I had never noticed before.

Second, [No Thank You, Evil](https://www.kickstarter.com/projects/montecookgames/no-thank-you-evil-a-game-of-make-believe-for-famil), a Kickstarter for an improv/story/role playing game for kids, this one written by long-time RPG designer Monte Cook. I'm growing quite a collection of games like this (see also: [Happy Birthday, Robot](https://www.kickstarter.com/projects/danielsolis/happy-birthday-robot)) and am just waiting for my kid to be ready to play them.

A holiday weekend and a short trip means that there won't be a blog post next week. I'll be back on May 31st.

If there are changes/topics/etc. you'd like to see, please reply to this email, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/4).

Until next time, true receivers.
