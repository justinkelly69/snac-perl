package SNAC::DTD::IncludeIgnore;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use String::Util qw(trim);

use SNAC::XML::Text;

use base 'Exporter';

sub parse {
    my ($dtd_string) = @_;

    return include(ignore($dtd_string));
}

sub include {
    my ($dtd_string) = @_;
    my $out_string   = "";

    while($dtd_string =~ /^(.*?)<!\[INCLUDE\[([^]]+?)\]\]>(.*)/s) {
        $out_string .= "$1$2";
        $dtd_string = $3;
    }

    return $out_string . $dtd_string;
}

sub ignore {
    my ($dtd_string) = @_;
    my $out_string   = "";

    while($dtd_string =~ /^(.*?)<!\[IGNORE\[[^]]+?\]\]>(.*)/s) {
        $out_string .= "$1";
        $dtd_string = $2;
    }

    return $out_string . $dtd_string;
}

1;
