package SNAC::DTD::Attributes;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::XML::Text qw/get_string/;

use base 'Exporter';

our $VERSION      = '1.0';
our $name_pattern = '[.A-Za-z0-9_-]+';
our $att_types    = 'ID|IDREF|IDREFS|NMTOKEN|NMTOKENS|ENTITY|ENTITIES|NOTATION';

sub parse {
    my ($att_list) = @_;
    my ( $name, $attributes );

    while (trim($att_list)) {

        if ( $att_list =~ /^\s*($name_pattern)\s*NOTATION\s+\(\s*(.*)/s ) {
            my $att_name = $1;
            my ( $enums, $default_value );
            ( $enums, $default_value, $att_list ) = enum_choice($2);
            $attributes->{$att_name} = [ 'NOTATION', $enums, $default_value ];
        }

        elsif ( $att_list =~ /^\s*($name_pattern)\s*CDATA\s+(.*)/s ) {
            $att_list = $2;
            my $att_name = $1;

            if ( $att_list =~ /^\s*(['"])(.*)/s ) {
                my ( $default_value );
                ( $default_value, $att_list ) = get_string( $2, $1 );
                $attributes->{$att_name} =
                  [ 'CDATA', 'DEFAULT', $default_value ];
            }

            elsif ( $att_list =~ /^\s*#FIXED\s*(['"])(.*)/s ) {
                my ( $fixed_value );
                ( $fixed_value, $att_list ) = get_string( $2, $1 );
                $attributes->{$att_name} = [ 'CDATA', 'FIXED', $fixed_value ];
            }

            elsif ( $att_list =~ /^s*#REQUIRED\s*(.*)/s ) {
                $att_list = $1;
                $attributes->{$att_name} = [ 'CDATA', 'REQUIRED' ];
            }

            elsif ( $att_list =~ /^s*#IMPLIED\s*(.*)/s ) {
                $att_list = $1;
                $attributes->{$att_name} = [ 'CDATA', 'IMPLIED' ];
            }

            elsif ( $att_list =~ /^\s*(.*)/s ) {
                $att_list = $1;
                $attributes->{$att_name} = [ 'CDATA', 'IMPLIED' ];
            }
        }

        elsif ( $att_list =~ /^\s*($name_pattern)\s*($att_types)\s+(.*)/s ) {
            $att_list = $3;

            my $att_name  = $1;
            my $att_types = $2;

            if ( $att_list =~ /^\s*#REQUIRED\s*(.*)/s ) {
                $att_list = $1;
                $attributes->{$att_name} = [ $att_types, 'REQUIRED' ];
            }

            elsif ( $att_list =~ /^\s*#IMPLIED\s*(.*)/s ) {
                $att_list = $1;
                $attributes->{$att_name} = [ $att_types, 'IMPLIED' ];
            }
        }

        elsif ( $att_list =~ /^\s*($name_pattern)\s*\(\s*(.*)/s ) {
            my $att_name  = $1;
            my ( $enums, $default_value );
            ( $enums, $default_value, $att_list ) = enum_choice($2);
            $attributes->{$att_name} = [ 'ENUMERATED', $enums, $default_value ];
        }

        else {
            print("Invalid Attribute Syntax '$att_list'\n");
        }

    }
    return $attributes;
}

sub enum_choice {
    my ($enum_string) = @_;
    my ( @enums, $default_value );

    while ( $enum_string =~ /^\s*($name_pattern)\s*\|(.*)/s ) {
        push( @enums, $1 );
        $enum_string = $2;
    }

    if ( $enum_string =~ /^\s*($name_pattern)\s*\)(.*)/s ) {
        push( @enums, $1 );
        $enum_string = $2;
    }
    else {
        die("Not an Enumerated String '$enum_string'\n");
    }

    if ( $enum_string =~ /^\s*(["'])(.*)/s ) {
        ( $default_value, $enum_string ) = SNAC::XML::Text::get_string( $2, $1 );
    }
    elsif ( $enum_string =~ /^\s*#(IMPLIED|REQUIRED)\s*(.*)/s ) {
        ( $default_value, $enum_string ) = ( $1, $2 );
    }
    else {
        die("No Default Value ['$default_value'] ['$enum_string']\n");
    }

    return ( \@enums, $default_value, $enum_string );
}

1;
