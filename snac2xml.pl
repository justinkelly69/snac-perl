sub snac2xml {
	my($json, $prefix, $prefixChar, $attPrefix) = @_;
	return _snac2xml(decode_json($json), $prefix, $prefixChar, $attPrefix);
}


sub _snac2xml {
	my($snac, $prefix, $prefixChar, $attPrefix) = @_;

	my $out;

	foreach (@{$snac}){

		if($_->{N}){
			my $ns = $_->{S};
			my $name = $_->{N};
			my $attributes = attributesToXML($_->{A}, "${prefix}${prefixChar}", $attPrefix);
			my $children = $_->{C};

			my $tagName;

			if($ns eq '@'){
				$tagName = "$name";
			}else {
				$tagName = "$ns:$name";
			}
			$out .= "\n$prefix<${tagName}${attributes}";

			if(@$children > 0){
				$out .= ">" ._snac2xml($children, "${prefix}${prefixChar}", $prefixChar, $attPrefix) ."\n$prefix</$tagName>";
			}else {
				$out .= " />";
			}

		}elsif($_->{D}){
			my $cdata = escapeCDATA($_->{D});
			$out .= "\n${prefix}<![CDATA[${cdata}]]>";

		}elsif($_->{M}){
			my $comment = escapeComment($_->{M});
			$out .= "\n${prefix}<!--${comment}-->";

		}elsif($_->{L}){
			my $lang = escapePILang($_->{L});
			my $body = escapePIBody($_->{B});
			$out .= "\n${prefix}<?${lang} ${body}?>";

		}elsif($_->{T}){
			my $text = escapeHtml($_->{T});
			$out .= "\n${prefix}${text}";
		}
	}

	return $out;
}


sub attributesToXML {
	my($atts, $prefix, $attPrefix) = @_;
	my $out = "";

	foreach $ns (keys %$atts){
		my %ns = %{$atts->{$ns}};
		foreach $name (keys %ns) {
			if($ns == '@'){
				my $value = escapeHtml($atts->{$ns}->{$name});
				$out .= "\n${prefix}${attPrefix}${name}=\"${value}\"";
			} else {
				my $value = escapeHtml($atts->{$ns}->{$name});
				$out .= "\n${prefix}${attPrefix}${ns}:${name}=\"${value}\"";
			}
		}
	}

	return $out;
}

1;