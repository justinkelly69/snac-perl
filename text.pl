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

1;