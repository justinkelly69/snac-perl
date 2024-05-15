#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON;
use String::Util qw(trim);

BEGIN {
    use lib './modules';
}
use SNAC::DTD::PEntities;


my $dtd;
{
    open my $fh, '<', $ARGV[0] or die "Can't read input file: $!";
    local $/ = undef;
    $dtd = <$fh>;
    close $fh;
}

my ($entities, $dtdString) = get_pentities($dtd);

my $json = JSON->new->allow_nonref;
print "pentities:\n---------------------------\n" . $json->pretty->encode($entities) . "\n";

my ($noEntitiesArray, $entitiesArray) = evaluate_pentities($entities, $noEntitiesArray, $entitiesArray);

my $dtd_out = parse($dtd);
print "$dtd\n---------------------------------\n$dtd_out\n";
