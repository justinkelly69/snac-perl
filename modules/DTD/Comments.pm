package SNAC::DTD::Comments;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::XML::Text;

use base 'Exporter';

sub parse {
    my ($dtd_string) = @_;
    my $out_string;
    my @segments = split( /<!--/, $dtd_string );

    for my $segment (@segments) {
        $segment =~ s/^.*?-->//s;
    }

    return join('', @segments);
}

1;