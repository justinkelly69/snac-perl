#!/home/jk/opt/perl/bin/perl

use Data::Dumper;

require "./attributes.pl";

$input = "xml/waffle.xml";

open my $fh, '<', $input;
$/ = undef;
my $xml = <$fh>;
my @prefix = ();
close $fh;

my $data = parseXML($xml);
print Data::Dumper->Dump([$data->{out}], [qw(out)]);

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
					T => $text
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
	}
}


