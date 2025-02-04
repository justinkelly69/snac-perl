use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "../text.pl";

my $name_pattern = name_pattern();

sub parseAttList {
    my ( $attList, $attributes ) = @_;
    my ($name, %attributes);

    if ( $attList =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name    = $1;
        $attList = $2;

        while ($attList) {

            if ( $attList =~ /^\s*($name_pattern)\s+NOTATION\s+\(\s*(.*)/s ) {

                my $attName = $1;
                my ($enums, $defaultValue);
                ( $enums, $defaultValue, $attList ) = enumChoice($2);
                $attributes{$name}{$attName} = [ 'NOTATION', $enums, $defaultValue ];
            }

            elsif ( $attList =~ /^\s*($name_pattern)\s+CDATA\s+(.*)/s ) {
                my $attName = $1;
                $attList = $2;

                if ( $attList =~ /^\s*(['"])(.*)/s ) {
                    my $defaultValue;
                    ( $defaultValue, $attList ) = getString( $2, $1 );
                    $attributes{$name}{$attName} =
                      [ 'CDATA', 'DEFAULT', $defaultValue ];
                }

                elsif ( $attList =~ /^\s*#FIXED\s*(['"])(.*)/s ) {
                    my $fixedValue;
                    ( $fixedValue, $attList ) = getString( $2, $1 );
                    $attributes{$name}{$attName} =
                      [ 'CDATA', 'FIXED', $fixedValue ];
                }

                elsif ( $attList =~ /^s*#REQUIRED\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ 'CDATA', 'REQUIRED' ];
                }

                elsif ( $attList =~ /^s*#IMPLIED\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ 'CDATA', 'IMPLIED' ];
                }

                elsif ( $attList =~ /^\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ 'CDATA', 'IMPLIED' ];
                }
            }

            elsif ( $attList =~ /^\s*($name_pattern)\s+($ATT_TYPES)\s+(.*)/s ) {
                my $attName = $1;
                my $attType = $2;
                $attList = $3;

                if ( $attList =~ /^\s*#REQUIRED\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ $attType, 'REQUIRED' ];
                }

                elsif ( $attList =~ /^\s*#IMPLIED\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ $attType, 'IMPLIED' ];
                }
            }

            elsif ( $attList =~ /^\s*($name_pattern)\s*\(\s*(.*)/s ) {
                my $attName = $1;
                my ($enums, $defaultValue);
                ( $enums, $defaultValue, $attList ) = enumChoice($2);
                $attributes{$name}{$attName} = [ 'ENUMERATED', $enums, $defaultValue ];
            }

            elsif ( $attList =~ /^\s*>(.*)/s ) {
                $attList = $1;
                return ( $attList, $attributes );
            }

            else {
                die("line fucked '$attList'\n");
            }
        }
    }
}

sub enumChoice {
    my ($str) = @_;
    my (@enums, $defaultValue);

    while ( $str =~ /^\s*($name_pattern)\s*\|(.*)/s ) {
        push( @enums, $1 );
        $str = $2;
    }

    if ( $str =~ /^\s*($name_pattern)\s*\)(.*)/s ) {
        push( @enums, $1 );
        $str = $2;
    }
    else {
        die("Not an Enumerated String '$1'\n");
    }

    if ( $str =~ /^\s*(["'])(.*)/s ) {
        ( $defaultValue, $str ) = getString( $2, $1 );
    }
    elsif ( $str =~ /^\s*#(IMPLIED|REQUIRED)\s*(.*)/s ) {
        ( $defaultValue, $str ) = ( $1, $2 );
    }
    else {
        die("No Default Value ['$defaultValue'] ['$str']\n");
    }

    return ( \@enums, $defaultValue, $str );
}