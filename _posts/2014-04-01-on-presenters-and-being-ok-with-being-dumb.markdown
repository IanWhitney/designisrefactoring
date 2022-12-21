---
layout: post
title: "On presenters and being OK with being dumb"
date: 2014-04-01 18:21:21 -0500
comments: true
categories: 
---

A page in our app has a lot of tooltips and help text. All of this text is static. But then came this customer request:

> "If the record is a Course Fee, show '**some text**'. Otherwise, show '**other text**'."

<!-- more -->

Fees are implemented using [single table inheritance](http://www.martinfowler.com/eaaCatalog/singleTableInheritance.html), so I already know exactly what kind of fee they are. I could just throw this right in the view.

```ruby
<% if @fee.kind_of?(Fee::Course) %>
  some text
<% else %>
  other text
<% end %>
```

Ugh. Why would we want our view to know about our class structure? Do you want to have to remember to change this view when the fee type changes?

I could do something like this:

```ruby
class Fee
  ...
  def dynamic_help_text
    "other text"
  end
  ...
end

class Fee::Course < Fee
  ...
  def dynamic_help_text
    "some text"
  end
  ...
end
```

And that's...ok? I guess? I don't see why the Fee needs to know something so purely presentational, though. Doesn't seem like its responsibility. Presentational stuff belongs in [presenters](http://blog.jayfields.com/2007/03/rails-presenter-pattern.html). And I love presenters!

Now, this view code will (hopefully, eventually) be entirely refactored to presenters. But it's not there yet. We can take a first step by introducing a presenter that only cares about help text and tooltips. Let's go:

```ruby
class FeeHelpPresenter

  def initialize(fee)
    self.fee = fee
  end

  def dynamic_help_text
    case fee.class
    when Fee::Course
      "some text"
    else
      "other text"
    end
  end

  private
  attr_accessor :fee
end
```

Then, by making the help presenter available through the fee, I could do something like this in the view:

```ruby
<%= @fee.help.dynamic_help_text %>
```

And, done. Well. There's that case statement switching on fee's class. That certainly smells bad. And it's not great to test, either. If I want to test the presenter outside of Rails (which I most definitely do), then I have to tell the tests that Fee::Course and its ilk exist.

My inclination would be to switch on a property or behavior of the fee. But this proved tricky to find. Deciding that I simply didn't have enough information at this time to make a good descision, I settled on a 'good enough' one. I let fees state if they were 'for_courses' or not, thinking that we might end up with other fee types that are for courses and all of those fees would share the same help text.

```ruby
class Fee
  ...
  def for_courses?
    false
  end
  ...
end

class Fee::Course < Fee
  ...
  def for_courses?
    true
  end
  ...
end

class FeeHelpPresenter
  ...
  def dynamic_help_text
    if fee.for_courses?
      "some text"
    else
      "other text"
    end
  end
  ...
end
```

And I'm admittedly not thrilled with that. It seems super dumb. But as this is the only case in the app where help text varies, I'm ok with this approach for now. And I sucessfully avoided putting logic in the view, so that's good. When more information becomes available, a better design may present itself.
