---
layout: post
title: "Romans and the Open/Closed Principle"
date: 2015-01-25T20:05:34-06:00
---

[Last week I introduced the Open/Closed Principle](http://designisrefactoring.com/2015/01/19/introducing-the-open-closed-principle/), this week let's see in in action. I'm going to warn you right off, this week's code gets kind of ridiculous. It is the ne plus ultra of contrived examples.

The Exercism [problem description](https://github.com/exercism/x-common/blob/master/roman-numerals.md) is simple enough. Their [example solution](https://github.com/exercism/xruby/blob/master/roman-numerals/example.rb) is one way to go about it. In my typical fashion I wrote something way longer and full of duplication.

<!--break-->

{% highlight ruby %}
class Fixnum
  def to_roman
    t, rem = to_thousands(self)
    h, rem = to_hundreds(rem)
    te, rem = to_tens(rem)
    o, _ = to_ones(rem)

    t + h + te + o
  end

  private

  def to_thousands(x)
    rom = "M" * (x / 1000)
    [rom, x.remainder(1000)]
  end

  def to_hundreds(x)
    h = x / 100
    rom = case
    when (h == 9)
      "CM"
    when (h >= 5)
      "D" + ("C" * (h - 5))
    when (h == 4)
      "CD"
    else
      "C" * h
    end
    [rom, x.remainder(100)]
  end

  def to_tens(x)
    t = x / 10
    rom = case
    when (t == 9)
      "XC"
    when (t >= 5)
      "L" + ("X" * (t - 5))
    when (t == 4)
      "XL"
    when (t > 0)
      "X" * t
    else
      ""
    end
    [rom, x.remainder(10)]
  end

  def to_ones(x)
    case
    when (x == 9)
      "IX"
    when (x >= 5)
      "V" + ("I" * (x - 5))
    when (x == 4)
      "IV"
    else
      "I" * x
    end
  end
end
{% endhighlight %}

And that's ugly. No two ways about it. But this is a first draft and first drafts should be ugly. We just want to get up and running and pass the tests, which this does.

Is this code Open/Closed? That's an impossible question to answer. Open/Closed isn't a binary state, it all depends on what change we want to make. But Roman numbering hasn't changed much recently, so maybe this code's Open/Closed-ness isn't all that relevant.

We are then surprised to hear that a new Roman empire has appeared. NeoRomans they call themselves. And, unlike their historic inspiration, they prefer round lines for their numbers. In their system:

- 1 = J
- 5 = R
- 10 = B
- 50 = P
- 100 = G
- 500 = Q
- 1000 = O

Is our code Open/Closed to implementing `to_neoroman`? Let's follow the steps from last week and find out. Those steps, again:

- Implement the new feature without changing any existing code
- Extract out the difference between your new code and the existing code
- Repeat as needed.

Step one, we implement `to_neoroman` without changing any existing code. It gets pretty long, so I'll just [link to the commit](https://github.com/IanWhitney/exercism_roman/blob/e1354ee9c86e39911ad36e8270a16a255e6f0a12/roman.rb).

Pretty terrible, right? I think we can agree that this is terrible. Before I had 4 duplicate methods, now I have 8. The new methods I introduced only differ in the letters they use, which gives us an obvious difference to extract out. Let's go back to the previous commit, do the refactoring and try again. This time we'll only change the design of the code. No functionality will be introduced or changed. And I do this by introducing a conversion parameter (_Refactoring_, p. 295).

{% highlight ruby %}
class Fixnum
  ROMAN_CONVERSION = {1000 => "M", 500 => "D", 100 => "C", 50 => "L", 10 => "X", 5 => "V", 1 => "I"}

  def to_roman
    t, rem = to_thousands(self)
    h, rem = to_hundreds(rem)
    te, rem = to_tens(rem)
    o, _ = to_ones(rem)

    t + h + te + o
  end

  private

  def to_thousands(x, conversion = ROMAN_CONVERSION)
    rom = conversion[1000] * (x / 1000)
    [rom, x.remainder(1000)]
  end
  ...
end
{% endhighlight %}


And with that, the new Neo-Romans can be added thusly:

{% highlight ruby %}
def to_neoroman
  conversion = {1000 => "O", 500 => "Q", 100 => "G", 50 => "P", 10 => "B", 5 => "R", 1 => "J"}
  t, rem = to_thousands(self, conversion)
  h, rem = to_hundreds(rem, conversion)
  te, rem = to_tens(rem, conversion)
  o, _ = to_ones(rem, conversion)

  t + h + te + o
end
{% endhighlight %}

And now we can say that our code is Open/Closed to different lettering systems. We also spot some simple duplication between the `to_roman` and `to_neoroman` methods which we fix with Extract Method:

{% highlight ruby %}
def to_roman
  conversion = {1000 => "M", 500 => "D", 100 => "C", 50 => "L", 10 => "X", 5 => "V", 1 => "I"}
  to_letters(conversion)
end

def to_neoroman
  conversion = {1000 => "O", 500 => "Q", 100 => "G", 50 => "P", 10 => "B", 5 => "R", 1 => "J"}
  to_letters(conversion)
end

def to_letters(conversion)
  t, rem = to_thousands(self, conversion)
  h, rem = to_hundreds(rem, conversion)
  te, rem = to_tens(rem, conversion)
  o, _ = to_ones(rem, conversion)

  t + h + te + o
end
{% endhighlight %}

Surely no other Roman counting systems exist, so our code is as good as it needs to be. What's that you say? We just discovered a new space-faring group of Romans that like to count up to 99,999? And they have new symbols for 5000 and 10,000? Since our code is Open/Closed now, we can surell just implement this new feature without changing any existing code!

{% highlight ruby %}
def to_exoroman
  conversion = {10_000 => "&", 5000 => "*", 1000 => "O", 500 => "Q", 100 => "G", 50 => "P", 10 => "B", 5 => "R", 1 => "J"}
  to_exoletters(conversion)
end

def to_exoletters(conversion)
  tt, rem = to_exo_ten_thousands(self, conversion)
  t, rem = to_exo_thousands(rem, conversion)
  h, rem = to_hundreds(rem, conversion)
  te, rem = to_tens(rem, conversion)
  o, _ = to_ones(rem, conversion)

  tt + t + h + te + o
end

#...

def to_exo_ten_thousands(x, conversion)
  rom = conversion[10000] * (x / 10000)
  [rom, x.remainder(10000)]
end

def to_exo_thousands(x, conversion)
  h = x / 1000
  rom = case
  when (h == 9)
    "#{conversion[1000]}#{conversion[10000]}"
  when (h >= 5)
    conversion[5000] + (conversion[1000] * (h - 5))
  when (h == 4)
    "#{conversion[1000]}#{conversion[5000]}"
  else
    conversion[1000] * h
  end
  [rom, x.remainder(1000)]
end
{% endhighlight %}

Obviously our code is not Open/Closed to this change. Let's follow the same process again. Now that we've tried implementing `to_exoroman` without changing our existing code, we can refactor the code that made implementation such a pain, namely:

- The current `to_thousands` method only works up to 3,999
- We have no method for powers of ten greater than 10<sup>3</sup>.

As has probably been clear from the first iteration, having all those methods for each power of ten is duplicating knowledge, and it makes the code hard to extend. If we fix that, we should be able to handle any power of ten.

{% highlight ruby %}
class Fixnum
  def to_roman
    conversion = {1000 => "M", 500 => "D", 100 => "C", 50 => "L", 10 => "X", 5 => "V", 1 => "I"}
    to_letters(conversion)
  end

  def to_neoroman
    conversion = {1000 => "O", 500 => "Q", 100 => "G", 50 => "P", 10 => "B", 5 => "R", 1 => "J"}
    to_letters(conversion)
  end

  private

  def to_letters(conversion)
    letters = ""
    number = self
    conversion.keys.each_slice(2) do |multiple_of_ten, _|
      l, number = convert_to_letters(number, multiple_of_ten, conversion)
      letters += l
    end

    letters
  end

  def convert_to_letters(number, multiple_of_ten, conversion)
    x = number / multiple_of_ten
    rom = case
    when (x == 9)
      "#{conversion[multiple_of_ten]}#{conversion[multiple_of_ten * 10]}"
    when (x >= 5)
      conversion[multiple_of_ten * 5] + (conversion[multiple_of_ten] * (x - 5))
    when (x == 4)
      "#{conversion[multiple_of_ten]}#{conversion[multiple_of_ten * 5]}"
    else
      conversion[multiple_of_ten] * x
    end
    [rom, number.remainder(multiple_of_ten)]
  end
end
{% endhighlight %}

In terms of the Refactoring book, this change most closely matches Parameterize Method (Refactoring, p. 283):

> several methods do similar things but with different values contained
> in the method body. Create one method that uses a parameter for the
> different values

The code's not great, but this change makes our code Open/Closed to the ExoRomans:

{% highlight ruby %}
def to_exoroman
  conversion = {10_000 => "&", 5000 => "\*", 1000 => "O", 500 => "Q", 100 => "G", 50 => "P", 10 => "B", 5 => "R", 1 => "J"}
  to_letters(conversion)
end
{% endhighlight %}

Whew. Space-faring Romans must be the last of the bunch. Oh, there's a splinter faction of Romans that now want to count in multiples of 12? Well, ok, our code must now be flexible enough to handle anything...

{% highlight ruby %}
 def to_duodeciroman
    conversion = {1728 => "Â", 864 => "Î", 144 => "Ç", 72 => "Ò", 12 => "¶", 6 => "∂", 1 => "˚"}
    to_duodeci_letters(conversion)
  end

#...

  def to_duodeci_letters(conversion)
    letters = ""
    num = self
    conversion.keys.each_slice(2) do |multiple_of_twelve, _|
      x = num / multiple_of_twelve
      rom = case
      when (x == 11)
        "#{conversion[multiple_of_twelve]}#{conversion[multiple_of_twelve * 12]}"
      when (x >= 6)
        conversion[multiple_of_twelve * 6] + (conversion[multiple_of_twelve] * (x - 6))
      when (x == 5)
        "#{conversion[multiple_of_twelve]}#{conversion[multiple_of_twelve * 6]}"
      else
        conversion[multiple_of_twelve] * x
      end
      num = num.remainder(multiple_of_twelve)
      letters += rom
    end
    letters
  end
{% endhighlight %}

This implementation shows that our existing code is only Open/Closed to multiples of 10. Back to refactoring. We extract out the 10-focused code into its own class, and then do another Extract Class to remove the conversion methods from Fixnum.

The full commit is getting long again. Here's the [full thing](https://github.com/IanWhitney/exercism_roman/blob/98cf29b480e3bdc5f8b70e91dd601d3241206a0d/roman.rb)

With that implemented, we can add the `to_duodeciroman` feature easily.

{% highlight ruby %}
def to_duodeciroman
  dictionary = {1728 => "Â", 864 => "Î", 144 => "Ç", 72 => "Ò", 12 => "¶", 6 => "∂", 1 => "˚"}
  RomanConverter.new(dictionary, DuoDeciRomans).convert(self)
end

class DuoDeciRomans
  def self.multiple
    12
  end

  def self.half_multiple
    multiple/2
  end
end
{% endhighlight %}

Set aside the quality of the code for now, I'm going to discuss that more in a second. Instead focus on what following the Open/Closed Principle has given us: Code that never stopped working. I showed this in detail last week, but it never hurts to mention it again. By never trying to simultaneously implement new features while re-designing my code, I kept my project in an always-working state. To me, that is the biggest win of following OCP.

Ok, now let's focus on the quality of the code. Here's the [full final version](https://github.com/IanWhitney/exercism_roman/blob/f6cc59cee8990af0499ed6b34b67289522c29b81/roman.rb). It's not great, is it? That `convert` method is super gross. Why, after following the super-great Open/Closed Principle, have we got such an ugly method? Mostly it's because the features we implemented never challenged that method's implementation. Our problems mostly stemmed from the parameters we passed to the method.

OCP by itself isn't a comprehensive design tool. It's a tool for applying grease to squeaky wheels. If a method in your code never needs to change, then OCP won't ever make it change. Because of this if you follow _only_ OCP then smelly code can hide and fester. Instead, you should always be on the lookout for other refactorings you can do after you finish implementing that new feature. 

Speaking of smells, this week's newsletter will start a series about the 'official' smells documented in _Refactoring_. Free to all comers, smelly or not. [Sign-up is easy](http://tinyletter.com/ianwhitney/) and you can always checkout [previous newsletters](http://tinyletter.com/ianwhitney/archive). Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), [GitHub](https://github.com/IanWhitney/designisrefactoring) or ian@ianwhitney.com
