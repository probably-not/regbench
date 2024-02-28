# Regbench

Some benchmarks of registries in Elixir in order to understand what issues there are in scale.

Benchmarks were ported (or at least I attempted to port them) from the [@ostinelli blog post about Process Registries in Erlang](http://www.ostinelli.net/an-evaluation-of-erlang-global-process-registries-meet-syn/).

Of course... I'm not great at Erlang, so maybe I screwed up the porting...

## Why?

I personally don't really believe people need to jump on the "built-in Erlang `:global` is bad at scale!!!" train that everyone immediately jumps on when people start talking about distributed registries in Elixir. I don't think anybody who is jumping on that train is actually getting to a point where it seriously affects scale (seeing as the `:global` can get to a few thousand registrations per second according to the blog post and lookups are consistently very low). However, the post was written in 2015, and I wanted to see whether Syn (and the conclusions that [@ostinelli](https://github.com/ostinelli) came to) still hold up.

## Results

TODO: Fill in results!