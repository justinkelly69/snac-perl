#!/home/jk/opt/perl/bin/perl

use JSON;
use Data::Dumper;

require "./dtd.pl";

printDTD('name* , value+, dirt, bag )');
printDTD('name | value| dirt| bag )');
printDTD('name* , value+, dirt, bag )+');
printDTD('name | value| dirt| bag )*');
printDTD('name* , value+, (house|on|fire)*, dirt, bag )+');
printDTD('name | value| (house*,on?,fire+)| dirt| bag )*');

printDTD('#PCDATA )');
printDTD('#PCDATA | name | value| dirt| bag )*');
printDTD('#PCDATA | name | value| (house*,on?,fire+)| dirt| bag )*');
printDTD(
'#PCDATA | (hello, world) | name | value| (house*,on?,fire+)| dirt| bag | (good, bye))*'
);
printDTD(
    '(hello|world), name , value, (house|on|fire)*, dirt, bag, (good| bye) )+'
);

my $dtd, $elements;
$dtd = "
<!ELEMENT name #ANY>
<!ELEMENT value #EMPTY>
<!ELEMENT message (hello, world)+>
";

while($dtd =~ /\s*<!ELEMENT\s+(.*)/s){
    ($dtd, $elements) = printElement($1, $elements);
}
$json = JSON->new->allow_nonref;
print $json->pretty->encode($elements) . "\n";

sub printElement {
    my($elementStr) = @_;
    return parseElement($elementStr, \%elements);
}


sub printDTD {
    my ($dtd) = @_;
    $json = JSON->new->allow_nonref;
    my ( $dtdOut, $kids ) = elementChildren($dtd);
    print("$dtd\n");
    print $json->pretty->encode($kids) . "\n";
}
