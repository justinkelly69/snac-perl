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

        if ( $elementStr =~ /\s*#ANY\s*>(.*)/s ) {
            $$elements{$name} = 'ANY';
            return ( $1, $elements );
        }

        elsif ( $elementStr =~ /\s*#EMPTY\s*>(.*)/s ) {
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

