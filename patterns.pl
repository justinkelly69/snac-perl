#!/home/jk/opt/perl/bin/perl

use Data::Dumper;
use JSON::MaybeXS qw(encode_json decode_json);
use String::Util  qw(trim);

require "./text.pl";

my $Char =
    '\N{U+0009}|\N{U+000A}|\N{U+000D}|'
  . '[\N{U+0020}-\N{U+D7FF}]|[\N{U+E000}-\N{U+FFFD}]|'
  . '[\N{U+10000}-\N{U+10FFFF}]';

my $S = '(\N{U+0009}|\N{U+000A}|\N{U+000D}|\N{U+0020})+';

my $NameStartChar =
    '([:A-Za-z_]|'
  . '[\N{U+00C0}-\N{U+00D6}]|[\N{U+00D8}-\N{U+00F6}]|'
  . '[\N{U+00F8}-\N{U+02FF}]|[\N{U+0370}-\N{U+037D}]|'
  . '[\N{U+037F}-\N{U+1FFF}]|[\N{U+200C}-\N{U+200D}]|'
  . '[\N{U+2070}-\N{U+218F}]|[\N{U+2C00}-\N{U+2FEF}]|'
  . '[\N{U+3001}-\N{U+D7FF}]|[\N{U+F900}-\N{U+FDCF}]|'
  . '[\N{U+FDF0}-\N{U+FFFD}]|[\N{U+10000}-\N{U+EFFFF}])';

my $NameChar =
    "($NameStartChar|[-.0-9\N{U+00B7}]|"
  . '[\N{U+0300}-\N{U+036F}]|[\N{U+203F}-\N{U+2040}])';

my $CharRef     = '(&#[0-9]+;|&#x[0-9a-fA-F]+;)';    # &#20; &#x3E;
my $Name        = "${NameStartChar}${NameChar}*";    # name123
my $Names       = "${Name}(\s+${Name})*";            # john fred x3434 y77
my $Nmtoken     = "${NameChar}+";                    # 12peter15
my $Nmtokens    = "${Nmtoken}(\s+${Nmtoken})*";      # 12peter15 hello 99
my $Reference   = "${EntityRef}|${CharRef}";         # &comma; %comma;
my $EntityRef   = "&${Name};";                       # &comma;
my $PEReference = "%${Name};";                       # %comma;

my $EntityValue =    # 'hello' | '%comma;' | '&comma;'
  "([^%&\"]|$PEReference|$Reference)*|'([^%&']|$PEReference|$Reference)*'"
  ;                  #  hello  |  %comma;  |  &comma;
my $AttValue = "\"([^<&\"]|$Reference)*\"|'([^<&']|$Reference)*'"
  ;                  #  hello  | '%comma'  | "&comma;"
my $SystemLiteral = "(\"[^\"]*\")|('[^']*')";
my $PubidChar     = "\N{U+20}|\N{U+D}|\N{U+A}|[-a-zA-Z0-9'()+,./:=?;!*#@$_%]";
my $PubidLiteral  = "\"$PubidChar*\"|'($PubidChar - ')* '";
my $CharData      = "[^<&]* - ([^<&]* ']]>' [^<&]*)";
my $Comment       = "<!--(($Char - '-')|('-' ($Char - '-')))*-->";
my $PI            = "<\?$PITarget ($S ($Char* - ($Char* ?> $Char*)))?\?>";
my $PITarget      = "$Name - (('X' | 'x') ('M' | 'm') ('L' | 'l'))";

my $CDSect  = "$CDStart $CData $CDEnd";
my $CDStart = '<![CDATA[';
my $CData   = "(Char* - (Char* ']]>' Char*))";
my $CDEnd   = ']]>';

my $document    = "$prolog $element $Misc*";
my $prolog      = "$XMLDecl? $Misc* ($doctypedecl $Misc*)?";
my $XMLDecl     = "<?xml $VersionInfo $EncodingDecl? $SDDecl? $S? ?>";
my $VersionInfo = "$S 'version' $Eq ('$VersionNum'|\"$VersionNum\")";
my $Eq          = "	$S? '=' $S?";
my $VersionNum  = '1.[0-9]+';
my $Misc        = "$Comment | $PI | $S";

