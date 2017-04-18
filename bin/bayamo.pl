#!/usr/bin/env perl

# Bayamo (prototype version), by Jason McIntosh <jmac@jmac.org>

use warnings;
use strict;

use FindBin;
use Getopt::Long qw( GetOptions );
use YAML qw( LoadFile );

##########
# Set up the config hash, priming it with command-line options.
my %config;
GetOptions (
    \%config,
    'config_file=s',
    'log_dir=s',
    'db_file=s',
    'text_color=s',
    'my_nickname=s',
    'seconds_to_pause=s',
);

# Merge the contents of the config file, if present, into the config hash.
unless ( defined $config{ config_file } ) {
    $config{ config_file } = "$FindBin::Bin/../conf/bayamo.conf";
}

unless ( -r $config{ config_file } ) {
    die "Can't open config file $config{ config_file }: $!";
}

my $config_file_ref = LoadFile( $config{ config_file } );
foreach ( keys %$config_file_ref ) {
    unless ( exists $config{ $_ } ) {
        $config{ $_ } = $config_file_ref->{ $_ };
    }
}

# Set some defaults.
$config{ log_dir } ||= "$FindBin::Bin/../log";
$config{ db_file } ||= "$FindBin::Bin/../db/bayamo.db";
$config{ text_color } ||= '000000';
$config{ seconds_to_pause } ||= 600;

use Path::Class::Dir;
use File::ChangeNotify;
use DB_File;
use Color::ANSI::Util qw( ansi256fg );
use Text::Wrap qw( wrap );

my $log_dir = Path::Class::Dir->new( $config{log_dir} );

my $db_file = $config{db_file};

my %last_line;
tie %last_line, 'DB_File', $db_file;

my $watcher = File::ChangeNotify->instantiate_watcher(
    directories => [ "$log_dir" ],
);

$SIG{INT} = sub { warn "\nOkay, bye.\n"; exit; };

my %color;
my %last_post_by_me;

while ( my @events = $watcher->wait_for_events() ) {
    for my $event ( @events ) {
        my $log_file = Path::Class::File->new( $event->path );

        # We care only about channel-level traffic.
        next unless $log_file->parent->parent->basename eq 'Channels';

        my $db_key = "$log_file";

        $last_line{ $db_key } ||= 0;

        my $channel_name = $log_file->parent->basename;
        my $network_name = $log_file->parent->parent->parent->basename;
        ( $network_name ) = $network_name =~ /^(\w+)/;

        my $color_key = "$channel_name $network_name";
        my $channel_color = get_color( $color_key );

        my $fh = $log_file->openr;
        while ( my $log_line = <$fh> ) {
            next if $. <= $last_line{ $db_key };

            $last_line{ $db_key } = $.;

            my ($w3_time, $message) = $log_line =~
                /^\[(.*?)\]\s+(.*)$/;

            # This nick pattern allows nicknames like [#this] for the sake of
            # ifirc's uncategorized-channel pseudo-nicks.
            my $nick_pattern = '(?:\[#)?\w+\]?';

            # Textual-logged messages start with '<nick>' and emotes
            # start with "• nick". Ignore all lines that aren't this.
            # This ignores most meta-information.
            unless ( $message =~ /^(<$nick_pattern|• $nick_pattern)/ ) {
                next;
            }

            my ( $nick_section, $nick ) = $message =~ /(^.*?($nick_pattern)\S+)/;

            # If this is *my* nickname, then I appear to be actively engaged
            # in this channel, and I don't need to see its content in Bayamo
            # for a few minutes at least.
            if (
                defined $config{ my_nickname }
                && ( $nick eq $config{ my_nickname } )
            ) {
                $last_post_by_me{ $color_key } = time;
            }
            if ( defined( $last_post_by_me{ $color_key } )
                 && (
                    $last_post_by_me{ $color_key } + $config{seconds_to_pause}
                    >= time
                 )
            ) {
                next;
            }

            my $nick_color = get_color( $nick );

            my $meta_ansi = ansi256fg( $channel_color );
            my $nick_ansi = ansi256fg( $nick_color );
            my $message_ansi = ansi256fg( $config{text_color} );

            my $new_line =
                "[$network_name $channel_name] $message\n";

            my $text = wrap( '', "\t", $new_line );

            my $nick_section_pattern = quotemeta $nick_section;
            $text =~
                s/$nick_section_pattern/$nick_ansi$nick_section$message_ansi/;
            $text = "$meta_ansi$text";

            print $text;

        }
    }
}

sub get_color {
    my ( $color_key ) = @_;

    unless ( exists $color{ $color_key } ) {
        my $new_color = sprintf(
            '%02X%02X%02X',
            int(rand(96)) + 32,
            int(rand(96)) + 32,
            int(rand(96)) + 32,
        );
        $color{ $color_key } = $new_color;
    }

    return $color{ $color_key };
}
