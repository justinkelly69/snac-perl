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
    my ( $entity_string, $entities ) = @_;
    my ( $entity_name, $entity_value );

    if ( $entity_string =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $entity_name   = $1;
        $entity_string = $2;

        if ( $entity_string =~ /^\s*(["'])(.*)/s ) {
            ( $entity_value, $entity_string ) = get_string( $2, $1 );
            $$entities{$entity_name} = $entity_value;
        }

        elsif ( $entity_string =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entity_value, $entity_string ) = get_string( $2, $1 );
            $$entities{$entity_name}{'SYSTEM'} = $entity_value;

            if ( $entity_string =~ /^\s*NDATA\s*($name_pattern)\s*(.*)/s ) {
                $entity_value                     = $1;
                $entity_string                    = $2;
                $$entities{$entity_name}{'NDATA'} = $entity_value;
            }
        }

        else {
            die("no entity $entity_name, $entity_string\n");
        }

        if ( $entity_string =~ /^\s*>(.*)/s ) {
            $entity_string = $1;
            return ( $entity_string, $entities );
        }
    }
    else {
        die "not an entity $1\n";
    }
}
