use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

sub parseElement {
    my ( $elementStr, $elements ) = @_;
    my $name;

    if ( $elementStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name       = $1;
        $elementStr = $2;

        if ( $elementStr =~ /^\s*ANY\s*(.*)/s ) {
            $$elements{$name} = 'ANY';
            $elementStr = $1;
        }

        elsif ( $elementStr =~ /^\s*EMPTY\s*(.*)/s ) {
            $$elements{$name} = 'EMPTY';
            $elementStr = $1;
        }

        elsif ( $elementStr =~ /^\s*\((.*)/s ) {
            my $children;
            ( $elementStr, $children ) = elementChildren($1);
            $$elements{$name} = $children;
        }

        else {
            die "Invalid string $elementStr\n";
        }
    }
    else {
        die "Not an element $elementStr\n";
    }

    if ( $elementStr =~ /^\s*>(.*)/s ) {
        $elementStr = $1;
        return ( $elementStr, $elements );
    }
}

sub elementChildren {
    my ($dtd) = @_;
    my @kids;
    my $atomType = 'X';

    while ($dtd) {

        # # Strip off ' | ' or ' , ' at start of string
        if ( $dtd =~ /^\s*[|,](.*)/s ) {
            $dtd = $1;
        }

        # (#PCDATA)
        elsif ( $dtd =~ /^\s*#PCDATA\s*\)(.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'T';
            }
            $dtd = $1;
            push( @kids, [ 'R', '#TEXT' ] );

            return ( $dtd, [ $atomType, \@kids ] );
        }

        # (#PCDATA | .... )
        elsif ( $dtd =~ /^\s*#PCDATA\s*[|](.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'M';
            }
            $dtd = $1;
        }

        # (name | .... )
        elsif ( $dtd =~ /^\s*(${name_pattern})\s*[|](.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'C';
            }
            my $atomName = $1;
            $dtd = $2;
            push( @kids, [ 'R', $atomName ] );
        }

        # (name , .... )
        elsif ( $dtd =~ /^\s*(${name_pattern})([?+*]?)\s*[,](.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'S';
            }
            my $atomName = $1;
            $dtd = $3;
            push( @kids, [ 'R', $atomName, quantify($2) ] );
        }

        # ( new particle
        elsif ( $dtd =~ /^\s*\(\s*(.*)/s ) {
            my $newKids;
            ( $dtd, $newKids ) = elementChildren($1);
            push( @kids, $newKids );
        }

        # name* ) // $COMMA
        elsif ( $dtd =~ /^\s*(${name_pattern})([?+*]?)\s*\)([?+*]?)(.*)/s ) {
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
