#!perl

use strict;
use warnings;

use Test::More tests => 4;
use FindBin qw($Bin);

use AtomicParsley::Command::Tags;
use AtomicParsley::Command;

my $ap = AtomicParsley::Command->new;
my $tags;
my $testfile = "$Bin/resources/Family.mp4";

# read_tags from tempfile that contains title, artist and genre
my $read_tags = $ap->read_tags($testfile);

# update
my $write_tags = AtomicParsley::Command::Tags->new(
    title   => '',
    artist  => ' ',
    genre   => undef,
    );
my $new_file = $ap->write_tags( $testfile, $write_tags );

# and read 
my $new_tags = $ap->read_tags($new_file);
is( $new_tags->title, undef, 'removed' );
is( $new_tags->artist, ' ', 'modified' );
is( $new_tags->genre, 'Comedy', 'kept' );

unlink $new_file;
ok( !-e $new_file );
