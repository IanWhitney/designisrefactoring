---
layout: post
title: "Creating images from JSON in Rails"
description: ""
category: 
tags: []
---
In a recent project I was asked to dynamically generate images that
would show the events scheduled in a room. The event data is stored in
an external system which I could get access to through its API.

<!--more-->

A little googling turned up
[IMGKit](https://github.com/csquared/IMGKit), which wraps around the
[wkhtmltoimage](https://github.com/antialize/wkhtmltopdf) program.

I created a tiny Rails app that only had one route
/room/[room_id]/events. And I limited the events conttroller to only one
action, :index. Then I defined one view /events/index.jpg.erb

    <% events.each do |event| %>
      <%= event.description %>
    <% end %>

Within the event#index action the creation of the image was handled with

    def index
      ...
      kit = IMGKit.new(render_to_string, width: 480, height: 800, :quality => 100)
      ...
      respond_to do |format|
        format.jpg do
          send_data(kit.to_jpg, :type => "image/jpeg", :disposition => 'inline')
        end
      end
    end

That's stuff you can learn in the IMGKit readme, though. Nothing too
exciting there. But I ran into some further problems that might be of
interest.

First: `render_to_string` renders only the action's template code, it
won't use the controller's layout file, or the application.html.erb
file. Even if you pass the right flag:

    render_to_string(:layout => true)

I couldn't get that to work at all. So if you have CSS files or HTML
structure that you need in your view, you'll have to put it inside the
action's erb file. So, my code in `/app/views/events/index.jpg.erb` file
ended up looking like:

    <!DOCTYPE html>
    <html>
    <head>
      <title>Amxtest</title>
      <style type='text/css'>
        html {
          ...
        }
        /* etc */
    </head>
    <body>
      ...
    </body>
    </html>

Also note that linking to files using `image_tag` or `stylesheet_tag`
won't work the way you expect. Relative links don't seem to work at all,
with or without Rails.root.

I solved this by setting environment-specific IMG_ROOT constant. So for
development it's set to `http://localhost:3000/` and then when I need to
show an image in my view, I save it to the /public/images directory and
link to it with:

    <%= image_tag("#{IMG_ROOT}/images/image_name.jpg") %>

An ugly hack, but it solved my problem.

This linking problem also means you can't easily include a CSS file in
your view. You could probably fix it the same way I fixed images, but
IMGKit offers this code that you can use inside the controller:

    kit = IMGKit.new(render_to_string, width: 480, height: 800, :quality => 100)
    css = File.open("#{Rails.root}/app/assets/stylesheets/images.css")
    kit.stylesheets << css

Lastly, the creation of images can take a few seconds, especially if
you're pulling data from a 3rd party service. So you'll probably want to
look at caching. That's a whole other topic, though.
