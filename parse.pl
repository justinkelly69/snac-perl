#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON::MaybeXS qw(encode_json decode_json);
use String::Util qw(trim);

require "./text.pl";
require "./snac2xml.pl";
require "./xml2snac.pl";

my $input = "xml/waffle.xml";
my $jsonOut = "out/snac.json";
my $xmlOut = "out/snac.xml";

my $options = {
	USE_CDATA => 1,
	SHOW_COMMENTS => 1,
	SHOW_PI => 1,
	PI_LANGUAGES => ['xml','php', 'php='],

	TRIM_TEXT => 1,
	NORMALIZE_TEXT => 1,
	USE_EMPTY_TEXT_NODES => 1,
	USE_EMPTY_NODES => 1,
	USE_PREFIXES => 1,
	PREFIX => '',
	PREFIX_CHARACTER => '    ',
	ATTRIBUTE_PREFIX => '  ',
	USE_NEWLINES => 1
};

open my $fh, '<', $input; #$ARGV[0];
$/ = undef;
my $xml = <$fh>;
my @prefix = ();
close $fh;

#print("open $xml\n");

my @stack;
my $json = xml2snac($xml, \@stack);
open my $jsonFh, '>', $jsonOut;
print $jsonFh $json;
close $jsonFh;

#print("$json\n");

my $xml1 = snac2xml($json, $options);
open my $xmlFh, '>', $xmlOut;
print $xmlFh $xml1;
close $xmlFh;
