#!/usr/bin/env perl

# Bayamo (prototype version), by Jason McIntosh <jmac@jmac.org>

our $VERSION = '0.2';

use warnings;
use strict;

use FindBin;
use Getopt::Long qw( GetOptions );
use YAML qw( LoadFile );

use JSON::XS;

$| = 1;

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
    'json',
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
$config{ log_dir } //= "$FindBin::Bin/../log";
$config{ db_file } //= "$FindBin::Bin/../db/bayamo.db";
$config{ text_color } //= '000000';
$config{ seconds_to_pause } //= 600;

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

my %color;
my %last_post_by_me;

# This nick pattern allows nicknames like [#this] for the sake of
# ifirc's uncategorized-channel pseudo-nicks.
my $nick_pattern = '(?:\[#)?\+?\w+\]?';

# On exit, delete the db file.
$SIG{INT} = sub { unlink $db_file; exit; };

while ( my @events = $watcher->wait_for_events() ) {
    for my $event ( @events ) {
        my $log_file = Path::Class::File->new( $event->path );

        # We care only about channel-level traffic.
        next unless $log_file->parent->parent->basename eq 'Channels';

        my $db_key = "$log_file";

        my $channel_name = $log_file->parent->basename;
        my $network_name = $log_file->parent->parent->parent->basename;
        ( $network_name ) = $network_name =~ /^(\w+)/;

        my $channel_key = "$channel_name $network_name";

        my $fh = $log_file->openr;
        while ( my $log_line = <$fh> ) {

            if ( defined $last_line{ $db_key } ) {
                next if $. <= $last_line{ $db_key };
            }
            else {
                # If the file has no representation in the database, then read it
                # all the way to the end before we do anything else.
                # Otherwise it'll just dump the entire contents of the file
                # the first time Bayamo sees it, and that's not useful.
                until ( $fh->eof ) {
                    $log_line = <$fh>;
                }
            }

            $last_line{ $db_key } = $.;

            my ($w3_time, $message) = $log_line =~
                /^\[(.*?)\]\s+(.*)$/;

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
                $last_post_by_me{ $channel_key } = time;
            }
            if ( defined( $last_post_by_me{ $channel_key } )
                 && (
                    $last_post_by_me{ $channel_key } + $config{seconds_to_pause}
                    >= time
                 )
            ) {
                next;
            }

            my %line_info = (
                nick => $nick,
                nick_section => $nick_section,
                network_name => $network_name,
                channel_name => $channel_name,
                message => $message,
                channel_key => $channel_key,
            );

            if ( $config{ json } ) {
                print_json( \%line_info );
            }
            else {
                print_ansi( \%line_info );
            }
        }
    }
}

sub print_ansi {
    my ( $line_ref ) = @_;

    my $nick_color = get_color( $line_ref->{ nick } );
    my $channel_color = get_color( $line_ref->{channel_key} );

    my $meta_ansi = ansi256fg( $channel_color );
    my $nick_ansi = ansi256fg( $nick_color );
    my $message_ansi = ansi256fg( $config{text_color} );

    my $new_line =
        "[$line_ref->{network_name} $line_ref->{channel_name}] $line_ref->{message}\n";

    my $text = wrap( '', "\t", $new_line );

    my $nick_section_pattern = quotemeta $line_ref->{nick_section};
    $text =~
        s/$nick_section_pattern/$nick_ansi$line_ref->{nick_section}$message_ansi/;
    $text = "$meta_ansi$text";

    print $text;
}

sub print_json {
    my ( $line_ref ) = @_;

    print encode_json( $line_ref );
    print "\n";
}

sub get_color {
    my ( $channel_key ) = @_;

    unless ( exists $color{ $channel_key } ) {
        my $new_color = sprintf(
            '%02X%02X%02X',
            int(rand(96)) + 32,
            int(rand(96)) + 32,
            int(rand(96)) + 32,
        );
        $color{ $channel_key } = $new_color;
    }

    return $color{ $channel_key };
}
