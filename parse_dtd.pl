#!/home/jk/opt/perl/bin/perl

use JSON;
use Data::Dumper;

require "./dtd.pl";

my $dtdString = <<EOF;
<!ENTITY % coreattrs 
     "id    ID    #IMPLIED
     class CDATA #IMPLIED
     style CDATA #IMPLIED
     title CDATA #IMPLIED"
>
...
<!ENTITY % attrs "%coreattrs; %i18n; %events;">
...
<!ENTITY % inline "a|%special;|%fontstyle;|%phrase;|%inline.forms;">
<!ENTITY % Inline "(#PCDATA | %inline; | %misc;)*">
<!ELEMENT h1 %Inline;>
<!ATTLIST h1
%attrs;
>
<!ATTLIST biography xlink CDATA #FIXED    "http://www.w3.org/1999/xlink">
<!ELEMENT person (first_name, last_name)>
<!ATTLIST person born CDATA #IMPLIED
                 died CDATA #IMPLIED>

<!ELEMENT date   (month, day, year)>
<!ELEMENT month  (#PCDATA)>
<!ELEMENT day    (#PCDATA)>
<!ELEMENT year   (#PCDATA)>

<!-- xlink:href must contain a URI.-->
<!ATTLIST emphasize type (simple|complex|easy) #REQUIRED
                    href CDATA   #IMPLIED>

<!ATTLIST downsize toot (simple|complex|easy) #REQUIRED
                    href CDATA   #IMPLIED>                    

<!ENTITY stooges "larry|curly|moe">

<!ELEMENT profession (#PCDATA)>
<!ELEMENT footnote   (#PCDATA)>

<!-- The source is given according to the Chicago Manual of Style
     citation conventions -->
<!ATTLIST footnote source CDATA #REQUIRED>

<!ELEMENT first_name (#PCDATA)>
<!ELEMENT last_name  (#PCDATA)>

<![INCLUDE[
     <!ATTLIST first_name text CDATA #FIXED "Fred">
     <!ATTLIST last_name text CDATA #FIXED "Flintstone">
]]>
<![IGNORE[
     <!ATTLIST first_name text CDATA #FIXED "Homer">
     <!ATTLIST last_name text CDATA #FIXED "Simpson">
]]>

<!ELEMENT image EMPTY>
<!ATTLIST image source CDATA   #REQUIRED
                width  NMTOKEN #REQUIRED
                height NMTOKEN #REQUIRED
                ALT    CDATA   #IMPLIED
>
<!ENTITY % top_level "( #PCDATA | image | paragraph | definition 
                      | person | profession | emphasize | last_name
                      | first_name | footnote | date )*">
<![INCLUDE[
     <!ATTLIST first_name text CDATA #FIXED "Fred">
     <!ATTLIST last_name text CDATA #FIXED "Flintstone">
]]>
<![IGNORE[
     <!ATTLIST first_name text CDATA #FIXED "Homer">
     <!ATTLIST last_name text CDATA #FIXED "Simpson">
]]>
<!NOTATION gif  SYSTEM "image/gif">
<!NOTATION tiff SYSTEM "image/tiff">
<!NOTATION jpeg SYSTEM "image/jpeg">
<!NOTATION png  SYSTEM "image/png">
<!ATTLIST  image type (gif | tiff | jpeg | png) "png" >                      

EOF

my $dtdString1 = <<EOF;
<!ELEMENT name ANY>
<!ELEMENT value EMPTY>
<!ELEMENT message (#PCDATA | name | value| (house*,on?,fire+)| dirt| bag )*>
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
<![INCLUDE[
     <!ATTLIST first_name text CDATA #FIXED "Fred">
     <!ATTLIST last_name text CDATA #FIXED "Flintstone">
]]>
<![IGNORE[
     <!ATTLIST first_name text CDATA #FIXED "Homer">
     <!ATTLIST last_name text CDATA #FIXED "Simpson">
]]>
<!NOTATION gif  SYSTEM \"image/gif\">
<!NOTATION tiff SYSTEM \"image/tiff\">
<!NOTATION jpeg SYSTEM \"image/jpeg\">
<!NOTATION png  SYSTEM \"image/png\">
<!NOTATION gif_image PUBLIC \"https://compuserve.com/images/gifs/v1\">
<!NOTATION tiff_image PUBLIC \"https://compuserve.com/images/tiffs/v1\" \"image/tiff\">

EOF


my $myDtd = $dtdString;
my %out;

my ( $pEntities, $myDtd ) = getEntities($myDtd);
$myDtd = removeComments($myDtd);
#print "$dtdString\n";

$json = JSON->new->allow_nonref;
#print "pentities: " . $json->pretty->encode($pEntities) . "\n";

my $dtd = parseDTD( $myDtd, \%out, 1);
#print "DTD: " . $json->pretty->encode(\%out) . "\n";