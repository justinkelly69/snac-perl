use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

$name_pattern = '[A-Za-z0-9_-]+';
$ATT_TYPES    = 'ID|IDREF|IDREFS|NMTOKEN|NMTOKENS|ENTITY|ENTITIES|NOTATION';


sub parseDTD {
    my ( $dtdString, $include ) = @_;
    my %dtd, %elements, %attributes, %entities, %notations, $name;
    my $elements   = \%elements;
    my $attributes = \%attributes;
    my $entities   = \%entities;
    my $notations  = \%notations;

    my $json = JSON->new->allow_nonref;

    while ( trim($dtdString) ne '' ) {

        if ( $dtdString =~ /^\s*<!ELEMENT\s+(.*)/s ) {
            ( $dtdString, $elements ) = parseElement( $1, $elements );
        }

        elsif ( $dtdString =~ /^\s*<!ATTLIST\s+(.*)/s ) {
            ( $dtdString, $attributes ) = parseAttList( $1, $attributes );
        }

        elsif ( $dtdString =~ /^\s*<!ENTITY\s+(.*)/s ) {
            ( $dtdString, $entities ) = parseEntity( $1, $entities );
        }

        elsif ( $dtdString =~ /^\s*<!NOTATION\s+(.*)/s ) {
            ( $dtdString, $notations ) = parseNotation( $1, $notations );
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