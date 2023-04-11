use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

$name_pattern   = '[A-Za-z0-9_-]*';
$qpattern       = '[?+*]?';
$SPACE          = '\s*';
$PCDATA         = '#PCDATA';
$VERTICALBAR    = '[|]';
$COMMA          = '[,]';
$VERTICAL_COMMA = '[|,]';

sub parseElement {
    my ( $elementStr, $elements ) = @_;
    my $name;

    if ( $elementStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name       = $1;
        $elementStr = $2;

        if ( $elementStr =~ /\s*ANY\s*>(.*)/s ) {
            $$elements{$name} = 'ANY';
            return ( $1, $elements );
        }

        elsif ( $elementStr =~ /\s*EMPTY\s*>(.*)/s ) {
            $$elements{$name} = 'EMPTY';
            return ( $1, $elements );
        }

        elsif ( $elementStr =~ /\s*\((.*)>(.*)/s ) {
            my ( $dtd, $children ) = elementChildren($1);
            $$elements{$name} = $children;
            return ( $2, $elements );
        }

        else {
            die "Invalid string $elementStr\n";
        }
    }
    else {
        die "Not an element $elementStr\n";
    }
}

sub elementChildren {
    my ($dtd) = @_;
    my @kids;
    my $atomType = 'X';

    while ($dtd) {

        # # Strip off ' | ' or ' , ' at start of string
        if ( $dtd =~ /^${SPACE}${VERTICAL_COMMA}(.*)/s ) {
            $dtd = $1;
        }

        # (#PCDATA)
        elsif ( $dtd =~ /^${SPACE}${PCDATA}${SPACE}\)(.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'T';
            }
            $dtd = $1;
            push( @kids, [ 'R', '#TEXT' ] );

            return ( $dtd, [ $atomType, \@kids ] );
        }

        # (#PCDATA | .... )
        elsif ( $dtd =~ /^${SPACE}${PCDATA}${SPACE}${VERTICALBAR}(.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'M';
            }
            $dtd = $1;
        }

        # (name | .... )
        elsif (
            $dtd =~ /^${SPACE}(${name_pattern})${SPACE}${VERTICALBAR}(.*)/s )
        {
            if ( $atomType eq 'X' ) {
                $atomType = 'C';
            }
            my $atomName = $1;
            $dtd = $2;
            push( @kids, [ 'R', $atomName ] );
        }

        # (name , .... )
        elsif ( $dtd =~
            /^${SPACE}(${name_pattern})(${qpattern})${SPACE}${COMMA}(.*)/s )
        {
            if ( $atomType eq 'X' ) {
                $atomType = 'S';
            }
            my $atomName = $1;
            $dtd = $3;
            push( @kids, [ 'R', $atomName, quantify($2) ] );
        }

        # ( new particle
        elsif ( $dtd =~ /^${SPACE}\(${SPACE}(.*)/s ) {
            my $newKids;
            ( $dtd, $newKids ) = elementChildren($1);
            push( @kids, $newKids );
        }

        # name* ) // $COMMA
        elsif ( $dtd =~
/^${SPACE}(${name_pattern})(${qpattern})${SPACE}\)(${qpattern})(.*)/s
          )
        {
            my $atomName = $1;
            $dtd = $4;
            if ( $atomName ne '' ) {
                if ( $atomType eq 'S' ) {
                    push( @kids, [ 'R', $atomName, quantify($2) ] );
                }
                else {
                    push( @kids, [ 'R', $atomName ] );
                }
            }

            return ( $dtd, [ $atomType, \@kids, quantify($3) ] );
        }

        else {
            die("something not right\n");
        }
    }
}

sub quantify {
    my ($quantifier) = @_;
    my $min = 1, $max = 1;

    if ( $quantifier eq '?' ) {
        $min = 0;
    }
    elsif ( $quantifier eq '+' ) {
        $max = -1;
    }
    elsif ( $quantifier eq '*' ) {
        $min = 0;
        $max = -1;
    }
    return ( $min, $max );
}

sub parseAttList {
    my ( $attList, $attributes ) = @_;
    my $name;

    if ( $attList =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name    = $1;
        $attList = $2;

        while ($attList) {

            if ( $attList =~ /^\s*($name_pattern)\s+CDATA\s+(.*)/s ) {
                my $attName = $1;
                $attList = $2;

                if ( $2 =~ /^\s*(['"])(.*)/s ) {
                    my $defaultValue;
                    ( $defaultValue, $attList ) = getString( $2, $1 );
                    $attributes{$name}{$attName} = [ 'C', 'D', $defaultValue ];
                }

                elsif ( $2 =~ /^\s*\(\s*(.*)/s ) {

                    my $enums, $defaultValue;
                    ( $enums, $defaultValue, $attList ) = enumChoice($1);
                    $json = JSON->new->allow_nonref;
                    $attributes{$name}{$attName} =
                      [ 'C', 'E', $enums, $defaultValue ];
                }

                elsif ( $2 =~ /^\s*#FIXED\s*(['"])(.*)/s ) {
                    my $fixedValue;
                    ( $fixedValue, $attList ) = getString( $2, $1 );
                    $attributes{$name}{$attName} = [ 'C', 'F', $fixedValue ];
                }

                elsif ( $2 =~ /^s*#REQUIRED\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ 'C', 'R' ];
                }

                elsif ( $2 =~ /^s*#IMPLIED\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ 'C', 'I' ];
                }

                elsif ( $2 =~ /^\s*(.*)/s ) {
                    $attList = $1;
                    $attributes{$name}{$attName} = [ 'C', 'I' ];
                }

            }

            elsif ( $attList =~ /\s*>(.*)/ ) {
                return ( $1, $attributes );
            }

            else {
                die("line fucked '$attList'\n");
            }

        }

        # CDATA
        # NMTOKEN
        # NMTOKENS
        # Enumeration
        # ENTITY
        # ENTITIES
        # ID
        # IDREF
        # IDREFS
        # NOTATION
    }

}

sub enumChoice {
    my ($str) = @_;
    my @enums, $defaultValue;

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
    else {
        die("No Default Value ['$defaultValue'] ['$str']\n");
    }

    return ( \@enums, $defaultValue, $str );
}
