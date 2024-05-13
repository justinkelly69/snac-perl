#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./lib/pentities.pl";
require "./lib/text.pl";

$name_pattern = '[.A-Za-z0-9_-]+';
$ATT_TYPES    = 'ID|IDREF|IDREFS|NMTOKEN|NMTOKENS|ENTITY|ENTITIES|NOTATION';


my $dtd;
{
    open my $fh, '<', $ARGV[0] or die "Can't read input file: $!";
    local $/ = undef;
    $dtd = <$fh>;
    close $fh;
}

my ($entities, $dtdString) = getEntities($dtd);

print "DTD:\n---------------------------\n$dtd\n";

my $json = JSON->new->allow_nonref;
print "pentities:\n---------------------------\n" . $json->pretty->encode($entities) . "\n";

my ($noEntitiesArray, $entitiesArray) = evaluateEntities($entities);
print "noEntitiesArray:\n---------------------------\n" . $json->pretty->encode($noEntitiesArray) . "\n";
print "entitiesArray:\n---------------------------\n" . $json->pretty->encode($entitiesArray) . "\n";

print "DTDString:\n---------------------------\n$dtdString\n";