my $doctypedecl =
  "<!DOCTYPE $S $Name ($S $ExternalID)? $S?('[' $intSubset ']' $S?)? >";

my $DeclSep   = "$PEReference|$S";
my $intSubset = "($markupdecl|$DeclSep)*";
my $markupdecl =
  "$elementdecl|$AttlistDecl|$EntityDecl|$NotationDecl|$PI|$Comment";

my $extSubset     = "$TextDecl? $extSubsetDecl";
my $extSubsetDecl = "($markupdecl|$conditionalSect|$DeclSep)*";

my $SDDecl    = "${S}standalone${Eq}(('(yes|no)')|(\"(yes|no)\"))";
my $element   = "${EmptyElemTag}|${STag}${content}${ETag}";
my $STag      = "<$Name($S$Attribute)*$S?>";
my $Attribute = "$Name$Eq$AttValue";
my $ETag      = "'</' $Name $S? '>'";
my $content =
  "$CharData? (($element | $Reference | $CDSect | $PI | $Comment) $CharData?)*";
my $EmptyElemTag       = "'<' $Name ($S $Attribute)* $S? '/>'";
my $elementdecl        = "'<!ELEMENT' $S $Name $S $contentspec $S? '>'";
my $contentspec        = "'EMPTY' | 'ANY' | $Mixed | $children";
my $children           = "($choice | $seq) ('?' | '*' | '+')?";
my $cp                 = "($Name | $choice | $seq) ('?' | '*' | '+')?";
my $choice             = "'(' $S? $cp ( $S? '|' $S? $cp )+ $S? ')'";
my $seq                = "'(' $S? $cp ( $S? ',' $S? $cp )* $S? ')'";
my $Mixed              = "($S?#PCDATA($S?|$S?$Name)*$S?)*|($S?#PCDATA$S?)";
my $AttlistDecl        = "'<!ATTLIST' $S $Name $AttDef* $S? '>'";
my $AttDef             = "$S $Name $S $AttType $S $DefaultDecl";
my $AttType            = "$StringType|$TokenizedType|$EnumeratedType";
my $StringType         = 'CDATA';
my $TokenizedType      = '[ID|IDREF|IDREFS|ENTITY|ENTITIES|NMTOKEN|NMTOKENS]';
my $EnumeratedType     = "$NotationType|$Enumeration";
my $NotationType       = "NOTATION$S($S?$Name($S?|$S?$Name)*$S?)";
my $Enumeration        = "($S?$Nmtoken($S?|$S?$Nmtoken)*$S?)";
my $DefaultDecl        = "#REQUIRED|#IMPLIED|((#FIXED$S)?$AttValue)";
my $conditionalSect    = "$includeSect|$ignoreSect";
my $includeSect        = "<![$S?INCLUDE$S?[$extSubsetDecl]]>";
my $ignoreSect         = "<![$S?IGNORE$S?[$ignoreSectContents*]]>";
my $ignoreSectContents = "$Ignore(<![$ignoreSectContents]]>$Ignore)*";
my $Ignore             = "$Char* - ($Char* (<![|]]>)$Char*)";
my $EntityDecl         = "$GEDecl|$PEDecl";
my $GEDecl             = "<!ENTITY${S}${Name}${S}${EntityDef}${S}?>";
my $PEDecl             = "<!ENTITY${S}%${S}${Name}${S}${PEDef} ${S}?>";
my $EntityDef          = "${EntityValue}|(${ExternalID} ${NDataDecl}?)";
my $PEDef              = "${EntityValue}|${ExternalID}";
my $ExternalID =
    "SYSTEM${S}${SystemLiteral}|"
  . "PUBLIC${S}${PubidLiteral}${S}${SystemLiteral}";
my $NDataDecl    = "${S}NDATA${S}${Name}";
my $TextDecl     = "'<?xml' $VersionInfo? $EncodingDecl $S? '?>'";
my $extParsedEnt = "$TextDecl? $content";
my $EncodingDecl = "${S}encoding${Eq}(\"${EncName}\"|'${EncName}')";
my $EncName      = "[A-Za-z]([A-Za-z0-9._]|'-')*";
my $NotationDecl = "<!NOTATION${S}${Name}${S}(${ExternalID}|${PublicID})${S}?>";
my $PublicID     = "PUBLIC${S}${PubidLiteral}";

