use strict;
use warnings;

package AtomicParsley::Command::Tags;

# ABSTRACT: represent the mp4 metatags

use Object::Tiny qw{
  artist
  title
  album
  genre
  tracknum
  disk
  comment
  year
  lyrics
  composer
  copyright
  grouping
  artwork
  bpm
  albumArtist
  compilation
  advisory
  stik
  description
  TVNetwork
  TVShowName
  TVEpisode
  TVSeasonNum
  TVEpisodeNum
  podcastFlag
  category
  keyword
  podcastURL
  podcastGUID
  purchaseDate
  encodingTool
  gapless
};

sub prepare {
    my $self = shift;

    # loop through all accessors and generate parameters for AP
    my @out;
    while ( my ( $key, $value ) = each(%$self) ) {
        push @out, "--$key";
        push @out, $value;
    }

    return @out;
}

1;

=head1 SYNOPSIS

  my $tags = AtomicParsley::Command::Tags->new(%tags);

=method prepare

Prepares the tags into an array suitable for passing to AtomicParsley via L<IPC::Cmd>.

=head1 SEE ALSO

=for :list
* L<AtomicParsley::Command>

=cut
