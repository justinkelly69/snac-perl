package SNAC::DTD::Elements;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::XML::Text;

our $VERSION      = '1.0';
our $name_pattern = '[.A-Za-z0-9_-]+';

my $json = JSON->new->allow_nonref;

sub parse {
    my ($contents) = @_;

    if ( $contents =~ /^\s*ANY\s*$/s ) {
        return { type => 'ANY' };
    }

    elsif ( $contents =~ /^\s*EMPTY\s*$/s ) {
        return { type => 'EMPTY' };
    }

    elsif ( $contents =~ /^\s*\(([^>]+?)\s*$/s ) {
        return element_children($1);
    }

    else {
        die "Not a valid ELEMENT 1 $contents\n";
    }
}

sub element_children {
    my ($children_string) = @_;
    my @kids;
    my $type = 'X';
    my ( $min, $max );

    my $size = 100;

    while ($children_string) {

        # (
        if ( $children_string =~ /^\s*\((.*)$/s ) {
            my ($newKids);
            ( $newKids, $children_string ) = element_children($1);
            push( @kids, $newKids );
        }

        # )
        elsif ( $children_string =~ /^\s*\)([?*+]?)\s*(.*)$/s ) {
            ( $min, $max ) = min_max($1);

            if ( $type eq 'T' ) {
                return { type => 'T' };
                    

            }
            else {
                return 
                {
                    type => $type,
                    kids => \@kids,
                    min  => $min,
                    max  => $max
                };
            }

        }

        # #PCDATA
        elsif ( $children_string =~ /^\s*#PCDATA\s*(.*)$/s ) {
            $type            = 'T';
            $children_string = $1;
        }

        # name*
        elsif ( $children_string =~ /^\s*($name_pattern)([?*+]?)\s*(.*)$/s ) {
            ( $min, $max ) = min_max($2);
            $children_string = $3;
            push(
                @kids,
                {
                    name => $1,
                    min  => $min,
                    max  => $max
                }
            );
        }

        # ,
        elsif ( $children_string =~ /^\s*\,\s*(.*)$/s ) {
            $type            = 'S';
            $children_string = $1;
        }

        # |
        elsif ( $children_string =~ /^\s*\|\s*(.*)$/s ) {
            if ( $type eq 'T' ) {
                $type = 'M';
            }
            else {
                $type = 'C';
            }
            $children_string = $1;
        }

        else {
            die "Invalid syntax $children_string\n";
        }
    }

    return @kids;
}

sub min_max {
    my ($quantifier) = @_;

    return ( 0,  1 ) if ( $quantifier eq '?' );
    return ( 1, -1 ) if ( $quantifier eq '+' );
    return ( 0, -1 ) if ( $quantifier eq '*' );
    return ( 1,  1 );
}

1;
