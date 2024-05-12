use Data::Dumper;
use JSON;
use String::Util qw(trim);

require "./text.pl";

$name_pattern = '[A-Za-z0-9_-]+';
$ATT_TYPES    = 'ID|IDREF|IDREFS|NMTOKEN|NMTOKENS|ENTITY|ENTITIES|NOTATION';

sub getEntities {
    my ($dtdString) = @_;
    my %pEntities;
    my $outString;
    my $pEntities = \%pEntities;

    while ( $dtdString =~ /<!ENTITY\s+%\s+(.*)/s ) {
        $outString .= $`;
        print("1 {{{" . normalizeString($1) . ")}}}\n");
        ( $pEntities, $dtdString ) = parsePEntity( $1, $pEntities );
    }
    $outString .= $dtdString;

    return ( $pEntities, $outString );
}

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

sub parseDTD {
    my ( $dtdString, $out, $include ) = @_;
    my $json = JSON->new->allow_nonref;

    while ( trim($dtdString) ne '' ) {

        if ( $dtdString =~ /^\s*<!ELEMENT\s+(.*)/s ) {
            if ( !defined( $$out{elements} ) ) {
                $$out{elements} = {};
            }
            $dtdString = parseElement( $1, $$out{elements}, $include );
        }

        elsif ( $dtdString =~ /^\s*<!ATTLIST\s+(.*)/s ) {
            if ( !defined( $$out{attributes} ) ) {
                $$out{attributes} = {};
            }
            $dtdString = parseAttList( $1, $$out{attributes}, $include );
        }

        elsif ( $dtdString =~ /^\s*<!ENTITY\s+(.*)/s ) {
            if ( !defined( $$out{entities} ) ) {
                $$out{entities} = {};
            }
            $dtdString = parseEntity( $1, $$out{entities}, $include );
        }

        elsif ( $dtdString =~ /^\s*<!NOTATION\s+(.*)/s ) {
            if ( !defined( $$out{notations} ) ) {
                $$out{notations} = {};
            }
            $dtdString = parseNotation( $1, $$out{notations}, $include );
        }
        elsif ( $dtdString =~ /^\s*\]\]>\s+(.*)/s ) {
            print "end\n";
            $dtdString = $1;
            return $dtdString;
        }
        elsif ( $dtdString =~ /^\s*<!\[INCLUDE\[\s+(.*?)]]>(.*)/s ) {
            #print "include [[[$1]]]\n";
            $dtdString = parseDTD( $1, $out, $include );
            $dtdString = parseDTD( $2, $out, $include );
            return $dtdString;
        }

        elsif ( $dtdString =~ /^\s*<!\[IGNORE\[\s+(.*?)]]>(.*)/s ) {
            #print "ignore [[[$1]]]\n";
            # $dtdString = parseDTD( $1, $out, $include );
            # $dtdString = parseDTD( $2, $out, $include );
            return $dtdString;
        }

        else {
            return $dtdString;
        }
    }
}

sub parseElement {
    my ( $elementStr, $elements, $include ) = @_;
    my $name;

    if ( $elementStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name       = $1;
        $elementStr = $2;

        if ( $elementStr =~ /^\s*ANY\s*(.*)/s ) {
            $$elements{$name} = 'ANY' if ($include);
            $elementStr = $1;
        }

        elsif ( $elementStr =~ /^\s*EMPTY\s*(.*)/s ) {
            $$elements{$name} = 'EMPTY' if ($include);
            $elementStr = $1;
        }

        elsif ( $elementStr =~ /^\s*\((.*)/s ) {
            my $children;
            ( $elementStr, $children ) = elementChildren( $1, $include );
            $$elements{$name} = $children if ($include);
        }

        else {
            die "Invalid string $elementStr\n";
        }
    }
    else {
        die "Not an element $elementStr\n";
    }

    if ( $elementStr =~ /^\s*>(.*)/s ) {
        $elementStr = $1;
        return $elementStr;
    }
}

sub elementChildren {
    my ( $dtd, $include ) = @_;
    my @kids;
    my $atomType = 'X';

    while ($dtd) {

        # # Strip off ' | ' or ' , ' at start of string
        if ( $dtd =~ /^\s*[|,](.*)/s ) {
            $dtd = $1;
        }

        # (#PCDATA)
        elsif ( $dtd =~ /^\s*#PCDATA\s*\)(.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'T';
            }
            $dtd = $1;
            push( @kids, [ 'R', '#TEXT' ] ) if ($include);

            return ( $dtd, [ $atomType, \@kids ] );
        }

        # (#PCDATA | .... )
        elsif ( $dtd =~ /^\s*#PCDATA\s*[|](.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'M';
            }
            $dtd = $1;
        }

        # (name | .... )
        elsif ( $dtd =~ /^\s*(${name_pattern})\s*[|](.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'C';
            }
            my $atomName = $1;
            $dtd = $2;
            push( @kids, [ 'R', $atomName ] ) if ($include);
        }

        # (name , .... )
        elsif ( $dtd =~ /^\s*(${name_pattern})([?+*]?)\s*[,](.*)/s ) {
            if ( $atomType eq 'X' ) {
                $atomType = 'S';
            }
            my $atomName = $1;
            $dtd = $3;
            push( @kids, [ 'R', $atomName, quantify($2) ] ) if ($include);
        }

        # ( new particle
        elsif ( $dtd =~ /^\s*\(\s*(.*)/s ) {
            my $newKids;
            ( $dtd, $newKids ) = elementChildren( $1, $include );
            push( @kids, $newKids ) if ($include);
        }

        # name* ) // $COMMA
        elsif ( $dtd =~ /^\s*(${name_pattern})([?+*]?)\s*\)([?+*]?)(.*)/s ) {
            my $atomName = $1;
            $dtd = $4;
            if ( $atomName ne '' ) {
                if ( $atomType eq 'S' ) {
                    push( @kids, [ 'R', $atomName, quantify($2) ] )
                      if ($include);
                }
                else {
                    push( @kids, [ 'R', $atomName ] ) if ($include);
                }
            }

            return ( $dtd, [ $atomType, \@kids, quantify($3) ] );
        }

        else {
            die("something not right\n");
        }
    }
}

sub quantify {
    my ($quantifier) = @_;
    my $min = 1, $max = 1;

    if ( $quantifier eq '?' ) {
        $min = 0;
    }
    elsif ( $quantifier eq '+' ) {
        $max = -1;
    }
    elsif ( $quantifier eq '*' ) {
        $min = 0;
        $max = -1;
    }
    return ( $min, $max );
}

sub parseAttList {
    my ( $attList, $attributes, $include ) = @_;
    my $name;

    if ( $attList =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $name    = $1;
        $attList = $2;

        while ($attList) {

            if ( $attList =~ /^\s*($name_pattern)\s+NOTATION\s+\(\s*(.*)/s ) {
                my $attName = $1;
                my $enums, $defaultValue;
                ( $enums, $defaultValue, $attList ) = enumChoice($2);
                $$attributes{$name}{$attName} =
                  [ 'NOTATION', $enums, $defaultValue ]
                  if ($include);
            }

            elsif ( $attList =~ /^\s*($name_pattern)\s+CDATA\s+(.*)/s ) {
                my $attName = $1;
                $attList = $2;
                if ( $attList =~ /^\s*(['"])(.*)/s ) {
                    my $defaultValue;
                    ( $defaultValue, $attList ) = getString( $2, $1 );
                    $$attributes{$name}{$attName} =
                      [ 'CDATA', 'DEFAULT', $defaultValue ]
                      if ($include);
                }

                elsif ( $attList =~ /^\s*#FIXED\s*(['"])(.*)/s ) {
                    my $fixedValue;
                    ( $fixedValue, $attList ) = getString( $2, $1 );
                    $$attributes{$name}{$attName} =
                      [ 'CDATA', 'FIXED', $fixedValue ]
                      if ($include);
                }

                elsif ( $attList =~ /^s*#REQUIRED\s*(.*)/s ) {
                    $attList = $1;
                    $$attributes{$name}{$attName} = [ 'CDATA', 'REQUIRED' ]
                      if ($include);
                }

                elsif ( $attList =~ /^s*#IMPLIED\s*(.*)/s ) {
                    $attList = $1;
                    $$attributes{$name}{$attName} = [ 'CDATA', 'IMPLIED' ]
                      if ($include);
                }

                elsif ( $attList =~ /^\s*(.*)/s ) {
                    $attList = $1;
                    $$attributes{$name}{$attName} = [ 'CDATA', 'IMPLIED' ]
                      if ($include);
                }
            }

            elsif ( $attList =~ /^\s*($name_pattern)\s+($ATT_TYPES)\s+(.*)/s ) {
                my $attName = $1;
                my $attType = $2;
                $attList = $3;

                if ( $attList =~ /^\s*#REQUIRED\s*(.*)/s ) {
                    $attList = $1;
                    $$attributes{$name}{$attName} = [ $attType, 'REQUIRED' ]
                      if ($include);
                }

                elsif ( $attList =~ /^\s*#IMPLIED\s*(.*)/s ) {
                    $attList = $1;
                    $$attributes{$name}{$attName} = [ $attType, 'IMPLIED' ]
                      if ($include);
                }
            }

            elsif ( $attList =~ /^\s*($name_pattern)\s*\(\s*(.*)/s ) {
                my $attName = $1;
                my $enums, $defaultValue;
                ( $enums, $defaultValue, $attList ) =
                  enumChoice( $2, $include );
                $$attributes{$name}{$attName} =
                  [ 'ENUMERATED', $enums, $defaultValue ]
                  if ($include);
            }

            elsif ( $attList =~ /^\s*>(.*)/s ) {
                $attList = $1;
                return $attList;
            }

            else {
                die("line incorrect '$attList'\n");
            }
        }

    }
}

sub enumChoice {
    my ( $str, $include ) = @_;
    my @enums, $defaultValue;

    while ( $str =~ /^\s*($name_pattern)\s*\|(.*)/s ) {
        push( @enums, $1 ) if ($include);
        $str = $2;
    }

    if ( $str =~ /^\s*($name_pattern)\s*\)(.*)/s ) {
        push( @enums, $1 ) if ($include);
        $str = $2;
    }
    else {
        die("Not an Enumerated String '$1'\n");
    }

    if ( $str =~ /^\s*(["'])(.*)/s ) {
        ( $defaultValue, $str ) = getString( $2, $1 );
    }
    elsif ( $str =~ /^\s*#(IMPLIED|REQUIRED)\s*(.*)/s ) {
        ( $defaultValue, $str ) = ( $1, $2 );
    }
    else {
        die("No Default Value ['$defaultValue'] ['$str']\n");
    }

    return ( \@enums, $defaultValue, $str );
}

# <!NOTATION gif  SYSTEM "image/gif">
sub parseNotation {
    my ( $notationStr, $notations, $include ) = @_;
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
                  }
                  if ($include);
            }
            else {
                $$notations{$name} = { PUBLIC => $public } if ($include);
            }
        }

        elsif ( $notationStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $system, $notationStr ) = getString( $2, $1 );
            $$notations{$name} = { SYSTEM => $system } if ($include);
        }

        if ( $notationStr =~ /^\s*>(.*)/s ) {
            $notationStr = $1;
            return $notationStr;
        }

        else {
            die "not a notation $1\n";
        }

    }

    else {
        die "Not an element $notationStr\n";
    }
}

# <!ENTITY da "&#xD;&#xA;">
# <!ENTITY turing_getting_off_bus
#          SYSTEM "http://www.turing.org.uk/turing/pi1/bus.jpg"
#          NDATA jpeg>
sub parseEntity {
    my ( $entityStr, $entities ) = @_;
    my $entityName, $entityValue;

    if ( $entityStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $entityName = $1;
        $entityStr  = $2;

        if ( $entityStr =~ /^\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName} = $entityValue;
        }

        elsif ( $entityStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName}{'SYSTEM'} = $entityValue;

            if ( $entityStr =~ /^\s*NDATA\s*($name_pattern)\s*(.*)/s ) {
                $entityValue                     = $1;
                $entityStr                       = $2;
                $$entities{$entityName}{'NDATA'} = $entityValue;
            }
        }

        else {
            die("no entity $entityName, $entityStr\n");
        }

        if ( $entityStr =~ /^\s*>(.*)/s ) {
            $entityStr = $1;
            return $entityStr;
        }
    }
    else {
        die "not an entity $1\n";
    }
}

# <!ENTITY % residential_content "address, footage, rooms, bedrooms, baths, available_date">
# <!ENTITY % names SYSTEM "names.dtd">
sub parsePEntity {
    my ( $entityStr, $entities ) = @_;
    my $entityName, $entityValue;

    if ( $entityStr =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $entityName = $1;
        $entityStr  = $2;

        if ( $entityStr =~ /^\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName} = $entityValue;
        }

        elsif ( $entityStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName}{'SYSTEM'} = $entityValue;
        }

        else {
            die("no entity $entityName, $entityStr\n");
        }

        if ( $entityStr =~ /^\s*>(.*)/s ) {
            $entityStr = $1;
            return ( $entities, $entityStr );
        }
    }
    else {
        die "not an entity $1\n";
    }
}
