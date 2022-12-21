---
layout: post
title: "Clever Code and Better Design, friends or enemies?!"
date: 2014-12-28 12:35:35 -0600
author: Ian Whitney
---

Hello, all!

If you are reading this, then you have decided that my occasional rambly blog posts about code design are **not enough**! Some may question your sanity, but not me. Let us ramble on together, spending far to much time thinking about where we should inject that dependency.

In case you missed it, I wrote a bit about the RNA Transcription exercise from Exercism.io. http://programming.ianwhitney.com/blog/2014/12/26/exercism-the-rna-transcription-exercise/

A Christmas present to myself was [_Metaprogramming Ruby 2_](https://pragprog.com/book/ppmetr2/metaprogramming-ruby-2) by Paolo Perotta. I don't tend to break out the metaprogramming tools that often, but it's something that I wanted to learn about. This is a odd book. It has an appendix of "spells" which are just little code snippets or patterns. People think metaprogramming is weird enough already, I'm not sure we need to pretend that it's magical. I thought the information in the book was good, just presented in a way that I didn't always care for.

The book also got me thinking about a design question. It includes a code snippet from the [REST-client gem](https://github.com/rest-client/rest-client). The full code is [here](https://github.com/rest-client/rest-client/blob/04f1e80a7fdcb319222f74b4a1a1610d41ed2ade/bin/restclient), but here's the relevant sample:

```ruby
POSSIBLE_VERBS = ['get', 'put', 'post', 'delete']
...
POSSIBLE_VERBS.each do |m|
  define_method(m.to_sym) do |path, *args, &b|
    r[path].public_send(m.to_sym, *args, &b)
  end
end
```

And that's certainly clever, right? You only support those 4 HTTP verbs, but the underlying implementation of the verbs is exactly the same. So, just define all 4 methods in the loop using some metaprogramming.

But I'm starting to believe that Clever is the enemy of Better Design. If, like I discussed at the end of my last post, better designed code is easier for more people to understand/maintain/extend, then I think it follows that simpler code is better designed than complex code. And the venn diagram of clever and complex code may not overlap 100%, but they certainly overlap a lot.

Would the REST-client code be easier to work with if it looked like this:

```ruby
def get(path, *args, &b)
  execute(:get, *args, &b)
end

def put(path, *args, &b)
  execute(:put, *args, &b)
end

def post(path, *args, &b)
  execute(:post, *args, &b)
end

def delete(path, *args, &b)
  execute(:delete, *args, &b)
end

def execute
  r[path].public_send(verb, *args, &b)
end
```

I think that this code is better designed that the current implementation because it is simpler. Yes, if your method signature changes, you have to change it in more than one place. But which is more likely, that you're going to change the method signature or that you're just looking at this code to figure out what it does?

There may be other reasons for the current REST-client design that I'm unaware of. If you see something I missed, please let me know!

And that's quite enough for now. Expect the next newsletter around January 8th. Watch the skies!
