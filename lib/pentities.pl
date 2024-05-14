# $pEntities = hash ref of parsed entities
# $outString = DTD with <!ENTITIES removed
sub getEntities {
    my ($dtdString) = @_;
    my %pEntities;
    my $outString;
    my $pEntities = \%pEntities;

    while ( $dtdString =~ /<!ENTITY\s+%\s+(.*)/s ) { # Get each entity
        $outString .= $`;  # concat it to the previous $outString
        chomp($outString);
        ( $pEntities, $dtdString ) = parsePEntity( $1, $pEntities );
    }
    $outString .= $dtdString;

    return ( $pEntities, $outString );
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
            $$entities{$entityName} = normalizeString($entityValue);
        }

        elsif ( $entityStr =~ /^\s*SYSTEM\s*(["'])(.*)/s ) {
            ( $entityValue, $entityStr ) = getString( $2, $1 );
            $$entities{$entityName}{'SYSTEM'} = normalizeString($entityValue);
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

# Checks whether an array value has %name;s
# and places it in %noEntitiesArray if it does
sub evaluateEntities {
    my($entityArray, $noEntitiesArray) = (@_);
    my %entitiesArray;

    my $json = JSON->new->allow_nonref;

    while(($key, $value) = each(%$entityArray)) {

        $value = processEntityValue($noEntitiesArray, $value);

        if($value !~ /%[.A-Za-z0-9_-]+;/) {
            $noEntitiesArray->{$key} = $value;
            #delete($entitiesArray{$key});
        }
        else {
            $entitiesArray{$key} = $value;
        }

    }

 
    my $oldSize = keys(%entitiesArray);
    my $newSize = 0;

    while(keys(%entitiesArray)){
        print("oldSize: $oldSize, newSize: $newSize\n");

        if($newSize >= $oldSize - 1){
            die ("Invalid key $!\n");
        }

        while(($key, $value) = each(%entitiesArray)) {
 
            $value = processEntityValue($noEntitiesArray, $value);

            if($value !~ /%[.A-Za-z0-9_-]+;/) {
                $noEntitiesArray->{$key} = $value;
                delete($entitiesArray{$key});
            }
            else {
                $entitiesArray{$key} = $value;
            }

        }
        $newSize = keys(%entitiesArray);
    }

    print("final noEntitiesArray: " . $json->pretty->encode($noEntitiesArray) . "\n");
    print("final entitiesArray: "   . $json->pretty->encode(\%entitiesArray)   . "\n");

    return ($noEntitiesArray, $entitiesArray);
}

sub processEntityValue {
    my($noEntitiesArray, $entitiesValue) = @_;
    my @names = split(/%/, $entitiesValue);
    my $out = $names[0];

    my $json = JSON->new->allow_nonref;

    for(my $i = 1; $i < @names; $i++) {
        if ($names[$i] =~ /^([.A-Za-z0-9_-]+);(.*)$/){

            if($noEntitiesArray->{$1}) {
                $out .= $noEntitiesArray->{$1} . $2;
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