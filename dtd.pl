#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

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

$json = JSON->new->allow_nonref;
print "pentities:\n---------------------------\n" . $json->pretty->encode($entities) . "\n";

print "DTDString:\n---------------------------\n$dtdString\n";

sub getEntities {
    my ($dtdString) = @_;
    my %pEntities;
    my $outString;
    my $pEntities = \%pEntities;

    while ( $dtdString =~ /<!ENTITY\s+%\s+(.*)/s ) {
        $outString .= $`;
        chomp($outString);
        ( $pEntities, $dtdString ) = parsePEntity( $1, $pEntities );
    }
    $outString .= $dtdString;

    return ( $pEntities, $outString );
}

# <!ENTITY % residential_content "address, footage, rooms, bedrooms, baths, available_date">
# <!ENTITY % names SYSTEM "names.dtd">
sub parsePEntity {
    my ( $entityStr, $entities ) = @_;
    my $entityName, $entityValue;

    if ( $entityStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $entityName = $1;
        $entityStr  = $2;

        if ( $entityStr =~ /^\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName} = normalizeString($entityValue);
        }

        elsif ( $entityStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName}{'SYSTEM'} = normalizeString($entityValue);
        }

        else {
            die("no entity $entityName, $entityStr\n");
        }

        if ( $entityStr =~ /^\s*>(.*)/s ) {
            $entityStr = $1;
            return ( $entities, $entityStr );
        }
    }
    else {
        die "not an entity $1\n";
    }
}
