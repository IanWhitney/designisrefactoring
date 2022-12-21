---
layout: post
title: "Validating associated plain Ruby objects"
description: ""
category: 
tags: []
---
In an application I'm working on, people can leave comments on a record. When they comment, they can also choose to email that comment to their co-workers. The client wanted the application to validate these email addresses and show an error if the commenter entered a bad email address.

<!--more-->

The email addresses aren't persisted. No reason to, as they are only used when sending out the email. So, there's no ActiveRecord model for `CommentRecipent` or anything like that. But the nicety of ActiveRecord-style validation was exactly what I was looking for. All I wanted the comment controller to do was something like this:

    def create
      ...
      if comment.save?
        # Send emails and notify the commenter of success
      else
        # notify commenter of problems with comment
      end
    end

Now, probably the most thorough way to approach this would be to create a plain-old-Ruby-object or two and get them to pass the [ActiveRecord Lint tests](http://yehudakatz.com/2010/01/10/activemodel-make-any-ruby-object-feel-like-activerecord/) and then have them use ActiveRecord validation. It works, and I've done that in the past. But this time I aimed for something a little lighter weight. What I wanted was for the Comment model to have these lines:

    validates_associated :recipients

    def recipients
      @recipients ||= CommentRecipients.new
    end

And then a comment could manage its recipients with an API like:

    @comment.recipients.add "someemail@test.com"
    @comment.recipients.valid?
    @comment.recipients.each do {|recipient| send_email_to(recipient)}

That's pretty much all I needed.

Looking at the [validates_associated documentation](http://apidock.com/rails/ActiveRecord/Validations/ClassMethods/validates_associated), I see that it eventually calls this code:

    if Array.wrap(value).reject {|r| r.marked_for_destruction? || r.valid?}.any?
      record.errors.add(attribute, :invalid, options.merge(:value => value))
    end

So for my recipients object it needs to respond to valid? and `marked_for_destruction?`. Valid? makes sense, but `marked_for_destruction?`, what is that? Here's the Rails documentaion description:

    Returns whether or not this record will be destroyed as part of the parents save transaction.

Since recipients are never perisisted, they are never marked for destruction. So I can just have this return false. So, now I know most of the methods my recipients object will have to handle:

- valid?
- marked_for_destruction?
- each
- add

And here's a first pass:

    class CommentRecipients
      include Enumerable

      def add(address)
        recipients << address
      end

      def recipients
        @recipients ||= []
      end

      def each(&block)
        @recipients.each do |r|
          block.call(r)
        end
      end

      #This method is here just so Comment can use validates_associated
      def marked_for_destruction?
        false
      end

      def valid?
      end

      private
    end

Including Enumerable lets me make this act like a collection. The collection of recipients lives in an Array (a Set might be better, actually), which grows by using `add`. I've defined #each do just iterate through the collection of recipients and I've hard-coded `marked_for_destruction?` to always return false. The only thing missing here is valid?

You could go about this a couple of ways. Define valid to iterate through @recipients and return `false` unless they all have valid email addresses. Or you could extract a CommentRecipent out to its own class. I did the latter. All the CommentRecipient has to respond to is `new`, `valid` and provide a way to set its address:

    class CommentRecipient
      attr_accessor :address

      def initialize(address="")
        self.address = address
      end

      def address=(x)
        @address = x.strip
      end

      def valid?
        /^.+@.+$/.match(address)
      end
    end

Not much to explain there. The only weird bit might be my valid? regex, as it's much less complex than most email validation patterns. I went that way after reading [this blog post](http://davidcel.is/blog/2012/09/06/stop-validating-email-addresses-with-regex/) about the hassle of regex-based email validation. This super-dumb pattern is good enough for now.

Introducing the new CommentRecipient introduces some changes to my Recipients collection:

    class CommentRecipients
      include Enumerable

      def add(address)
        recipients << CommentRecipient.new(address)
      end

      ...

      def each(&block)
        @recipients.each do |r|
          block.call(r.address)
        end
      end

      ...

      def valid?
        invalid_recipients.empty?
      end

      private

      def invalid_recipients
        recipients.select {|r| !r.valid?}
      end
    end

Normally that each definition would return each recipient, but I have it returning each address for the purpose of integrating with some other code that should probably be rewritten.

And this works. A comment now validates its recipients and won't save if one of them is invalid. And the application returns this awesome error message:

    Recipient is invalid

Well, that's super useful! Let's turn that into something a human can understand. I could define the error collection and set up the messages in there. Or I could use the Rails internationalization library, which is way easier for this one simple case. If I had a situation where a Recipient could be invalid for a variety of reasons I'd take the more robust errors approach. But in this situation I could just add the following to `config/locals/en.yml`

    activerecord:
      attributes:
        comment:
          recipients: "Other recipients"
      errors:
        models:
          comment:
            attributes:
              recipients:
                invalid: "can only contain valid email addresses. Separate multiple addresses with a comma."

And now we have a much better validation message.
