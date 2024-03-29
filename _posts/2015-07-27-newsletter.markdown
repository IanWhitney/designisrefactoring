---
layout: post
title: "Simplify code by extracting out object creation"
date: 2015-07-27 12:35:35 -0600
author: Ian Whitney
---

Code Smells and Integration Tests, Pt. 2

First off, an apology. After 6 months of saying "Reply to this newsletter to get in touch!", I only just learned that replies weren't actually being forwarded to me. My mistake. I have fixed that setting in TinyLetter.

Through tweets and the recently-discovered replies, it seems that people want to see the refactoring steps that might improve the code from [last newsletter](http://tinyletter.com/ianwhitney/letters/code-smells-and-integration-tests-pt-2). So, let's do that!

Our code from last time:

```ruby
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

And, as I mentioned last time, we start running into a lot of hassle as soon as we try to unit test this code.

```ruby
describe "column_count" do
  uri = "http://localhost:3000/test.csv"
  uri_double = URI.parse(uri)
  expect(URI).to receive(:parse).with(uri).and_return(uri_double)

  file_contents = File.read("fixtures/test.csv")
  allow(uri_double).to receive(:read).and_return(file_contents)
  csv_double = CSV.parse(file_contents, headers: true)
  expect(CSV).to receive(:parse).with(file_contents, headers: true).and_return(csv_double)
  expect(FileInfo.new(uri).column_count).to eq(csv_double.first.headers.count)
end
```

That's not a unit test, it's a full duplicate of our implementation.

A couple of newsletters back I [suggested a way to visualize why this code is hard to test](http://tinyletter.com/ianwhitney/letters/code-smells-and-integration-tests). If you inline all the method calls used in 'column_count' you get:

```
CSV.parse(URI.parse(uri).read, headers: true).first.headers.count
```

Which is a lot of work for one method. And nearly all of that work is creating objects. What happens if we extract that work and only give `column_count` just the object it needs? First, let's extract the URI creation.

```ruby
class FileInfo
  def new(uri)
    self.uri = uri
    get_file
  end

  #...
  attr_accessor :uri
  attr_reader :file

  def get_file
    @file = CSV.parse(uri.read, headers: true)
  end
end

uri = URI.parse(http://localhost:3000)
FileInfo.new(uri).column_count
```

That reduces our unit test to:

```ruby
describe "column_count" do
  uri_double = URI.parse("http://localhost:3000/test.csv")

  file_contents = File.read("fixtures/test.csv")
  allow(uri_double).to receive(:read).and_return(file_contents)
  csv_double = CSV.parse(file_contents, headers: true)
  expect(CSV).to receive(:parse).with(file_contents, headers: true).and_return(csv_double)
  expect(FileInfo.new(uri).column_count).to eq(csv_double.first.headers.count)
end
```

Better. Still a ways to go. Let's extract out CSV.

```ruby
class FileInfo
  def new(csv)
    file = self.csv
  end

  #...
  attr_accessor :file
end

uri = URI.parse(http://localhost:3000)
file = CSV.parse(uri.read, headers: true)
FileInfo.new(file).column_count
```

Which brings our unit test to:

```ruby
describe "column_count" do
  csv_double = CSV.parse(File.read("fixtures/test.csv"), headers: true)
  expect(FileInfo.new(csv_double).column_count).to eq(csv_double.first.headers.count)
end
```

Which fairly succinctly tests the behavior that the method provides.

Obviously I'm cheating a little bit here. I extracted the URI and CSV code out of the class but I didn't put it anywhere. It's just hanging out in a nameless void of Ruby. In the real world you'd put that code in their own classes. `FileInfo` expects a header-parsed CSV file, so make a class that provides that

```
class HeaderCSV < SimpleDelegator
  def self.build(file)
    new(CSV.parse(file.read, headers: true))
  end
end

file = HeaderCSV.new(URI.parse('http://localhost:3000').read)
FileInfo.new(file).column_count
```

There are still problems with this code. The naming is weird and there are about a million ways you could break it. But it's now well-covered by tests and can be further refactored.

In the next couple of newsletters I plan on looking at two ways of writing this code from scratch that will leave it in a much better state. But that's for later. For now, links.

I have spent the last 3 weeks integrating Sidekiq at work, code that will probably be the basis of several upcoming blog posts and presentations. This week's links are resources that have helped me out with Sidekiq.

First, the [Sidekiq wiki](https://github.com/mperham/sidekiq/wiki) which is well-written and super useful. Before I wrote any code I spent most of a day reading the wiki and it helped our design immensely.

Then, [Decomposing Sidekiq workers](http://blog.8thlight.com/kevin-buchanan/2015/05/04/decomposing-asynchronous-workers-in-ruby.html) by Kevin Buchanan. While we didn't follow this approach, I do like it and it helped inform some decisions that we made.

And [Working with Ruby Threads](http://www.jstorimer.com/products/working-with-ruby-threads) was a vital resource. Sidekiq is thread-based, which you have to keep in mind while implementing workers. I've liked all of Jesse's books, but this is the one to read if you're dealing with Sidekiq.

If you are reading this on July 27, 2015 I'm doing a presentation about Sidekiq tonight at [Ruby.mn](http://www.ruby.mn). Free beer and pizza, if you need more enticement.

Finally, something fun, the [Culture novels](https://en.wikipedia.org/wiki/Culture_series) by [Iain \[M\] Banks](http://www.iain-banks.net/). I have read all of them at least once, and am currently re-reading the entire series. I find them to be a fascinating analysis of utopias, technology and morality. And they are super entertaining!

If there are changes/topics/etc. you'd like to see, please reply to this email, [Tweet](https://twitter.com/iwhitney) or [Comment](https://github.com/IanWhitney/newsletter/pull/7).

Until next time, true receivers.
