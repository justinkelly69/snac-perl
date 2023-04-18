sub snac2xml {
    my ( $json, $options ) = @_;
    return _snac2xml(
        decode_json($json), $options->{PREFIX},
        $options->{PREFIX_CHARACTER},
        $options->{ATTRIBUTE_PREFIX}, $options
    );
}

sub _snac2xml {
    my ( $snac, $prefix, $prefixChar, $attPrefix, $options ) = @_;

    my $out;

    foreach ( @{$snac} ) {

        if ( $_->{N} ) {
            my $ns   = $_->{S};
            my $name = $_->{N};
            my $attributes =
              attributesToXML( $_->{A}, "${prefix}${prefixChar}", $attPrefix );
            my $children = $_->{C};

            my $tagName;

            if ( $ns eq '@' ) {
                $tagName = "$name";
            }
            else {
                $tagName = "$ns:$name";
            }
            $out .= prefix($prefix) . "<${tagName}${attributes}";

            if ( @$children > 0 ) {
                $out .= ">"
                  . _snac2xml( $children, "${prefix}${prefixChar}",
                    $prefixChar, $attPrefix, $options )
                  . prefix($prefix)
                  . "</$tagName>";
            }
            else {
                $out .= " />";
            }

        }
        elsif ( $_->{D} ) {
            my $cdata = $_->{D};
            if ( $options->{USE_CDATA} ) {
                $cdata = escapeCDATA($cdata);
                $out .= prefix($prefix) . "<![CDATA[${cdata}]]>";
            }
            else {
                $cdata = escapeHtml($cdata);
                $out .= prefix($prefix) . "${cdata}";
            }

        }
        elsif ( $_->{M} ) {
            if ( $options->{SHOW_COMMENTS} ) {
                my $comment = escapeComment( $_->{M} );
                $out .= prefix($prefix) . "<!--${comment}-->";
            }
        }
        elsif ( $_->{L} ) {
            if ( $options->{SHOW_PI} ) {
                my $lang      = escapePILang( $_->{L} );
                my $languages = $options->{PI_LANGUAGES};
                if ( grep( /$lang/, @$languages ) ) {
                    my $body = escapePIBody( $_->{B} );
                    $out .= prefix($prefix) . "<?${lang} ${body}?>";
                }
            }
        }
        elsif ( $_->{T} ) {
            my $text = escapeHtml( $_->{T} );
            if ( $options->{TRIM_TEXT} ) {
                $text =~ s/^\s+//;
                $text =~ s/\s+$//;
            }
            if ( $options->{NORMALIZE_TEXT} ) {
                $text =~ s/\s+/ /g;
            }
            $out .= prefix($prefix) . "${text}";
        }
    }

    return $out;
}

sub attributesToXML {
    my ( $atts, $prefix, $attPrefix ) = @_;
    my $out = "";

    foreach $ns ( keys %$atts ) {
        my %ns = %{ $atts->{$ns} };
        foreach $name ( keys %ns ) {
<<<<<<< HEAD
            if ( $ns eq '@' ) {
=======
            if ( $ns == '@' ) {
>>>>>>> 967d3adb1c7f15306a5c348dc4e099b7a6d899b3
                my $value = escapeHtml( $atts->{$ns}->{$name} );
                $out .=
                  prefix( ${prefix} . ${attPrefix} ) . "${name}=\"${value}\"";
            }
            else {
                my $value = escapeHtml( $atts->{$ns}->{$name} );
                $out .= prefix( ${prefix} . ${attPrefix} )
                  . "${ns}:${name}=\"${value}\"";
            }
        }
    }

    return $out;
}

sub prefix {
    my ($prefix) = @_;
    my $out = "";

    if ( $options->{USE_NEWLINES} ) {
        $out .= "\n";
    }

    if ( $options->{USE_PREFIXES} ) {
        $out .= $prefix;
    }

    return $out;
}

1;
