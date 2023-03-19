#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON::MaybeXS qw(encode_json decode_json);

require "./text.pl";
require "./snac2xml.pl";
require "./xml2snac.pl";

$input = "xml/waffle-bad.xml";
$jsonOut = "out/snac.json";
$xmlOut = "out/snac.xml";

open my $fh, '<', $input;
$/ = undef;
my $xml = <$fh>;
my @prefix = ();
close $fh;

my @stack;
my $json = xml2snac($xml, \@stack);
open my $jsonFh, '>', $jsonOut;
print $jsonFh $json;
close $jsonFh;

#print("$json\n");

my $xml = snac2xml($json, "", "\t", '  ');
open my $xmlFh, '>', $xmlOut;
print $xmlFh $xml;
close $xmlFh;
