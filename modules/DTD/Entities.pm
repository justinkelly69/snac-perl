package SNAC::DTD::Entities;

use strict;
use warnings;

use SNAC::XML::Text;

use base 'Exporter';

our $VERSION      = '1.0';
our $name_pattern = '[.A-Za-z0-9_-]+';

# <!ENTITY da "&#xD;&#xA;">
# <!ENTITY turing_getting_off_bus
#          SYSTEM "http://www.turing.org.uk/turing/pi1/bus.jpg"
#          NDATA jpeg>
sub parse {
    my ($entity_string) = @_;
    my ($out);

    if ( $entity_string =~ /^\s*(["'])(.*)/s ) {
        my ($entity_value);
        ( $entity_value, $entity_string ) = get_string( $2, $1 );
        $out = { name => $entity_value };

        if ( $entity_string =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            my ($entity_system);
            ( $entity_system, $entity_string ) = get_string( $2, $1 );
            $out->{system} = $entity_system;

            if ( $entity_string =~ /^\s*NDATA\s*($name_pattern)\s*/s ) {
                my $entity_ndata = $1;
                $out->{ndata} = $entity_ndata;
            }
        }
    }
    else {
        die("no entity $entity_string\n");
    }

    return $out;
}

1;

