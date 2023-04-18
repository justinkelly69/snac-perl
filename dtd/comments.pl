sub removeComments {
    my ($dtdString) = @_;
    my $outString;

    while ( $dtdString =~ /<!--.*?-->(.*)/s ) {
        $outString .= $`;
        $dtdString = $1;
    }
    $outString .= $dtdString;

    return $outString;
}