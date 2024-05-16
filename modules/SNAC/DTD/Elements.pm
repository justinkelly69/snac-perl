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
    my ( $element_string, $elements, $children_string ) = @_;
    my $name;

    if ( $element_string =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name           = $1;
        $element_string = $2;

        #<!ELEMENT name ANY>
        if ( $element_string =~ /^\s*ANY\s*>(.*)/s ) {
            $$elements{$name} = 'ANY';
            $element_string = $1;
        }

        #<!ELEMENT name EMPTY>
        elsif ( $element_string =~ /^\s*EMPTY\s*>(.*)/s ) {
            $$elements{$name} = 'EMPTY';
            $element_string = $1;
        }

        #<!ELEMENT name (children)>
        elsif ( $element_string =~ /^\s*\(([^>]+)>(.*)/s ) {
            ( $$elements{$name}, $element_string ) = element_children($1);
        }

        else {
            die "Not a valid ELEMENT 1 $element_string\n";
        }
    }
    else {
        die "Not a valid ELEMENT 2 $element_string\n";
    }

    print($json->pretty->encode($elements)) ;


    return ( $element_string, $elements );

}

sub element_children {
    my ($children_string) = @_;
    my @kids;
    my $type = 'X';
    my ( $min, $max );

    my $size = 100;

    #print("$children_string\n");

    while ($children_string) {
        #print("00000 $children_string\n");

        # (
        if ( $children_string =~ /^\s*\((.*)$/s ) {
            my ($newKids);
            ( $newKids, $children_string ) = element_children($1);
            push( @kids, $newKids );
            #print("11111 $children_string\n");
        }

        # )
        elsif ( $children_string =~ /^\s*\)([?*+]?)\s*(.*)$/s ) {
            ( $min, $max ) = min_max($1);
            #print("22222 $children_string\n");
            return (
                {
                    type => $type,
                    kids => \@kids,
                    min  => $min,
                    max  => $max
                },
                $2
            );
        }

        # #PCDATA
        elsif ( $children_string =~ /^\s*#PCDATA\s*(.*)$/s ) {
            $type            = 'T';
            $children_string = $1;
            #print("33333 $children_string\n");
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
            #print("44444 $children_string\n");
        }

        # ,
        elsif ( $children_string =~ /^\s*\,\s*(.*)$/s ) {
            $type            = 'S';
            $children_string = $1;
            #print("55555 $children_string\n");
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
            #print("66666 $children_string\n");
        }

        else {
            #print("77777 $children_string\n");
            die "Invalid syntax $children_string\n";
        }
    }
}

sub min_max {
    my ($quantifier) = @_;

    return ( 0,  1 ) if ( $quantifier eq '?' );
    return ( 1, -1 ) if ( $quantifier eq '+' );
    return ( 0, -1 ) if ( $quantifier eq '*' );
    return ( 1,  1 );
}
