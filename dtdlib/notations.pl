use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

# <!NOTATION gif  SYSTEM "image/gif">
sub parseNotation {
    my ( $notationStr, $notations ) = @_;
    my $name, $public, $system;

    if ( $notationStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name        = $1;    # gif
        $notationStr = $2;

        if ( $notationStr =~ /^\s*PUBLIC\s*(["'])(.*)/s ) {
            ( $public, $notationStr ) = getString( $2, $1 );

            if ( $notationStr =~ /^\s+(["'])(.*)/s ) {
                ( $system, $notationStr ) = getString( $2, $1 );
                $$notations{$name} = {
                    PUBLIC => $public,
                    SYSTEM => $system
                };
            }
            else {
                $$notations{$name} = { PUBLIC => $public };
            }
        }

        elsif ( $notationStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $system, $notationStr ) = getString( $2, $1 );
            $$notations{$name} = { SYSTEM => $system };
        }

        if ( $notationStr =~ /^\s*>(.*)/s ) {
            $notationStr = $1;
            return ( $notationStr, $notations );
        }

        else {
            die "not a notation $1\n";
        }
    }

    else {
        die "Not an element $notationStr\n";
    }
}
