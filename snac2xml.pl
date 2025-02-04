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
            $out .= prefix($prefix, $options) . "<${tagName}${attributes}";

            if ( @$children > 0 ) {
                $out .= ">"
                  . _snac2xml( $children, "${prefix}${prefixChar}",
                    $prefixChar, $attPrefix, $options )
                  . prefix($prefix, $options)
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
                $out .= prefix($prefix, $options) . "<![CDATA[${cdata}]]>";
            }
            else {
                $cdata = escapeHtml($cdata);
                $out .= prefix($prefix, $options) . "${cdata}";
            }

        }
        elsif ( $_->{M} ) {
            if ( $options->{SHOW_COMMENTS} ) {
                my $comment = escapeComment( $_->{M} );
                $out .= prefix($prefix, $options) . "<!--${comment}-->";
            }
        }
        elsif ( $_->{L} ) {
            if ( $options->{SHOW_PI} ) {
                my $lang      = escapePILang( $_->{L} );
                my $languages = $options->{PI_LANGUAGES};
                if ( grep( /$lang/, @$languages ) ) {
                    my $body = escapePIBody( $_->{B} );
                    $out .= prefix($prefix, $options) . "<?${lang} ${body}?>";
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
            $out .= prefix($prefix, $options) . "${text}";
        }
    }

    return $out;
}

sub attributesToXML {
    my ( $atts, $prefix, $attPrefix, $options ) = @_;
    my $out = "";

    foreach my $ns ( keys %$atts ) {
        my %ns = %{ $atts->{$ns} };
        foreach my $name ( keys %ns ) {
            if ( $ns == '@' ) {
                my $value = escapeHtml( $atts->{$ns}->{$name} );
                $out .=
                  prefix( ${prefix} . ${attPrefix} , $options) . "${name}=\"${value}\"";
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
    my ($prefix, $options) = @_;
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
