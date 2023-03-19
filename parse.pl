#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON::MaybeXS qw(encode_json decode_json);

require "./attributes.pl";
require "./text.pl";

$input = "xml/waffle.xml";
$jsonOut = "out/snac.json";
$xmlOut = "out/snac.xml";

open my $fh, '<', $input;
$/ = undef;
my $xml = <$fh>;
my @prefix = ();
close $fh;

my $data = parseXML($xml);
#my $snac = Data::Dumper->Dump([$data->{out}], [qw(out)]);
my $snac = encode_json($data->{out});
open my $jsonFh, '>', $jsonOut;
print $jsonFh $snac;
close $jsonFh;

my $xml = snac2xml($data->{out}, "", "\t", '  ');
open my $xmlFh, '>', $xmlOut;
print $xmlFh $xml;
close $xmlFh;

sub parseXML {
	my ($xml) = @_;
	my @out;
	my @stack;

	while($xml) {

		# OPEN TAG
		if($xml =~ /^<([\w]*:?[\w]+)(.*)$/s){

			my $attData = getAttributes($2);
			$xml = $attData->{xml};

			my $snac = {
				S => '@',
				N => $1,
				A => $attData->{snac},
				C => []
			};
			my $index = index($1, ':');
			if($index > -1){
				$snac->{S} = substr($1, 0, $index);
				$snac->{N} = substr($1, $index + 1);
			}
			push(
				@stack,
				{
					S => $snac->{S},
					N => $snac->{N}
				}
			);

			if($attData->{'kids'}){
				my($kids) = parseXML($xml);

				$snac->{C} = $kids->{out};
				$xml = $kids->{xml};

				push(@out, $snac);

			}else {
				push(@out, $snac);
			}
		}

		# CLOSE TAG
		elsif($xml =~ /^<\/([\w]*:?[\w]+)>(.*)$/s){

			my $snac = {
				S => '@',
				N => $1
			};

			my $index = index($1, ':');
			if($index > -1){
				$snac->{S} = substr($1, 0, $index);
				$snac->{N} = substr($1, $index + 1);
			}

			my $prev = pop(@stack);
			if($prev->{S} != $snac->{S} || $prev->{N} != $snac->{N}){
				die "UNMATCHED TAG <$prev->{S}:$prev->{N}></$snac->{S}:$snac->{N}>\n";
			}

			$xml = $2;

			return {
				xml => $xml,
				out => \@out
			};
		}

		# CDATA
		elsif($xml =~ /^<!\[CDATA\[(.*?)\]\]>(.*)$/s){

			push(
				@out,
				{
					D => $1
				}
			);
			$xml = $2;
		}

		# Comment
		elsif($xml =~ /^<!--(.*?)-->(.*)$/s){
			push(
				@out,
				{
					M => $1
				}
			);
			$xml = $2;
		}

		# PI
		elsif($xml =~ /^<\?(\w+=?)\s+(.*?)\?>(.*)$/s){
			push(
				@out,
				{
					L => $1,
					B => $2
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

		# BLANK
		elsif($xml =~ /^$/s){
			push(
				@out,
				{
					T => ''
				}
			);
			$xml = $2;
		}

		# INVALID
		else {
			#die "NOT AN ELEMENT [$xml]\n";
			last;
		}
	}

	return {
		xml => $xml,
		out => \@out
	};
}


sub snac2xml {
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
			$out .= "\n$prefix<$tagName $attributes";

			if(@$children > 0){
				$out .= ">\n" .snac2xml($children, "${prefix}${prefixChar}", $prefixChar, $attPrefix) ."\n$prefix</$tagName>";
			}else {
				$out .= "/>\n";
			}

		}elsif($_->{D}){
			$out .= "\n$prefix<![CDATA[$_->{D}]]>";

		}elsif($_->{M}){
			$out .= "\n$prefix<!--$_->{M}-->";

		}elsif($_->{L}){
			$out .= "\n$prefix<?$_->{L} $_->{B}?>";

		}elsif($_->{T}){
			my $text = escapeHtml($_->{T});
			$out .= "\n${prefix}${text}";
		}
	}

	return $out;
}
