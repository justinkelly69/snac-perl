
sub getEntities {
    my ($dtdString) = @_;
    my %pEntities;
    my $outString;
    my $pEntities = \%pEntities;

    while ( $dtdString =~ /<!ENTITY\s+%\s+(.*)/s ) {
        $outString .= $`;
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

sub evaluateEntities0 {
    my($entityArray) = (@_);
    return sortEntities($entityArray);
}

sub evaluateEntities {
    my($entityArray) = (@_);
    my ($noEntitiesArray, $entitiesArray) = sortEntities($entityArray, $noEntitiesArray);

    #print ("keylength " . keys(%$entitiesArray) . "\n");
    #print ("keylength " . keys(%$noEntitiesArray) . "\n");

    for(keys(%$entitiesArray)) {
        print("entitiesArray key: $_\n");
        $entitiesArray->{$_} = insertEntityValues($entitiesArray->{$_}, $noEntitiesArray);
    }
    ($noEntitiesArray, $entitiesArray) = sortEntities($entitiesArray, $noEntitiesArray);

    return (\%noEntitiesArray, \%entitiesArray);
}

# Split a strring with %name;s and replace them with values
sub insertEntityValues {
    my ($entitiesString, $noEntitiesArray) = @_;

    print("entitiesString: $entitiesString\n");

    my @entityValues = split( '%', $entitiesString);
    my $out = "";

    my $json = JSON->new->allow_nonref;
    print("entityValues: "    . $json->pretty->encode($entityValues)    . "\n");
    print("noEntitiesArray: " . $json->pretty->encode($noEntitiesArray) . "\n");

    for $entityValue (@entityValues) {
        #print("(entityValue: [[$entityValue]])\n");

        $entityValue =~ /^([.A-Za-z0-9_-]+);(.*)/;
        print("1 (($1)) (($2)) \"" . $noEntitiesArray->{$1} ."\"");
        if($noEntitiesArray->{$1}){
            print " true\n";
            $out .= $noEntitiesArray->{$1} . $2;
        }
        else {
            print " false\n";
            $out .= "%$1;$2";
        }
    }

    print "out: $out\n";

    return $out;
}

# Checks whether an array value has %name;s
# and places it in %noEntitiesArray if it does
sub sortEntities {
    my($entityArray, $noEntitiesArray) = (@_);

    my %entitiesArray;
    my %noEntitiesArray = %$noEntitiesArray;
    my %entityArray = %$entityArray;

    my $json = JSON->new->allow_nonref;

    #print("entityArray: " . $json->pretty->encode($entityArray) . "\n");
    #print ("keylength entityArray before: " . keys(%entityArray) . "\n");

    #print("noEntitiesArray: " . $json->pretty->encode($noEntitiesArray) . "\n");
    #print ("keylength noEntitiesArray before: " . keys(%noEntitiesArray) . "\n");

    while(($key, $value) = each(%entityArray)) {
        #print("sortEntries key:$key ");
        if($value !~ /%[.A-Za-z0-9_-]+;/) {
            #print("true $value\n");
            $noEntitiesArray{$key} = $value;
        }
        else {
            #print("false $value\n");
            $entitiesArray{$key} = $value;
        }
    }

    #print ("keylength entitiesArray after: " . keys(%entitiesArray) . "\n");
    #print ("keylength noEntitiesArray after: " . keys(%noEntitiesArray) . "\n");

    return (\%noEntitiesArray, \%entitiesArray);
}

1;