sub escapeHtml {
	my($value) = @_;

	$value =~ s!&!&amp;!g;
	$value =~ s!<!&lt;!g;
	$value =~ s!>!&gt;!g;
	$value =~ s!'!&apos;!g;
	$value =~ s!"!&quot;!g;

	return $value;
}


sub unEscapeHtml {
	my($value) = @_;

	$value =~ s!&amp;!&!g;
	$value =~ s!&lt;!<!g;
	$value =~ s!&gt;!>!g;
	$value =~ s!&apos;!'!g;
	$value =~ s!&quot;!"!g;

	return $value;
}


sub escapeCDATA {
	my($value) = @_;

	$value =~ s!]]>!]]&gt;!g;

	return $value;
}


sub escapeComment {
	my($value) = @_;

	$value =~ s!--! - - !g;

	return $value;
}


sub escapePILang {
	my($value) = @_;

	if($value !~ m![a-z]+[0-9]?=?!){
		return '';
	}

	return $value;
}


sub escapePIBody {
	my($value) = @_;

	$value =~ s!\?>!?&gt;!g;
    
	return $value;
}

sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

1;