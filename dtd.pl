use Data::Dumper;

use String::Util qw(trim);

require "./text.pl";

my $name_pattern   = '[A-Za-z0-9_-]*';
my $qpattern       = '[?+*]?';
my $SPACE          = '\s*';
my $PCDATA         = '#PCDATA';
my $VERTICALBAR    = '[|]';
my $COMMA          = '[,]';
my $VERTICAL_COMMA = '[|,]';

sub entityChildren {
    my ($dtd) = @_;
    my @kids;
    my $atomType = 'X';

    while ($dtd) {

        # Strip off ' | ' or ' , ' at start of string
        if ( $dtd =~ /^${SPACE}${VERTICAL_COMMA}(.*)/ ) {
            $dtd = $1;
        }

        # (#PCDATA)
        elsif ( $dtd =~ /^${SPACE}${PCDATA}${SPACE}\)(.*)/ ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'T';
            }
            $dtd = $1;
            push( @kids, [ 'R', '#TEXT' ] );

            return ( $dtd, [ $atomType, \@kids ] );
        }

        # (#PCDATA | .... )
        elsif ( $dtd =~ /^${SPACE}${PCDATA}${SPACE}${VERTICALBAR}(.*)/ ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'M';
            }
            $dtd = $1;
        }

        # (name | .... )
        elsif ( $dtd =~ /^${SPACE}(${name_pattern})${SPACE}${VERTICALBAR}(.*)/ )
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
            /^${SPACE}(${name_pattern})(${qpattern})${SPACE}${COMMA}(.*)/ )
        {
            if ( $atomType eq 'X' ) {
                $atomType = 'S';
            }
            my $atomName = $1;
            $dtd = $3;
            push( @kids, [ 'R', $atomName, quantify($2) ] );
        }

        # ( new particle
        elsif ( $dtd =~ /^${SPACE}\(${SPACE}(.*)/ ) {
            my $newKids;
            ($dtd, $newKids) = entityChildren($1);
            push(@kids, $newKids);
        }   

        # name* ) // $VERTICALBAR
        elsif (
            $dtd =~ /^${SPACE}(${name_pattern})${SPACE}\)(${qpattern})(.*)/ )
        {
            my $atomName = $1;
            $dtd = $3;
            push( @kids, [ 'R', $atomName ] );

            return ( $dtd, [ $atomType, \@kids, quantify($2) ] );
        }

        # name* ) // $COMMA
        elsif ( $dtd =~
            /^${SPACE}(${name_pattern})(${qpattern})${SPACE}\)(${qpattern})(.*)/
          )
        {
            my $atomName = $1;
            $dtd = $4;
            push( @kids, [ 'R', $atomName, quantify($2) ] );

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

