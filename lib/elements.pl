#!/usr/bin/env perl

use strict;
use warnings;

package Elements;
use strict;
use warnings;

use Exporter qw(import);
 
our @EXPORT = qw(any empty node_name text element_list);

sub any {
    return { _ => 'A' };
}

sub empty {
    return { _ => 'E' };
}

sub node_name {
    my ( $name, $min, $max ) = @_;

    return {
        name => $name,
        min  => $min,
        max  => $max
    };
}

sub text {
    return { _ => 'T' };
}

sub element_list {
    my ( $type, $kids, $min, $max ) = @_;

    return {
        type => $type,
        kids => $kids,
        min  => $min,
        max  => $max
    };
}

1;