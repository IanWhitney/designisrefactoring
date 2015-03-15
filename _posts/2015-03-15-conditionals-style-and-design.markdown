---
layout: post
title: "Conditionals: Style and Design"
date: 2015-03-15T10:17:43-05:00
---

Wow! Last week's post got quite a lot of attention. [Ruby Weekly](http://rubyweekly.com/issues/237), a long comment thread on [my Gist](https://gist.github.com/IanWhitney/5e2f3ff7099768f3cf40), numerous Twitter conversations, [2 threads](http://www.reddit.com/r/ruby/comments/2ywf6p/refactoring_away_a_conditional/) [on Reddit](http://www.reddit.com/r/ruby/comments/2yv2le/refactoring_away_a_conditional/) and who knows what else. Considering that I do the bare minimum of publicity for this site, it was all quite surprising.

Many readers shared their opinions on the code, both positive and negative. This is fantastic! Agree with me or not, I love that people not only spent the time reading my article, but that they also spent the time thinking about their own code and how they want it to look. I can't help but be happy about that.

This week I want to continue the conversation by discussing the criticisms and alternatives that people provided. Along the way, maybe I'll say something interesting about the difference between Design and Style.

<!--break-->

**Point 1: Conditionals are Fine**

This was brought up more than once, but I first heard it from [Ryan McGeary](https://gist.github.com/rmm5t/cf74958eb839b1403ad4). As a universal statement, I can't agree with the idea that conditionals are not bad. I've spent too much time debugging conditionals. But saying "All Conditionals Are Bad" is probably just as unfair. Conditionals can certainly attract problems, but that doesn't mean they always do. Let's take two examples of the same conditional.

{% highlight ruby %}
def take_damage(damage)
  life -= damage

  if alive?
    puts "Whew, you survived!"
  else
    puts "Game Over"
  end
end
{% endhighlight %}

Imagine this code in two games. The first, DeathChamp, is a super-hard rogue-like only allows a player to be living or dead. The second, Am I Dead, is an art-game exploration of the afterlife, has many states for a player before and after death. They can be shades, poltergeists, zombies, etc.

In DeathChamp our example conditional will probably never change. But in Am I Dead it could quickly balloon to look like this:

{% highlight ruby %}
def take_damage(damage)
  life -= damage

  if alive?
    if near_death?
      puts "The spirits are gathering near you"
    elsif has_died_before?
      #etc
      #etc
      #etc
  else
    if has_zombie_amulet?
      #etc
      #etc
      #etc
  end
end
{% endhighlight %}

As always, the argument for or against a technique comes down to, "It depends." You want your best designed code to be in the parts of your application that change the most. If you have a conditional that will change a lot, it will cause you problems. Get rid of it. But, if you have a conditional that will never change then you almost certainly have better things to do with your time than refactor it away.

A mistake I made in last week's post was to not clearly state the sorts of change that I expected Bob to undergo. If, for example, I had a system that would only ever support Yelling, Questioning and Silent statements, then my conditional would be fine. But I knew that I wanted Bob to be able to easily respond to new kinds of statements and that my conditional would soon become unwieldy. However, I did not make that clear in my post.

**Point 1.5: Use a Case Statement**

This might be obvious to everyone but I think it was only last year that I realized, "Hey, case statements and if statements are the same thing!" Everyone else knows this. And a few people, such as [Jacques Fuentes](https://twitter.com/jpfuentes2/status/576095846913159168), suggested that Bob's original code would be better if I converted the If statement to a Case statement. Let's see what that looks like:

{% highlight ruby %}
  def reply_to(statement)
    case
    when statement.strip.empty?
      "Fine. Be that way!"
    when statement.upcase == statement && statement.downcase != statement
      "Woah, chill out!"
    when statement.end_with?("?")
      "Sure."
    else
      "Whatever."
    end
  end
{% endhighlight %}

And, now that I've clarified that we want Bob to be able to respond to more kinds of statements, let's see how we'd implement a Whisper statement with a Case.

{% highlight ruby %}
  def reply_to(statement)
    case
    #.... unchanged
    when statement.downcase == statement && statement.upcase != statement
      "Why are you talking so quietly?"
    else
      "Whatever."
    end
  end
{% endhighlight %}

Implementing that with an If statement would look exactly the same. The only difference is a `when` instead of an `elsif`.

In terms of **design** these solutions are identical. My definition of code design is the arranging of code so that it remains easy to extend, fix and maintain. If adding a new feature in two code bases requires identical steps, those code bases have an identical design.

Refactoring changes the design of your code, hopefully for the better. Since moving from If to Case didn't change our design, we can not call it a refactoring. So what is it? It is a change of **style**.

Style is all the choices we make in our code either because they are pleasing or because we find that it makes our code nicer. Style is important. It's why I don't use a ternary in one method, a Case in the next method and an If in the third method. That is bad style. But in terms of design, those three implementations are the same.

This distinction between **design** and **style** is important, though it can be blurry. The important thing to keep in mind is that 'refactoring' is specifically a change to the code's design. Other changes can be important and good, but they aren't a refactoring.

**Point 2: Too many classes, too much class knowledge**

Speaking of style, I think my programming style leads to a lot of classes. Not everyone likes this! Some people are [blunt](http://www.reddit.com/r/ruby/comments/2ywf6p/refactoring_away_a_conditional/cpdqf80), while others are [thoughtful and constructive](https://gist.github.com/IanWhitney/5e2f3ff7099768f3cf40#comment-1412217). You can guess which one I prefer!

More than one person pointed out that my many-class solution required Bob to 'know' about these classes. By using class names in his `reply_to` method, and by having a method named `respond_to_yelling`, Bob has knowledge that a Yelling class exists. And that knowledge limits him in certain ways. Imagine this new feature:

1. Add a new kind of statement, YellingQuestion.
2. Bob responds to this kind of statement with "Woah, chill out!" Same as if the statement was yelled.
3. Bob's sister, Charlene, has different answers for Yelling and YellingQuestion.

And now Bob has two methods, `respond_to_yelling` and `respond_to_yellingquestion` that have an identical implementation. This doesn't seem ideal. Yes, we can use `alias_method` but is that actually an improvement?

[Ariel Caplan's raised the flag](https://twitter.com/amcaplan/status/576363855594414080) about this class knowledge, and my proliferation of classes. Not only that, he took the time to write out an implementation he preferred, which I'll summarize here. I recommend reading through [his full comment](https://gist.github.com/IanWhitney/5e2f3ff7099768f3cf40#comment-1412217).

{% highlight ruby %}
class Bob
  REPLIES = Hash.new("Whatever.").merge!(
    silence: 'Fine. Be that way!',
    yelling: 'Woah, chill out!',
    question: 'Sure.'
  )

  def reply_to(statement)
    REPLIES[statement.type]
  end 
end

Statement = Struct.new(:type, :statement)

class StatementFactory
  STATEMENT_TYPES = {
    silence: -> (phrase) { phrase.strip.empty? },
    yelling: -> (phrase) { phrase.upcase == phrase && phrase.downcase != phrase },
    question: -> (phrase) { phrase.end_with?('?') }
  }

  def self.build_statement(phrase)
    Statement.new(type_for_statement(phrase), phrase)
  end

  def self.type_for_statement(phrase)
    STATEMENT_TYPES.each_key.find { |type|
      STATEMENT_TYPES[type].call(phrase)
    }
  end
end
{% endhighlight %}

Let's try the same thing we did with the Case statement and implement the same feature in Ariel's code and my own. In my code, implementing the YellingQuestion just for Bob would be:

{% highlight ruby %}
class YellingQuestion < Statement
  def self.match?(statement)
    statement.upcase == statement && 
    statement.downcase != statement &&
    statement.end_with?("?")
  end
end 

class Bob
  #...
   def reply_to_yellingquestion
    "Woah, chill out!"
    end
  end
end 

class Statements
  def self.all
    [YellingQuestion, Question, Yelling, Silence, NullStatement]
  end
end 
{% endhighlight %}

And with Ariel's code

{% highlight ruby %}
class Bob
  REPLIES = Hash.new("Whatever.").merge!(
    yelling_question: 'Woah, chill out!',
    silence: 'Fine. Be that way!',
    yelling: 'Woah, chill out!',
    question: 'Sure.'
  )
  #...
end

class StatementFactory
  STATEMENT_TYPES = {
    yelling_question: -> (phrase) { phrase.upcase == phrase && phrase.downcase != phrase && phrase.end_with?('?') },
    silence: -> (phrase) { phrase.strip.empty? },
    yelling: -> (phrase) { phrase.upcase == phrase && phrase.downcase != phrase },
    question: -> (phrase) { phrase.end_with?('?') }
  }
  #...
end
{% endhighlight %}

In both solutions we have do do three things:

1. Tell Bob about a concept of yelling_question, and how to respond to it
2. Add yelling_question to a collection of Statements
3. Define how to identify a yelling_question

If the same feature takes the same steps to implement in two different code basis do we actually have different designs? Maybe not. Maybe these two solutions are of different styles. Where I use classes, Ariel uses lambdas, but the end result might actually be the same.

**Point 3: Relying on Class names is bad, as is metaprogramming**

[John Reese](https://twitter.com/RockyTheRanger/status/576524876074389504) focused on the shared knowledge of class names and suggested I look at the Visitor pattern. Others didn't like the metaprogramming of using class names to handle method name generation. I never liked my approach of method calling via class names but I didn't know a better way to do it. After digging into Visitor for a bit I found [this article by Aaron "Tenderlove" Patterson from in 2009](http://blog.rubybestpractices.com/posts/aaronp/001_double_dispatch_dance.html). 2009! I still wrote a surprising amount of classic VBScript in 2009, but Tenderlove was already laying down awesome Ruby knowledge. Thanks, Tenderlove!

Following his example of double dispatch, Bob and friends now look like this:

{% highlight ruby %}
class Bob
  def reply_to(statement)
    statement.reply(self)
  rescue
    default_reply
  end

  def reply_to_question
    "Sure."
  end
  #...
end

class Question < Statement
  #...

  def reply(recipient)
    recipient.reply_to_question
  end
end
{% endhighlight %}

This has some advantages. Bob no longer has to know that he's dealing with class names, and we can write statements classes that have different behaviors, but that generate the same reply. Such as:

{% highlight ruby %}
class Query < Statement
  #... some query-specific behavior

  def reply(recipient)
    recipient.reply_to_question
  end
end

class Interrogation < Statement
  #... some interrogation-specific behavior

  def reply(recipient)
    recipient.reply_to_question
  end
end
{% endhighlight %}

I can see that being a definite improvement, and leading to even better changes later. I have put [the full code in a new gist](https://gist.github.com/IanWhitney/5e2f3ff7099768f3cf40). Let's apply the YellingQuestion feature and see if we've actually changed the design of this code:

{% highlight ruby %}
class YellingQuestion < Statement
  def self.match?(statement)
    statement.upcase == statement && 
    statement.downcase != statement &&
    statement.end_with?("?")
  end

  def reply(recipient)
    recipient.reply_to_yelling_question
  end
end 

class Bob
  #...
   def reply_to_yelling_question
    "Woah, chill out!"
    end
  end
end 

class Statements
  def self.all
    [YellingQuestion, Question, Yelling, Silence, NullStatement]
  end
end 
{% endhighlight %}

Wait! Other than the new `reply` method in YellingQuestion, that's the exact same code as before. Has using double dispatch even changed the design of our code? Not as far as implementing YellingQuestion goes, apparently. Though, as I showed above, it would be a design change if we were implementing Query and Interrogation. This is how fuzzy the line between Design and Style can be; it all depends on what you're implementing. Regardless, I do find double dispatch to be a definite improvement.

I don't doubt that you have insightful and interesting things to say about this code, but I can promise that my next blog post will *not* be about Bob. I'm done thinking about Bob for now!

Speaking of the next blog post, I'm going to alter my publication schedule. Up until now I have tried to do a blog post and a newsletter each week. That has turned out to be too much. I'm going to try alternating blog posts and newsletters, so there will only be one of each per week. Newsletters will continue to focus on the Code Smells in _Refactoring_, while blog posts will continue to be about refactoring/design/rambly ramblings/etc. If you've subscribed to the newsletter, expect a discussion of Feature Envy within the week. If not, expect a blog post in about 2 weeks.

Speaking of that newsletter, you can [sign-up for the free](http://tinyletter.com/ianwhitney/), check out [previous issues](http://tinyletter.com/ianwhitney/archive) or start ironing your best green suit for St. Patrick's Day. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com
