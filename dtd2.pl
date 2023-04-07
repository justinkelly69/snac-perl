use Data::Dumper;

use String::Util qw(trim);

require "./text.pl";

my $name_pattern = '[A-Za-z0-9_-]*';
my $qpattern     = '[?+*]?';

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

sub entityChildren {
    my ($dtd) = @_;
    my @kids;
    my $type = 'Z';

    # Text Only (#PCDATA)
    if ( $dtd =~ /^\s*#PCDATA\s*\)(.*)/ ) {
        $type = 'T';
        $dtd  = $1;
        return ( $dtd, [ 'T', [], 1, 1 ] );
    }

    # Mixed (#PCDATA | ....)
    elsif ( $dtd =~ /^\s*#PCDATA\s*([|])(.*)/ ) {
        $type = 'M';
        $dtd  = $2;

        while ( $dtd =~ /^\s*(${name_pattern})(${qpattern})\s*([|])(.*)/ ) {

            if ( $type ne 'M' ) {
                die "Wrong type '$type'\n";
            }

            push( @kids, [ 'R', $1, quantify($2) ] );
            $dtd = $4;
        }
    }

    # Sequence
    while ( $dtd =~ /^\s*(${name_pattern})(${qpattern})\s*([,])(.*)/ ) {
        if ( $type eq 'Z' ) {
            $type = 'S';
        }
        else {
            if ( $type ne 'S' ) {
                die "Wrong type '$type'\n";
            }
        }
        push( @kids, [ 'R', $1, quantify($2) ] );
        $dtd = $4;
    }

    # Choice
    while ( $dtd =~ /^\s*(${name_pattern})(${qpattern})\s*([|])(.*)/ ) {
        if ( $type eq 'Z' ) {
            $type = 'C';
        }
        else {
            if ( $type ne 'C' ) {
                die "Wrong type '$type'\n";
            }
        }
        push( @kids, [ 'R', $1, quantify($2) ] );
        $dtd = $4;
    }

    # End Bracket with one node
    if ( $dtd =~ /^\s*(${name_pattern})(${qpattern})\s*\)(${qpattern})(.*)/ ) {
        push( @kids, [ 'R', $1, quantify($2) ] );
        $dtd = $4;
        #$dtd =~ s/[|,]//;
        print("# End Bracket with one node '$dtd'\n");
        return ( $dtd, [ $type, \@kids, quantify($3) ] );
    }

    # End Bracket with no node
    elsif ( $dtd =~ /^\s*\)(${qpattern})(.*)/ ) {
        $dtd = $2;
        print("# End Bracket with no node '$dtd'\n");
        return ( $dtd, [ $type, \@kids, quantify($1) ] );
    }

    # New Node. Call recursive
    elsif ( $dtd =~ /^\s*\((.*)/ ) {
        print("# New Node. before recursive '$dtd'\n");
        ( $dtd, $newKids ) = entityChildren($1);
        print("# New Node. after recursive '$dtd'\n");
        push( @kids, $newKids );
        return ( $dtd, [ $type, \@kids, quantify($3) ] );
    }

    else {
        die("Something Wrong $dtd\n");
    }

}

