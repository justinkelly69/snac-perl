#!/home/jk/opt/perl/bin/perl

use JSON::MaybeXS qw(encode_json decode_json);

require "./dtd.pl";

parse_particle(" (#PCDATA)*");
parse_particle(" (#PCDATA | name* |value?)*");
parse_particle(" (name* |value?)?");
parse_particle(" (name+ ,value?)+");
parse_particle(" (alpha+ , beta? , zeta)+");
#parse_particle(" (alpha+ , beta? , (gamma | delta | epsilon) , zeta)+");
parse_particle(" (alpha+ | beta? | (gamma , delta , epsilon) | zeta)+");
parse_particle(" (#PCDATA | alpha+ | beta? | (gamma , delta , epsilon) | zeta)+");

sub parse_particle {
    my ($dtd) = @_;
    print("$dtd\n");
    print encode_json( read_children($dtd) ) . "\n\n";
}