##################################
my $entityChildren = '[^>]+';

##################################

my $Letter = "$BaseChar |$Ideographic";

my $BaseChar =
    '\N{U+0386}|\N{U+038C}|\N{U+03DA}|\N{U+03DC}|\N{U+03DE}|\N{U+03E0}|'
  . '\N{U+0559}|\N{U+06D5}|\N{U+093D}|\N{U+09B2}|\N{U+0A5E}|\N{U+0A8D}|'
  . '\N{U+0ABD}|\N{U+0AE0}|\N{U+0B3D}|\N{U+0B9C}|\N{U+0CDE}|\N{U+0E30}|'
  . '\N{U+0E84}|\N{U+0E8A}|\N{U+0E8D}|\N{U+0EA5}|\N{U+0EA7}|\N{U+0EB0}|'
  . '\N{U+0EBD}|\N{U+1100}|\N{U+1109}|\N{U+113C}|\N{U+113E}|\N{U+1140}|'
  . '\N{U+114C}|\N{U+114E}|\N{U+1150}|\N{U+1159}|\N{U+1163}|\N{U+1165}|'
  . '\N{U+1167}|\N{U+1169}|\N{U+1175}|\N{U+119E}|\N{U+11A8}|\N{U+11AB}|'
  . '\N{U+11BA}|\N{U+11EB}|\N{U+11F0}|\N{U+11F9}|\N{U+1F59}|\N{U+1F5B}|'
  . '\N{U+1F5D}|\N{U+1FBE}|\N{U+2126}|\N{U+212E}|'
  . '[\N{U+0041}-\N{U+005A}]|[\N{U+0061}-\N{U+007A}]|[\N{U+00C0}-\N{U+00D6}]|'
  . '[\N{U+00D8}-\N{U+00F6}]|[\N{U+00F8}-\N{U+00FF}]|[\N{U+0100}-\N{U+0131}]|'
  . '[\N{U+0134}-\N{U+013E}]|[\N{U+0141}-\N{U+0148}]|[\N{U+014A}-\N{U+017E}]|'
  . '[\N{U+0180}-\N{U+01C3}]|[\N{U+01CD}-\N{U+01F0}]|[\N{U+01F4}-\N{U+01F5}]|'
  . '[\N{U+01FA}-\N{U+0217}]|[\N{U+0250}-\N{U+02A8}]|[\N{U+02BB}-\N{U+02C1}]|'
  . '[\N{U+0388}-\N{U+038A}]|[\N{U+038E}-\N{U+03A1}]|[\N{U+03A3}-\N{U+03CE}]|'
  . '[\N{U+03D0}-\N{U+03D6}]|[\N{U+03E2}-\N{U+03F3}]|[\N{U+0401}-\N{U+040C}]|'
  . '[\N{U+040E}-\N{U+044F}]|[\N{U+0451}-\N{U+045C}]|[\N{U+045E}-\N{U+0481}]|'
  . '[\N{U+0490}-\N{U+04C4}]|[\N{U+04C7}-\N{U+04C8}]|[\N{U+04CB}-\N{U+04CC}]|'
  . '[\N{U+04D0}-\N{U+04EB}]|[\N{U+04EE}-\N{U+04F5}]|[\N{U+04F8}-\N{U+04F9}]|'
  . '[\N{U+0531}-\N{U+0556}]|[\N{U+0561}-\N{U+0586}]|[\N{U+05D0}-\N{U+05EA}]|'
  . '[\N{U+05F0}-\N{U+05F2}]|[\N{U+0621}-\N{U+063A}]|[\N{U+0641}-\N{U+064A}]|'
  . '[\N{U+0671}-\N{U+06B7}]|[\N{U+06BA}-\N{U+06BE}]|[\N{U+06C0}-\N{U+06CE}]|'
  . '[\N{U+06D0}-\N{U+06D3}]|[\N{U+06E5}-\N{U+06E6}]|[\N{U+0905}-\N{U+0939}]|'
  . '[\N{U+0958}-\N{U+0961}]|[\N{U+0985}-\N{U+098C}]|[\N{U+098F}-\N{U+0990}]|'
  . '[\N{U+0993}-\N{U+09A8}]|[\N{U+09AA}-\N{U+09B0}]|[\N{U+09B6}-\N{U+09B9}]|'
  . '[\N{U+09DC}-\N{U+09DD}]|[\N{U+09DF}-\N{U+09E1}]|[\N{U+09F0}-\N{U+09F1}]|'
  . '[\N{U+0A05}-\N{U+0A0A}]|[\N{U+0A0F}-\N{U+0A10}]|[\N{U+0A13}-\N{U+0A28}]|'
  . '[\N{U+0A2A}-\N{U+0A30}]|[\N{U+0A32}-\N{U+0A33}]|[\N{U+0A35}-\N{U+0A36}]|'
  . '[\N{U+0A38}-\N{U+0A39}]|[\N{U+0A59}-\N{U+0A5C}]|[\N{U+0A72}-\N{U+0A74}]|'
  . '[\N{U+0A85}-\N{U+0A8B}]|[\N{U+0A8F}-\N{U+0A91}]|[\N{U+0A93}-\N{U+0AA8}]|'
  . '[\N{U+0AAA}-\N{U+0AB0}]|[\N{U+0AB2}-\N{U+0AB3}]|[\N{U+0AB5}-\N{U+0AB9}]|'
  . '[\N{U+0B05}-\N{U+0B0C}]|[\N{U+0B0F}-\N{U+0B10}]|[\N{U+0B13}-\N{U+0B28}]|'
  . '[\N{U+0B2A}-\N{U+0B30}]|[\N{U+0B32}-\N{U+0B33}]|[\N{U+0B36}-\N{U+0B39}]|'
  . '[\N{U+0B5C}-\N{U+0B5D}]|[\N{U+0B5F}-\N{U+0B61}]|[\N{U+0B85}-\N{U+0B8A}]|'
  . '[\N{U+0B8E}-\N{U+0B90}]|[\N{U+0B92}-\N{U+0B95}]|[\N{U+0B99}-\N{U+0B9A}]|'
  . '[\N{U+0B9E}-\N{U+0B9F}]|[\N{U+0BA3}-\N{U+0BA4}]|[\N{U+0BA8}-\N{U+0BAA}]|'
  . '[\N{U+0BAE}-\N{U+0BB5}]|[\N{U+0BB7}-\N{U+0BB9}]|[\N{U+0C05}-\N{U+0C0C}]|'
  . '[\N{U+0C0E}-\N{U+0C10}]|[\N{U+0C12}-\N{U+0C28}]|[\N{U+0C2A}-\N{U+0C33}]|'
  . '[\N{U+0C35}-\N{U+0C39}]|[\N{U+0C60}-\N{U+0C61}]|[\N{U+0C85}-\N{U+0C8C}]|'
  . '[\N{U+0C8E}-\N{U+0C90}]|[\N{U+0C92}-\N{U+0CA8}]|[\N{U+0CAA}-\N{U+0CB3}]|'
  . '[\N{U+0CB5}-\N{U+0CB9}]|[\N{U+0CE0}-\N{U+0CE1}]|[\N{U+0D05}-\N{U+0D0C}]|'
  . '[\N{U+0D0E}-\N{U+0D10}]|[\N{U+0D12}-\N{U+0D28}]|[\N{U+0D2A}-\N{U+0D39}]|'
  . '[\N{U+0D60}-\N{U+0D61}]|[\N{U+0E01}-\N{U+0E2E}]|[\N{U+0E32}-\N{U+0E33}]|'
  . '[\N{U+0E40}-\N{U+0E45}]|[\N{U+0E81}-\N{U+0E82}]|[\N{U+0E87}-\N{U+0E88}]|'
  . '[\N{U+0E94}-\N{U+0E97}]|[\N{U+0E99}-\N{U+0E9F}]|[\N{U+0EA1}-\N{U+0EA3}]|'
  . '[\N{U+0EAA}-\N{U+0EAB}]|[\N{U+0EAD}-\N{U+0EAE}]|[\N{U+0EB2}-\N{U+0EB3}]|'
  . '[\N{U+0EC0}-\N{U+0EC4}]|[\N{U+0F40}-\N{U+0F47}]|[\N{U+0F49}-\N{U+0F69}]|'
  . '[\N{U+10A0}-\N{U+10C5}]|[\N{U+10D0}-\N{U+10F6}]|[\N{U+1102}-\N{U+1103}]|'
  . '[\N{U+1105}-\N{U+1107}]|[\N{U+110B}-\N{U+110C}]|[\N{U+110E}-\N{U+1112}]|'
  . '[\N{U+1154}-\N{U+1155}]|[\N{U+115F}-\N{U+1161}]|[\N{U+116D}-\N{U+116E}]|'
  . '[\N{U+1172}-\N{U+1173}]|[\N{U+11AE}-\N{U+11AF}]|[\N{U+11B7}-\N{U+11B8}]|'
  . '[\N{U+11BC}-\N{U+11C2}]|[\N{U+1E00}-\N{U+1E9B}]|[\N{U+1EA0}-\N{U+1EF9}]|'
  . '[\N{U+1F00}-\N{U+1F15}]|[\N{U+1F18}-\N{U+1F1D}]|[\N{U+1F20}-\N{U+1F45}]|'
  . '[\N{U+1F48}-\N{U+1F4D}]|[\N{U+1F50}-\N{U+1F57}]|[\N{U+1F5F}-\N{U+1F7D}]|'
  . '[\N{U+1F80}-\N{U+1FB4}]|[\N{U+1FB6}-\N{U+1FBC}]|[\N{U+1FC2}-\N{U+1FC4}]|'
  . '[\N{U+1FC6}-\N{U+1FCC}]|[\N{U+1FD0}-\N{U+1FD3}]|[\N{U+1FD6}-\N{U+1FDB}]|'
  . '[\N{U+1FE0}-\N{U+1FEC}]|[\N{U+1FF2}-\N{U+1FF4}]|[\N{U+1FF6}-\N{U+1FFC}]|'
  . '[\N{U+212A}-\N{U+212B}]|[\N{U+2180}-\N{U+2182}]|[\N{U+3041}-\N{U+3094}]|'
  . '[\N{U+30A1}-\N{U+30FA}]|[\N{U+3105}-\N{U+312C}]|[\N{U+AC00}-\N{U+D7A3}]';

