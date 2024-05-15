package SNAC::XML::Text;
use strict;
use warnings;
our $VERSION = '1.0';

use base 'Exporter';
our @EXPORT = qw(
    escape_html 
    unescape_html 
    escape_cdata 
    escape_comment 
    escape_pi_lang 
    escape_pi_body
    trim 
    get_string 
    normalize_string
);

our $name_pattern = '[.A-Za-z0-9_-]+';

# comment
sub escape_html {
    my ($value) = @_;

    $value =~ s!&!&amp;!g;
    $value =~ s!<!&lt;!g;
    $value =~ s!>!&gt;!g;
    $value =~ s!'!&apos;!g;
    $value =~ s!"!&quot;!g;

    return $value;
}

sub unescape_html {
    my ($value) = @_;

    $value =~ s!&amp;!&!g;
    $value =~ s!&lt;!<!g;
    $value =~ s!&gt;!>!g;
    $value =~ s!&apos;!'!g;
    $value =~ s!&quot;!"!g;

    return $value;
}

sub escape_cdata {
    my ($value) = @_;
    $value =~ s!]]>!]]&gt;!g;
    return $value;
}

sub escape_comment {
    my ($value) = @_;
    $value =~ s!--! - - !g;
    return $value;
}

sub escape_pi_lang {
    my ($value) = @_;
    if ( $value !~ m![a-z]+[0-9]?=?! ) {
        return '';
    }
    return $value;
}

sub escape_pi_body {
    my ($value) = @_;
    $value =~ s!\?>!?&gt;!g;
    return $value;
}

sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub get_string {
    my ( $string, $quoteChar ) = @_;
    my ($value);

    for my $i ( 0 .. length($string) - 1 ) {

        if (substr( $string, $i, 1 ) =~ m!^$quoteChar$! # character is " or '
            && substr( $string, $i - 1, 1 ) !~ m!^\\$! ){   # preceding character is not \

            $value = substr( $string, 0, $i );
            $value =~ s!\\$quoteChar!$quoteChar!g; # \' to ' \" to "
            $value  = unescape_html($value);
            $string = substr( $string, $i + 1 );
            
            return ( $value, $string );
        }
    }
    die "BAD STRING '$string'\n";
}

sub normalize_string {
    my( $string ) = @_;

    my @lines = split(/\s+/, $string);
    $string = join(' ', @lines);
    $string =~ s/\s*\|\s*/ | /g;
    $string =~ s/\s*,\s*/ , /g;
    $string =~ s/\(\s+/(/g;
    $string =~ s/\s+\)/)/g;

    return trim($string);
}

1;
