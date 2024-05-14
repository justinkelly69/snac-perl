
sub parsePEntities {
    my($dtd_text, $entities) = @_;

    foreach $key (keys(%$entities)) {
        my @segments = split(/%$key;/, $dtd_text);
        $dtd_text = join($entities->{$key}, @segments);
    }

    return $dtd_text;
}


# $p_entities = hash ref of parsed entities
# $out_string = DTD with <!ENTITIES removed
sub getEntities {
    my ($dtd_string) = @_;
    my %p_entities;
    my $out_string;
    my $p_entities = \%p_entities;

    while ( $dtd_string =~ /<!ENTITY\s+%\s+(.*)/s ) { # Get each entity
        $out_string .= $`;  # concat it to the previous $out_string
        chomp($out_string);
        ( $p_entities, $dtd_string ) = parsePEntity( $1, $p_entities );
    }
    $out_string .= $dtd_string;

    return ( $p_entities, $out_string );
}

# <!ENTITY % residential_content "address, footage, rooms, bedrooms, baths, available_date">
# <!ENTITY % names SYSTEM "names.dtd">
sub parsePEntity {
    my ( $entity_string, $entities ) = @_;
    my $entity_name, $entity_value;

    if ( $entity_string =~ /^\s*($name_pattern)\s+(.*)/s ) {
        $entity_name = $1;
        $entity_string  = $2;

        if ( $entity_string =~ /^\s*(["'])(.*)/s ) {
            ( $entity_value, $entity_string ) = getString( $2, $1 );
            $$entities{$entity_name} = normalizeString($entity_value);
        }

        elsif ( $entity_string =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entity_value, $entity_string ) = getString( $2, $1 );
            $$entities{$entity_name}{'SYSTEM'} = normalizeString($entity_value);
        }

        else {
            die("no entity $entity_name, $entity_string\n");
        }

        if ( $entity_string =~ /^\s*>(.*)/s ) {
            $entity_string = $1;
            return ( $entities, $entity_string );
        }
    }
    else {
        die "not an entity $1\n";
    }
}

# Checks whether an array value has %name;s
# and places it in %no_entities_array if it does
sub evaluateEntities {
    my($entity_array, $no_entities_array) = (@_);
    my %entities_array;

    my $json = JSON->new->allow_nonref;

    while(($key, $value) = each(%$entity_array)) {

        $value = processEntityValue($no_entities_array, $value);

        if($value !~ /%[.A-Za-z0-9_-]+;/) {
            $no_entities_array->{$key} = $value;
        }
        else {
            $entities_array{$key} = $value;
        }

    }

    my $old_size = keys(%entities_array);
    my $new_size = 0;
    my $x_key = "*";
    my $x_value = "*";
    my $tries = 0;

    while(keys(%entities_array)){

        if($new_size >= $old_size - 1){
            $tries++;
        }
        else {
            $tries = 0;
        }

        die  "$tries Invalid key $x_key -> $x_value\n" if ($tries == 3);

        while(($key, $value) = each(%entities_array)) {
            $x_key = $key;
            $x_value = $value;
            $value = processEntityValue($no_entities_array, $value);

            if($value !~ /%[.A-Za-z0-9_-]+;/) {
                $no_entities_array->{$key} = $value;
                delete($entities_array{$key});
            }
            else {
                $entities_array{$key} = $value;
            }

        }
        $new_size = keys(%entities_array);
    }

    print("final no_entities_array: " . $json->pretty->encode($no_entities_array) . "\n");
    print("final entities_array: "   . $json->pretty->encode(\%entities_array)   . "\n");

    return ($no_entities_array, $entities_array);
}

sub processEntityValue {
    my($no_entities_array, $entities_value) = @_;
    my @names = split(/%/, $entities_value);
    my $out = $names[0];

    my $json = JSON->new->allow_nonref;

    for(my $i = 1; $i < @names; $i++) {
        if ($names[$i] =~ /^([.A-Za-z0-9_-]+);(.*)$/){

            if($no_entities_array->{$1}) {
                $out .= $no_entities_array->{$1} . $2;
            }
            else {
                $out .= "%$1;$2";
            }
        }
        else {
            $out .= "%$1;$2";
        }
    }
    return $out;
}

1;