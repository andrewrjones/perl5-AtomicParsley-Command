use 5.010;
use strict;
use warnings;

package AtomicParsley::Command;

# ABSTRACT: Interface to the Atomic Parsley command

use AtomicParsley::Command::Tags;
use IPC::Cmd '0.72', ();
use File::Spec '3.33';
use File::Copy;

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # the path to AtomicParsley
    my $ap = $args->{'ap'} // 'AtomicParsley';
    $self->{'ap'} = IPC::Cmd::can_run($ap) or die "Can not run $ap";
    $self->{'verbose'} = $args->{'verbose'} // 0;

    $self->{'success'}       = undef;
    $self->{'error_message'} = undef;
    $self->{'full_buf'}      = undef;
    $self->{'stdout_buf'}    = undef;
    $self->{'stderr_buf'}    = undef;

    bless( $self, $class );
    return $self;
}

sub read_tags {
    my ( $self, $path ) = @_;

    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    my $cmd = [ $self->{ap}, $path, '-t' ];

    # run the command
    $self->_run($cmd);

    # parse the output and create new AtomicParsley::Command::Tags object
    my $tags = $self->_parse_tags( $self->{'stdout_buf'}[0] );

    # $tags
    return $tags;
}

sub write_tags {
    my ( $self, $path, $tags, $replace ) = @_;

    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    my $cmd = [ $self->{ap}, $path, $tags->prepare ];

    # run the command
    $self->_run($cmd);

    # return the temp file
    my $tempfile = $self->_get_temp_file( $directories, $file );

    if ($replace) {

        # move
        move( $tempfile, $path );
        return $path;
    }
    else {
        return $tempfile;
    }
}

# Run the command
sub _run {
    my ( $self, $cmd ) = @_;

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => $cmd, verbose => $self->{'verbose'} );

    $self->{'success'}       = $success;
    $self->{'error_message'} = $error_message;
    $self->{'full_buf'}      = $full_buf;
    $self->{'stdout_buf'}    = $stdout_buf;
    $self->{'stderr_buf'}    = $stderr_buf;
}

# Parse the tags from AtomicParsley's output.
# Returns a new AtomicParsley::Command::Tags object
sub _parse_tags {
    my ( $self, $output ) = @_;

    my %tags;
    for my $line ( split( /\n/, $output ) ) {
        if ( $line =~ /^Atom \"(.+)\" contains: (.*)$/ ) {
            my $key   = $1;
            my $value = $2;
            given ($key) {
                when (/alb$/) {
                    $tags{'album'} = $value;
                }
                when ('aART') {
                    $tags{'albumArtist'} = $value;
                }
                when (/ART$/) {
                    $tags{'artist'} = $value;
                }
                when ('catg') {
                    $tags{'category'} = $value;
                }
                when (/cmt$/) {
                    $tags{'comment'} = $value;
                }
                when ('cprt') {
                    $tags{'copyright'} = $value;
                }
                when (/day$/) {
                    $tags{'year'} = $value;
                }
                when ('desc') {
                    $tags{'description'} = $value;
                }
                when ('disk') {
                    $value =~ s/ of /\//;
                    $tags{'disk'} = $value;
                }
                when (/ge?n(|re)$/) {
                    $tags{'genre'} = $value;
                }
                when (/grp$/) {
                    $tags{'grouping'} = $value;
                }
                when ('keyw') {
                    $tags{'keyword'} = $value;
                }
                when (/lyr$/) {
                    $tags{'lyrics'} = $value;
                }
                when (/nam$/) {
                    $tags{'title'} = $value;
                }
                when ('rtng') {
                    $tags{'advisory'} = _get_advisory_value($value);
                }
                when ('stik') {
                    $tags{'stik'} = $value;
                }
                when ('tmpo') {
                    $tags{'bpm'} = $value;
                }
                when ('trkn') {
                    $value =~ s/ of /\//;
                    $tags{'tracknum'} = $value;
                }
                when ('tven') {
                    $tags{'TVEpisode'} = $value;
                }
                when ('tves') {
                    $tags{'TVEpisodeNum'} = $value;
                }
                when ('tvsh') {
                    $tags{'TVShowName'} = $value;
                }
                when ('tvnn') {
                    $tags{'TVNetwork'} = $value;
                }
                when ('tvsn') {
                    $tags{'TVSeasonNum'} = $value;
                }
                when (/too$/) {
                    $tags{'encodingTool'} = $value;
                }
                when (/wrt$/) {
                    $tags{'composer'} = $value;
                }
            }
        }
    }

    return AtomicParsley::Command::Tags->new(%tags);
}

# Try our best to get the name of the temp file.
# Unfortunately. the temp file contains a random number,
# so this is a best guess.
sub _get_temp_file {
    my ( $self, $directories, $file ) = @_;

    # remove suffix
    $file =~ s/(\.\w+)$/-temp-/;
    my $suffix = $1;

    # search directory
    for my $tempfile ( glob("$directories*$suffix") ) {

        # return the first match
        if ( $tempfile =~ /^$directories$file.*$suffix$/ ) {
            return $tempfile;
        }
    }
}

# Get the advisory value of an mp4 file, if present.
sub _get_advisory_value {
    my $advisory = shift;

    # TODO: check all values
    given ($advisory) {
        when ('Clean Content') {
            return 'clean';
        }
    }
}

1;

=head1 SYNOPSIS

  my $ap = AtomicParsley::Command->new({
    ap => '/path/to/AtomicParsley', # will die if not found
    verbose => 1,
  });
  
  # read tags from a file
  my $tags = $ap->read_tags( '/path/to/mp4' );
  
  # write tags to a file
  my $path = $ap->write_tags( '/path/to/mp4', $tags, 1 );

=method read_tags( $path )

Read the meta tags from a file and returns a L<AtomicParsley::Command::Tags> object.

=method write_tags( $path, $tags, $replace )

Writes the tags to a mp4 file.

$tags is a L<AtomicParsley::Command::Tags> object.

If $replace is true, the existing file will be replaced with the new, tagged file. Otherwise, the tagged file will be a temp file, with the existing file untouched.

Returns the path on success.

=head1 BUGS

=for :list
* Doesn't load all the "advisory" values for an mp4 file.
* The following tags have not been implemented:
  * artwork
  * compilation
  * podcastFlag
  * podcastURL
  * podcastGUID
  * purchaseDate
  * gapless

=head1 SEE ALSO

=for :list
* L<App::MP4Meta>

=cut
