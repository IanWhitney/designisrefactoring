---
layout: post
title: "Testing Sunspot with Sunspot_Matchers"
date: 2014-03-29 14:05:03 -0500
comments: true
categories: 
---

[Sunspot](http://sunspot.github.io/) is a way of doing [Solr](http://lucene.apache.org/solr/) searches with Ruby objects. We have an application that implements a somewhat complex search that can include a variety of parameters.

<!-- more -->

```ruby
FeeOccurrence.search do

  # a ton of search parameter parsing goes on.

  fulltext search_params[:search] unless search_params[:search].blank?

  all_of do
    with(:fiscal_year, fiscal_year.year)
    with(:fee_category_ids, search_params[:fee_category]) unless search_params[:fee_category].blank?
    with(:rrc_id, search_params[:rrc]) unless search_params[:rrc].blank?
    with(:fee_state, fee_states) unless fee_states.blank?
    with(:sort_fee_type, fee_type) unless fee_type.blank?

    if cannot? :view, Fee::Tuition
      without(:sort_fee_type, 'Tuition')
    end

    any_of do
      with(:synced_flag, true) if search_params[:search_synced_fees]
      with(:synced_flag, false) if search_params[:search_unsynced_fees]
    end

    any_of do
      with(:changed_flag, true) if search_params[:search_changed_fees]
      with(:changed_flag, false) if search_params[:search_unchanged_fees]
    end
  end

  if request.format.html?
    paginate(:page => params[:page], :per_page => params[:per_page])
  else
    paginate(:page => 1, :per_page => 1000000000)
  end

  order_by(params[:sort].to_sym, params[:order].to_sym)
end
```

My impression is that most people implement this method in the controller. We certainly did, and many samples I looked at did the same. This makes a certain sense, as search likely maps to a controller action. But having code of this size and complexity in a controller certainly smells fishy and makes me think we should extract this out.

We could extract this to the object being searched. But I lean towards extracting it to its own class, something whose sole responibility is encapsulating this Sunspot interaction.

And by extracting it to its own thing, we can give it its own suite of tests. But how do you test search? I don't really want to ensure that Sunspot works as advertised. And I certainly don't want to populate a database with a bunch of fixtures just so that I can search them. Boo for slow tests.

My inclination here would be to set expectations. If I execute a search for `name = blah` then Sunspot should receive `with(:name, 'blah')`. Simple enough.

Well...not really.

The fact that Sunspot wraps all of its search setup in a block breaks my normal approach. There's apparently nothing for me to set an expectation on. I tried a variety of increasingly dumb ways to test this, all to no avail.

Thankfully my boss is a better googler than I am and the people at Pivotal Labs are smarter than I am. My boss found [Sunspot Matchers](http://pivotallabs.com/test-driven-fulltext-search-in-2-commits-with-solr-sunspot-and-sunspot_matchers/) from a [Pivotal Labs blog post](http://pivotallabs.com/test-driven-fulltext-search-in-2-commits-with-solr-sunspot-and-sunspot_matchers/). This gem gives you the ability to spy on what Sunspot is doing and make assertions about the search configuration. It's mostly designed for Rspec, but a kind soul [added Test::Unit support](https://github.com/pivotal/sunspot_matchers/pull/5). But there are some slight differences between the two.

One of those differences is in spying on fulltext searching. In rspec, `:keywords` and `:fulltext` are synonymous. But the Test::Unit version only supports `:keywords`. A minor thing, but I have submitted [a pull request](https://github.com/pivotal/sunspot_matchers/pull/13) that fixes it. So it's possible that the gem is fixed by the time you read this.

Also, the behavior can also be slightly odd if you have a situation like the following. Say my Sunspot code has these two lines:

```ruby
with(:fee_state, search_params[:fee_states]) if search_params[:fee_states]
without(:fee_state, 'Protected') unless user.has_protected_access?
```

The first line just searches on whatever `fee_states` the user has selected, but only if the user has selected one or more fee_states. The 2nd line explicitly excludes Protected state if the user is prevented from seeing them.

In testing this, I would expect this test work:

```ruby
should "not include fee_state if fee_state parameters is absent" do
  test_params = {}
  # code to run search
  assert_has_no_search_params Sunspot.session, :with, :fee_state, any_param
end
```

Straightforward enough. I'm not including the `fee_states` key in my search params, so there should be no search criteria for fee_states.

Instead, this fails. It fails because Sunspot still adds the exclusion of fees in the procteced state.

Now, I don't think this should fail because I haven't added any `with` clauses for fee_states. Yes, I've added a `without` clause, but that's different. But sunspot_matchers (or Sunspot) thinks otherwise. So I have to test like so:

```ruby
  should 'search not search for fee states if not included' do
    user.stub(:can_see_protected?).returns(true)
    params.delete(:fee_states)
    search.results
    assert_has_no_search_params Sunspot.session, :with, :fee_state, any_params
  end
```

Now the user can see protected fees, thus the `without` clause isn't added, thus my tests pass. But to do so I have to stub some methods totally unrelated to the logic under test. I'm not sure if the gem has to behave in this way, but I have opened [an issue](https://github.com/pivotal/sunspot_matchers/issues/14). Maybe I can help fix this as well.

Little glitches aside, sunspot_matchers totally saved my butt this week. Without it I couldn't have possibly tested this code. And witohut tests the very necessary refactoring I did would have been next to impossible.