my $Ideographic = '\N{U+3007}|[\N{U+4E00}-\N{U+9FA5}]|[\N{U+3021}-\N{U+3029}]';

my $CombiningChar =
    '\N{U+05BF}|\N{U+05C4}|\N{U+0670}|\N{U+093C}|\N{U+094D}|\N{U+09BC}|'
  . '\N{U+09BE}|\N{U+09BF}|\N{U+09D7}|\N{U+0A02}|\N{U+0A3C}|\N{U+0A3E}|'
  . '\N{U+0A3F}|\N{U+0ABC}|\N{U+0B3C}|\N{U+0BD7}|\N{U+0D57}|\N{U+0E31}|'
  . '\N{U+0EB1}|\N{U+0F35}|\N{U+0F37}|\N{U+0F39}|\N{U+0F3E}|\N{U+0F3F}|'
  . '\N{U+0F97}|\N{U+0FB9}|\N{U+20E1}|\N{U+3099}|\N{U+309A}|'
  . '[\N{U+0300}-\N{U+0345}]|[\N{U+0360}-\N{U+0361}]|[\N{U+0483}-\N{U+0486}]|'
  . '[\N{U+0591}-\N{U+05A1}]|[\N{U+05A3}-\N{U+05B9}]|[\N{U+05BB}-\N{U+05BD}]|'
  . '[\N{U+05C1}-\N{U+05C2}]|[\N{U+064B}-\N{U+0652}]|[\N{U+06D6}-\N{U+06DC}]|'
  . '[\N{U+06DD}-\N{U+06DF}]|[\N{U+06E0}-\N{U+06E4}]|[\N{U+06E7}-\N{U+06E8}]|'
  . '[\N{U+06EA}-\N{U+06ED}]|[\N{U+0901}-\N{U+0903}]|[\N{U+093E}-\N{U+094C}]|'
  . '[\N{U+0951}-\N{U+0954}]|[\N{U+0962}-\N{U+0963}]|[\N{U+0981}-\N{U+0983}]|'
  . '[\N{U+09C0}-\N{U+09C4}]|[\N{U+09C7}-\N{U+09C8}]|[\N{U+09CB}-\N{U+09CD}]|'
  . '[\N{U+09E2}-\N{U+09E3}]|[\N{U+0A40}-\N{U+0A42}]|[\N{U+0A47}-\N{U+0A48}]|'
  . '[\N{U+0A4B}-\N{U+0A4D}]|[\N{U+0A70}-\N{U+0A71}]|[\N{U+0A81}-\N{U+0A83}]|'
  . '[\N{U+0ABE}-\N{U+0AC5}]|[\N{U+0AC7}-\N{U+0AC9}]|[\N{U+0ACB}-\N{U+0ACD}]|'
  . '[\N{U+0B01}-\N{U+0B03}]|[\N{U+0B3E}-\N{U+0B43}]|[\N{U+0B47}-\N{U+0B48}]|'
  . '[\N{U+0B4B}-\N{U+0B4D}]|[\N{U+0B56}-\N{U+0B57}]|[\N{U+0B82}-\N{U+0B83}]|'
  . '[\N{U+0BBE}-\N{U+0BC2}]|[\N{U+0BC6}-\N{U+0BC8}]|[\N{U+0BCA}-\N{U+0BCD}]|'
  . '[\N{U+0C01}-\N{U+0C03}]|[\N{U+0C3E}-\N{U+0C44}]|[\N{U+0C46}-\N{U+0C48}]|'
  . '[\N{U+0C4A}-\N{U+0C4D}]|[\N{U+0C55}-\N{U+0C56}]|[\N{U+0C82}-\N{U+0C83}]|'
  . '[\N{U+0CBE}-\N{U+0CC4}]|[\N{U+0CC6}-\N{U+0CC8}]|[\N{U+0CCA}-\N{U+0CCD}]|'
  . '[\N{U+0CD5}-\N{U+0CD6}]|[\N{U+0D02}-\N{U+0D03}]|[\N{U+0D3E}-\N{U+0D43}]|'
  . '[\N{U+0D46}-\N{U+0D48}]|[\N{U+0D4A}-\N{U+0D4D}]|[\N{U+0E34}-\N{U+0E3A}]|'
  . '[\N{U+0E47}-\N{U+0E4E}]|[\N{U+0EB4}-\N{U+0EB9}]|[\N{U+0EBB}-\N{U+0EBC}]|'
  . '[\N{U+0EC8}-\N{U+0ECD}]|[\N{U+0F18}-\N{U+0F19}]|[\N{U+0F71}-\N{U+0F84}]|'
  . '[\N{U+0F86}-\N{U+0F8B}]|[\N{U+0F90}-\N{U+0F95}]|[\N{U+0F99}-\N{U+0FAD}]|'
  . '[\N{U+0FB1}-\N{U+0FB7}]|[\N{U+20D0}-\N{U+20DC}]|[\N{U+302A}-\N{U+302F}]';

