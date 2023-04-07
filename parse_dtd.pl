#!/home/jk/opt/perl/bin/perl

use JSON;
use Data::Dumper;

require "./dtd.pl";

# printDTD('name* , value+, dirt, bag )');
# printDTD('name* | value+| dirt| bag )');
# printDTD('name* , value+, dirt, bag )+');
# printDTD('name* | value+| dirt| bag )*');
printDTD('name* , value+, (house|on|fire)*, dirt, bag )+');
printDTD('name* | value+| (house*,on?,fire+)| dirt| bag )*');
# printDTD('#PCDATA )');
# printDTD('#PCDATA | name* | value+| dirt| bag )*');
printDTD('#PCDATA | name* | value+| (house*,on?,fire+)| dirt| bag )*');


sub printDTD {
    my ($dtd) = @_;
    $json = JSON->new->allow_nonref;
    my ( $dtdOut, $kids ) = entityChildren($dtd);
    print("$dtd\n");
    print $json->pretty->encode($kids) . "\n";
}
