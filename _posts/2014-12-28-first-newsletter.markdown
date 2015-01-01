---
layout: post
title: "First Newsletter"
date: 2014-12-28T17:43:20-06:00
---

Thanks to a slip of my fingers, the first newsletter went out a few days early and with a super-dumb error in it. If you haven't subscribed, you can read it [here](http://tinyletter.com/ianwhitney/letters/clever-code-and-better-design-friends-or-enemies).

The final method in that code example should read

```ruby
def execute(path, *args, &b)
  r[path].public_send(verb, *args, &b)
end
```

TinyLetter (understandably) doesn't let you edit newsletters that you've sent, so I will just put the fix here.
