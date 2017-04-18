# Bayamo

Bayamo is a _braided chat stream viewer_. Feed it many disparate chat sources (so long as they're all either IRC or forcibly mashed through IRC gateways), and it will knit them into a single, completely non-interactive text stream.

**This is a very early proof-of-concept prototype,** shared in the spirit of sharing and not under any assumption that anyone besides the creator might make immediate practical use of it.

<!--
[You can read an apologia for Bayamo on its creator's blog.]()
-->

## Sample output

A typical minute-long span of typical use, seen in a macOS Terminal window:

![A screenshot of Bayamo in action](http://fogknife.com/images/posts/bayamo-prototype.png)

Within this sample -- whose IRC nicks have been blotted out for propriety's sake -- we see conversations from two [Freenode IRC](http://freenode.net) channels (#macos and #perl), the general channel a private social Slack I inhabit, and the video games discussion channel of [IFMud](http://ifmud.port4000.com). Four message-sources from three wholly separate networks, but all presented in the same flow from my perspective.

I leave the question of how I access an IRC network, a Slack, and a MUD through a single IRC client as an exercise for the reader.

## Requirements

You need to have a copy of [the Textual IRC client](https://www.codeux.com/textual/) running on macOS. (I know, right? _Prototype._)

As for the required Perl modules: if you enjoy blindly running `curl | bash` invocations straight off of GitHub README files as much as I do, then you can just do this:

    curl -fsSL https://cpanmin.us | perl - --installdeps .
    
More conservative users can install [cpanm](https://github.com/miyagawa/cpanminus) manually and then run `cpanm --installdeps .` instead.


## Usage

1. Configure Textual to *log everything*, if it is not already so configured. (Look under Textual &rarr; Preferences &rarr; Adavnced &rarr; Log Location.)

1. Do not configure Textual to format logged usernames and timestamps and such in any way other than its default.

    If you're already a Textual user who has customized all this stuff and long since forgotten its factory defaults, this isn't going to work too well. Ha ha! I did mention this was a prototype, right?

1. Copy `conf/bayamo-example.conf` to `conf/bayamo.conf`, and update as appropriate. (See below for the full list

1. Run it from the command line. You can provide command-line options to override the config file or Bayamo's own defaults. (Example: `bin/bayamo --my_nickname=AnnePerkins`

## Configuration

Each of these can be set as config-file directives, or as command-line options.

* **config_file** Local filesystem path to Bayamo's config file.

    Default: [Bayamo's location]/../conf/bayamo.conf
    
* **db_file** Local filesystem path to Bayamo's database file. If it doesn't exist, Bayamo will create it, so long as it can write to the enclosing directory.

    Default: [Bayamo's location]/../db/bayamo.db
    
* **log_dir** Local filesystem path to Textual's top-level log directory.

    Default: [Bayamo's location]/../log/
    
* **my_nickname** If you define this, then Bayamo will try to detect channels you're actively engaged in, and not display any text from them for a while.

    No default value.
    
* **seconds_to_pause** The length of time, in seconds, that Bayamo will ignore a channel after you yourself say something inside it.

    Default: 600
    
* **text_color** The six-character hexadecimal RGB code that Bayamo should use for message text display (versus channel and nick display).

    Default: 000000

## Project status

I have no idea what Bayamo wants to be yet. It probably doesn't just want to be a short script that works with a very specific IRC client setup and then just prints to STDOUT.

I think this is an idea with legs, and I look forward to seeing where it walks me. I shall update this repository when appropriate.

## Blame

Jason McIntosh ([jmac@jmac.org](mailto:jmac@jmac.org), GitHub: [jmacdotorg](https://github.com/jmacdotorg), Twitter: [@jmacdotorg](http://twitter.com/jmacdotorg)) created this tool. Questions, comments, et cetera to him. Pull requests always welcome. Thanks!