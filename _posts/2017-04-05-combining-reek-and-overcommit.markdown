---
layout: post
title: "Combining Reek and Overcommit"
date: 2017-04-05T17:29:01-05:00
---

My team has been using [Overcommit](https://github.com/brigade/overcommit) for a while. We like how easy it makes it to set up Git commit hooks for the entire team and how easy it is to see what those hooks are.

Recently we decided to add [Reek](https://github.com/troessner/reek) to our Code Quality process. To make it automatic we wanted to run Reek as part of our pre-commit hook. Overcommit [already has a default hook for Reek](https://github.com/brigade/overcommit/blob/master/lib/overcommit/hook/pre_commit/reek.rb), so making Reek run as part of every commit was super easy. Great!

But.

When committing Reek warned us about smells that we couldn't change. For example, Reek doesn't like the default Rails migration syntax for a variety of (good) reasons. But my team isn't going to change the Rails migration syntax so having Reek warn us about those changes wasn't useful.

Reek offers many ways to silence these warnings. A recent addition is the `exclude_paths` configuration option. If you have this in your Reek config file

```
# Directories below will not be scanned at all
exclude_paths:
  - db/migrate
```

Then when you run `reek .` it won't tell you about any smelly files in `db/migrate`. Hooray!

But.

When we ran Reek in our pre-commit hook it kept warning us about files in `db/migrate`. Why?

Well, what Overcommit does is ask Git for a list of all files that have changed. It then passes each of those files to Reek. So, if a file changes in `db/migrate` then Reek is run with 

```
reek ./db/migrate/file_that_changed.rb
```

And Reek's behavior is to always check a file if given a path to a specific file. Even if the file is in an excluded directory.

Sigh.

After checking if it was cool with the Reek team we submitted a couple of PRs that gave Reek a new option `--force-exclusion`. We chose the flag name because it's the same one used by [Rubocop](https://github.com/bbatsov/rubocop/blob/022e7322b731b06bd31ce5ef1bac378b27551ed0/spec/rubocop/options_spec.rb#L48). Might as well be consistent. The flag tells Reek to ignore files in an excluded path, even when provided the path to a specific file. This work has been merged into Reek as of version 4.6.0, though you probably want 4.6.1 because of a bug with absolute paths.

For Overcommit to use the new flag you'll need to update your `.overcommit.yml` file:

```yml
PreCommit:
  Reek:
    enabled: true
    flags: ['--single-line', '--no-color', '--force-exclusion']
```

If you skip that part Reek will not use the new flag and you'll still get warnings about files in excluded paths.

Now you can easily combine the great work of the Reek and Overcommit teams. Thanks to them for managing such helpful projects!
