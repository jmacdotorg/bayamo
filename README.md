# Bayamo

Bayamo is a _braided chat stream viewer_. Feed it many disparate chat sources (so long as they're all either IRC or forcibly mashed through IRC gateways), and it will knit them into a single, completely non-interactive text stream.

**This is a very early proof-of-concept prototype,** shared in the spirit of sharing and not under any assumption that anyone besides the creator might make immediate practical use of it. Friend, it doesn't even have command-line options yet, let alone a version number.

<!--
[You can read an apologia for Bayamo on its creator's blog.]()
-->

## Sample output

A typical minute-long span of typical use:

![A screenshot of Bayamo in action](http://fogknife.com/images/posts/bayamo-prototype.png)

Within this sample -- whose IRC nicks have been blotted out for propriety's sake -- we see conversations from two [Freenode IRC](http://freenode.net) channels (#macos and #perl), the general channel a private social Slack I inhabit, and the video games discussion channel of [IFMud]. Four message-sources from three wholly separate networks, but all presented in the same flow from my perspective.

## Requirements

You need to have a copy of [the Textual IRC client](https://www.codeux.com/textual/) running on macOS. (I know, right? _Prototype._)

## Usage

1. Configure Textual to log everything, if it is not already so configured. (Look under Textual &rarr; Preferences &rarr; Adavnced &rarr; Log Location.)

1. Copy `conf/bayamo-example.conf` to `conf/bayamo.conf`, and update as appropriate.

1. Run it from the command line! Whee!

## Blame

Jason McIntosh ([jmac@jmac.org](mailto:jmac@jmac.org), GitHub: [jmacdotorg](https://github.com/jmacdotorg), Twitter: [@jmacdotorg](http://twitter.com/jmacdotorg)) created this tool. Questions, comments, et cetera to him. Pull requests always welcome. Thanks!