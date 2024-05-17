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
    my ($notation_string) = @_;
    my ( $public, $system, $out );

    if ( $notation_string =~ /^\s*PUBLIC\s*(["'])(.*)/s ) {
        ( $public, $notation_string ) = get_string( $2, $1 );

        $out = { public => $public };

        if ( $notation_string =~ /^\s+(["'])(.*)/s ) {
            ( $system, $notation_string ) = get_string( $2, $1 );
            $out->{system} = $system;
        }
    }

    elsif ( $notation_string =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
        ( $system, $notation_string ) = get_string( $2, $1 );
        $out = { system => $system };
    }

    else {
        die "not a notation $1\n";
    }

    return $out;
}

1;

