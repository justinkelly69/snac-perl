use strict;
use warnings;

my $name_pattern = '[.A-Za-z0-9_-]+';

# comment
sub escapeHtml {
    my ($value) = @_;

    $value =~ s!&!&amp;!g;
    $value =~ s!<!&lt;!g;
    $value =~ s!>!&gt;!g;
    $value =~ s!'!&apos;!g;
    $value =~ s!"!&quot;!g;

    return $value;
}

sub unEscapeHtml {
    my ($value) = @_;

    $value =~ s!&amp;!&!g;
    $value =~ s!&lt;!<!g;
    $value =~ s!&gt;!>!g;
    $value =~ s!&apos;!'!g;
    $value =~ s!&quot;!"!g;

    return $value;
}

sub escapeCDATA {
    my ($value) = @_;
    $value =~ s!]]>!]]&gt;!g;
    return $value;
}

sub escapeComment {
    my ($value) = @_;
    $value =~ s!--! - - !g;
    return $value;
}

sub escapePILang {
    my ($value) = @_;
    if ( $value !~ m![a-z]+[0-9]?=?! ) {
        return '';
    }
    return $value;
}

sub escapePIBody {
    my ($value) = @_;
    $value =~ s!\?>!?&gt;!g;
    return $value;
}

# sub trim {
#     my $s = shift;
#     $s =~ s/^\s+|\s+$//g;
#     return $s;
# }

sub getString {
    my ( $string, $quoteChar ) = @_;
    my ($value);

    for my $i ( 0 .. length($string) - 1 ) {

        if (substr( $string, $i, 1 ) =~ m!^$quoteChar$! # character is " or '
            && substr( $string, $i - 1, 1 ) !~ m!^\\$! ){   # preceding character is not \

            $value = substr( $string, 0, $i );
            $value =~ s!\\$quoteChar!$quoteChar!g; # \' to ' \" to "
            $value  = unEscapeHtml($value);
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
