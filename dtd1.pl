#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON::MaybeXS qw(encode_json decode_json);
use String::Util  qw(trim);

require "./text.pl";

sub read_children {
    my ($dtdString) = @_;

    my @particles, $type, $name;
    my $atom_type = 'X';
    my $atom_quantifier;

    my $particle_name;
    my $particle_quantifier;
    my $particle_separator;

    if ( $dtdString =~ m/\s*\(#PCDATA\s*(\|?)(.*)/ ) {
        $atom_type = 'T';
        $dtdString = $2;

        # (#PCDATA .... )
        while ( length( trim($dtdString) ) > 0 ) {

            print("dtdString 1 0 = '$dtdString'\n");

            # "("
            if ( $dtdString =~ m/\s*(\(.*)/s ) {

                #$dtdString = $1;
                print("particle_name 1 1 = '$particle_name'\n");
                print("dtdString 1 1 = '$dtdString'\n");

                push( @particles, read_children($dtdString) );

                return [ $atom_type, \@particles, min_max($atom_quantifier) ];
            }

            # "name* |"
            elsif ( $dtdString =~ m/([A-Za-z0-9_-]+)([?+*]?)\s*\|(.*)/s ) {
                $atom_type           = 'M';
                $name                = $1;
                $particle_quantifier = $2;
                $dtdString           = $3;

                print("particle_name 1 2 = '$particle_name'\n");
                print("dtdString 1 2 = '$dtdString'\n");

                push( @particles,
                    [ 'R', $name, min_max($particle_quantifier) ] );
            }

            # "name* )*"
            elsif (
                $dtdString =~ m/([A-Za-z0-9_-]+)([?+*]?)\s*\)([?+*]?)(.*)/s )
            {
                $name                = $1;
                $particle_quantifier = $2;
                $atom_quantifier     = $3;
                $dtdString           = $4;

                print("particle_name 1 3 = '$particle_name'\n");
                print("dtdString 1 3 = '$dtdString'\n");

                push( @particles,
                    [ 'R', $name, min_max($particle_quantifier) ] );

                return [ $atom_type, \@particles, min_max($atom_quantifier) ];

            }

            # ")*"
            elsif ( $dtdString =~ m/\)([?+*]?)(.*)/s ) {
                $atom_quantifier = $1;
                $dtdString       = $2;

                print("particle_name 1 4 = '$particle_name'\n");
                print("dtdString 1 4 = '$dtdString'\n");

                return [ $atom_type, \@particles, min_max($atom_quantifier) ];
            }

            else {
                die("Invalid Syntax 1 '$dtdString'\n");
            }
        }
    }

    # (....)
    elsif ( $dtdString =~ m/\s*\((.*)/ ) {
        my $atom_type = 'X';

        $dtdString = $1;

        while ( length( trim($dtdString) ) > 0 ) {

            print("dtdString 2 0 = '$dtdString'\n");

            # "[,|] ("
            if ( $dtdString =~ m/\s*(\(.*)/s ) {

                #$dtdString = $1;
                print("particle_name 2 1 = '$particle_name'\n");
                print("dtdString 2 1 = '$dtdString'\n");

                push( @particles, read_children($dtdString) );
                return [ $atom_type, \@particles, min_max($atom_quantifier) ];
            }

            # "name* [,|]"
            elsif ( $dtdString =~ m/\s*([A-Za-z0-9_-]+)([?+*]?)\s*([,|])(.*)/s )
            {
                $atom_type           = 'X';
                $particle_name       = $1;
                $particle_quantifier = $2;
                $particle_separator  = $3;
                $atom_type = get_atom_type( $atom_type, $particle_separator );

                $dtdString = $4;
                print("particle_name 2 2 = '$particle_name'\n");
                print("dtdString 2 2 = '$dtdString'\n");

                push( @particles,
                    [ 'R', $particle_name, min_max($particle_quantifier) ] );
            }

            # "name* )*"
            elsif (
                $dtdString =~ m/\s*([A-Za-z0-9_-]+)([?+*]?)\s*\)([?+*]?)(.*)/s )
            {
                $particle_name       = $1;
                $particle_quantifier = $2;
                $atom_quantifier     = $3;

                $dtdString = $4;
                print("particle_name 2 3 = '$particle_name'\n");
                print("dtdString 2 3 = '$dtdString'\n");

                push( @particles,
                    [ 'R', $particle_name, min_max($particle_quantifier) ] );

                return [ $atom_type, \@particles, min_max($atom_quantifier) ];
            }

            # ")*"
            elsif ( $dtdString =~ m/^\s*\)([?+*]?)(.*)/s ) {

                $atom_quantifier = $1;

                $dtdString = $4;
                print("particle_name 2 4 = '$particle_name'\n");
                print("dtdString 2 4 = '$dtdString'\n");

                return [ $atom_type, \@particles, min_max($atom_quantifier) ];
            }

            else {
                die("Invalid Syntax 2 '$dtdString'\n");
            }
        }

    }

    # elsif ( $dtdString =~ m/\s*EMPTY\s*>(.*)/ ) {
    # }

    # elsif ( $dtdString =~ m/\s*ANY\s*>(.*)/ ) {
    # }
}

sub min_max {
    my ($symbol) = @_;
    my $min      = 1;
    my $max      = 1;

    if ( $symbol eq '?' ) {
        $min = 0;
    }
    elsif ( $symbol eq '+' ) {
        $max = -1;
    }
    elsif ( $symbol eq '*' ) {
        $min = 0;
        $max = -1;
    }

    return ( $min, $max );
}

sub get_atom_type {
    my ( $atom_type, $symbol ) = @_;

    # first loop only
    if ( $atom_type eq 'X' ) {

        # sequence
        if ( $symbol eq ',' ) {
            $atom_type = 'S';
        }

        #choice
        elsif ( $symbol eq '|' ) {
            $atom_type = 'C';
        }
    }

    # all other loops
    else {
        # sequence should not have '|' characters
        if ( $atom_type eq 'S' && $symbol eq '|' ) {
            die("Wrong symbol 'S','|'");
        }

        # choice should not have ',' characters
        elsif ( $atom_type eq 'C' && $symbol eq ',' ) {
            die("Wrong symbol 'C',','");
        }
    }
    return $atom_type;
}
