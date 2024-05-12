use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

sub getEntities {
    my ($dtdString) = @_;
    my %pEntities;
    my $outString;
    my $pEntities = \%pEntities;

    while ( $dtdString =~ /<!ENTITY\s+%\s+(.*)/s ) {
        $outString .= $`;
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
            $$entities{$entityName} = $entityValue;
        }

        elsif ( $entityStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName}{'SYSTEM'} = $entityValue;
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

