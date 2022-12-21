---
layout: post
title: "Totally Bogus Doubles for Tests"
description: ""
category: 
tags: []
---
I love me some mocks and stubs. Like many people, I didn't really get
the idea until I did [some reading](http://martinfowler.com/articles/mocksArentStubs.html) about the technique. And then I didn't *really* get it until I did [some more reading](http://www.poodr.com/). And even then I didn't __really__ get it until I re-wrote a suite of tests like 3 times, each time getting closer to that coding nirvana: a blazingly fast group of tests that exposes dependencies and is resilient to change.

<!--more-->

A big step for me was implementing real testing doubles, moving away
from tiny structs and actually creating a Ruby class to act as my
double. The functionality and reusability of these doubles is great. But
they introduce a problem. For example, take this dumb code:

    class Record
      attr_accessor :number

      def initialize
       #A ton of db work
      end

      def length
        # even more db work
      end
    end

    class RecordDouble
      attr_accessor :number

      def length
        @length ||= rand(50)
      end
    end

Now I can use RecordDouble as a collaborator in a test and not have to
incurr the pain of creating a real record instance. Yay. 


    class RecordCollaboratorTest
      before :each do
        @record_double = RecordDouble.new
        @it = RecordCollaborator.new(@record_double)
      end

      it "should use record length in some way" do
        assert_equal @record_double.length, @it.length
      end
    end

And all is good. Then I change the length method on the Record object:

    class Record
      ...
      def length(options_hash)
      end
    end

And a varitey of bad things happen, right? My tests no longer document
how to use my code. My tests pass, but production could fail. There's
drift, and drift = rot = badness.

And even if that never happens, using doubles like this is duplication.
I have two classes that have (or should have) the same interface. Every
change in one needs to be made in the other.

A quick solution I implemented when I did this the first time came, more
or less, from Sandi Metz's book.

    class RecordTest
      setup do
        @it = RecordDouble.new
      end

      include RecordInterfaceTest
      ...
    end

    class RecordDoubleTest
      setup do
        @it = RecordDouble.new
      end

      include RecordInterfaceTest
      ...
    end

    module RecordInterfaceTest
      [:number, :id, length].each |m|
        assert @it.responds_to?(m)
      end
    end

Still duplication (actually now triplication of the API methods), but at
least I could control drift. Kind of. If Record or RecordDouble stopped
supporting a method that was in the interface test, an alarm bell would
go off. But if arity changed, I wouldn't notice.

Fast forward several months and I find myself implementing this pattern
again in a different code base. But now I have [this video](http://confreaks.com/videos/2452-railsconf2013-the-magic-tricks-of-testing), in which (at the 29 minute mark), Sandi Metz points to four ([quacky](https://github.com/benmoss/quacky), [bogus](https://github.com/psyho/bogus), [rspec-fire](https://github.com/xaviershay/rspec-fire), [minitest-firemock](https://github.com/cfcosta/minitest-firemock)) gems that can solve this problem in a better way.

After reviewing the options, I chose Bogus. Its use seemed the cleanest
and it appeared to have solid documentation. I eventually found that documentation to be somewhat lacking, hence this blog post.

First, I'm implementing this with MiniTest spec, and their documentation
leaned more to the Rspec crowd. And I'm testing ActiveRecord objects,
while their documentation focused on plain Ruby code. Those little
wrinkles can trip you up. They certainly tripped me up.

### Getting your 'test_helper' in shape

I created a new helper file 

    ENV["RAILS_ENV"] = "test"
    require File.expand_path('../../config/environment', __FILE__)
    require 'minitest/autorun'
    require 'bogus/minitest/spec'

### On to the test

    describe Fruit do
      fake(:garden)
      fake(:trellis) { Support::Trellis }

      describe "#initialize" do
        before do
          stub(garden).fertilized? { true }
          stub(trellis).material { 'wood' }
        end
        ...
      end
    end

Here I'll be testing a Fruit object. It has two collaborators I need to
double: Garden and Trellis. Here you see the two ways you can call the
Bogus fake method. In the first I pass no block, so Bogus assumes I want
to fake an instance of Garden. But for trellis, I pass in the class I
want.

All of the examples in Bogus use the first method. The 2nd [is
documented] (https://www.relishapp.com/bogus/bogus/v/0-1-4/docs/fakes/faking-existing-classes), but I was so busy looking at the examples that I didn't notice.

### Now the magic

The result of fakes is that I can use `garden` and `trellis` in
my tests and stub methods on them. And that separate directory of double
classes? Gone. The library of interface tests? Gone. All I have now are
the real object defitions that I fake during tests.

### And the magic has a posse

But if I try to stub something that the classes don't support, Bogus will throw an error.

    stub(garden).disco_party? { true} => #NameError: #<Garden:0x3fea091c41b0> does not respond to disco_party?

And arity is respected:

    stub(trellis).leg_number(1, 'huh?') { nil } => ArgumentError: tried to stub leg_number(count) with arguments: 1,'huh?'

### But maybe not magic enough?

This is all excellent and much appreciated. Now I can create doubles
with ease and not worry about API drift. Let's throw them on some
ActiveRecord models. Here's a Fee that has a value code that's persisted
in a database: 

    irb> f = Fee.first
    => #<Fee code: 100>

Let's double that and use it in a test:

    describe FeeCollaborator do
      fake(:fee)

      describe "#initialize" do
        before do
          stub(fee).code { 999 }
        end
        ...
      end
    end

And instead of a happy shiny double, you'll get:

    NameError: #<Fee:0x3fc3b60eed2c> does not respond to code

But Fee obviously responds to code, I just saw it in the console! And
here's where the Bogus documentation is, pardon me for saying it,
slightly bogus. Under Configuration Options, theres a link for
[Fake_ar_attributes](https://www.relishapp.com/bogus/bogus/v/0-1-4/docs/configuration/fake-ar-attributes) which will tell you why this is breaking and how to fix it. In short, just put this in your initial test_helper file:

    Bogus.configure do |c|
      c.fake_ar_attributes = true
    end

And your tests of ActiveRecord objects will work.

There's a lot more Bogus features that I'm looking forward to trying.
Spies, contracts and argument matchers all look great. And if I find any
tricks to implementing those features, I'll post them here.