my $Digit =
    '[\N{U+0030}-\N{U+0039}]|[\N{U+0660}-\N{U+0669}]|[\N{U+06F0}-\N{U+06F9}]|'
  . '[\N{U+0966}-\N{U+096F}]|[\N{U+09E6}-\N{U+09EF}]|[\N{U+0A66}-\N{U+0A6F}]|'
  . '[\N{U+0AE6}-\N{U+0AEF}]|[\N{U+0B66}-\N{U+0B6F}]|[\N{U+0BE7}-\N{U+0BEF}]|'
  . '[\N{U+0C66}-\N{U+0C6F}]|[\N{U+0CE6}-\N{U+0CEF}]|[\N{U+0D66}-\N{U+0D6F}]|'
  . '[\N{U+0E50}-\N{U+0E59}]|[\N{U+0ED0}-\N{U+0ED9}]|[\N{U+0F20}-\N{U+0F29}]';

my $Extender =
    '\N{U+00B7}|\N{U+02D0}|\N{U+02D1}|\N{U+0387}|\N{U+0640}|\N{U+0E46}|'
  . '\N{U+0EC6}|\N{U+3005}|'
  . '[\N{U+3031}-\N{U+3035}]|[\N{U+309D}-\N{U+309E}]|[\N{U+30FC}-\N{U+30FE}]';
