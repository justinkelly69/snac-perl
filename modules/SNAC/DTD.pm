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
use SNAC::DTD::IncludeIgnore;
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

    my $dtd_string = SNAC::DTD::Comments::parse($dtd);
    $dtd_string = SNAC::DTD::PEntities::parse($dtd_string);
    $dtd_string = SNAC::DTD::IncludeIgnore::parse($dtd_string);

    while ( trim($dtd_string) ne '' ) {

        if ( $dtd_string =~ /^\s*<!ELEMENT\s+($name_pattern)\s+([^>]+)>(.*)/s )
        {
            $elements->{$1} = SNAC::DTD::Elements::parse($2);
            $dtd_string = $3;
        }

        elsif (
            $dtd_string =~ /^\s*<!ATTLIST\s+($name_pattern)\s+([^>]+)>(.*)/s )
        {
            $attributes->{$1} = SNAC::DTD::Attributes::parse($2);
            $dtd_string = $3;
        }

        elsif (
            $dtd_string =~ /^\s*<!ENTITY\s+($name_pattern)\s+([^>]+)>(.*)/s )
        {
            $entities->{$1} = SNAC::DTD::Entities::parse($2);
            $dtd_string = $3;
        }

        elsif (
            $dtd_string =~ /^\s*<!NOTATION\s+($name_pattern)\s+([^>]+)>(.*)/s )
        {
            $notations->{$1} = SNAC::DTD::Notations::parse($2);
            $dtd_string = $3;
        }

        else {
            print("can't find anything\n");
        }
    }


    return {
        elements   => $elements,
        attributes => $attributes,
        entities   => $entities,
        notations  => $notations
    };
}
