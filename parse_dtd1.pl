#!/home/jk/opt/perl/bin/perl

use JSON;
use Data::Dumper;

require "./dtd.pl";

my $dtdString = <<EOF;
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

<!ATTLIST downsize toot NOTATION (simple|complex|easy) #REQUIRED
                    href CDATA   #IMPLIED>                    

<!ENTITY stooges "larry|curly|moe">

<!ELEMENT profession (#PCDATA)>
<!ELEMENT footnote   (#PCDATA)>

<!-- The source is given according to the Chicago Manual of Style
     citation conventions -->
<!ATTLIST footnote source CDATA #REQUIRED>

<!ELEMENT first_name (#PCDATA)>
<!ELEMENT last_name  (#PCDATA)>

<!ELEMENT image EMPTY>
<!ATTLIST image source CDATA   #REQUIRED
                width  NMTOKEN #REQUIRED
                height NMTOKEN #REQUIRED
                ALT    CDATA   #IMPLIED
>
<!ENTITY % top_level "( #PCDATA | image | paragraph | definition 
                      | person | profession | emphasize | last_name
                      | first_name | footnote | date )*">

<!NOTATION gif  SYSTEM "image/gif">
<!NOTATION tiff SYSTEM "image/tiff">
<!NOTATION jpeg SYSTEM "image/jpeg">
<!NOTATION png  SYSTEM "image/png">
<!ATTLIST  image type (gif | tiff | jpeg | png) "png" >                      

EOF

my ( $pEntities, $dtdString ) = getEntities($dtdString);
$dtdString = removeComments($dtdString);
#print "$dtdString\n";

$json = JSON->new->allow_nonref;
print "pentities: " . $json->pretty->encode($pEntities) . "\n";

my $dtd = parseDTD( $dtdString, 1 );
print "DTD: " . $json->pretty->encode($dtd) . "\n";