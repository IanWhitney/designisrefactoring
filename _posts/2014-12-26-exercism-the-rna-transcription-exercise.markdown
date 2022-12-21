---
layout: post
title: "Exercism: The RNA Transcription Exercise"
date: 2014-12-26 12:35:35 -0600
comments: true
categories: 
---

[The Readme](https://github.com/exercism/x-common/blob/master/rna-transcription.md)

[The Test Suite](https://github.com/exercism/xruby/blob/master/rna-transcription/complement_test.rb)

As with the Gigasecond exercise, it doesn't take much to get this to pass. The example solution is:

```ruby 
class Complement
  def self.of_dna(strand)
    strand.tr('CGTA', 'GCAU')
  end

  def self.of_rna(strand)
    strand.tr('GCAU', 'CGTA')
  end
end
```

(An aside: Did you know that Exercism has example solutions in [their Git repo](https://github.com/exercism/xruby/blob/master/rna-transcription/example.rb)? I did not. I was wondering why 40% of people's solutions looked exactly the same. Copying and pasting ain't learning, folks)

<!--more-->

I, personally, have never seen `tr` in the wild, so that was not my first solution. Mine was super dumb, and much longer.

```ruby
class Complement
  def self.of_dna(strand)
    ret = ""
    strand.each_char { |x| ret << find_dna_complement_of(x) }
    ret
  end

  def self.of_rna(strand)
    ret = ""
    strand.each_char { |x| ret << find_rna_complement_of(x) }
    ret
  end

  def self.find_dna_complement_of(nucleotide)
    case nucleotide
    when 'C'
      'G'
    when 'G'
      'C'
    when 'T'
      'A'
    when 'A'
      'U'
    end
  end

  def self.find_rna_complement_of(nucleotide)
    case nucleotide
    when 'C'
      'G'
    when 'G'
      'C'
    when 'U'
      'A'
    when 'A'
      'T'
    end
  end
end
```

My [commit message](https://github.com/IanWhitney/exercism_problems/commit/41e206b405e242fd166b3ade7448385f8f34de52) talks a bit about the duplication in this code and I try to highlight the [knowledge duplication](http://cleancoders.com/episode/bawch-episode-4/show) that I want to remove in my next commit. Which I did, thusly:

```ruby
  #...
  def self.of_dna(strand)
    build_complement_for(strand, "dna")
  end

  def self.of_rna(strand)
    build_complement_for(strand, "rna")
  end

  def self.build_complement_for(strand, type)
    ret = ""
    strand.each_char { |x| ret << public_send("find_#{type}_complement_of".to_sym, x) }
    ret
  end
  #...
```

Better. But a giant red flag just went up -- a parameter named `type`. That almost always means one thing: I'm trying to implement polymorphism without using classes. Rarely a good idea. Here come the RNA and DNA classes:

```ruby
class Complement
  def self.of_dna(strand)
    build_complement_for(strand, DNA)
  end

  def self.of_rna(strand)
    build_complement_for(strand, RNA)
  end

  def self.build_complement_for(strand, type)
    ret = ""
    strand.each_char { |x| ret << type.new(x).complement }
    ret
  end
end

class RNA
  attr_accessor :nucleotide

  def initialize(nucleotide)
    self.nucleotide = nucleotide
  end

  def complement
    case nucleotide
    when 'C'
      'G'
    when 'G'
      'C'
    when 'U'
      'A'
    when 'A'
      'T'
    end
  end
end

class DNA
  #...same as RNA except for the complement return values
end
```

Ok, but why don't RNA and DNA know anything about strands? That seems like something they should know.


```ruby
class Complement
  def self.of_dna(strand)
    DNA.new(strand).complement
  end

  def self.of_rna(strand)
    RNA.new(strand).complement
  end
end

class RNA
  attr_accessor :strand

  def initialize(strand)
    self.strand = strand
  end

  def nucleotides
    strand.chars
  end

  def complement
    nucleotides.inject("") do |ret, nucleotide|
      ret << complement_of(nucleotide)
    end
  end
  #...
end
#...
```

And then we can make it more Ruby-like by using its `to_*` idiom, creating the [`to_dna` and `to_rna` methods](https://github.com/IanWhitney/exercism_problems/commit/cce80eb93332cf4de38e5037f93a3d201b162d7f)

Also, here I'm moving the resonsibility of knowing about complements. Previously, DNA would know what its RNA complement was. Why? DNA should know DNA complements and RNA should know RNA complements. If DNA wants to know about RNA, it should ask RNA.

```ruby
class Complement
  def self.of_dna(strand)
    DNA.new(strand).to_rna
  end

  def self.of_rna(strand)
    RNA.new(strand).to_dna
  end
end

class RNA
  attr_accessor :strand

  def self.complement_for(nucleotide)
    {"C" => "G", "G" => "C", "T" => "A", "A" => "U"}[nucleotide]
  end

  #...

  def to_dna
    nucleotides.inject("") do |ret, nucleotide|
      ret << DNA.complement_for(nucleotide)
    end
  end
end

class DNA
  #... you can imagine what this looks like
end
```

Finally, I tackle the obvious problem of inheritance. DNA and RNA are both examples of nucleic acids and their behavior is almost exactly the same. I'm comfortable with using inheritance here because I don't see any of the common inheritance problems arising. This is a shallow, narrow object family; and there aren't going to be weird grand-children classes or partial API implementations. My final solution to the problem:

```ruby
class Complement
  def self.of_dna(strand)
    DNA.new(strand).to_rna
  end

  def self.of_rna(strand)
    RNA.new(strand).to_dna
  end
end

class NucleicAcid
  attr_accessor :strand

  def initialize(strand)
    self.strand = strand
  end

  def nucleotides
    strand.chars
  end

  def transcribe_to(acid)
    nucleotides.inject("") do |ret, nucleotide|
      ret << acid.complement_for(nucleotide)
    end
  end

  def to_dna
    raise StandardError, "Call this on descendants"
  end

  def to_rna
    raise StandardError, "Call this on descendants"
  end

  def self.complement_for(nucleotide)
    raise StandardError, "Call this on descendants"
  end
end

class RNA < NucleicAcid
  def self.complement_for(nucleotide)
    {"C" => "G", "G" => "C", "T" => "A", "A" => "U"}[nucleotide]
  end

  def to_dna
    transcribe_to(DNA)
  end

  def to_rna
    self
  end
end

class DNA < NucleicAcid
  def self.complement_for(nucleotide)
    {"C" => "G", "G" => "C", "U" => "A", "A" => "T"}[nucleotide]
  end

  def to_rna
    transcribe_to(RNA)
  end

  def to_dna
    self
  end
end
```

My one hesitation here was having a `to_dna` method on DNA and a `to_rna` method on RNA. These methods have to be there to satisfy [Liskov](https://en.wikipedia.org/wiki/Liskov_substitution_principle), but I wondered if they were necessary. However, Ruby actually has a lot of methods like this. For example, String instances respond to `to_s`, and Integers respond to `to_i`. Realizing that made me a lot more comfortable with my approach.

As has been true in all of my Exercism solutions, this code goes far beyond what it needs to do in order to get the tests to pass. It's also about 60 lines longer than Exercism's own example solution. Is there value in this verbosity? That is not a question with a single answer. If I were writing this code to help me pass a Biology 101 class, then no. If I were writing it for use in a synthetic biology lab that is creating their own nucleic acids? Then maybe.

But I'm writing it for Exercism (and for these blog posts). Exercism wants me to, "Make the tests pass. Keep the code as simple, readable, and expressive as you can." And it advises nitpickers to make suggestions that make the code:

1. Simple
2. Readable
3. Maintainable
4. Modular

Those 4 rules are pretty close to the "4 Rules of Simple Design", as stated by [Corey Haines](https://leanpub.com/4rulesofsimpledesign)

1. Tests pass
2. Express Intent
3. No duplication of knowledge
4. Small

Or, if you prefer [Sandi Metz's acronym](http://www.poodr.com/), code that is TRUE

1. Transparent
2. Reasonable
3. Usable
4. Exemplary

These descriptions of "good design" (or "better design", if you're Corey Haines) are all different words to describe code that people have found easy to work with over a long period of time. Because design doesn't matter if you just want to run the code once. If you want to do that, just slap in Exercism's example code and move on. Plenty of people do.

But if you're trying to design better code, then you need to look at more than just making a few tests pass. The questions I like to ask myself are:

1. Will I understand this code if I look at it in 6 months?
2. Will my co-workers understand this code when they have to fix it?
3. Will future maintaners be able to extend this code with very little hassle?
4. Will other teams be able to extend this code without problems?

The first question affects just me, the second affects 3-5 people, the third affects dozens and the fourth affects an uknown number of people. Thinking about the number of people that will be able to easily understand/use/modify your code is a usefuly way of thinking about design. Poorly designed code will not satisfy many people; well desgined code will.

So, with that in mind, let's circle back to the original question. Is there value in my Exercism solution? I obviously think so, but I'm biased. I'll leave the question for you to answer. Which code would you rather work with?
