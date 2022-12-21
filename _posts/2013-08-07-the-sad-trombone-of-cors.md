---
layout: post
title: "The sad trombone of CORS"
description: ""
category: 
tags: []
---
I was so pleased with myself for figuring out all that CORS nonsense.
Then I realized that [none of it would work with IE8 and IE9](http://blogs.msdn.com/b/ieinternals/archive/2010/05/13/xdomainrequest-restrictions-limitations-and-workarounds.aspx).

Being unable to use cookies and custom headers is an absolute
dealbreaker for this project. So, no CORS for us.
