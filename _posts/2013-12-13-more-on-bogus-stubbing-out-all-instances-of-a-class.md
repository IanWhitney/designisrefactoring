---
layout: post
title: "More on Bogus: Stubbing out all instances of a class"
description: ""
category: 
tags: []
---
I continue working with [Bogus](https://github.com/psyho/bogus/) and finding how to do things that I think should be easy, but that Bogus doesn't make very clear. Hopefully this blog post will help those similarly confused.

<!--more-->

Today I needed to test a controller. The controller method is dead stupid.

    def create
      account = Account.new(params)
      if account.valid?
        render nothing: true
      else
        head :bad_request
      end
    end

The normal Bogus approach relies heavily on dependency injection, which doesn't work for controller tests. I can't create the instance of Account outside of the controller and pass it into the create method. So I had to set up Bogus so that it would stub all instances of Account.

    describe AccountsController do
      describe "Creation" do
        fake(:account)

        it "gives a bad request if the accout details are invalid " do
          stub(account).valid? {false}
          stub(Account).new(any_args) { account }
          ...
        end
     end
    end

I don't see this documented in Bogus itself, but I found the hint I needed by looking at [this issue](https://github.com/psyho/bogus/issues/36)
