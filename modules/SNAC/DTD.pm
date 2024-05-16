package SNAC::DTD;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::DTD::Attributes;
use SNAC::DTD::Comments;
use SNAC::DTD::Elements;
use SNAC::DTD::Entities;
use SNAC::DTD::Notations;
use SNAC::DTD::PEntities;
use SNAC::XML::Text;

use base 'Exporter';

our $VERSION      = '1.0';
our $name_pattern = '[.A-Za-z0-9_-]+';

sub parse_dtd {
    my ($dtd) = @_;
    my ( %dtd, %elements, %attributes, %entities, %notations, $name );

    my $elements   = \%elements;
    my $attributes = \%attributes;
    my $entities   = \%entities;
    my $notations  = \%notations;

    my $json = JSON->new->allow_nonref;

    my $dtd_string = SNAC::DTD::PEntities::parse($dtd);
    $dtd_string = SNAC::DTD::Comments::parse($dtd_string);

    #print("dtd_string [[[$dtd_string]]]\n");

    while ( trim($dtd_string) ne '' ) {

        if ( $dtd_string =~ /^\s*<!ELEMENT\s+(.*)/s ) {

            #print("\$1: $1\n");
            ( $dtd_string, $elements ) =
              SNAC::DTD::Elements::parse( $1, $elements );
        }

        elsif ( $dtd_string =~ /^\s*<!ATTLIST\s+(.*)/s ) {
            ( $dtd_string, $attributes ) =
              SNAC::DTD::Attributes::parse( $1, $attributes );
        }

        elsif ( $dtd_string =~ /^\s*<!ENTITY\s+(.*)/s ) {
            ( $dtd_string, $entities ) =
              SNAC::DTD::Entities::parse( $1, $entities );
        }

        elsif ( $dtd_string =~ /^\s*<!NOTATION\s+(.*)/s ) {
            ( $dtd_string, $notations ) =
              SNAC::DTD::Notations::parse( $1, $notations );
        }

        else {
            last;
        }
    }

    return {
        elements   => $elements,
        attributes => $attributes,
        entities   => $entities,
        notations  => $notations
    };
}
