---
layout: post
title: "CORS with authentication via POST and cookies"
description: ""
category: 
tags: []
---
Ember apps frequently need to talk to web APIs. And those APIs are
frequently on other sites than the Ember app. Doing Javascript requests
between these two sites is problematic because of the [same origin
policy](http://en.wikipedia.org/wiki/Same_origin_policy).

<!--more-->

A couple of weeks ago I ran into this problem while learning Ember. I
wanted Ember to pull data from my [goofy test site](http://theflophouserecommends.herokuapp.com/), but immediately ran afoul of the same origin policy. I solved it there by using [JSONP](http://en.wikipedia.org/wiki/JSONP), which isn't the best approach.

For work I needed to solve the same problem but couldn't use JSONP, so I
got to use its suggested replacement, [Cross-origin resource sharing](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) (CORS). Where JSONP wraps JSON in some braces so that the browsers can pretend they aren't violating single origin, CORS requires you to explicitly set up your API server to allow cross-site requests.

Most guides I've seen have a setup like this:

    Header set Access-Control-Allow-Origin "*"

Which basically says "Hey, everyone get a taste of my API." It's a fast
way to get your server set up on CORS, but it also has 0 restrictions.
In some cases this is great -- I certainly wouldn't want to lock down an
API that I wanted people to use freely. But in the case I was working
on, I needed a more complex setup. And there's not a lot of
documentation on the Web about more complex setups.

I needed to solve some problems:

- I needed to authenticate with the API server via a POST request.
- My subsequent GET requests needed to include a cookie.
- I needed to restrict the server so that it only allowed POST and GET
  requests.

The last one is the easiest. Your server configuration file will need a
line like this:

    <add name="Access-Control-Allow-Methods" value="GET,POST,OPTIONS" />

That's IIS7 specific, but your server will have something similar.
2/3rds of those verbs are simple enough but the OPTIONS verb might seem
weird. That one is explained well [here](http://www.html5rocks.com/en/tutorials/cors/#toc-handling-a-not-so-simple-request).

In order for the server to work with cookies cross-site, I needed this
line:

    <add name="Access-Control-Allow-Credentials" value="true" />

And by including that line, I'm now prevented from using the `*`
wildcard for `Access-Control-Allow-Origin`, meaning I now have to
restrict it to a single domain. There are ways to allow multiple
domains, but they are server specific and can probably be googled. So
for the purposes of my development, I have:

    <add name="Access-Control-Allow-Origin" value="http://localhost:8888" />


I also have this in my server config, but I have no idea why it's there.
I totally cargo-culted it in:

    <add name="Access-Control-Allow-Headers" value="Content-Type" />

And that's the server-side of things. On to the client.

In my POST request for authentication, I ended up with the following
jQuery code:

    $.ajax({
      type: 'POST',
      url: 'https://server.boo',
      data: "{username: 'user', password: 'password!'}",
      contentType: 'text/json',

      xhrFields: {
        withCredentials: true 
      },

      headers: {
      },

      success: function(response) {
        //Do something on success
      },

      error: function(response) {
        //Do something on error
      }
    });

Yours might be slightly different as I had to hit a weird resource and
pass it JSON for authentication. The important bit of this code is
`withCredentials: true` as it tells the browser to save the cookie it
gets in response to this request.

The code for GET requests is as follows:

    $.ajax({
      type: 'GET',
      url: 'https://server.boo/~api',
      data: {fields: "Id,Resource.Name,Resource.Thing"},
      xhrFields: {
        withCredentials: true 
      },
      headers: {
      },
      success: function(response) {
        //Do something on success
      },
      error: function(response) {
        //Do something on error
      }
    });

And that sends off a nice request that looks like:

    https://server.boo/~api?fields=Id,Resource.Name,Resource.Thing

Which is what I need for the API I'm working with.

Again, the important part here is `withCredentials:true` as that tells
the request to include the cooke that I saved when authenticating.

As useful as CORS is, I found it really hard to find good documentation
on how to set up anything more advanced than the "Let everyone have
access!" approach. Hopefully this helps someone out.
