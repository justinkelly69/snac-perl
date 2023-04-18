#!/home/jk/opt/perl/bin/perl

use JSON;
use Data::Dumper;

require "./dtd.pl";

# printDTD('name* , value+, dirt, bag )');
# printDTD('name | value| dirt| bag )');
# printDTD('name* , value+, dirt, bag )+');
# printDTD('name | value| dirt| bag )*');
# printDTD('name* , value+, (house|on|fire)*, dirt, bag )+');
# printDTD('name | value| (house*,on?,fire+)| dirt| bag )*');

# printDTD('#PCDATA )');
# printDTD('#PCDATA | name | value| dirt| bag )*');
# printDTD('#PCDATA | name | value| (house*,on?,fire+)| dirt| bag )*');
# printDTD(
# '#PCDATA | (hello, world) | name | value| (house*,on?,fire+)| dirt| bag | (good, bye))*'
# );
# printDTD(
#     '(hello|world), name , value, (house|on|fire)*, dirt, bag, (good| bye) )+'
# );

sub printDTD {
    my ($dtd) = @_;
    $json = JSON->new->allow_nonref;
    my ( $dtdOut, $kids ) = elementChildren($dtd);
    print("$dtd\n");
    print $json->pretty->encode($kids) . "\n";
}

my $dtd, $elements;
$dtd = "
<!ELEMENT name #ANY>
<!ELEMENT value #EMPTY>
<!ELEMENT message (#PCDATA | name | value| (house*,on?,fire+)| dirt| bag )*>
";

# print("$dtd\n");
# while ( $dtd =~ /\s*<!ELEMENT\s+(.*)/s ) {
#     ( $dtd, $elements ) = printElement( $1, $elements );
# }

# $json = JSON->new->allow_nonref;
# print $json->pretty->encode($elements) . "\n";

sub printElement {
    my ($elementStr) = @_;
    return parseElement( $elementStr, \%elements );
}

my $attList, %attributes;
$attList = "
<!ATTLIST person
    id ID #REQUIRED
    ssn ID #IMPLIED
    noname CDATA
    idref IDREF #IMPLIED
    idrefs IDREFS #IMPLIED
    nmtoken NMTOKEN #IMPLIED
    nmtokens NMTOKENS #REQUIRED
    entity ENTITY #IMPLIED
    entities ENTITIES #REQUIRED
    notation NOTATION #REQUIRED
    firstname CDATA #REQUIRED
    middlename CDATA #IMPLIED
    letters (alpha|beta|gamma|delta|epsilon) \"delta\"
    lastname CDATA #FIXED 'Smith'
    status CDATA \"god almighty\" 
>
hello world
";

if ( $attList =~ /\s*<!ATTLIST\s+(.*)/s ) {
    $attList = $1;
    printAttributes( $attList, \%attributes );
}

sub printAttributes {
    my ( $attList, $attributes ) = @_;
    print("before: $attList\n");

    $json = JSON->new->allow_nonref;
    ( $attList, $attributes ) = parseAttList( $attList, $attributes );
    print $json->pretty->encode($attributes) . "\n";
    
    print("after: $attList\n");

}

my $notationList, %notations;
$notationList = "
<!NOTATION gif  SYSTEM \"image/gif\">
<!NOTATION tiff SYSTEM \"image/tiff\">
<!NOTATION jpeg SYSTEM \"image/jpeg\">
<!NOTATION png  SYSTEM \"image/png\">
<!NOTATION gif_image PUBLIC \"https://compuserve.com/images/gifs/v1\">
<!NOTATION tiff_image PUBLIC \"https://compuserve.com/images/tiffs/v1\" \"image/tiff\">
";

#print("$notationList\n");
#printNotations( $notationList, \%notations );

sub printNotations {
    my ( $notationString, $notations ) = @_;

    while ( $notationString =~ /^\s*<!NOTATION\s+(.*)/s ) {
        ( $notations, $notationString ) = parseNotation( $1, $notations );
    }
    $json = JSON->new->allow_nonref;
    print $json->pretty->encode($notations) . "\n";
}

my $entityList, %entities;
$entityList = "
<!ENTITY name \"James P. Sullivan\">
<!ENTITY helper \"Mike Wazowski\">
<!ENTITY restaurant \"Harryhausens\">
<!ENTITY boss SYSTEM \"https://theboss.com\">
<!ENTITY turing_getting_off_bus
          SYSTEM \"http://www.turing.org.uk/turing/pi1/bus.jpg\"
          NDATA jpeg>
";

# print("$entityList\n");
# printEntities( $entityList, \%entities );

sub printEntities {
    my ( $entityString, $entities ) = @_;

    while ( $entityString =~ /^\s*<!ENTITY\s+(.*)/s ) {
        ( $entities, $entityString ) = parseEntity( $1, $entities );
    }
    $json = JSON->new->allow_nonref;
    print $json->pretty->encode($entities) . "\n";
}

my $pEntityList, %pentities;
$pEntityList = "
<!ENTITY % residential_content \"address, footage, rooms, baths\">
<!ENTITY % rental_content      \"rent\">
<!ENTITY % purchase_content    \"price\">
<!ENTITY % names               SYSTEM \"names.dtd\">
";

# print("$pEntityList\n");
# printPEntities( $pEntityList, \%pEntities );

sub printPEntities {
    my ( $pEntityString, $pEntities ) = @_;

    while ( $pEntityString =~ /^\s*<!ENTITY\s+%\s+(.*)/s ) {
        ( $pEntities, $pEntityString ) = parseEntity( $1, $pEntities );
    }
    $json = JSON->new->allow_nonref;
    print $json->pretty->encode($pEntities) . "\n";
}
