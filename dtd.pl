#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON;
use String::Util qw(trim);

BEGIN {
    use lib './modules';
}

use SNAC::DTD;

my $dtd;
{
    open my $fh, '<', $ARGV[0] or die "Can't read input file: $!";
    local $/ = undef;
    $dtd = <$fh>;
    close $fh;
}
my $json = JSON->new->allow_nonref;
my $out = SNAC::DTD::parse_dtd($dtd);

print($json->pretty->encode($out));


