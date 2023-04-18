use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

# <!ENTITY da "&#xD;&#xA;">
# <!ENTITY turing_getting_off_bus
#          SYSTEM "http://www.turing.org.uk/turing/pi1/bus.jpg"
#          NDATA jpeg>
sub parseEntity {
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

            if ( $entityStr =~ /^\s*NDATA\s*($name_pattern)\s*(.*)/s ) {
                $entityValue                     = $1;
                $entityStr                       = $2;
                $$entities{$entityName}{'NDATA'} = $entityValue;
            }
        }

        else {
            die("no entity $entityName, $entityStr\n");
        }

        if ( $entityStr =~ /^\s*>(.*)/s ) {
            $entityStr = $1;
            return ( $entityStr, $entities );
        }
    }
    else {
        die "not an entity $1\n";
    }
}