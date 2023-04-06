sub xml2snac {
	my($xml, $stack) = @_;
	local @stack;
	return encode_json(_xml2snac($xml)->{out});
}

sub _xml2snac {
	my ($xml) = @_;
	my @out;

	while($xml) {

		# OPEN TAG
		if($xml =~ /^<([\w]*:?[\w]+)(.*)$/s){
			my $nameTag = $1;
			my $attData = getAttributes($2);
			$xml = $attData->{xml};

			my $snac = {
				S => '@',
				N => $nameTag,
				A => $attData->{snac},
				C => []
			};
			my $index = index($nameTag, ':');
			if($index > -1){
				$snac->{S} = substr($nameTag, 0, $index);
				$snac->{N} = substr($nameTag, $index + 1);
			}

			push(
				@stack,
				{
					S => $snac->{S},
					N => $snac->{N}
				}
			);

			if($attData->{'kids'}){
				my($kids) = _xml2snac($xml);
				$snac->{C} = $kids->{out};
				$xml = $kids->{xml};
				push(@out, $snac);

			}else {
				push(@out, $snac);
				my $prev = pop(@stack);
			}

			#printStack(@stack);
		}

		# CLOSE TAG
		elsif($xml =~ /^<\/([\w]*:?[\w]+)>(.*)$/s){
			my $nameTag = $1;
			my $snac = {
				S => '@',
				N => $nameTag
			};

			my $index = index($nameTag, ':');
			if($index > -1){
				$snac->{S} = substr($nameTag, 0, $index);
				$snac->{N} = substr($nameTag, $index + 1);
			}

			#printStack(@stack);

			my $prev = pop(@stack);
			if($prev->{S} ne $snac->{S} || $prev->{N} ne $snac->{N}){
				die "\n\nUNMATCHED TAG <$prev->{S}:$prev->{N}></$snac->{S}:$snac->{N}>\n";
			}

			$xml = $2;
			return {
				xml => $xml,
				out => \@out
			};
		}

		# CDATA
		elsif($xml =~ /^<!\[CDATA\[(.*?)\]\]>(.*)$/s){
			my $cdata = $1;
			push(
				@out,
				{
					D => $cdata
				}
			);
			$xml = $2;
		}

		# COMMENT
		elsif($xml =~ /^<!--(.*?)-->(.*)$/s){
			my $comment = $1;
			push(
				@out,
				{
					M => $comment
				}
			);
			$xml = $2;
		}

		# PI
		elsif($xml =~ /^<\?(\w+=?)\s+(.*?)\?>(.*)$/s){
			my $lang = $1;
			my $body = $2;
			push(
				@out,
				{
					L => $lang,
					B => $body
				}
			);
			$xml = $3;
		}

		# TEXT
		elsif($xml =~ /^([^<>]+)(.*)$/s){
			my $text = $1;
			push(
				@out,
				{
					T => unEscapeHtml($text)
				}
			);
			$xml = $2;
		}

		# BLANK TEXT
		elsif($xml =~ /^$/s){
			push(
				@out,
				{
					T => ''
				}
			);

			#$xml = $2;
		}

		# INVALID ELEMENT
		else {
			die "NOT AN ELEMENT [$xml]\n";
		}
	}

	return {
		xml => $xml,
		out => \@out
	};
}


sub getAttributes {
	my($xml) = @_;
	my %attributes;

	while($xml) {

		# CLOSE ATTRIBUTE
		if($xml =~ m!^\s*(/?>)(.*)$!s){
			my $kids = 0;

			if($1 eq '>') {
				$kids = 1;
			}

			return {
				xml => $2,
				kids => $kids,
				snac => \%attributes
			};
		}

		# OPEN ATTRIBUTE
		elsif($xml =~ m!^\s*([\w]+:?[\w]+)=(['"])(.*)$!s){
			my $att = addAttribute(\%attributes, $1, $2, $3);
			$attributes = $att->{attributes};
			$xml = $att->{xml};
		}

		# INVALID ATTRIBUTE
		else {
			die("INVALID ATTRIBUTE [$xml]\n");
		}
	}
}


sub addAttribute {
	my($attributes, $nameStr, $quoteChar, $xml) = @_;

	my $attVal = getAttributeValue($quoteChar, $xml);

	my $colonIndex = index($nameStr, ':');
	if($colonIndex == -1){
		if(!exists $attributes->{'@'}){
			$attributes->{'@'} = {};
		}
		$attributes->{'@'}->{$nameStr} = $attVal->{value};
	}else {
		$ns = substr($nameStr, 0, $colonIndex);
		$name = substr($nameStr, $colonIndex + 1);
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

1;
