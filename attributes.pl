

sub getAttributes {
	my($xml) = @_;
	my %attributes;

	while($xml) {

		# CLOSE EMPTY ATTRIBUTE
		if($xml =~ m!^\s*/>(.*)$!s){

			#print "CLOSE EMPTY ATTRIBUTE\n";
			return {
				xml => $1,
				kids => 0,
				snac => \%attributes
			};
		}

		# CLOSE ATTRIBUTE
		elsif($xml =~ m!^\s*>(.*)$!s){ # create child array
			 #print "CLOSE ATTRIBUTE\n";
			return {
				xml => $1,
				kids => 1,
				snac => \%attributes
			};
		}

		# OPEN ATTRIBUTE
		elsif($xml =~ m!^\s*([\w]+:?[\w]+)=(['"])(.*)$!s){

			#print("$1=$2");
			my $att = attribute(\%attributes, $1, $2, $3);
			$attributes = $att->{attributes};
			$xml = $att->{xml};
		}

		# INVALID ATTRIBUTE
		else {
			die("INVALID ATTRIBUTE [$xml]\n");
		}
	}
}


sub attribute {
	my($attributes, $nameStr, $quoteChar, $xml) = @_;

	my $attVal = getAttributeValue($quoteChar, $xml);

	my $colonIndex = index($nameStr, ':');
	if($colonIndex == -1){
		if(!exists $attributes->{'@'}){
			$attributes->{'@'} = {};
		}

		#print("\nNAMESTR $nameStr\n");
		$attributes->{'@'}->{$nameStr} = $attVal->{value};
	}else {
		$ns = substr($nameStr, 0, $colonIndex);
		$name = substr($nameStr, $colonIndex + 1);

		#print("\nNS $ns, NAME $name\n");
		if(!exists $attributes->{$ns}){
			$attributes->{$ns} = {};
		}
		$attributes->{$ns}->{$name} = $attVal->{value};
	}
	return {
		atts => $attributes,
		xml => $attVal->{xml}
	};
}


sub getAttributeValue {
	my ($quoteChar, $xml) = @_;
	my $value;
	my $correct = 0;
	for my $i (0..length($xml) - 1){
		if(substr($xml, $i, 1) =~ m!^$quoteChar$! && substr($xml, $i - 1, 1) !~ m!^\\$!) {
			$value = substr($xml, 0, $i);
			$value =~ s!\\$quoteChar!$quoteChar!g;
			$value = unEscapeHtml($value);

			#print("$value$quoteChar\n");
			$xml = substr($xml, $i + 1);
			$correct = 1;
			last;
		}
	}
	if($correct == 0) {
		die "BAD ATTRIBUTE VALUE [$xml]\n";
	}

	return {
		value => $value,
		xml => $xml
	};
}


sub attributesToXML {
	my($atts, $prefix, $attPrefix) = @_;
	my $out = "";

	foreach $ns (keys %$atts){
		my %ns = %{$atts->{$ns}};
		foreach $name (keys %ns) {
			if($ns == '@'){
				my $value = escapeHtml($atts->{$ns}->{$name});
				$out .= "\n${prefix}${attPrefix}${name}=\"$value\"";
			} else {
				my $value = escapeHtml($atts->{$ns}->{$name});
				$out .= "\n${prefix}${attPrefix}${ns}:${name}=\"$value\"";
			}
		}
	}

	return $out;
}

1;