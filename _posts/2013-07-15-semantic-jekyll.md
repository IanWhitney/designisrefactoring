---
layout: post
title: "Semantic Jekyll"
description: ""
category: 
tags: []
---
Although Jekyll Bootstrap is a great way to get a blog up and running
quickly, I'm still someone who is going to tweak the HTML until I get a
document structure I want.

<!--more-->

I saw two big initial problems with the themes that come with JB: they
didn't use modern [HTML5 structure elements](http://alistapart.com/article/previewofhtml5), instead using divs to create document sections. And they didn't include [WAI-ARIA
roles](http://blog.paciellogroup.com/2013/02/using-wai-aria-landmarks-2013/), a newer
accessibility feature that I'm trying to use consistently.

So I customized the Tom theme to use these elements and packaged it up
into a new theme,
[semantic_jekyll](https://github.com/IanWhitney/semantic_jekyll/). I
might be using the term 'semantic' incorrectly here, but I thought it
applied as now the document struture uses more semantically useful
elements like nav, footer, article, etc. There are still divs in there,
but far fewer.

Feel free to use the theme or send any suggested changes my way.
