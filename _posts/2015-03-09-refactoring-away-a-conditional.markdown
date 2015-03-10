---
layout: post
title: "Refactoring away a conditional"
date: 2015-03-09T19:27:10-05:00
---

Conditionals! No one likes them. They look innocent enough to start, but they attract more conditionals and grow into thorny nests of nested ifs. Blech-o! 

Fowler's _Refactoring_ offers a lot of ways of removing conditionals, but using Ruby gives us options that he did not have. So, instead of focusing on one of Fowler's patterns this week, I'm going to focus on one I use.

<!--break-->

Let's take a simple problem,

> Bob answers 'Sure.' if you ask him a question.
> He answers 'Whoa, chill out!' if you yell at him.
> He says 'Fine. Be that way!' if you address him without actually saying anything.
> He answers 'Whatever.' to anything else.

And give it a simple solution:

```
class Bob
  def reply_to(statement)
    if statement.strip.empty?
      "Fine. Be that way!"
    elsif statement.upcase == statement && statement.downcase != statement
      "Woah, chill out!"
    elsif statement.end_with?("?")
      "Sure."
    else
      "Whatever."
    end
  end
end

Bob.new.reply_to("HELLO")
#=> "Whoah, chill out!"
```

Following the 2nd of the [4 simple rules](http://designisrefactoring.com/2015/01/05/4-simple-rules-of-raindrops/), we decide that our conditional tests don't express intent and that there's a "Statement" class that could encapsulate that behavior. We refactor slowly and carefully, first adding a Statement class via Struct. This is a simple application of Extract Class.

```
Statement = Struct.new(:statement) do
  def empty?
    statement.strip.empty?
  end

  def yelling?
    statement.upcase == statement && statement.downcase != statement
  end

  def questioning?
    statement.end_with?("?")
  end
end
```

And then replacing our code, one conditional at a time, with the new object, ending with:

```
class Bob
  def reply_to(statement)
    statement = Statement.new(statement)
    if statement.empty?
      "Fine. Be that way!"
    elsif statement.yelling?
      "Woah, chill out!"
    elsif statement.questioning?
      "Sure."
    else
      "Whatever."
    end
  end
end

Statement = Struct.new(:statement) do
  def empty?
    statement.strip.empty?
  end

  def yelling?
    statement.upcase == statement && statement.downcase != statement
  end

  def questioning?
    statement.end_with?("?")
  end
end

Bob.new.reply_to("Hello?")
#=> "Sure."
```

This is clearer. Extract Class has allowed us to unify and consolidate a concept that was muddy. But it hasn't solved all our problems. I still see two areas of concern:

1. Why does `Bob` know how to instantiate a `Statement`?
2. That dang conditional is still there, making it hard for us to give Bob new replies.

Or, if we think of previously-discussed design heuristics:

1. Bob has 2 responsibilities, creating Statements and responding to them.
2. Bob's responses are not open to extension.

The first problem is simple enough, we just pass in a `Statement` instance instead of a string.

```
class Bob
  def reply_to(statement)
    if statement.empty?
      "Fine. Be that way!"
    elsif statement.yelling?
      "Woah, chill out!"
    elsif statement.questioning?
      "Sure."
    else
      "Whatever."
    end
  end
end

Statement = Struct.new(:statement) do
  #...
end

Bob.new.reply_to(Statement.new("HELLO!"))
#=> "Whoa, chill out!"
```

Bob now replies to statement duck-types instead of strings. Go, Bob! Now we can focus on the conditional.

Bob asks the statement about its properties. Are you yelling? Are you a question? Etc. Bob picks a response based on that information. This limits Bob, he can only respond to method types he knows about, and it ties him very tightly to the current selection of statement properties. But what if Bob asked the statement what **class** it is?

```
class Bob
  def reply_to(statement)
    if statement.is_a?(Silence)
      "Fine. Be that way!"
    elsif statement.is_a?(Yelling)
      "Woah, chill out!"
    elsif statement.is_a?(Question)
      "Sure."
    else
      "Whatever."
    end
  end
end

Silence = Struct.new(:statement)
Yelling = Struct.new(:statement)
Question = Struct.new(:statement)

Bob.new.reply_to(Yelling.new("HELLO!"))
#=> "Whoah, chill out!"
```

Admittedly, this doesn't look any better. In fact, it probably looks worse. We've just swapped checking query method -- `yelling?` -- for a class check -- `is_a?(Yelling)`. Why? Before I answer that, let's do one more refactoring. This time we'll use Extract Method to separate the reply from the code that determines which reply to make.

```
class Bob
  def reply_to(statement)
    if statement.is_a?(Silence)
      respond_to_silence
    elsif statement.is_a?(Yelling)
      respond_to_yelling
    elsif statement.is_a?(Question)
      respond_to_question
    else
      default_reply
    end
  end

  def respond_to_silence
    "Fine. Be that way!"
  end

  def respond_to_yelling
    "Woah, chill out!"
  end

  def respond_to_question
    "Sure."
  end

  def default_reply
    "Whatever."
  end
end
```

The similarity between the statement class names and the names of Bob's new methods is not a coincidence, it's there so that we can remove that if statement using dynamic method calling.

```
class Bob
  def reply_to(statement)
    public_send("reply_to_#{statement.class}".downcase.to_sym)
  rescue NoMethodError
    default_reply
  end

  def reply_to_silence
    "Fine. Be that way!"
  end

  def reply_to_yelling
    "Woah, chill out!"
  end

  def reply_to_question
    "Sure."
  end

  def default_reply
    "Whatever."
  end
end

Question      = Struct.new(:statement)
Yelling       = Struct.new(:statement)
Silence       = Struct.new(:statement)
NullStatement = Struct.new(:statement)

Bob.new.reply_to(Question.new("Hello?"))
#=> "Sure."
```

Bob's if statement is gone! I can now easily extend Bob to reply to new kinds of statements. If Bob has a method that follows the `reply_to_[class name]` format, he can reply to it. If he doesn't, then he uses his default response. The addition of a new type of statement no longer means that I have to change any of Bob's existing methods. Hooray!

But now we have to know what kind of statement we want to build before we ask Bob to reply to it. And there's nothing preventing me from creating a Question statement that isn't actually a question. Problematic. I know what a terrible programmer I am, so I know that I'm going to screw this up. We need a class to create statements for us.

```
class Bob
  #... Bob is unchanged from before
end

class StatementFactory
  def self.build(statement)
    if statement.strip.empty?
      Silence.new(statement)
    elsif statement.upcase == statement && statement.downcase != statement
      Yelling.new(statement)
    elsif statement.end_with?("?")
      Question.new(statement)
    else
      NullStatement.new
    end
  end
end

Bob.new.reply_to(StatementFactory.build("Hello!"))
#=> "Whatever."
```

Like a bad penny, that if statement came right back. I told you that conditionals were no good. Worse, StatementFactory has the old, opaque conditionals again.

This ever-reappearing if statement tells us that the knowledge of what kind of statement "Hello?" is still isn't in the right place. First it was in Bob, but Bob shouldn't have to figure out if a string is a Question. Then we shifted the responsibility to the programmer, but we shouldn't rely on programmers to do anything right. Now it's moved to StatementFactory, which is better, but not great. Yes, it's still a gross if statement, but at least it's in a place where I would expect a gross if statement to live.

However, what if we made Question decide if "Hello?" is a Question?

```
class Bob
  #... still unchanged
end

class Statements
  def self.all
    [Question, Yelling, Silence, NullStatement]
  end
end

Statement = Struct.new(:statement)

class Question < Statement
  def self.match?(statement)
    statement.end_with?("?")
  end
end

class Yelling < Statement
  def self.match?(statement)
    statement.upcase == statement && statement.downcase != statement
  end
end

class Silence < Statement
  def self.match?(statement)
    statement.strip.empty?
  end
end

class NullStatement < Statement
  def self.match?(statement)
    true
  end
end

class StatementFactory
  def self.build(statement)
    Statements.all.detect { |s| s.match?(statement) }.new(statement)
  end
end
```

I've assembled all the code into [a gist](https://gist.github.com/IanWhitney/5e2f3ff7099768f3cf40), if you want to see everything in one place.

Now each kind of Statement is its own class and they each know if they match the provided string. The Factory builds the first Statement that matches. And Bob can easily reply to any type of Statement we want. The only kludge here is the `Statements.all` method, and there are ways around that. You can look up a Class's descendants, or you could have statement classes register themselves. Each has its own downsides, but those are for another post. Our if statement is gone, this time for good.

The Design is Refactoring newsletter continues its trek through code smells. Last week I [highlighted some places that Shotgun Surgery might be hiding](http://tinyletter.com/ianwhitney/letters/shotgun-surgery-a-pretty-exciting-name-something-so-tedious). Avoid those nasty surprises, for free, by subscribing. You can [sign-up for the newsletter](http://tinyletter.com/ianwhitney/), check out [previous issues](http://tinyletter.com/ianwhitney/archive) or start working on that swimsuit tan. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com
