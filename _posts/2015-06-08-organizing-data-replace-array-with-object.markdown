---
layout: post
title: "Organizing Data: Replace Array with Object"
date: 2015-06-08T12:59:35-05:00
---

In two previous posts -- [Replace Data Value with Object](http://designisrefactoring.com/2015/04/26/organizing-data-replace-data-value-with-object/) and [So Long Value, Hello Reference](http://designisrefactoring.com/2015/05/11/so-long-value-object-hello-reference/) -- I illustrated ways of replacing string method parameters with something more useful: Value Objects and Reference Objects. The motivation for these refactorings was pretty simple -- strings are useless when it comes to storing application logic and objects are easy to create.

This week it's time to look at Arrays and Hashes. You will probably not be shocked to learn that these structures are about as useful as strings when it comes to application behavior. Sure, you can use them more successfully than strings. But as soon as any complexity rears its head, you should refactor them into 'real' objects.

This all comes down to a code smell that I quickly glossed over in an [earlier newsletter](http://tinyletter.com/ianwhitney/letters/not-very-much-about-primitives), Primitive Obsession. Defined as "[using primitive data types to represent domain ideas](http://c2.com/cgi/wiki?PrimitiveObsession)", you'll see Primitive Obsession everywhere once you start looking for it. Options being parsed out of an array by position, hashes being used to configure objects, strings being parsed via regex, and so on. That doesn't mean that primitives are bad; we certainly need strings, arrays and the like. But as soon as you find yourself putting any sort of behavior in one a "Primitive Obsession!" alarm should go off in your head and you should extract that code into a class.

Arrays and Hashes are frequently the focus of Primitive Obsession because they hide the problem so well. They are super convenient ways to pass around collections of data, they have so many convenient methods, and with hashes it's almost like you're using a real class. Especially if you're using [Hashie::Mash](https://github.com/intridea/hashie#mash).

But Arrays and Hashes are Primitive. They exist to hold data in a specific way and that's it. Let them do their job and write actual classes for everything else.

## Following the pattern

Let's say we have some code that makes a SOAP request. And, wisely, we wrap that request in an Adapter as we hope to abandon SOAP as quickly as we can. Initially we only have to provide 1 option to the SOAP library, the name of a college campus:

{% highlight ruby %}
class QueryService
  def initialize(campus)
    self.campus = campus
  end

  def run
    SoapRequest.new(campus).results
  end

  private

  attr_accessor :campus
end

QueryService.new(campus: "TwinCities").run
{% endhighlight %}

Inevitably, the SOAP service changes and we have to provide a campus and a term, but only if the request is for a Summer term. We decide to do this with a Hash. We could have used an Array, but the Hash lets us refer to values by a name instead of position. Other than that the implementation would be identical.

{% highlight ruby %}
class QueryService
  def initialize(options)
    self.campus = options[:campus]
    self.term = options[:term] || "Default"
  end

  def run
    SoapRequest.new(campus, term).results
  end

  private

  attr_accessor :campus, :term
end

QueryService.new({campus: "TwinCities"}).run
QueryService.new({campus: "TwinCities", term: "SUMMER2015"}).run
{%endhighlight %}

That one attribute change necessitated:

- 3 changes inside of QueryService
  - One of which adds a conditional
- Additional changes inside of SoapRequest

When we need to add a new option, we'll make another set of nearly identical changes. This could quickly get out of hand.

We're using a data structure where we need a concept. Our Primitive Obsession alarm goes off and we decide to refactor.

### Extract a class

The hash is being used to configure the query. So we create a new class called QueryConfiguration. I'm not an imaginative namer.

{% highlight ruby %}
class QueryConfiguration
  attr_accessor :campus, :term

  def initialize(options)
    self.campus = options[:campus]
    self.term = options[:term] || "Default"
  end
end
{%endhighlight %}

This class is still configured by a hash. That's fine for now. More importantly it gives us a class in which to hang this configuration logic.

### Use the new class

{% highlight ruby %}
class QueryService
  def initialize(configuration)
    self.configuration = configuration
  end

  def run
    SoapRequest.new(configuration).results
  end

  private

  attr_accessor :configuration
end

config = QueryConfiguration.new({campus: "TwinCities", term: "FALL2015"})
QueryService.new(config).run
{%endhighlight %}

### Replace the hash with attribute setters

{% highlight ruby %}
class QueryConfiguration
  attr_accessor :campus, :term

  def initialize
    yield self if block_given?
  end

  def term
    @term || "Default"
  end
end

class QueryService
  def initialize(configuration)
    self.configuration = configuration
  end

  def run
    SoapRequest.new(configuration).results
  end

  private

  attr_accessor :configuration
end

config = QueryConfiguration.new do |q|
  q.campus = "TwinCities"
  q.term = "SUMMER2015"
end

QueryService.new(config).run
{%endhighlight %}

I've been digging the `yield self if block_given?` approach lately, so I'm using that here. It's not integral to the refactoring, it's just neat.

Now QueryService is back to being a thin wrapper around SoapRequest, and we have a clear place to put the query configuration. Even better, that place is easy to extend and change.

Want more talk of code smells and related nonsense? [Sign up for my free newsletter](http://tinyletter.com/ianwhitney/)! Check out [previous issues](http://tinyletter.com/ianwhitney/archive) if you want to catch up on my previous ramblings. Comments/feedback/&c. welcome [on twitter](https://twitter.com/iwhitney/), at ian@ianwhitney.com, or [leave comments on the pull request for this post](https://github.com/IanWhitney/designisrefactoring/pull/4).
