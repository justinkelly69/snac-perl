package SNAC::DTD::Attributes;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::XML::Text;

use base 'Exporter';

our $VERSION      = '1.0';
our $name_pattern = '[.A-Za-z0-9_-]+';
our $attribute_types =
  'ID|IDREF|IDREFS|NMTOKEN|NMTOKENS|ENTITY|ENTITIES|NOTATION';

sub parse {
    my ( $attribute_list, $attributes ) = @_;
    my ( $name, %attributes );

    if ( $attribute_list =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name           = $1;
        $attribute_list = $2;

        while ($attribute_list) {

            if ( $attribute_list =~
                /^\s*($name_pattern)\s+NOTATION\s+\(\s*(.*)/s )
            {

                my $attribute_name = $1;
                my ( $enums, $default_value );
                ( $enums, $default_value, $attribute_list ) = enum_choice($2);
                $attributes{$name}{$attribute_name} =
                  [ 'NOTATION', $enums, $default_value ];

            }
            elsif ( $attribute_list =~ /^\s*($name_pattern)\s+CDATA\s+(.*)/s ) {
                my $attribute_name = $1;
                $attribute_list = $2;

                if ( $attribute_list =~ /^\s*(['"])(.*)/s ) {
                    my $default_value;
                    ( $default_value, $attribute_list ) =
                      SNAC::XML::Text::get_string( $2, $1 );
                    $attributes{$name}{$attribute_name} =
                      [ 'CDATA', 'DEFAULT', $default_value ];

                }
                elsif ( $attribute_list =~ /^\s*#FIXED\s*(['"])(.*)/s ) {
                    my $fixedValue;
                    ( $fixedValue, $attribute_list ) =
                      SNAC::XML::Text::get_string( $2, $1 );
                    $attributes{$name}{$attribute_name} =
                      [ 'CDATA', 'FIXED', $fixedValue ];

                }
                elsif ( $attribute_list =~ /^s*#REQUIRED\s*(.*)/s ) {
                    $attribute_list = $1;
                    $attributes{$name}{$attribute_name} =
                      [ 'CDATA', 'REQUIRED' ];

                }
                elsif ( $attribute_list =~ /^s*#IMPLIED\s*(.*)/s ) {
                    $attribute_list = $1;
                    $attributes{$name}{$attribute_name} =
                      [ 'CDATA', 'IMPLIED' ];

                }
                elsif ( $attribute_list =~ /^\s*(.*)/s ) {
                    $attribute_list = $1;
                    $attributes{$name}{$attribute_name} =
                      [ 'CDATA', 'IMPLIED' ];
                }

            }
            elsif ( $attribute_list =~
                /^\s*($name_pattern)\s+($attribute_types)\s+(.*)/s )
            {
                my $attribute_name = $1;
                my $attribute_type = $2;
                $attribute_list = $3;

                if ( $attribute_list =~ /^\s*#REQUIRED\s*(.*)/s ) {
                    $attribute_list = $1;
                    $attributes{$name}{$attribute_name} =
                      [ $attribute_type, 'REQUIRED' ];

                }
                elsif ( $attribute_list =~ /^\s*#IMPLIED\s*(.*)/s ) {
                    $attribute_list = $1;
                    $attributes{$name}{$attribute_name} =
                      [ $attribute_type, 'IMPLIED' ];
                }

            }
            elsif ( $attribute_list =~ /^\s*($name_pattern)\s*\(\s*(.*)/s ) {
                my $attribute_name = $1;
                my ( $enums, $default_value );
                ( $enums, $default_value, $attribute_list ) = enum_choice($2);
                $attributes{$name}{$attribute_name} =
                  [ 'ENUMERATED', $enums, $default_value ];

            }
            elsif ( $attribute_list =~ /^\s*>(.*)/s ) {
                $attribute_list = $1;
                return ( $attribute_list, $attributes );

            }
            else {
                die("Invalid Syntax: '$attribute_list'\n");
            }
        }
    }
}

sub enum_choice {
    my ($str) = @_;
    my ( @enums, $default_value );

    while ( $str =~ /^\s*($name_pattern)\s*\|(.*)/s ) {
        push( @enums, $1 );
        $str = $2;
    }

    if ( $str =~ /^\s*($name_pattern)\s*\)(.*)/s ) {
        push( @enums, $1 );
        $str = $2;
    }
    else {
        die("Not an Enumerated String '$1'\n");
    }

    if ( $str =~ /^\s*(["'])(.*)/s ) {
        ( $default_value, $str ) = SNAC::XML::Text::get_string( $2, $1 );
    }
    elsif ( $str =~ /^\s*#(IMPLIED|REQUIRED)\s*(.*)/s ) {
        ( $default_value, $str ) = ( $1, $2 );
    }
    else {
        die("No Default Value ['$default_value'] ['$str']\n");
    }

    return ( \@enums, $default_value, $str );
}
