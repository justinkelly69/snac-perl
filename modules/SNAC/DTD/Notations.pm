package SNAC::DTD::Notations;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::XML::Text;

our $VERSION      = '1.0';
our $name_pattern = '[.A-Za-z0-9_-]+';

# <!NOTATION gif  SYSTEM "image/gif">
sub parse {
    my ( $notation_string, $notations ) = @_;
    my ( $name, $public, $system );

    if ( $notation_string =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name            = $1;    # gif
        $notation_string = $2;

        if ( $notation_string =~ /^\s*PUBLIC\s*(["'])(.*)/s ) {
            ( $public, $notation_string ) = get_string( $2, $1 );

            if ( $notation_string =~ /^\s+(["'])(.*)/s ) {
                ( $system, $notation_string ) = get_string( $2, $1 );
                $$notations{$name} = {
                    PUBLIC => $public,
                    SYSTEM => $system
                };
            }
            else {
                $$notations{$name} = { PUBLIC => $public };
            }
        }

        elsif ( $notation_string =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $system, $notation_string ) = get_string( $2, $1 );
            $$notations{$name} = { SYSTEM => $system };
        }

        if ( $notation_string =~ /^\s*>(.*)/s ) {
            $notation_string = $1;
            return ( $notation_string, $notations );
        }

        else {
            die "not a notation $1\n";
        }
    }

    else {
        die "Not an element $notation_string\n";
    }
}
