<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs" version="2.0">

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- ======================================================================= -->
  <!-- GLOBAL VARIABLES                                                        -->
  <!-- ======================================================================= -->

  <xsl:variable name="marcDatafieldDesc">
    <!--<xsl:copy-of select="document('marcDesc.xml')//*:datafield"/>-->
    <marcDesc xmlns:sch="http://purl.oclc.org/dsdl/schematron"
      xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

      <!-- Linking subfield constraints -->
      <!-- @tag="-1000" guarantees that these patterns will appear first -->
      <pattern xmlns="http://purl.oclc.org/dsdl/schematron" tag="-1000">
        <title>Subfield 6 (value pattern)</title>
        <rule context="*:subfield[@code = '6']">
          <assert test="matches(., '^\d{3}-\d{2}(/(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})(/r)?)?$')"
            >Subfield $6 must match regex:
            '^\d{3}-\d{2}(/(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})(/r)?)?$'</assert>
        </rule>
      </pattern>
      <pattern xmlns="http://purl.oclc.org/dsdl/schematron" tag="-1000">
        <title>Subfield 8 (value pattern)</title>
        <rule context="*:subfield[@code = '8']">
          <!-- Value -->
          <assert test="matches(., '^[0-9]+(\.[0-9]+(\\[apux])?)?$')">Subfield 8 must match regex:
            '^[0-9]+(\.[0-9]+(\\[apux])?)?$'</assert>
        </rule>
      </pattern>
      <pattern xmlns="http://purl.oclc.org/dsdl/schematron" tag="-1000">
        <title>Subfield 8 (matching linking number)</title>
        <rule context="*:subfield[@code = '8'][matches(., '^[0-9]')]">
          <let name="linkingNumber" value="replace(., '^([0-9]+).*$', '$1')"/>
          <assert
            test="count(preceding::*:subfield[@code = '8'][matches(substring(., 1, string-length($linkingNumber)), $linkingNumber)]) + count(following::*:subfield[@code = '8'][matches(substring(., 1, string-length($linkingNumber)), $linkingNumber)]) &gt; 0"
            role="warning">There are usually at least two subfield 8s with the same linkingNumber
            (<value-of select="$linkingNumber"/>)</assert>
        </rule>
      </pattern>
      <pattern xmlns="http://purl.oclc.org/dsdl/schematron" tag="-1000">
        <title>Subfield 8 (unique sequence number)</title>
        <rule context="*:subfield[@code = '8'][matches(., '^[0-9]+\.[0-9]+')]">
          <let name="linkingSequence" value="replace(., '^([0-9]+\.[0-9]+).*$', '$1')"/>
          <assert
            test="
              count(preceding::*:subfield[@code = '8'][matches(substring(., 1, string-length($linkingSequence)), $linkingSequence)]) +
              count(following::*:subfield[@code = '8'][matches(substring(., 1, string-length($linkingSequence)), $linkingSequence)]) = 0"
            >Linking sequence (<value-of select="$linkingSequence"/>) is not unique.</assert>
        </rule>
      </pattern>

      <record tag="-1" desc="Record">
        <report test="count(*:datafield[matches(@tag, '100|110|111|130')]) &gt; 1">Only one 1XX tag
          is allowed per record.</report>
        <report test="count(*:datafield[matches(@tag, '100|110|111|130')]) &lt; 1" role="warning">At
          least one 1XX tag is recommended.</report>
        <assert test="count(*:datafield[matches(@tag, '260|264')]) &gt; 0" role="warning">Datafield
          260 or 264 is recommended.</assert>
        <pattern>
          <title>Co-constraint between 008/33 and 6xx datafield(s)</title>
          <rule
            context="*:record[matches(substring(*:leader, 7, 1), 'a|m') and matches(substring(*:leader, 8, 1), 'a|c|d|m') and *:datafield[matches(@tag, '^6')]]">
            <assert
              test="*:controlfield[@tag = '008'][matches(substring(text(), 34, 1), '0|\||\s')]"
              role="warning">Typically, subject headings are applied only to non-fiction
              items.</assert>
          </rule>
        </pattern>
      </record>

      <!-- leader, controlfield, and datafield constraints -->
      <!-- @occurs M = mandatory, R = recommended -->
      <!-- Leader -->
      <leader repeat="NR" occurs="M" tag="000" desc="Leader">
    <length>24</length>
    <code position="1" length="5" values="'[0-9]{5}'" desc="Record length"/>
    <code position="6" length="1" values="'[acdnp]'" desc="Record status code"/>
    <code position="7" length="1" values="'[acdefgijkmoprt]'" desc="Bibl type code"/>
    <code position="8" length="1" values="'[a-dims]'" desc="Bibl level code"/>
    <code position="9" length="1" values="'[\p{Zs}a]'" desc="Type of control"/>
    <code position="10" length="1" values="'[\p{Zs}a]'" desc="Character encoding scheme"/>
    <code position="11" length="1" values="'2'" desc="Indicator count"/>
    <code position="12" length="1" values="'2'" desc="Subfield code count"/>
    <code position="13" length="4" values="'[0-9]{4}'" desc="Base address of data"/>
    <code position="18" length="1" values="'[\p{Zs}1234578uzIKLMEJ]'" desc="Encoding level code"/>
    <code position="19" length="1" values="'[\p{Zs}acinu]'" desc="Descriptive standard code"/>
    <code position="20" length="1" values="'[\p{Zs}abc]'" desc="Multipart resource record level"/>
    <code position="21" length="4" values="'4500'" desc="Length of field"/>
    <pattern>
      <title>Co-constraint with 008/06</title>
      <rule context="*:leader[matches(substring(text(), 8, 1), 'm')]">
        <assert test="not(../*:controlfield[@tag = '008'][matches(substring(text(), 7, 1), '[cdiku]')])">When
        Leader 07 matches 'm', 008/06 (Type of date/publication status flag) cannot match
        '[cdiku]'</assert>
      </rule>
    </pattern>
  </leader>
      <!-- Controlfields -->
      <controlfield tag="001" repeat="NR" occurs="M" desc="Control number"/>
      <controlfield tag="002" repeat="NR" desc="Locally defined (unofficial)"/>
      <controlfield tag="003" repeat="NR" occurs="M" desc="Control number identifier"/>
      <controlfield tag="005" repeat="NR" desc="Date and time of latest transaction">
    <assert test="matches(., '^\d{14}\.\d$')">Date and time of latest transaction must match 'YYYYMMDDHHMMSS.F'</assert>
  </controlfield>
      <controlfield tag="006" repeat="R" desc="Additional material characteristics">
    <length>18</length>
    <code position="1" length="1" values="'[ac-gijkmoprst]'" desc="Form of material"/>
  </controlfield>
      <controlfield tag="006" materialType="BK" desc="Book">
    <code position="2" length="4" desc="Illustrations" values="'\p{Zs}{4}|[a-mop]{4}|\|{4}|[a-mop]{3}\p{Zs}|[a-mop]{2}\p{Zs}{2}|[a-mop]\p{Zs}{3}'"/>
    <code position="6" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="7" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="8" length="4" desc="Nature of contents" values="'\|{4}|\p{Zs}{4}|[a-gij-wyz256]{4}|[a-gij-wyz256]{3}(\p{Zs}|\|)|[a-gij-wyz256]{2}(\p{Zs}{2}|\|{2})|[a-gij-wyz256](\p{Zs}{3}|\|{3})'"/>
    <code position="12" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="13" length="1" desc="Conference publication" values="'[01\|\p{Zs}]'"/>
    <code position="14" length="1" desc="Festschrift" values="'[01\|\p{Zs}]'"/>
    <code position="15" length="1" desc="Index" values="'[01\|\p{Zs}]'"/>
    <code position="16" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="17" length="1" desc="Literary form" values="'[01defhijmpsu\|\p{Zs}]'"/>
    <code position="18" length="1" desc="Biography" values="'[\p{Zs}a-d\|]'"/>
  </controlfield>
      <controlfield tag="006" materialType="CF" desc="Computer file">
    <code position="2" length="4" desc="Undefined" values="'[\p{Zs}\|]{4}'"/>
    <code position="6" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="7" length="1" desc="Form of item" values="'[\p{Zs}oq\|]'"/>
    <code position="8" length="2" desc="Undefined" values="'[\p{Zs}\|]{2}'"/>
    <code position="10" length="1" desc="Type of file" values="'[a-jmuz\|\p{Zs}]'"/>
    <code position="11" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="12" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="13" length="6" desc="Undefined" values="'[\p{Zs}\|]{6}'"/>
  </controlfield>
      <controlfield tag="006" materialType="MP" desc="Map">
    <code position="2" length="4" desc="Relief" values="'\p{Zs}{4}|\|{4}|[a-gijkmz]{4}|[a-gijkmz]{3}\p{Zs}|[a-gijkmz]{2}\p{Zs}{2}|[a-gijkmz]\p{Zs}{3}'"/>
    <code position="6" length="2" desc="Projection" values="'(\p{Zs}\p{Zs}|aa|ab|ac|ad|ae|af|ag|am|an|ap|au|az|ba|bb|bc|bd|be|bf|bg|bh|bi|bj|bk|bl|bo|br|bs|bu|bz|ca|cb|cc|ce|cp|cu|cz|da|db|dc|dd|de|df|dg|dh|dl|zz|\|\|)'"/>
    <code position="8" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="9" length="1" desc="Type of cartographic material" values="'[a-guz\|\p{Zs}]'"/>
    <code position="10" length="2" desc="Undefined" values="'[\p{Zs}\|]{2}'"/>
    <code position="12" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="13" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="14" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="15" length="1" desc="Index" values="'[01\|\p{Zs}]'"/>
    <code position="16" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="17" length="2" desc="Special format characteristics" values="'\p{Zs}{2}|\|{2}|[ejklnoprz]{2}|[ejklnoprz]{1}\p{Zs}'"/>
  </controlfield>
      <controlfield tag="006" materialType="MU" desc="Music">
    <code position="2" length="2" desc="Form of composition" values="'(an|bd|bg|bl|bt|ca|cb|cc|cg|ch|cl|cn|co|cp|cr|cs|ct|cy|cz|df|dv|fg|fl|fm|ft|gm|hy|jz|mc|md|mi|mo|mp|mr|ms|mu|mz|nc|nn|op|or|ov|pg|pm|po|pp|pr|ps|pt|pv|rc|rd|rg|ri|rp|rq|sd|sg|sn|sp|st|su|sy|tc|tl|ts|uu|vi|vr|wz|za|zz|\|\||\p{Zs}\p{Zs})'"/>
    <code position="4" length="1" desc="Format of music" values="'[a-eg-npuz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Music parts" values="'[\p{Zs}defnu\|]'"/>
    <code position="6" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="7" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="8" length="6" desc="Accompanying matter" values="'[a-ikrsz]{6}|[\p{Zs}\|]{6}|[a-ikrsz]{5}[\p{Zs}\|]|[a-ikrsz]{4}[\p{Zs}\|]{2}|[a-ikrsz]{3}[\p{Zs}\|]{3}|[a-ikrsz]{2}[\p{Zs}\|]{4}|[a-ikrsz][\p{Zs}\|]{5}'"/>
    <code position="14" length="2" desc="Literary text for sound recordings" values="'\p{Zs}{2}|[a-prstz]{2}|\|{2}|[a-prstz]\p{Zs}'"/>
    <code position="16" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="17" length="1" desc="Transposition and arrangement" values="'[\p{Zs}abcnu\|]'"/>
    <code position="18" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
  </controlfield>
      <controlfield tag="006" materialType="CR" desc="Continuing resource">
    <code position="2" length="1" desc="Frequency" values="'[\p{Zs}a-kmqstuwz\|]'"/>
    <code position="3" length="1" desc="Regularity" values="'[nrux\|\p{Zs}]'"/>
    <code position="4" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="5" length="1" desc="Type of continuing resource" values="'[\p{Zs}dlmnpw\|]'"/>
    <code position="6" length="1" desc="Form of original item" values="'[\p{Zs}a-foqs\|]'"/>
    <code position="7" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="8" length="1" desc="Nature of entire work" values="'[\p{Zs}a-ik-wyz56\|]'"/>
    <code position="9" length="3" desc="Nature of contents" values="'\p{Zs}{3}|\|{3}|[a-ik-wyz56]{3}|[a-ik-wyz56]{2}\p{Zs}|[a-ik-wyz56]\p{Zs}{2}'"/>
    <code position="12" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="13" length="1" desc="Conference publication" values="'[01\|\p{Zs}]'"/>
    <code position="14" length="3" desc="Undefined" values="'[\p{Zs}\|]{3}'"/>
    <code position="17" length="1" desc="Original alphabet or script of title" values="'[\p{Zs}a-luz\|]'"/>
    <code position="18" length="1" desc="Entry convention" values="'[012\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="006" materialType="VM" desc="Visual material">
    <code position="2" length="3" desc="Running time" values="'(nnn|\|\|\||00[0-9]|0[1-9][0-9]|[1-9][0-9][0-9])'"/>
    <code position="5" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="6" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="7" length="5" desc="Undefined" values="'[\p{Zs}\|]{5}'"/>
    <code position="12" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="13" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="14" length="3" desc="Undefined" values="'[\p{Zs}\|]{3}'"/>
    <code position="17" length="1" desc="Type of visual material" values="'[a-dfgik-tvwz\|\p{Zs}]'"/>
    <code position="18" length="1" desc="Technique" values="'[aclnuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="006" materialType="MX" desc="Mixed material">
    <code position="2" length="5" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="7" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="8" length="11" desc="Undefined" values="'[\p{Zs}\|]'"/>
  </controlfield>
      <controlfield tag="007" repeat="R" desc="Physical description fixed field">
    <code position="1" length="1" values="'[acdfghkmoqrstvz]'" desc="Category of material code"/>
  </controlfield>
      <controlfield tag="007" materialCode="a" desc="Map">
    <length>8</length>
    <code position="2" length="1" desc="SMD code" values="'[dgjkqrsuyz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Color code" values="'[ac\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Physical medium code" values="'[a-gijlnp-z\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Type of reproduction code" values="'[fnuz\|\p{Zs}]'"/>
    <code position="7" length="1" desc="Production/reproduction details code" values="'[a-duz\|\p{Zs}]'"/>
    <code position="8" length="1" desc="Positive/negative aspect code" values="'[abmn\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="c" desc="Electronic resource">
    <length>14</length>
    <code position="2" length="1" desc="SMD code" values="'[a-fhjkmoruz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="4" length="1" desc="Color code" values="'[abcgmnuz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Dimensions code" values="'[aegijnouvz\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Sound code" values="'[\p{Zs}au\|]'"/>
    <code position="7" length="3" desc="Image bit depth code" values="'\d{3}|mmm|nnn|---|\|\|\||[\p{Zs}]{3}'"/>
    <code position="10" length="1" desc="File formats code" values="'[amu\|\p{Zs}]'"/>
    <code position="11" length="1" desc="Quality assurance target code" values="'[anpu\|\p{Zs}]'"/>
    <code position="12" length="1" desc="Antecedent/source code" values="'[a-dmnu\|\p{Zs}]'"/>
    <code position="13" length="1" desc="Level of compression code" values="'[abdmu\|\p{Zs}]'"/>
    <code position="14" length="1" desc="Reformatting quality code" values="'[anpru\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="d" desc="Globe">
   <length>6</length>
   <code position="2" length="1" desc="SMD code" values="'[a-ceuz\|\p{Zs}]'"/>
   <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
   <code position="4" length="1" desc="Color code" values="'[ac\|\p{Zs}]'"/>
   <code position="5" length="1" desc="Physical medium code" values="'[a-gijlnpu-z\|\p{Zs}]'"/>
   <code position="6" length="1" desc="Type of reproduction code" values="'[fnuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="f" desc="Tactile material">
    <length>10</length>
    <code position="2" length="1" desc="SMD code" values="'[a-duz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="2" desc="Class of braille writing code" values="'[a-emnuz][a-emnuz\p{Zs}]|\|{2}'"/>
    <code position="6" length="1" desc="Level of contraction code" values="'[abmnuz\|\p{Zs}]'"/>
    <code position="7" length="3" desc="Braille music format code" values="'[a-lnuz][a-lnuz\p{Zs}]{2}|\|{3}'"/>
    <code position="10" length="1" desc="Special physical characteristics code" values="'[abnuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="g" desc="Projected graphic">
    <length>9</length>
    <code position="2" length="1" desc="SMD code" values="'[cdfos-uz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Color code" values="'[a-chmnuz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Base of emulsion code" values="'[dejkmou\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Sound on medium or separate code" values="'[abu\p{Zs}\|]'"/>
    <code position="7" length="1" desc="Medium for sound code" values="'[a-iuz\p{Zs}\|]'"/>
    <code position="8" length="1" desc="Dimensions code" values="'[a-gjks-z\|\p{Zs}]'"/>
    <code position="9" length="1" desc="Secondary support material code" values="'[c-ehjkmuz\p{Zs}\|]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="h" desc="Microform">
    <length>13</length>
    <code position="2" length="1" desc="SMD code" values="'[a-hjuz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Positive/negative aspect code" values="'[abmu\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Dimensions code" values="'[adfghlmopuz\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Reduction ratio range code" values="'[a-euv\|\p{Zs}]'"/>
    <code position="7" length="3" desc="Reduction ratio code" values="'\p{Zs}{3}|\d{3}|\d{2}-|\d--|-{3}'"/>
    <!--<code position="7" length="3" desc="Reduction ratio code" values="'[0-9]{3}|[0-9]{2}\-|[0-9]\-\\\\-|[\-]{3}'"/>-->
    <code position="10" length="1" desc="Color code" values="'[bcmuz\|\p{Zs}]'"/>
    <code position="11" length="1" desc="Emulsion on film code" values="'[abcmnuz\|\p{Zs}]'"/>
    <code position="12" length="1" desc="Generation code" values="'[abcmu\|\p{Zs}]'"/>
    <code position="13" length="1" desc="Base of film code" values="'[acdimnprtuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="k" desc="Nonprojected graphic">
    <length>6</length>
    <code position="2" length="1" desc="SMD code" values="'[ac-ln-suvz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Color code" values="'[abchm\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Primary support material code" values="'[a-il-wz\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Secondary support material code" values="'[\p{Zs}a-il-wz\|]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="m" desc="Motion picture">
    <length>23</length>
    <code position="2" length="1" desc="SMD code" values="'[cforuz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Color code" values="'[bchmnuz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Motion picture presentation format code" values="'[a-fuz\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Sound on medium or separate code" values="'[\p{Zs}abu\|]'"/>
    <code position="7" length="1" desc="Medium for sound code" values="'[\p{Zs}a-iuz]'"/>
    <code position="8" length="1" desc="Dimensions code" values="'[a-guz\|\p{Zs}]'"/>
    <code position="9" length="1" desc="Configuration of playback channels code" values="'[kmnqsuz\|\p{Zs}]'"/>
    <code position="10" length="1" desc="Production elements code" values="'[a-gnz\|\p{Zs}]'"/>
    <code position="11" length="1" desc="Positive/negative aspect code" values="'[abnuz\|\p{Zs}]'"/>
    <code position="12" length="1" desc="Generation code" values="'[deoruz\|\p{Zs}]'"/>
    <code position="13" length="1" desc="Base of film code" values="'[acdimnprtuz\|\p{Zs}]'"/>
    <code position="14" length="1" desc="Refined categories of color code" values="'[a-np-vz\|\p{Zs}]'"/>
    <code position="15" length="1" desc="Kind of color stock or print code" values="'[a-dnuz\|\p{Zs}]'"/>
    <code position="16" length="1" desc="Deterioration stage code" values="'[a-hklm\|\p{Zs}]'"/>
    <code position="17" length="1" desc="Completeness code" values="'[cinu\|\p{Zs}]'"/>
    <code position="18" length="6" desc="Film inspection date" values="'([0-9]{4}([0-9]{2}|[\-]{2}))|[\-]{6}'"/>
  </controlfield>
      <controlfield tag="007" materialCode="o" desc="Kit">
    <length>2</length>
    <code position="2" length="1" desc="SMD code" values="'[u\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="q" desc="Notated music">
    <length>2</length>
    <code position="2" length="1" desc="SMD code" values="'[u\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="r" desc="Remote-sensing image">
    <length>11</length>
    <code position="2" length="1" desc="SMD code" values="'[u\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Altitude of sensor code" values="'[abcnuz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Attitude of sensor code" values="'[abcnu\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Cloud cover code" values="'[0-9nu\|\p{Zs}]'"/>
    <code position="7" length="1" desc="Platform construction type code" values="'[a-inuz\|\p{Zs}]'"/>
    <code position="8" length="1" desc="Platform use category code" values="'[abcmnuz\|\p{Zs}]'"/>
    <code position="9" length="1" desc="Sensor type code" values="'[abuz\|\p{Zs}]'"/>
    <code position="10" length="2" desc="Data type code" values="'(aa|da|db|dc|dd|de|df|dv|dz|ga|gb|gc|gd|ge|gf|gg|gu|gz|ja|jb|jc|jv|ma|mb|mm|nn|pa|pb|pc|pd|pe|pz|ra|rb|rc|rd|sa|ta|uu|zz|\|\|)'"/>
  </controlfield>
      <controlfield tag="007" materialCode="s" desc="Sound recording">
    <length>14</length>
    <code position="2" length="1" desc="SMD code" values="'[degiqstuwz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Speed code" values="'[a-fhiklmopruz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Configuration of playback channels code" values="'[mqsuz\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Groove width or pitch code" values="'[mnsuz\|\p{Zs}]'"/>
    <code position="7" length="1" desc="Dimensions code" values="'[a-gjosnuz\|\p{Zs}]'"/>
    <code position="8" length="1" desc="Tape width code" values="'[l-puz\|\p{Zs}]'"/>
    <code position="9" length="1" desc="Tape configuration code" values="'[a-fnuz\|\p{Zs}]'"/>
    <code position="10" length="1" desc="Kind of disc, cylinder or tape" values="'[abdimnrstuz\|]'"/>
    <code position="11" length="1" desc="Kind of material" values="'[abcgilmnprswuz\|]'"/>
    <code position="12" length="1" desc="Kind of cutting" values="'[hlnu\|]'"/>
    <code position="13" length="1" desc="Special playback code" values="'[a-hnuz\|\p{Zs}]'"/>
    <code position="14" length="1" desc="Capture and storage code" values="'[abdeuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="t" desc="Text">
    <length>2</length>
    <code position="2" length="1" desc="SMD code" values="'[a-duz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="v" desc="Videorecording">
    <length>9</length>
    <code position="2" length="1" desc="SMD code" values="'[acdfnruz\|\p{Zs}]'"/>
    <code position="3" length="1" desc="Undefined" values="'[\p{Zs}\\\|]'"/>
    <code position="4" length="1" desc="Color code" values="'[bcmnuz\|\p{Zs}]'"/>
    <code position="5" length="1" desc="Videorecording format code" values="'[a-km-qsuvz\|\p{Zs}]'"/>
    <code position="6" length="1" desc="Sound on medium code" values="'[\p{Zs}abu\|]'"/>
    <code position="7" length="1" desc="Medium of sound code" values="'[\p{Zs}a-iuz\|]'"/>
    <code position="8" length="1" desc="Dimensions code" values="'[amo-ruz\|\p{Zs}]'"/>
    <code position="9" length="1" desc="Configuration of playback channels code" values="'[kmnqsuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="007" materialCode="z" desc="Unspecified">
    <length>2</length>
    <code position="2" length="1" desc="SMD code" values="'[muz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="008" repeat="NR" occurs="M" desc="Fixed-length data elements">
    <length>40</length>
    <pattern>
      <title>Co-constraint with leader</title>
      <rule context="*:controlfield[@tag = '008'][matches(substring(text(), 7, 1), '[cdiku]')]">
        <assert test="preceding-sibling::*:leader[not(matches(substring(text(), 8, 1), 'm'))]">When 008/06 (Type of
        date/publication status flag) matches '[cdiku]', Leader 07 (Bibliographic level) cannot
        match 'm'</assert>
      </rule>
    </pattern>
    <pattern>
      <title>Co-constraint with 6xx</title>
      <rule context="*:controlfield[@tag = '008'][matches(substring(text(), 34, 1), '0')]">
        <assert test="following-sibling::*:datafield[matches(@tag, '^6')]" role="warning">Non-fiction material typically has at least one subject heading</assert>
      </rule>
    </pattern>
    <code position="1" length="6" values="'[0-9]{6}'" desc="Date entered"/>
    <code position="7" length="1" values="'[bcdeikmnpqrstu\|]'" desc="Type of date/publication status flag"/>
    <code position="8" length="4" values="'[0-9]{4}|[\p{Zs}u\\\|]{4}|[0-9\p{Zs}u\\\|]{4}'" desc="Date 1"/>
    <code position="12" length="4" values="'[0-9]{4}|[\p{Zs}u\\\|]{4}|[0-9\p{Zs}u\\\|]{4}'" desc="Date 2"/>
    <code position="16" length="3" values="$marcCountryCodes" desc="Country code"/>
    <code position="36" length="3" values="$marcLangCodes" desc="Language code"/>
    <!-- OCLC-specific, ignored for now -->
    <!--<code position="39" length="1" values="'[\p{Zs}\\\|dorsx]'" desc="Modified record flag"/>-->
    <code position="40" length="1" values="'[\p{Zs}\\\|cdu]'" desc="Cataloging source flag"/>
  </controlfield>

      <controlfield tag="008" materialType="BK" desc="Book">
    <code position="19" length="4" desc="Illustrations" values="'\p{Zs}{4}|\|{4}|[a-mop]{4}|[a-mop]{3}\p{Zs}|[a-mop]{2}\p{Zs}{2}|[a-mop]\p{Zs}{3}'"/>
    <code position="23" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="24" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="25" length="4" desc="Nature of contents" values="'[a-gij-wyz256]{4}|\|{4}|\p{Zs}{4}|[a-gij-wyz256]{3}(\p{Zs}|\|)|[a-gij-wyz256]{2}(\p{Zs}{2}|\|{2})|[a-gij-wyz256](\p{Zs}{3}|\|{3})'"/>
    <code position="29" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="30" length="1" desc="Conference publication" values="'[01\|\p{Zs}]'"/>
    <code position="31" length="1" desc="Festschrift" values="'[01\|\p{Zs}]'"/>
    <code position="32" length="1" desc="Index" values="'[01\|\p{Zs}]'"/>
    <code position="33" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="34" length="1" desc="Literary form" values="'[01defhijmpsu\|\p{Zs}]'"/>
    <code position="35" length="1" desc="Biography" values="'[\p{Zs}a-d\|]'"/>
  </controlfield>
      <controlfield tag="008" materialType="CF" desc="Computer file">
    <code position="19" length="4" desc="Undefined" values="'[\p{Zs}\|]{4}'"/>
    <code position="23" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="24" length="1" desc="Form of item" values="'[\p{Zs}oq\|]'"/>
    <code position="25" length="2" desc="Undefined" values="'[\p{Zs}\|]{2}'"/>
    <code position="27" length="1" desc="Type of file" values="'[a-jmuz\|\p{Zs}]'"/>
    <code position="28" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="29" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="30" length="6" desc="Undefined" values="'[\p{Zs}\|]{6}'"/>
  </controlfield>
      <controlfield tag="008" materialType="MP" desc="Map">
    <code position="19" length="4" desc="Relief" values="'[a-gijkmz]{4}|\|{4}|\p{Zs}{4}|[a-gijkmz]{3}\p{Zs}|[a-gijkmz]{2}\p{Zs}{2}|[a-gijkmz]\p{Zs}{3}'"/>
    <code position="23" length="2" desc="Projection" values="'(\p{Zs}\p{Zs}|aa|ab|ac|ad|ae|af|ag|am|an|ap|au|az|ba|bb|bc|bd|be|bf|bg|bh|bi|bj|bk|bl|bo|br|bs|bu|bz|ca|cb|cc|ce|cp|cu|cz|da|db|dc|dd|de|df|dg|dh|dl|zz|\|\|)'"/>
    <code position="25" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="26" length="1" desc="Type of cartographic material" values="'[a-guz\|\p{Zs}]'"/>
    <code position="27" length="2" desc="Undefined" values="'[\p{Zs}\|]{2}'"/>
    <code position="29" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="30" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="31" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="32" length="1" desc="Index" values="'[01\|\p{Zs}]'"/>
    <code position="33" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="34" length="2" desc="Special format characteristics" values="'[ejklnoprz]{2}|\|{2}|\p{Zs}{2}|[ejklnoprz]{1}\p{Zs}'"/>
  </controlfield>
      <controlfield tag="008" materialType="MU" desc="Music">
    <code position="19" length="2" desc="Form of composition" values="'(an|bd|bg|bl|bt|ca|cb|cc|cg|ch|cl|cn|co|cp|cr|cs|ct|cy|cz|df|dv|fg|fl|fm|ft|gm|hy|jz|mc|md|mi|mo|mp|mr|ms|mu|mz|nc|nn|op|or|ov|pg|pm|po|pp|pr|ps|pt|pv|rc|rd|rg|ri|rp|rq|sd|sg|sn|sp|st|su|sy|tc|tl|ts|uu|vi|vr|wz|za|zz|\|\||\p{Zs}\p{Zs})'"/>
    <code position="21" length="1" desc="Format of music" values="'[a-eg-npuz\|\p{Zs}]'"/>
    <code position="22" length="1" desc="Music parts" values="'[\p{Zs}defnu\|]'"/>
    <code position="23" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="24" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="25" length="6" desc="Accompanying matter" values="'[a-ikrsz]{6}|[\p{Zs}\|]{6}|[a-ikrsz]{5}[\p{Zs}\|]|[a-ikrsz]{4}[\p{Zs}\|]{2}|[a-ikrsz]{3}[\p{Zs}\|]{3}|[a-ikrsz]{2}[\p{Zs}\|]{4}|[a-ikrsz][\p{Zs}\|]{5}'"/>
    <code position="31" length="2" desc="Literary text for sound recordings" values="'[a-prstz]{2}|\|{2}|\p{Zs}{2}|[a-prstz]\p{Zs}'"/>
    <code position="33" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="34" length="1" desc="Transposition and arrangement" values="'[\p{Zs}abcnu\|]'"/>
    <code position="35" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
  </controlfield>
      <controlfield tag="008" materialType="CR" desc="Continuing resource">
    <code position="19" length="1" desc="Frequency" values="'[\p{Zs}a-kmqstuwz\|]'"/>
    <code position="20" length="1" desc="Regularity" values="'[nrux\|\p{Zs}]'"/>
    <code position="21" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="22" length="1" desc="Type of continuing resource" values="'[\p{Zs}dlmnpw\|]'"/>
    <code position="23" length="1" desc="Form of original item" values="'[\p{Zs}a-foqs\|]'"/>
    <code position="24" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="25" length="1" desc="Nature of entire work" values="'[\p{Zs}a-ik-wyz56\|]'"/>
    <code position="26" length="3" desc="Nature of contents" values="'[a-ik-wyz56]{3}|\|{3}|\p{Zs}{3}|[a-ik-wyz56]{2}\p{Zs}|[a-ik-wyz56]\p{Zs}{2}'"/>
    <code position="29" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="30" length="1" desc="Conference publication" values="'[01\|\p{Zs}]'"/>
    <code position="31" length="3" desc="Undefined" values="'[\p{Zs}\|]{3}'"/>
    <code position="34" length="1" desc="Original alphabet or script of title" values="'[\p{Zs}a-luz\|]'"/>
    <code position="35" length="1" desc="Entry convention" values="'[012\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="008" materialType="VM" desc="Visual material">
    <code position="19" length="3" desc="Running time" values="'(nnn|\|\|\||00[0-9]|0[1-9][0-9]|[1-9][0-9][0-9])'"/>
    <code position="22" length="1" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="23" length="1" desc="Target audience" values="'[\p{Zs}a-gj\|]'"/>
    <code position="24" length="5" desc="Undefined" values="'[\p{Zs}\|]{5}'"/>
    <code position="29" length="1" desc="Government publication" values="'[\p{Zs}acfilmosuz\|]'"/>
    <code position="30" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="31" length="3" desc="Undefined" values="'[\p{Zs}\|]{3}'"/>
    <code position="34" length="1" desc="Type of visual material" values="'[a-dfgik-tvwz\|\p{Zs}]'"/>
    <code position="35" length="1" desc="Technique" values="'[aclnuz\|\p{Zs}]'"/>
  </controlfield>
      <controlfield tag="008" materialType="MX" desc="Mixed material">
    <code position="19" length="5" desc="Undefined" values="'[\p{Zs}\|]'"/>
    <code position="24" length="1" desc="Form of item" values="'[\p{Zs}a-dfoqrs\|]'"/>
    <code position="25" length="11" desc="Undefined" values="'[\p{Zs}\|]'"/>
  </controlfield>

      <!-- Datafields -->
      <datafield tag="010" repeat="NR" desc="Library of congress control number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="LC control number"/>
        <subfield code="b" repeat="R" desc="NUCMC control number"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid LC control number"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="013" repeat="R" desc="Patent control information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Number"/>
        <subfield code="b" repeat="NR" desc="Country"/>
        <subfield code="c" repeat="NR" desc="Type of number"/>
        <subfield code="d" repeat="R" desc="Date"/>
        <subfield code="e" repeat="R" desc="Status"/>
        <subfield code="f" repeat="R" desc="Party to document"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="015" repeat="R" desc="National bibliography number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="National bibliography number"/>
        <subfield code="q" repeat="R" desc="Qualifying information"/>
        <subfield code="z" repeat="R" desc="Canceled/Invalid national bibliographic number"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="016" repeat="R" desc="National bibliographic agency control number">
        <ind1 values=" 7" desc="National bibliographic agency"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Record control number"/>
        <subfield code="z" repeat="R" desc="Canceled or invalid record control number"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="017" repeat="R" desc="Copyright or legal deposit number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="R" desc="Copyright registration number"/>
        <subfield code="b" repeat="NR" desc="Assigning agency"/>
        <subfield code="d" repeat="NR" desc="Date"/>
        <subfield code="i" repeat="NR" desc="Display Text"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid copyright or legal deposit number"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="018" repeat="NR" desc="Copyright article-fee code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Copyright article-fee code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="019" repeat="NR" desc="OCLC control number cross-reference">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="OCLC control number of merged and deleted record"/>
      </datafield>
      <datafield tag="020" repeat="R" desc="International standard book number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="International Standard Book Number"/>
        <subfield code="c" repeat="NR" desc="Terms of availability"/>
        <subfield code="q" repeat="R" desc="Qualifier"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid ISBN"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="022" repeat="R" desc="International standard serial number">
        <ind1 values=" 01" desc="Level of international interest"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="l" repeat="NR" desc="Issn-l"/>
        <subfield code="m" repeat="R" desc="Canceled ISSN-L"/>
        <subfield code="y" repeat="R" desc="Incorrect ISSN"/>
        <subfield code="z" repeat="R" desc="Canceled ISSN"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="024" repeat="R" desc="Other standard identifier">
        <ind1 values="0123478" desc="Type of standard number or code"/>
        <ind2 values=" 01" desc="Difference indicator"/>
        <subfield code="a" repeat="NR" desc="Standard number or code"/>
        <subfield code="c" repeat="NR" desc="Terms of availability"/>
        <subfield code="d" repeat="NR" desc="Additional codes following the standard number or code"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid standard number or code"/>
        <subfield code="q" repeat="R" desc="Qualifying information"/>
        <subfield code="2" repeat="NR" desc="Source of number or code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="025" repeat="R" desc="Overseas acquisition number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Overseas acquisition number"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="026" repeat="R" desc="Fingerprint identifier">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="First and second groups of characters"/>
        <subfield code="b" repeat="R" desc="Third and fourth groups of characters"/>
        <subfield code="c" repeat="NR" desc="Date"/>
        <subfield code="d" repeat="R" desc="Number of volume or part"/>
        <subfield code="e" repeat="NR" desc="Unparsed fingerprint"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="5" repeat="R" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="027" repeat="R" desc="Standard technical report number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Standard technical report number"/>
        <subfield code="q" repeat="R" desc="Qualifying information"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="028" repeat="R" desc="Publisher number">
        <ind1 values="0-6" desc="Type of publisher number"/>
        <ind2 values="0-3" desc="Note/added entry controller"/>
        <subfield code="a" repeat="NR" desc="Publisher number"/>
        <subfield code="b" repeat="NR" desc="Source"/>
        <subfield code="q" repeat="R" desc="Qualifying information"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="029" repeat="R" desc="Other system control number">
        <ind1 values="01" desc="Type of system control number"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="OCLC library identifier"/>
        <subfield code="b" repeat="NR" desc="System control number"/>
        <subfield code="c" repeat="NR" desc="OAI set name"/>
        <subfield code="t" repeat="NR" desc="Content type identifier"/>
      </datafield>
      <datafield tag="030" repeat="R" desc="Coden designation">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Coden"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid CODEN"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="031" repeat="R" desc="Musical incipits information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Number of work"/>
        <subfield code="b" repeat="NR" desc="Number of movement"/>
        <subfield code="c" repeat="NR" desc="Number of excerpt"/>
        <subfield code="d" repeat="R" desc="Caption or heading"/>
        <subfield code="e" repeat="NR" desc="Role"/>
        <subfield code="g" repeat="NR" desc="Clef"/>
        <subfield code="m" repeat="NR" desc="Voice/instrument"/>
        <subfield code="n" repeat="NR" desc="Key signature"/>
        <subfield code="o" repeat="NR" desc="Time signature"/>
        <subfield code="p" repeat="NR" desc="Musical notation"/>
        <subfield code="q" repeat="R" desc="General note"/>
        <subfield code="r" repeat="NR" desc="Key or mode"/>
        <subfield code="s" repeat="R" desc="Coded validity note"/>
        <subfield code="t" repeat="R" desc="Text incipit"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="y" repeat="R" desc="Link text"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="System code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="032" repeat="R" desc="Postal registration number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Postal registration number"/>
        <subfield code="b" repeat="NR" desc="Source (agency assigning number)"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="033" repeat="R" desc="Date/time and place of an event">
        <ind1 values=" 012" desc="Type of date in subfield $a"/>
        <ind2 values=" 012" desc="Type of event"/>
        <subfield code="a" repeat="R" desc="Formatted date/time"/>
        <subfield code="b" repeat="R" desc="Geographic classification area code"/>
        <subfield code="c" repeat="R" desc="Geographic classification subarea code"/>
        <subfield code="p" repeat="R" desc="Place of event"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="034" repeat="R" desc="Coded cartographic mathematical data">
        <ind1 values="013" desc="Type of scale"/>
        <ind2 values=" 01" desc="Type of ring"/>
        <subfield code="a" repeat="NR" desc="Category of scale"/>
        <subfield code="b" repeat="R" desc="Constant ratio linear horizontal scale"/>
        <subfield code="c" repeat="R" desc="Constant ratio linear vertical scale"/>
        <subfield code="d" repeat="NR" desc="Coordinates — westernmost longitude"/>
        <subfield code="e" repeat="NR" desc="Coordinates — easternmost longitude"/>
        <subfield code="f" repeat="NR" desc="Coordinates — northernmost latitude"/>
        <subfield code="g" repeat="NR" desc="Coordinates — southernmost latitude"/>
        <subfield code="h" repeat="R" desc="Angular scale"/>
        <subfield code="j" repeat="NR" desc="Declination — northern limit"/>
        <subfield code="k" repeat="NR" desc="Declination — southern limit"/>
        <subfield code="m" repeat="NR" desc="Right ascension — eastern limit"/>
        <subfield code="n" repeat="NR" desc="Right ascension — western limit"/>
        <subfield code="p" repeat="NR" desc="Equinox"/>
        <subfield code="r" repeat="NR" desc="Distance from earth"/>
        <subfield code="s" repeat="R" desc="G-ring latitude"/>
        <subfield code="t" repeat="R" desc="G-ring longitude"/>
        <subfield code="x" repeat="NR" desc="Beginning date"/>
        <subfield code="y" repeat="NR" desc="Ending date"/>
        <subfield code="z" repeat="NR" desc="Name of extraterrestial body"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="035" repeat="R" desc="System control number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="System control number"/>
        <!-- OCLC permits subfield b that LC does not. -->
        <!-- The OCLC symbol of the institution that assigned the number. Use subfield ǂb for each subfield ǂa and each 
      subfield ǂz. Enter subfield ǂb after the appropriate subfield. If you are following LC practice, do not use 
      subfield ǂb. (https://www.oclc.org/bibformats/en/0xx/035.html) -->
        <subfield code="b" repeat="R" desc="Institution symbol"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid control number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="036" repeat="NR" desc="Original study number for computer data files">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Original study number"/>
        <subfield code="b" repeat="NR" desc="Source (agency assigning number)"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="037" repeat="R" desc="Source of acquisition">
        <ind1 values=" 23" desc="Source of acquisition sequence"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Stock number"/>
        <subfield code="b" repeat="NR" desc="Source of stock number/acquisition"/>
        <subfield code="c" repeat="R" desc="Terms of availability"/>
        <subfield code="f" repeat="R" desc="Form of issue"/>
        <subfield code="g" repeat="R" desc="Additional format characteristics"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="R" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="038" repeat="NR" desc="Record content licensor">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Record content licensor"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="040" repeat="NR" desc="Cataloging source">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Original cataloging agency"/>
        <!-- https://www.oclc.org/bibformats/en/0xx/040.html says $b is mandatory -->
        <subfield code="b" repeat="NR" desc="Language of cataloging">
      <assert test="matches(., $marcLangCodes)">Subfield $b must match a valid language code</assert>
    </subfield>
        <subfield code="c" repeat="NR" desc="Transcribing agency"/>
        <subfield code="d" repeat="R" desc="Modifying agency"/>
        <subfield code="e" repeat="R" desc="Description conventions"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="041" repeat="R" desc="Language code">
        <ind1 values=" 01" desc="Translation indication"/>
        <ind2 values=" 7" desc="Source of code"/>
        <subfield code="a" repeat="R" desc="Language code of text/sound track or separate title">
      <assert test="matches(., $marcLangCodes)">Subfield $a must match a valid language code</assert>
    </subfield>
        <subfield code="b" repeat="R" desc="Language code of summary or abstract">
      <assert test="matches(., $marcLangCodes)">Subfield $b must match a valid language code</assert>
    </subfield>
        <subfield code="d" repeat="R" desc="Language code of sung or spoken text">
      <assert test="matches(., $marcLangCodes)">Subfield $d must match a valid language code</assert>
    </subfield>
        <subfield code="e" repeat="R" desc="Language code of librettos">
      <assert test="matches(., $marcLangCodes)">Subfield $e must match a valid language code</assert>
    </subfield>
        <subfield code="f" repeat="R" desc="Language code of table of contents">
      <assert test="matches(., $marcLangCodes)">Subfield $f must match a valid language code</assert>
    </subfield>
        <subfield code="g" repeat="R" desc="Language code of accompanying material other than librettos">
      <assert test="matches(., $marcLangCodes)">Subfield $g must match a valid language code</assert>
    </subfield>
        <subfield code="h" repeat="R" desc="Language code of original and/or intermediate translations of text">
      <assert test="matches(., $marcLangCodes)">Subfield $h must match a valid language code</assert>
    </subfield>
        <subfield code="j" repeat="R" desc="Language code of subtitles or captions">
      <assert test="matches(., $marcLangCodes)">Subfield $j must match a valid language code</assert>
    </subfield>
        <subfield code="k" repeat="R" desc="Language code of intermediate translations">
      <assert test="matches(., $marcLangCodes)">Subfield $k must match a valid language code</assert>
    </subfield>
        <subfield code="m" repeat="R" desc="Language code of original accompanying materials other than librettos">
      <assert test="matches(., $marcLangCodes)">Subfield $m must match a valid language code</assert>
    </subfield>
        <subfield code="n" repeat="R" desc="Language code of original libretto">
      <assert test="matches(., $marcLangCodes)">Subfield $n must match a valid language code</assert>
    </subfield>
        <subfield code="p" repeat="R" desc="Language code of captions">
      <assert test="matches(., $marcLangCodes)">Subfield $p must match a valid language code</assert>
    </subfield>
        <subfield code="q" repeat="R" desc="Language code of accessible audio">
      <assert test="matches(., $marcLangCodes)">Subfield $q must match a valid language code</assert>
    </subfield>
        <subfield code="r" repeat="R" desc="Language code of accessible visual language (non-textual)">
      <assert test="matches(., $marcLangCodes)">Subfield $r must match a valid language code</assert>
    </subfield>
        <subfield code="2" repeat="NR" desc="Source of code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="042" repeat="NR" desc="Authentication code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Authentication code"/>
      </datafield>
      <datafield tag="043" repeat="NR" desc="Geographic area code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Geographic area code"/>
        <subfield code="b" repeat="R" desc="Local GAC code"/>
        <subfield code="c" repeat="R" desc="ISO code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="R" desc="Source of local code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="044" repeat="NR" desc="Country of publishing/producing entity code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="MARC country code">
       <assert test="matches(., $marcCountryCodes)">Subfield $a must match a valid country code</assert>
    </subfield>
        <subfield code="b" repeat="R" desc="Local subentity code"/>
        <subfield code="c" repeat="R" desc="ISO country code"/>
        <subfield code="2" repeat="R" desc="Source of local subentity code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="045" repeat="NR" desc="Time period of content">
        <ind1 values=" 012" desc="Type of time period in subfield $b or $c"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Time period code"/>
        <subfield code="b" repeat="R" desc="Formatted 9999 B.C. through C.E. time period"/>
        <subfield code="c" repeat="R" desc="Formatted pre-9999 B.C. time period"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="046" repeat="R" desc="Special coded dates">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of date code"/>
        <subfield code="b" repeat="NR" desc="Date 1 (B.C. date)"/>
        <subfield code="c" repeat="NR" desc="Date 1 (C.E. date)"/>
        <subfield code="d" repeat="NR" desc="Date 2 (B.C. date)"/>
        <subfield code="e" repeat="NR" desc="Date 2 (C.E. date)"/>
        <subfield code="j" repeat="NR" desc="Date resource modified"/>
        <subfield code="k" repeat="NR" desc="Beginning or single date created"/>
        <subfield code="l" repeat="NR" desc="Ending date created"/>
        <subfield code="m" repeat="NR" desc="Beginning of date valid"/>
        <subfield code="n" repeat="NR" desc="End of date valid"/>
        <subfield code="o" repeat="NR" desc="Single or starting date for aggregated content"/>
        <subfield code="p" repeat="NR" desc="Ending date for aggregated content"/>
        <subfield code="2" repeat="NR" desc="Source of date"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="047" repeat="R" desc="Form of musical composition code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 7" desc="Source of code"/>
        <subfield code="a" repeat="R" desc="Form of musical composition code"/>
        <subfield code="2" repeat="NR" desc="Source of code"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="048" repeat="R" desc="Number of musical instruments or voices code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 7" desc="Source specified in subfield $2"/>
        <subfield code="a" repeat="R" desc="Performer or ensemble"/>
        <subfield code="b" repeat="R" desc="Soloist"/>
        <subfield code="2" repeat="NR" desc="Source of code"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="049" repeat="NR" desc="Local holdings">
        <ind1 values=" 012" desc="Controls printing"/>
        <ind2 values=" 01" desc="Indicates the completeness of holdings data"/>
        <subfield code="a" repeat="R" desc="Holding library" occurs="M"/>
        <subfield code="c" repeat="R" desc="Copy statement"/>
        <subfield code="d" repeat="R" desc="Definition of bibliographic subdivisions"/>
        <subfield code="l" repeat="R" desc="Local processing data"/>
        <subfield code="m" repeat="R" desc="Missing elements"/>
        <subfield code="n" repeat="NR" desc="Notes about holdings"/>
        <subfield code="o" repeat="R" desc="Local processing data"/>
        <subfield code="p" repeat="R" desc="Secondary bibliographic subdivision"/>
        <subfield code="q" repeat="R" desc="Third bibliographic subdivision"/>
        <subfield code="r" repeat="R" desc="Fourth bibliographic subdivision"/>
        <subfield code="s" repeat="R" desc="Fifth bibliographic subdivision"/>
        <subfield code="t" repeat="R" desc="Sixth bibliographic subdivision"/>
        <subfield code="u" repeat="R" desc="Seventh bibliographic subdivision"/>
        <subfield code="v" repeat="R" desc="Primary bibliographic subdivision"/>
        <subfield code="y" repeat="NR" desc="Inclusive dates of publication or coverage"/>
      </datafield>
      <datafield tag="050" repeat="R" desc="Library of congress call number">
        <ind1 values=" 01" desc="Existence in LC collection"/>
        <!-- Second indicator was defined in 1982. Prior to that change, 050 was an agency-assigned field 
      and contained only call numbers assigned by the Library of Congress. LC records created before the 
      definition of this indicator may contain a blank (#) meaning undefined in this position. -->
        <ind2 values=" 04" desc="Source of call number"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="u" repeat="R" desc="Locally defined"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="051" repeat="R" desc="Library of congress copy, issue, offprint statement">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="c" repeat="NR" desc="Copy information"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="052" repeat="R" desc="Geographic classification">
        <ind1 values=" 17" desc="Code source"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Geographic classification area code"/>
        <subfield code="b" repeat="R" desc="Geographic classification subarea code"/>
        <subfield code="d" repeat="R" desc="Populated place name"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Code source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="055" repeat="R" desc="Classification numbers assigned in canada">
        <ind1 values=" 01" desc="Existence in LAC collection"/>
        <ind2 values="0-9" desc="Type, completeness, source of class/call number"/>
        <subfield code="a" repeat="NR" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of call/class number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="060" repeat="R" desc="National library of medicine call number">
        <ind1 values=" 01" desc="Existence in NLM collection"/>
        <!-- Second indicator was defined in 1982. Prior to that change, 060 was an agency-assigned 
      field and contained only call numbers assigned by the National Library of Medicine. NLM 
      records created before the definition of this indicator may contain a blank (#) meaning 
      undefined in the second indicator position. -->
        <ind2 values=" 04" desc="Source of call number"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="061" repeat="R" desc="National library of medicine copy statement">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="c" repeat="NR" desc="Copy information"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="066" repeat="NR" desc="Character sets present">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Primary G0 character set"/>
        <subfield code="b" repeat="NR" desc="Primary G1 character set"/>
        <subfield code="c" repeat="R" desc="Alternate G0 or G1 character set"/>
      </datafield>
      <datafield tag="070" repeat="R" desc="National agricultural library call number">
        <ind1 values=" 01" desc="Existence in NAL collection"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="071" repeat="R" desc="National agricultural library copy statement">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="c" repeat="NR" desc="Copy information"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="072" repeat="R" desc="Subject category code">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 07" desc="Source specified in subfield $2"/>
        <subfield code="a" repeat="NR" desc="Subject category code"/>
        <subfield code="x" repeat="R" desc="Subject category code subdivision"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="074" repeat="R" desc="Gpo item number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="GPO item number"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid GPO item number"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="080" repeat="R" desc="Universal decimal classification number">
        <ind1 values=" 01" desc="Type of edition"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Universal Decimal Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="x" repeat="R" desc="Common auxiliary subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Edition identifier"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="082" repeat="R" desc="Dewey decimal classification number">
        <!-- Code # (No edition information recorded) was valid 1979-1987. Records created before the 
      definition of the first indicator in 1979 may contain a blank (#) meaning undefined in this 
      indicator position. -->
        <ind1 values=" 017" desc="Type of edition"/>
        <ind2 values=" 04" desc="Source of classification number"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="m" repeat="NR" desc="Standard or optional designation"/>
        <subfield code="q" repeat="NR" desc="Assigning agency"/>
        <subfield code="2" repeat="NR" desc="Edition number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="083" repeat="R" desc="Additional dewey decimal classification number">
        <ind1 values="017" desc="Type of edition"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="c" repeat="R" desc="Classification number — Ending number of span"/>
        <subfield code="m" repeat="NR" desc="Standard or optional designation"/>
        <subfield code="q" repeat="NR" desc="Assigning agency"/>
        <subfield code="y" repeat="R" desc="Table sequence number for internal subarrangement or add table"/>
        <subfield code="z" repeat="R" desc="Table identification"/>
        <subfield code="2" repeat="NR" desc="Edition number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="084" repeat="R" desc="Other classification number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Classification number"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="q" repeat="NR" desc="Assigning agency"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="085" repeat="R" desc="Synthesized classification number components">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Number where instructions are found-single number or beginning number of span"/>
        <subfield code="b" repeat="R" desc="Base number"/>
        <subfield code="c" repeat="R" desc="Classification number-ending number of span"/>
        <subfield code="f" repeat="R" desc="Facet designator"/>
        <subfield code="r" repeat="R" desc="Root number"/>
        <subfield code="s" repeat="R" desc="Digits added from classification number in schedule or external table"/>
        <subfield code="t" repeat="R" desc="Digits added from internal subarrangement or add table"/>
        <subfield code="u" repeat="R" desc="Number being analyzed"/>
        <subfield code="v" repeat="R" desc="Number in internal subarrangement or add table where instructions are found"/>
        <subfield code="w" repeat="R" desc="Table identification-Internal subarrangement or add table"/>
        <subfield code="y" repeat="R" desc="Table sequence number for internal subarrangement or add table"/>
        <subfield code="z" repeat="R" desc="Table identification"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="086" repeat="R" desc="Government document classification number">
        <ind1 values=" 01" desc="Number source"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Classification number"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid classification number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Number source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="088" repeat="R" desc="Report number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Report number"/>
        <subfield code="z" repeat="R" desc="Canceled/invalid report number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="090" repeat="R" desc="Locally assigned LC-type call number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Classification number" occurs="M"/>
        <subfield code="b" repeat="NR" desc="Local cutter number"/>
        <subfield code="e" repeat="NR" desc="Feature heading"/>
        <subfield code="f" repeat="NR" desc="Filing suffix"/>
        <subfield code="m" repeat="NR" desc="Insttitution code"/>
        <subfield code="q" repeat="NR" desc="Library"/>
      </datafield>
      <datafield tag="092" repeat="R" desc="Locally assigned dewey call number">
        <ind1 values=" 01" desc="DDC edition"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Classification number" occurs="M"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="e" repeat="NR" desc="Feature heading"/>
        <subfield code="f" repeat="NR" desc="Filing suffix"/>
        <subfield code="2" repeat="NR" desc="Edition number"/>
        <!-- $2 appears to be optional -->
        <!--<subfield code="2" repeat="NR" desc="Edition number" occurs="R"/>-->
      </datafield>
      <datafield tag="096" repeat="R" desc="Locally assigned nlm-type call number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Classification number" occurs="M"/>
        <subfield code="b" repeat="NR" desc="Item number"/>
        <subfield code="e" repeat="NR" desc="Feature heading"/>
        <subfield code="f" repeat="NR" desc="Filing suffix"/>
      </datafield>
      <datafield tag="098" repeat="R" desc="Other classification schemes">
        <ind1 values="0-9" desc="OCLC defined"/>
        <ind2 values="0-9" desc="OCLC defined"/>
        <subfield code="a" repeat="R" desc="Classification number" occurs="M"/>
        <subfield code="e" repeat="NR" desc="Feature heading"/>
        <subfield code="f" repeat="NR" desc="Filing suffix"/>
      </datafield>
      <datafield tag="099" repeat="R" desc="Local free-text call number">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 019" desc="Source of call number"/>
        <subfield code="a" repeat="R" desc="Classification number" occurs="M"/>
        <subfield code="e" repeat="NR" desc="Feature heading"/>
        <subfield code="f" repeat="NR" desc="Filing suffix"/>
      </datafield>
      <datafield tag="100" repeat="NR" desc="Main entry — personal name">
        <ind1 values="013" desc="Type of personal name entry element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Personal name"/>
        <subfield code="b" repeat="NR" desc="Numeration"/>
        <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
        <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="j" repeat="R" desc="Attribution qualifier"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Fuller form of name"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="110" repeat="NR" desc="Main entry — corporate name">
        <ind1 values="012" desc="Type of corporate name entry element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
        <subfield code="b" repeat="R" desc="Subordinate unit"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="111" repeat="NR" desc="Main entry — meeting name">
        <ind1 values="012" desc="Type of meeting name entry element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting"/>
        <subfield code="e" repeat="R" desc="Subordinate unit"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="j" repeat="R" desc="Relator term"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="130" repeat="NR" desc="Main entry — uniform title">
        <ind1 values="0-9" desc="Nonfiling characters"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="210" repeat="R" desc="Abbreviated title">
        <ind1 values="01" desc="Title added entry"/>
        <ind2 values=" 0" desc="Type"/>
        <subfield code="a" repeat="NR" desc="Abbreviated title"/>
        <subfield code="b" repeat="NR" desc="Qualifying information"/>
        <subfield code="2" repeat="R" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="222" repeat="R" desc="Key title">
        <ind1 values=" " desc="Specifies whether variant title and/or added entry is required"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Key title"/>
        <subfield code="b" repeat="NR" desc="Qualifying information"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="240" repeat="NR" desc="Uniform title">
        <ind1 values="01" desc="Uniform title printed or displayed"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="242" repeat="R" desc="Translation of title by cataloging agency">
        <ind1 values="01" desc="Title added entry"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Title"/>
        <subfield code="b" repeat="NR" desc="Remainder of title"/>
        <subfield code="c" repeat="NR" desc="Statement of responsibility, etc."/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="y" repeat="NR" desc="Language code of translated title">
      <assert test="matches(., $marcLangCodes)">Subfield $y must match a valid language code</assert>
    </subfield>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="243" repeat="NR" desc="Collective uniform title">
        <ind1 values="01" desc="Uniform title printed or displayed"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="245" repeat="NR" occurs="M" desc="Title statement">
        <ind1 values="01" desc="Title added entry"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Title" occurs="M"/>
        <subfield code="b" repeat="NR" desc="Remainder of title"/>
        <subfield code="c" repeat="NR" desc="Statement of responsibility, etc."/>
        <subfield code="f" repeat="NR" desc="Inclusive dates"/>
        <subfield code="g" repeat="NR" desc="Bulk dates"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="246" repeat="R" desc="Varying form of title">
        <ind1 values="0-3" desc="Note/added entry controller"/>
        <ind2 values=" 012345678" desc="Type of title"/>
        <subfield code="a" repeat="NR" desc="Title proper/short title"/>
        <subfield code="b" repeat="NR" desc="Remainder of title"/>
        <subfield code="f" repeat="NR" desc="Date or sequential designation"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="i" repeat="NR" desc="Display text"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="247" repeat="R" desc="Former title">
        <ind1 values="01" desc="Title added entry"/>
        <ind2 values="01" desc="Note controller"/>
        <subfield code="a" repeat="NR" desc="Title"/>
        <subfield code="b" repeat="NR" desc="Remainder of title"/>
        <subfield code="f" repeat="NR" desc="Date or sequential designation"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="250" repeat="R" desc="Edition statement">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Edition statement"/>
        <subfield code="b" repeat="NR" desc="Remainder of edition statement"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="251" repeat="R" desc="Version information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Version"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="254" repeat="NR" desc="Musical presentation statement">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Musical presentation statement"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="255" repeat="R" desc="Cartographic mathematical data">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Statement of scale"/>
        <subfield code="b" repeat="NR" desc="Statement of projection"/>
        <subfield code="c" repeat="NR" desc="Statement of coordinates"/>
        <subfield code="d" repeat="NR" desc="Statement of zone"/>
        <subfield code="e" repeat="NR" desc="Statement of equinox"/>
        <subfield code="f" repeat="NR" desc="Outer G-ring coordinate pairs"/>
        <subfield code="g" repeat="NR" desc="Exclusion G-ring coordinate pairs"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="256" repeat="NR" desc="Computer file characteristics">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Computer file characteristics"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="257" repeat="R" desc="Country of producing entity for archival films">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Country of producing entity"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="258" repeat="R" desc="Philatelic issue date">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Issuing jurisdiction"/>
        <subfield code="b" repeat="NR" desc="Denomination"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="260" repeat="R" desc="Publication, distribution, etc. (imprint)">
        <ind1 values=" 23" desc="Sequence of publishing statements"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Place of publication, distribution, etc."/>
        <subfield code="b" repeat="R" desc="Name of publisher, distributor, etc."/>
        <subfield code="c" repeat="R" desc="Date of publication, distribution, etc."/>
        <!-- Subfield $d is obsolete -->
        <subfield code="d" repeat="NR" desc="Plate or publisher's number for music (Pre-AACR 2)"/>
        <subfield code="e" repeat="R" desc="Place of manufacture"/>
        <subfield code="f" repeat="R" desc="Manufacturer"/>
        <subfield code="g" repeat="R" desc="Date of manufacture"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <rule
          context="*:datafield[@tag = '260' and matches(substring(../*:leader, 8, 1), '[am]') and not(../*:datafield[@tag = '502'])]">
          <assert test="*:subfield[@code = 'a']" role="warning">Subfield $a is recommended.</assert>
          <assert test="*:subfield[@code = 'b']" role="warning">Subfield $b is recommended.</assert>
          <assert test="*:subfield[@code = 'c']" role="warning">Subfield $c is recommended.</assert>
        </rule>
      </datafield>
      <!-- Datafield 261 is obsolete -->
      <datafield tag="261" repeat="NR" desc="IMPRINT STATEMENT FOR FILMS (Pre-AACR 1 Revised)">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Producing company"/>
        <subfield code="b" repeat="R" desc="Releasing company (primary distributor)"/>
        <subfield code="d" repeat="R" desc="Date of production, release, etc."/>
        <subfield code="e" repeat="R" desc="Contractual producer"/>
        <subfield code="f" repeat="R" desc="Place of production, release, etc."/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <!-- Datafield 262 is obsolete -->
      <datafield tag="262" repeat="NR" desc="IMPRINT STATEMENT FOR SOUND RECORDINGS (Pre-AACR 2)">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Place of production, release, etc."/>
        <subfield code="b" repeat="NR" desc="Publisher or trade name"/>
        <subfield code="c" repeat="NR" desc="Date of production, release, etc."/>
        <subfield code="k" repeat="NR" desc="Serial identification"/>
        <subfield code="l" repeat="NR" desc="Matrix and/or take number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="263" repeat="NR" desc="Projected publication date">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Projected publication date"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="264" repeat="R"
        desc="Production, publication, distribution, manufacture, and copyright notice">
        <ind1 values=" 23" desc="Sequence of statements"/>
        <ind2 values="0-4" desc="Function of entity"/>
        <subfield code="a" repeat="R" desc="Place of production, publication, distribution, manufacture"/>
        <subfield code="b" repeat="R" desc="Name of producer, publisher, distributor, manufacturer"/>
        <subfield code="c" repeat="R" desc="Date of production, publication, distribution, manufacture, or copyright notice"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="270" repeat="R" desc="Address">
        <ind1 values=" 12" desc="Level"/>
        <ind2 values=" 07" desc="Type of address"/>
        <subfield code="a" repeat="R" desc="Address"/>
        <subfield code="b" repeat="NR" desc="City"/>
        <subfield code="c" repeat="NR" desc="State or province"/>
        <subfield code="d" repeat="NR" desc="Country"/>
        <subfield code="e" repeat="NR" desc="Postal code"/>
        <subfield code="f" repeat="NR" desc="Terms preceding attention name"/>
        <subfield code="g" repeat="NR" desc="Attention name"/>
        <subfield code="h" repeat="NR" desc="Attention position"/>
        <subfield code="i" repeat="NR" desc="Type of address"/>
        <subfield code="j" repeat="R" desc="Specialized telephone number"/>
        <subfield code="k" repeat="R" desc="Telephone number"/>
        <subfield code="l" repeat="R" desc="Fax number"/>
        <subfield code="m" repeat="R" desc="Electronic mail address"/>
        <subfield code="n" repeat="R" desc="TDD or TTY number"/>
        <subfield code="p" repeat="R" desc="Contact person"/>
        <subfield code="q" repeat="R" desc="Title of contact person"/>
        <subfield code="r" repeat="R" desc="Hours"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="300" repeat="R" occurs="R" desc="Physical description">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Extent"/>
        <subfield code="b" repeat="NR" desc="Other physical details"/>
        <subfield code="c" repeat="R" desc="Dimensions"/>
        <subfield code="e" repeat="NR" desc="Accompanying material"/>
        <subfield code="f" repeat="R" desc="Type of unit"/>
        <subfield code="g" repeat="R" desc="Size of unit"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <rule
          context="*:datafield[@tag = '300' and  matches(substring(../*:leader, 7, 1), '[at]') and matches(substring(../*:leader, 8, 1), '[am]')]">
          <assert test="*:subfield[@code = 'a']" role="warning">Subfield $a is recommended.</assert>
          <assert test="*:subfield[@code = 'c']" role="warning">Subfield $c is recommended.</assert>
        </rule>
      </datafield>
      <datafield tag="306" repeat="NR" desc="Playing time">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Playing time"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="307" repeat="R" desc="Hours, etc.">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Hours"/>
        <subfield code="b" repeat="NR" desc="Additional information"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="310" repeat="R" desc="Current publication frequency">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Current publication frequency"/>
        <subfield code="b" repeat="NR" desc="Date of current publication frequency"/>
        <subfield code="0" repeat="NR" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="321" repeat="R" desc="Former publication frequency">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Former publication frequency"/>
        <subfield code="b" repeat="NR" desc="Dates of former publication frequency"/>
        <subfield code="0" repeat="NR" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <assert test="*:subfield[@code = 'b']" role="warning">Subfield $b is recommended.</assert>
      </datafield>
      <datafield tag="336" repeat="R" desc="Content type">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Content type term"/>
        <subfield code="b" repeat="R" desc="Content type code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="337" repeat="R" desc="Media type">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Media type term"/>
        <subfield code="b" repeat="R" desc="Media type code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="338" repeat="R" desc="Carrier type">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Carrier type term"/>
        <subfield code="b" repeat="R" desc="Carrier type code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="340" repeat="R" desc="Physical medium">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Material base and configuration"/>
        <subfield code="b" repeat="R" desc="Dimensions"/>
        <subfield code="c" repeat="R" desc="Materials applied to surface"/>
        <subfield code="d" repeat="R" desc="Information recording technique"/>
        <subfield code="e" repeat="R" desc="Support"/>
        <subfield code="f" repeat="R" desc="Production rate/ratio"/>
        <subfield code="h" repeat="R" desc="Location within medium"/>
        <subfield code="i" repeat="R" desc="Technical specifications of medium"/>
        <subfield code="j" repeat="R" desc="Generation"/>
        <subfield code="k" repeat="R" desc="Layout"/>
        <subfield code="m" repeat="R" desc="Book format"/>
        <subfield code="n" repeat="R" desc="Font size"/>
        <subfield code="o" repeat="R" desc="Polarity"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="341" repeat="R" desc="Accessibility content">
        <ind1 values="01" desc="Application"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Content access mode"/>
        <subfield code="b" repeat="R" desc="Textual assistive features"/>
        <subfield code="c" repeat="R" desc="Visual assistive features"/>
        <subfield code="d" repeat="R" desc="Auditory assistive features"/>
        <subfield code="e" repeat="R" desc="Tactile assistive features"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="342" repeat="R" desc="Geospatial reference data">
        <ind1 values="01" desc="Geospatial reference dimension"/>
        <ind2 values="0-8" desc="Geospatial reference method"/>
        <subfield code="a" repeat="NR" desc="Name"/>
        <subfield code="b" repeat="NR" desc="Coordinate or distance units"/>
        <subfield code="c" repeat="NR" desc="Latitude resolution"/>
        <subfield code="d" repeat="NR" desc="Longitude resolution"/>
        <subfield code="e" repeat="R" desc="Standard parallel or oblique line latitude"/>
        <subfield code="f" repeat="R" desc="Oblique line longitude"/>
        <subfield code="g" repeat="NR" desc="Longitude of central meridian or projection center"/>
        <subfield code="h" repeat="NR" desc="Latitude of projection origin or projection center"/>
        <subfield code="i" repeat="NR" desc="False easting"/>
        <subfield code="j" repeat="NR" desc="False northing"/>
        <subfield code="k" repeat="NR" desc="Scale factor"/>
        <subfield code="l" repeat="NR" desc="Height of perspective point above surface"/>
        <subfield code="m" repeat="NR" desc="Azimuthal angle"/>
        <subfield code="o" repeat="NR" desc="Landsat number and path number"/>
        <subfield code="p" repeat="NR" desc="Zone identifier"/>
        <subfield code="q" repeat="NR" desc="Ellipsoid name"/>
        <subfield code="r" repeat="NR" desc="Semi-major axis"/>
        <subfield code="s" repeat="NR" desc="Denominator of flattening ratio"/>
        <subfield code="t" repeat="NR" desc="Vertical resolution"/>
        <subfield code="u" repeat="NR" desc="Vertical encoding method"/>
        <subfield code="v" repeat="NR" desc="Local planar, local, or other projection or grid description"/>
        <subfield code="w" repeat="NR" desc="Local planar or local georeference information"/>
        <subfield code="2" repeat="NR" desc="Reference method used"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="343" repeat="R" desc="Planar coordinate data">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Planar coordinate encoding method"/>
        <subfield code="b" repeat="NR" desc="Planar distance units"/>
        <subfield code="c" repeat="NR" desc="Abscissa resolution"/>
        <subfield code="d" repeat="NR" desc="Ordinate resolution"/>
        <subfield code="e" repeat="NR" desc="Distance resolution"/>
        <subfield code="f" repeat="NR" desc="Bearing resolution"/>
        <subfield code="g" repeat="NR" desc="Bearing units"/>
        <subfield code="h" repeat="NR" desc="Bearing reference direction"/>
        <subfield code="i" repeat="NR" desc="Bearing reference meridian"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="344" repeat="R" desc="Sound characteristics">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Type of recording"/>
        <subfield code="b" repeat="R" desc="Recording medium"/>
        <subfield code="c" repeat="R" desc="Playing speed"/>
        <subfield code="d" repeat="R" desc="Groove characteristics"/>
        <subfield code="e" repeat="R" desc="Track configuration"/>
        <subfield code="f" repeat="R" desc="Tape configuration"/>
        <subfield code="g" repeat="R" desc="Configuration of playback channels"/>
        <subfield code="h" repeat="R" desc="Special playback characteristics"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="345" repeat="R" desc="Projection characteristics of moving image">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Presentation format"/>
        <subfield code="b" repeat="R" desc="Projection speed"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="346" repeat="R" desc="Video characteristics">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Video format"/>
        <subfield code="b" repeat="R" desc="Broadcast standard"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="347" repeat="R" desc="Digital file characteristics">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="File type"/>
        <subfield code="b" repeat="R" desc="Encoding format"/>
        <subfield code="c" repeat="R" desc="File size"/>
        <subfield code="d" repeat="R" desc="Resolution"/>
        <subfield code="e" repeat="R" desc="Regional encoding"/>
        <subfield code="f" repeat="R" desc="Transmission speed"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="348" repeat="R" desc="Format of Notated Music">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Format of notated music term"/>
        <subfield code="b" repeat="R" desc="Format of notated music code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="351" repeat="R" desc="Organization and arrangement of materials">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Organization"/>
        <subfield code="b" repeat="R" desc="Arrangement"/>
        <subfield code="c" repeat="NR" desc="Hierarchical level"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="352" repeat="R" desc="Digital graphic representation">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Direct reference method"/>
        <subfield code="b" repeat="R" desc="Object type"/>
        <subfield code="c" repeat="R" desc="Object count"/>
        <subfield code="d" repeat="NR" desc="Row count"/>
        <subfield code="e" repeat="NR" desc="Column count"/>
        <subfield code="f" repeat="NR" desc="Vertical count"/>
        <subfield code="g" repeat="NR" desc="VPF topology level"/>
        <subfield code="i" repeat="NR" desc="Indirect reference description"/>
        <subfield code="q" repeat="R" desc="Format of the digital image"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="355" repeat="R" desc="Security classification control">
        <ind1 values="0123458" desc="Controlled element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Security classification"/>
        <subfield code="b" repeat="R" desc="Handling instructions"/>
        <subfield code="c" repeat="R" desc="External dissemination information"/>
        <subfield code="d" repeat="NR" desc="Downgrading or declassification event"/>
        <subfield code="e" repeat="NR" desc="Classification system"/>
        <subfield code="f" repeat="NR" desc="Country of origin code">
       <assert test="matches(., $marcCountryCodes)">Subfield $b must match a valid country code</assert>
    </subfield>
        <subfield code="g" repeat="NR" desc="Downgrading date"/>
        <subfield code="h" repeat="NR" desc="Declassification date"/>
        <subfield code="j" repeat="R" desc="Authorization"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="357" repeat="NR" desc="Originator dissemination control">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Originator control term"/>
        <subfield code="b" repeat="R" desc="Originating agency"/>
        <subfield code="c" repeat="R" desc="Authorized recipients of material"/>
        <subfield code="g" repeat="R" desc="Other restrictions"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="362" repeat="R" desc="Dates of publication and/or sequential designation">
        <ind1 values="01" desc="Format of date"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Dates of publication and/or sequential designation"/>
        <subfield code="z" repeat="NR" desc="Source of information"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="363" repeat="R" desc="Normalized date and sequential designation">
        <ind1 values=" 01" desc="Start/End designator"/>
        <ind2 values=" 01" desc="State of issuanceUndefined"/>
        <subfield code="a" repeat="NR" desc="First level of enumeration"/>
        <subfield code="b" repeat="NR" desc="Second level of enumeration"/>
        <subfield code="c" repeat="NR" desc="Third level of enumeration"/>
        <subfield code="d" repeat="NR" desc="Fourth level of enumeration"/>
        <subfield code="e" repeat="NR" desc="Fifth level of enumeration"/>
        <subfield code="f" repeat="NR" desc="Sixth level of enumeration"/>
        <subfield code="g" repeat="NR" desc="Alternative numbering scheme, first level of enumeration"/>
        <subfield code="h" repeat="NR" desc="Alternative numbering scheme, second level of enumeration"/>
        <subfield code="i" repeat="NR" desc="First level of chronology"/>
        <subfield code="j" repeat="NR" desc="Second level of chronology"/>
        <subfield code="k" repeat="NR" desc="Third level of chronology"/>
        <subfield code="l" repeat="NR" desc="Fourth level of chronology"/>
        <subfield code="m" repeat="NR" desc="Alternative numbering scheme, chronology"/>
        <subfield code="u" repeat="NR" desc="First level textual designation"/>
        <subfield code="v" repeat="NR" desc="First level of chronology, issuance"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="365" repeat="R" desc="Trade price">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Price type code"/>
        <subfield code="b" repeat="NR" desc="Price amount"/>
        <subfield code="c" repeat="NR" desc="Currency code"/>
        <subfield code="d" repeat="NR" desc="Unit of pricing"/>
        <subfield code="e" repeat="NR" desc="Price note"/>
        <subfield code="f" repeat="NR" desc="Price effective from"/>
        <subfield code="g" repeat="NR" desc="Price effective until"/>
        <subfield code="h" repeat="NR" desc="Tax rate 1"/>
        <subfield code="i" repeat="NR" desc="Tax rate 2"/>
        <subfield code="j" repeat="NR" desc="ISO country code"/>
        <subfield code="k" repeat="NR" desc="MARC country code">
      <assert test="matches(., $marcCountryCodes)">Subfield $k must match a valid MARC country code</assert>
    </subfield>
        <subfield code="m" repeat="NR" desc="Identification of pricing entity"/>
        <subfield code="2" repeat="NR" desc="Source of price type code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="366" repeat="R" desc="Trade availability information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Publishers' compressed title identification"/>
        <subfield code="b" repeat="NR" desc="Detailed date of publication"/>
        <subfield code="c" repeat="NR" desc="Availability status code"/>
        <subfield code="d" repeat="NR" desc="Expected next availability date"/>
        <subfield code="e" repeat="NR" desc="Note"/>
        <subfield code="f" repeat="NR" desc="Publishers' discount category"/>
        <subfield code="g" repeat="NR" desc="Date made out of print"/>
        <subfield code="j" repeat="NR" desc="ISO country code"/>
        <subfield code="k" repeat="NR" desc="MARC country code">
      <assert test="matches(., $marcCountryCodes)">Subfield $k must match a valid MARC country code</assert>
    </subfield>
        <subfield code="m" repeat="NR" desc="Identification of agency"/>
        <subfield code="2" repeat="NR" desc="Source of availability status code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="370" repeat="R" desc="Associated place">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="c" repeat="R" desc="Associated country"/>
        <subfield code="f" repeat="R" desc="Other associated place"/>
        <subfield code="g" repeat="R" desc="Place of origin of work"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="s" repeat="NR" desc="Start period"/>
        <subfield code="t" repeat="NR" desc="End period"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="v" repeat="R" desc="Source of information"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="377" repeat="R" desc="Associated language">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 7" desc="Source of code"/>
        <subfield code="a" repeat="R" desc="Language code"/>
        <subfield code="l" repeat="R" desc="Language term"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="380" repeat="R" desc="Form of work">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Form of work"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="381" repeat="R"
        desc="Other distinguishing characteristics of work or expression">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Other distinguishing characteristics"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="v" repeat="R" desc="Source of information"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="382" repeat="R" desc="Medium of performance">
        <ind1 values=" 01" desc="Display constant controller"/>
        <ind2 values=" 01" desc="Access control"/>
        <subfield code="a" repeat="R" desc="Medium of performance"/>
        <subfield code="b" repeat="R" desc="Soloist"/>
        <subfield code="d" repeat="R" desc="Doubling instrument"/>
        <subfield code="e" repeat="R" desc="Number of ensembles of the same type"/>
        <subfield code="n" repeat="R" desc="Number of performers of the same medium"/>
        <subfield code="p" repeat="R" desc="Alternative medium performance"/>
        <subfield code="r" repeat="NR" desc="Total number of individuals performing alongside ensembles"/>
        <subfield code="s" repeat="NR" desc="Total number of performers"/>
        <subfield code="t" repeat="NR" desc="Total number of ensembles"/>
        <subfield code="v" repeat="R" desc="Note"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="383" repeat="R" desc="Numeric designation of musical work">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Serial number"/>
        <subfield code="b" repeat="R" desc="Opus number"/>
        <subfield code="c" repeat="R" desc="Thematic index number"/>
        <subfield code="d" repeat="NR" desc="Thematic index code"/>
        <subfield code="e" repeat="NR" desc="Publisher associated with opus number"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="384" repeat="NR" desc="Key">
        <ind1 values=" 01" desc="Key type"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Key"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="385" repeat="R" desc="Audience characteristics">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Audience term"/>
        <subfield code="b" repeat="R" desc="Audience code"/>
        <subfield code="m" repeat="NR" desc="Demographic group term"/>
        <subfield code="n" repeat="NR" desc="Demographic group code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="386" repeat="R" desc="Creator/contributor characteristics">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Creator/contributor term"/>
        <subfield code="b" repeat="R" desc="Creator/contributor code"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="m" repeat="NR" desc="Demographic group term"/>
        <subfield code="n" repeat="NR" desc="Demographic group code"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="388" repeat="R" desc="Time period of creation">
        <ind1 values=" 12" desc="Type of time period"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Time period of creation term"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="400" repeat="R" desc="Series statement/added entry — personal name (pre rda)">
        <ind1 values="013" desc="Type of personal name entry element"/>
        <ind2 values="01" desc="Pronoun represents main entry"/>
        <subfield code="a" repeat="NR" desc="Personal name"/>
        <subfield code="b" repeat="NR" desc="Numeration"/>
        <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
        <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="NR" desc="Volume number/sequential designation "/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number "/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number "/>
      </datafield>
      <datafield tag="410" repeat="R" desc="Series statement/added entry — corporate name (pre rda)">
        <ind1 values="012" desc="Type of corporate name entry element"/>
        <ind2 values="01" desc="Pronoun represents main entry"/>
        <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
        <subfield code="b" repeat="R" desc="Subordinate unit"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="NR" desc="Volume number/sequential designation "/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="411" repeat="R" desc="Series statement/added entry — meeting name (pre rda)">
        <ind1 values="012" desc="Type of meeting name entry element"/>
        <ind2 values="01" desc="Pronoun represents main entry"/>
        <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="NR" desc="Date of meeting"/>
        <subfield code="e" repeat="R" desc="Subordinate unit"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="NR" desc="Volume number/sequential designation "/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <!-- Datafield 440 is obsolete -->
      <datafield tag="440" repeat="R" desc="Series statement/added entry — title [obsolete]">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Title"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="v" repeat="NR" desc="Volume number/sequential designation "/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="490" repeat="R" desc="Series statement">
        <ind1 values="01" desc="Series tracing policy"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Series statement"/>
        <subfield code="l" repeat="NR" desc="Library of Congress call number"/>
        <subfield code="v" repeat="R" desc="Volume number/sequential designation "/>
        <!-- https://www.oclc.org/bibformats/en/4xx/490.html says $x is repeatable -->
        <subfield code="x" repeat="R" desc="International Standard Serial Number"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <pattern>
          <title>Co-constraint with 8xx</title>
          <rule context="*:datafield[@tag = '490' and @ind1 = '1']">
            <assert test="../*:datafield[matches(@tag, '800|810|811|830')]">When @ind1 = "1", a
              corresponding 8xx field is required</assert>
          </rule>
        </pattern>
      </datafield>
      <datafield tag="500" repeat="R" desc="General note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="General note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="501" repeat="R" desc="With note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="With note"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="502" repeat="R" desc="Dissertation note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Dissertation note"/>
        <subfield code="b" repeat="NR" desc="Degree type"/>
        <subfield code="c" repeat="NR" desc="Name of granting institution"/>
        <subfield code="d" repeat="NR" desc="Year of degree granted"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="o" repeat="R" desc="Dissertation identifier"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="504" repeat="R" desc="Bibliography, etc. note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Bibliography, etc. note"/>
        <subfield code="b" repeat="NR" desc="Number of references"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="505" repeat="R" desc="Formatted contents note">
        <ind1 values="0128" desc="Display constant controller"/>
        <ind2 values=" 0" desc="Level of content designation"/>
        <subfield code="a" repeat="NR" desc="Formatted contents note"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="r" repeat="R" desc="Statement of responsibility"/>
        <subfield code="t" repeat="R" desc="Title"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <rule context="*:datafield[@tag = '505'][@ind2 eq '0']">
          <report test="*:subfield[matches(@code, 'a')]">Subfield a is not permitted in extended
            contents note</report>
        </rule>
      </datafield>
      <datafield tag="506" repeat="R" desc="Restrictions on access note">
        <ind1 values=" 01" desc="Restriction"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Terms governing access"/>
        <subfield code="b" repeat="R" desc="Jurisdiction"/>
        <subfield code="c" repeat="R" desc="Physical access provisions"/>
        <subfield code="d" repeat="R" desc="Authorized users"/>
        <subfield code="e" repeat="R" desc="Authorization"/>
        <subfield code="f" repeat="R" desc="Standard terminology for access restiction"/>
        <subfield code="g" repeat="R" desc="Availability date"/>
        <subfield code="q" repeat="NR" desc="Supplying agency"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="507" repeat="NR" desc="Scale note for graphic material">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Representative fraction of scale note"/>
        <subfield code="b" repeat="NR" desc="Remainder of scale note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="508" repeat="R" desc="Creation/production credits note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Creation/production credits note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="510" repeat="R" desc="Citation/references note">
        <ind1 values="0-4" desc="Coverage/location in source"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Name of source"/>
        <subfield code="b" repeat="NR" desc="Coverage of source"/>
        <subfield code="c" repeat="NR" desc="Location within source"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="511" repeat="R" desc="Participant or performer note">
        <ind1 values="01" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Participant or performer note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="513" repeat="R" desc="Type of report and period covered note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of report"/>
        <subfield code="b" repeat="NR" desc="Period covered"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="514" repeat="NR" desc="Data quality note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Attribute accuracy report"/>
        <subfield code="b" repeat="R" desc="Attribute accuracy value"/>
        <subfield code="c" repeat="R" desc="Attribute accuracy explanation"/>
        <subfield code="d" repeat="NR" desc="Logical consistency report"/>
        <subfield code="e" repeat="NR" desc="Completeness report"/>
        <subfield code="f" repeat="NR" desc="Horizontal position accuracy report"/>
        <subfield code="g" repeat="R" desc="Horizontal position accuracy value"/>
        <subfield code="h" repeat="R" desc="Horizontal position accuracy explanation"/>
        <subfield code="i" repeat="NR" desc="Vertical positional accuracy report"/>
        <subfield code="j" repeat="R" desc="Vertical positional accuracy value"/>
        <subfield code="k" repeat="R" desc="Vertical positional accuracy explanation"/>
        <subfield code="m" repeat="NR" desc="Cloud cover"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="z" repeat="R" desc="Display note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="515" repeat="R" desc="Numbering peculiarities note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Numbering peculiarities note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="516" repeat="R" desc="Type of computer file or data note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of computer file or data note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="518" repeat="R" desc="Date/time and place of an event note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Date/time and place of an event note"/>
        <subfield code="d" repeat="R" desc="Date of event"/>
        <subfield code="o" repeat="R" desc="Other event information"/>
        <subfield code="p" repeat="R" desc="Place of event"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="R" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="520" repeat="R" desc="Summary, etc.">
        <ind1 values=" 012348" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Summary, etc. note"/>
        <subfield code="b" repeat="NR" desc="Expansion of summary note"/>
        <subfield code="c" repeat="NR" desc="Assigning agency"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="2" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="521" repeat="R" desc="Target audience note">
        <ind1 values=" 012348" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Target audience note"/>
        <subfield code="b" repeat="NR" desc="Source"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="522" repeat="R" desc="Geographic coverage note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Geographic coverage note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="524" repeat="R" desc="Preferred citation of described materials note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Preferred citation of described materials note"/>
        <subfield code="2" repeat="NR" desc="Source of schema used"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="525" repeat="R" desc="Supplement note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Supplement note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="526" repeat="R" desc="Study program information note">
        <ind1 values="08" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Program name"/>
        <subfield code="b" repeat="NR" desc="Interest level"/>
        <subfield code="c" repeat="NR" desc="Reading level"/>
        <subfield code="d" repeat="NR" desc="Title point value"/>
        <subfield code="i" repeat="NR" desc="Display text"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="530" repeat="R" desc="Additional physical form available note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Additional physical form available note"/>
        <subfield code="b" repeat="NR" desc="Availability source"/>
        <subfield code="c" repeat="NR" desc="Availability conditions"/>
        <subfield code="d" repeat="NR" desc="Order number"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="532" repeat="R" desc="Accessibility note">
        <ind1 values="0128" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Summary of accessibility"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="533" repeat="R" desc="Reproduction note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of reproduction"/>
        <subfield code="b" repeat="R" desc="Place of reproduction"/>
        <subfield code="c" repeat="R" desc="Agency responsible for reproduction"/>
        <subfield code="d" repeat="NR" desc="Date of reproduction"/>
        <subfield code="e" repeat="NR" desc="Physical description of reproduction"/>
        <subfield code="f" repeat="R" desc="Series statement of reproduction"/>
        <subfield code="m" repeat="R" desc="Dates and/or sequential designation of issues reproduced"/>
        <subfield code="n" repeat="R" desc="Note about reproduction"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Fixed-length data elements of reproduction"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="534" repeat="R" desc="Original version note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Main entry of original"/>
        <subfield code="b" repeat="NR" desc="Edition statement of original"/>
        <subfield code="c" repeat="NR" desc="Publication, distribution, etc. of original"/>
        <subfield code="e" repeat="NR" desc="Physical description, etc. of original"/>
        <subfield code="f" repeat="R" desc="Series statement of original"/>
        <subfield code="k" repeat="R" desc="Key title of original"/>
        <subfield code="l" repeat="NR" desc="Location of original"/>
        <subfield code="m" repeat="NR" desc="Material specific details"/>
        <subfield code="n" repeat="R" desc="Note about original"/>
        <subfield code="o" repeat="R" desc="Other resource identifier"/>
        <subfield code="p" repeat="NR" desc="Introductory phrase"/>
        <subfield code="t" repeat="NR" desc="Title statement of original"/>
        <subfield code="x" repeat="R" desc="International Standard Serial Number"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="535" repeat="R" desc="Location of originals/duplicates note">
        <ind1 values="12" desc="Additional information about custodian"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Custodian"/>
        <subfield code="b" repeat="R" desc="Postal address"/>
        <subfield code="c" repeat="R" desc="Country"/>
        <subfield code="d" repeat="R" desc="Telecommunications address"/>
        <subfield code="g" repeat="NR" desc="Repository location code"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="536" repeat="R" desc="Funding information note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Text of note"/>
        <subfield code="b" repeat="R" desc="Contract number"/>
        <subfield code="c" repeat="R" desc="Grant number"/>
        <subfield code="d" repeat="R" desc="Undifferentiated number"/>
        <subfield code="e" repeat="R" desc="Program element number"/>
        <subfield code="f" repeat="R" desc="Project number"/>
        <subfield code="g" repeat="R" desc="Task number"/>
        <subfield code="h" repeat="R" desc="Work unit number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="538" repeat="R" desc="System details note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="System details note"/>
        <subfield code="i" repeat="NR" desc="Display text"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="3" repeat="NR" desc="Materials specified "/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="539" repeat="R" desc="Fixed-length data elements of reproduction note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of date/publication status" occurs="R"/>
        <subfield code="b" repeat="NR" desc="Date 1/beginning date of publication" occurs="R"/>
        <subfield code="c" repeat="NR" desc="Date 2/ending date of publication" occurs="R"/>
        <subfield code="d" repeat="NR" desc="Place of publication, production, or execution" occurs="R"/>
        <subfield code="e" repeat="NR" desc="Frequency" occurs="R"/>
        <subfield code="f" repeat="NR" desc="Regularity" occurs="R"/>
        <subfield code="g" repeat="NR" desc="Form of item"/>
      </datafield>
      <datafield tag="540" repeat="R" desc="Terms governing use and reproduction note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Terms governing use and reproduction"/>
        <subfield code="b" repeat="NR" desc="Jurisdiction"/>
        <subfield code="c" repeat="NR" desc="Authorization"/>
        <subfield code="d" repeat="NR" desc="Authorized users"/>
        <subfield code="f" repeat="R" desc="Use and reproduction rights"/>
        <subfield code="g" repeat="R" desc="Availability date"/>
        <subfield code="q" repeat="NR" desc="Supplying agency"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="541" repeat="R" desc="Immediate source of acquisition note">
        <ind1 values=" 01" desc="Privacy"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Source of acquisition"/>
        <subfield code="b" repeat="NR" desc="Address"/>
        <subfield code="c" repeat="NR" desc="Method of acquisition"/>
        <subfield code="d" repeat="NR" desc="Date of acquisition"/>
        <subfield code="e" repeat="NR" desc="Accession number"/>
        <subfield code="f" repeat="NR" desc="Owner"/>
        <subfield code="h" repeat="NR" desc="Purchase price"/>
        <subfield code="n" repeat="R" desc="Extent"/>
        <subfield code="o" repeat="R" desc="Type of unit"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="542" repeat="R" desc="Information relating to copyright status">
        <ind1 values=" 01" desc="Privacy"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Personal creator"/>
        <subfield code="b" repeat="NR" desc="Personal creator death date"/>
        <subfield code="c" repeat="NR" desc="Corporate creator"/>
        <subfield code="d" repeat="R" desc="Copyright holder"/>
        <subfield code="e" repeat="R" desc="Copyright holder contact information"/>
        <subfield code="f" repeat="R" desc="Copyright statement"/>
        <subfield code="g" repeat="NR" desc="Copyright date"/>
        <subfield code="h" repeat="R" desc="Copyright renewal date"/>
        <subfield code="i" repeat="NR" desc="Publication date"/>
        <subfield code="j" repeat="NR" desc="Creation date"/>
        <subfield code="k" repeat="R" desc="Publisher"/>
        <subfield code="l" repeat="NR" desc="Copyright status"/>
        <subfield code="m" repeat="NR" desc="Publication status"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="NR" desc="Research date"/>
        <subfield code="p" repeat="R" desc="Country of publication or creation"/>
        <subfield code="q" repeat="NR" desc="Assigning agency"/>
        <subfield code="r" repeat="NR" desc="Jurisdiction of copyright assessment"/>
        <subfield code="s" repeat="NR" desc="Source of information"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="544" repeat="R" desc="Location of other archival materials note">
        <ind1 values=" 01" desc="Relationship"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Custodian"/>
        <subfield code="b" repeat="R" desc="Address"/>
        <subfield code="c" repeat="R" desc="Country"/>
        <subfield code="d" repeat="R" desc="Title"/>
        <subfield code="e" repeat="R" desc="Provenance"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="545" repeat="R" desc="Biographical or historical data">
        <ind1 values=" 01" desc="Type of data"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Biographical or historical note"/>
        <subfield code="b" repeat="NR" desc="Expansion"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="546" repeat="R" desc="Language note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Language note"/>
        <subfield code="b" repeat="R" desc="Information code or alphabet"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="547" repeat="R" desc="Former title complexity note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Former title complexity note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="550" repeat="R" desc="Issuing body note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Issuing body note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="552" repeat="R" desc="Entity and attribute information note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Entity type label"/>
        <subfield code="b" repeat="NR" desc="Entity type definition and source"/>
        <subfield code="c" repeat="NR" desc="Attribute label"/>
        <subfield code="d" repeat="NR" desc="Attribute definition and source"/>
        <subfield code="e" repeat="R" desc="Enumerated domain value"/>
        <subfield code="f" repeat="R" desc="Enumerated domain value definition and source"/>
        <subfield code="g" repeat="NR" desc="Range domain minimum and maximum"/>
        <subfield code="h" repeat="NR" desc="Codeset name and source"/>
        <subfield code="i" repeat="NR" desc="Unrepresentable domain"/>
        <subfield code="j" repeat="NR" desc="Attribute units of measurement and resolution"/>
        <subfield code="k" repeat="NR" desc="Beginning date and ending date of attribute values"/>
        <subfield code="l" repeat="NR" desc="Attribute value accuracy"/>
        <subfield code="m" repeat="NR" desc="Attribute value accuracy explanation"/>
        <subfield code="n" repeat="NR" desc="Attribute measurement frequency"/>
        <subfield code="o" repeat="R" desc="Entity and attribute overview"/>
        <subfield code="p" repeat="R" desc="Entity and attribute detail citation"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="z" repeat="R" desc="Display note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="555" repeat="R" desc="Cumulative index/finding aids note">
        <ind1 values=" 08" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Cumulative index/finding aids note"/>
        <subfield code="b" repeat="R" desc="Availability source"/>
        <subfield code="c" repeat="NR" desc="Degree of control"/>
        <subfield code="d" repeat="NR" desc="Bibliographic reference"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="556" repeat="R" desc="Information about documentation note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Information about documentation note"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="561" repeat="R" desc="Ownership and custodial history">
        <ind1 values=" 01" desc="Privacy"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="History"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="562" repeat="R" desc="Copy and version identification note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Identifying markings"/>
        <subfield code="b" repeat="R" desc="Copy identification"/>
        <subfield code="c" repeat="R" desc="Version identification"/>
        <subfield code="d" repeat="R" desc="Presentation format"/>
        <subfield code="e" repeat="R" desc="Number of copies"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="563" repeat="R" desc="Binding information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Binding note"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="565" repeat="R" desc="Case file characteristics note">
        <ind1 values=" 08" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Number of cases/variables"/>
        <subfield code="b" repeat="R" desc="Name of variable"/>
        <subfield code="c" repeat="R" desc="Unit of analysis"/>
        <subfield code="d" repeat="R" desc="Universe of data"/>
        <subfield code="e" repeat="R" desc="Filing scheme or code"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="567" repeat="R" desc="Methodology note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Methodology note"/>
        <subfield code="b" repeat="R" desc="Controlled term"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="R" desc="Source of term"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="580" repeat="R" desc="Linking entry complexity note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Linking entry complexity note"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="581" repeat="R" desc="Publications about described materials note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Publications about described materials note"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="583" repeat="R" desc="Action note">
        <ind1 values=" 01" desc="Privacy"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Action"/>
        <subfield code="b" repeat="R" desc="Action identification"/>
        <subfield code="c" repeat="R" desc="Time/date of action"/>
        <subfield code="d" repeat="R" desc="Action interval"/>
        <subfield code="e" repeat="R" desc="Contingency for action"/>
        <subfield code="f" repeat="R" desc="Authorization"/>
        <subfield code="h" repeat="R" desc="Jurisdiction"/>
        <subfield code="i" repeat="R" desc="Method of action"/>
        <subfield code="j" repeat="R" desc="Site of action"/>
        <subfield code="k" repeat="R" desc="Action agent"/>
        <subfield code="l" repeat="R" desc="Status"/>
        <subfield code="n" repeat="R" desc="Extent"/>
        <subfield code="o" repeat="R" desc="Type of unit"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="584" repeat="R" desc="Accumulation and frequency of use note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Accumulation"/>
        <subfield code="b" repeat="R" desc="Frequency of use"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="585" repeat="R" desc="Exhibitions note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Exhibitions note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="586" repeat="R" desc="Awards note">
        <ind1 values=" 8" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Awards note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="588" repeat="R" desc="Source of description note">
        <ind1 values=" 01" desc="Display constant controller"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Source of description note"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="590" repeat="R" desc="Local note">
        <ind1 values=" 01" desc="Privacy"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Local note" occurs="M"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="591" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="592" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="593" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="594" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="595" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="596" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="597" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="598" repeat="R" desc="Local note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>-->
      </datafield>
      <datafield tag="599" repeat="R" desc="Differentiable local note">
        <ind1 values=" 0-9" desc="Locally defined"/>
        <ind2 values=" 0-9" desc="Locally defined"/>
        <!-- Spec says subfields not repeatable, data doesn't conform -->
        <subfield code="a" repeat="R" desc="Local note"/>
        <subfield code="b" repeat="R" desc="Local note"/>
        <subfield code="c" repeat="R" desc="Local note"/>
        <subfield code="d" repeat="R" desc="Local note"/>
        <subfield code="e" repeat="R" desc="Local note"/>
        <subfield code="f" repeat="R" desc="Local note"/>
        <subfield code="g" repeat="R" desc="Local note"/>
        <subfield code="h" repeat="R" desc="Local note"/>
        <subfield code="i" repeat="R" desc="Local note"/>
        <subfield code="j" repeat="R" desc="Local note"/>
        <subfield code="k" repeat="R" desc="Local note"/>
        <subfield code="l" repeat="R" desc="Local note"/>
        <subfield code="m" repeat="R" desc="Local note"/>
        <subfield code="n" repeat="R" desc="Local note"/>
        <subfield code="o" repeat="R" desc="Local note"/>
        <subfield code="p" repeat="R" desc="Local note"/>
        <subfield code="q" repeat="R" desc="Local note"/>
        <subfield code="r" repeat="R" desc="Local note"/>
        <subfield code="s" repeat="R" desc="Local note"/>
        <subfield code="t" repeat="R" desc="Local note"/>
        <subfield code="u" repeat="R" desc="Local note"/>
        <subfield code="v" repeat="R" desc="Local note"/>
        <subfield code="w" repeat="R" desc="Local note"/>
        <subfield code="x" repeat="R" desc="Local note"/>
        <subfield code="y" repeat="R" desc="Local note"/>
        <subfield code="z" repeat="R" desc="Local note"/>
        <subfield code="6" repeat="R" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <!--<subfield code="a" repeat="NR" desc="Local note"/>
    <subfield code="b" repeat="NR" desc="Local note"/>
    <subfield code="c" repeat="NR" desc="Local note"/>
    <subfield code="d" repeat="NR" desc="Local note"/>
    <subfield code="e" repeat="NR" desc="Local note"/>
    <subfield code="f" repeat="NR" desc="Local note"/>
    <subfield code="g" repeat="NR" desc="Local note"/>
    <subfield code="h" repeat="NR" desc="Local note"/>
    <subfield code="i" repeat="NR" desc="Local note"/>
    <subfield code="j" repeat="NR" desc="Local note"/>
    <subfield code="k" repeat="NR" desc="Local note"/>
    <subfield code="l" repeat="NR" desc="Local note"/>
    <subfield code="m" repeat="NR" desc="Local note"/>
    <subfield code="n" repeat="NR" desc="Local note"/>
    <subfield code="o" repeat="NR" desc="Local note"/>
    <subfield code="p" repeat="NR" desc="Local note"/>
    <subfield code="q" repeat="NR" desc="Local note"/>
    <subfield code="r" repeat="NR" desc="Local note"/>
    <subfield code="s" repeat="NR" desc="Local note"/>
    <subfield code="t" repeat="NR" desc="Local note"/>
    <subfield code="u" repeat="NR" desc="Local note"/>
    <subfield code="v" repeat="NR" desc="Local note"/>
    <subfield code="w" repeat="NR" desc="Local note"/>
    <subfield code="x" repeat="NR" desc="Local note"/>
    <subfield code="y" repeat="NR" desc="Local note"/>
    <subfield code="z" repeat="NR" desc="Local note"/>
    <subfield code="6" repeat="NR" desc="Linkage"/>
    <subfield code="8" repeat="R" desc="Field link and sequence number"/>-->
      </datafield>
      <datafield tag="600" repeat="R" desc="Subject added entry — personal name">
        <ind1 values="013" desc="Type of personal name entry element"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Personal name"/>
        <subfield code="b" repeat="NR" desc="Numeration"/>
        <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
        <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="j" repeat="R" desc="Attribution qualifier"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Fuller form of name"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="610" repeat="R" desc="Subject added entry — corporate name">
        <ind1 values="012" desc="Type of corporate name entry element"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
        <subfield code="b" repeat="R" desc="Subordinate unit"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="611" repeat="R" desc="Subject added entry — meeting name">
        <ind1 values="012" desc="Type of meeting name entry element"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="NR" desc="Date of meeting"/>
        <subfield code="e" repeat="R" desc="Subordinate unit"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="j" repeat="R" desc="Relator term"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="630" repeat="R" desc="Subject added entry — uniform title">
        <ind1 values="0-9" desc="Nonfiling characters"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="647" repeat="R" desc="Subject added entry — named event">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Named event"/>
        <subfield code="c" repeat="R" desc="Location of named event"/>
        <subfield code="d" repeat="NR" desc="Date of named event"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="648" repeat="R" desc="Subject added entry — chronological term">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Chronological term"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="650" repeat="R" desc="Subject added entry — topical term">
        <ind1 values=" 012" desc="Level of subject"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Topical term or geographic name as entry element"/>
        <subfield code="b" repeat="NR" desc="Topical term following geographic name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of event"/>
        <subfield code="d" repeat="NR" desc="Active dates"/>
        <subfield code="e" repeat="NR" desc="Relator term"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="651" repeat="R" desc="Subject added entry — geographic name">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Geographic name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="653" repeat="R" desc="Index term — uncontrolled">
        <ind1 values=" 012" desc="Level of index term"/>
        <ind2 values=" 0123456" desc="Type of term or name"/>
        <subfield code="a" repeat="R" desc="Uncontrolled term"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="654" repeat="R" desc="Subject added entry — faceted topical terms">
        <ind1 values=" 012" desc="Level of subject"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Focus term"/>
        <subfield code="b" repeat="R" desc="Non-focus term"/>
        <subfield code="c" repeat="R" desc="Facet/hierarchy designation"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="655" repeat="R" desc="Index term — genre/form">
        <ind1 values=" 0" desc="Type of heading"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Genre/form data or focus term"/>
        <subfield code="b" repeat="R" desc="Non-focus term"/>
        <subfield code="c" repeat="R" desc="Facet/hierarchy designation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="656" repeat="R" desc="Index term — occupation">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="7" desc="Source of term"/>
        <subfield code="a" repeat="NR" desc="Occupation"/>
        <subfield code="k" repeat="NR" desc="Form"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term" occurs="M"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="657" repeat="R" desc="Index term — function">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="7" desc="Source of term"/>
        <subfield code="a" repeat="NR" desc="Function"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term" occurs="M"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="658" repeat="R" desc="Index term — curriculum objective">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Main curriculum objective"/>
        <subfield code="b" repeat="R" desc="Subordinate curriculum objective"/>
        <subfield code="c" repeat="NR" desc="Curriculum code"/>
        <subfield code="d" repeat="NR" desc="Correlation factor"/>
        <subfield code="2" repeat="NR" desc="Source of term or code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="662" repeat="R" desc="Subject added entry — hierarchical place name">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Country or larger entity"/>
        <subfield code="b" repeat="NR" desc="First-order political jurisdiction"/>
        <subfield code="c" repeat="R" desc="Intermediate political jurisdiction"/>
        <subfield code="d" repeat="NR" desc="City"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="R" desc="City subsection"/>
        <subfield code="g" repeat="R" desc="Other nonjurisdictional geographic region and feature"/>
        <subfield code="h" repeat="R" desc="Extraterrestrial area"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="690" repeat="R" desc="Local subject added entry — topical term">
        <ind1 values=" 012" desc="Level of subject"/>
        <ind2 values=" 01234567" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Topical term or geographic name as entry element"/>
        <subfield code="b" repeat="NR" desc="Topical term following geographic name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of event"/>
        <subfield code="d" repeat="NR" desc="Active dates"/>
        <subfield code="e" repeat="NR" desc="Relator term"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <subfield code="9" repeat="NR" desc="Special entry"/>
      </datafield>
      <datafield tag="691" repeat="R" desc="Local subject added entry — geographic name">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" 01234567" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Geographic name"/>
        <subfield code="b" repeat="NR" desc="Geographic element following geographic name"/>
        <subfield code="g" repeat="R" desc="Miscellaneous information"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <subfield code="9" repeat="NR" desc="Special entry"/>
      </datafield>
      <datafield tag="695" repeat="R" desc="Added class number">
        <ind1 values=" 012" desc="Type of edition"/>
        <ind2 values="0123459" desc="Classification scheme"/>
        <subfield code="a" repeat="NR" desc="Added class number" occurs="M"/>
        <subfield code="b" repeat="R" desc="Item number"/>
        <subfield code="e" repeat="R" desc="Heading"/>
        <subfield code="f" repeat="R" desc="Filing suffix"/>
        <subfield code="2" repeat="NR" desc="Edition number"/>
      </datafield>
      <datafield tag="696" repeat="R" desc="Local subject added entry — personal name">
        <ind1 values="013" desc="Type of personal name entry element"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Personal name"/>
        <subfield code="b" repeat="NR" desc="Numeration"/>
        <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
        <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="j" repeat="R" desc="Attribution qualifier"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Fuller form of name"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <subfield code="9" repeat="NR" desc="Special entry"/>
      </datafield>
      <datafield tag="697" repeat="R" desc="Local subject added entry — corporate name">
        <ind1 values="012" desc="Type of corporate name entry element"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
        <subfield code="b" repeat="R" desc="Subordinate unit"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <subfield code="9" repeat="NR" desc="Special entry"/>
      </datafield>
      <datafield tag="698" repeat="R" desc="Local subject added entry — meeting name">
        <ind1 values="012" desc="Type of meeting name entry element"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="NR" desc="Date of meeting"/>
        <subfield code="e" repeat="R" desc="Subordinate unit"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="j" repeat="R" desc="Relator term"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <subfield code="9" repeat="NR" desc="Special entry"/>
      </datafield>
      <datafield tag="699" repeat="R" desc="Local subject added entry — uniform title">
        <ind1 values="0-9" desc="Nonfiling characters"/>
        <ind2 values="0-7" desc="Thesaurus"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="v" repeat="R" desc="Form subdivision"/>
        <subfield code="x" repeat="R" desc="General subdivision"/>
        <subfield code="y" repeat="R" desc="Chronological subdivision"/>
        <subfield code="z" repeat="R" desc="Geographic subdivision"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
        <subfield code="9" repeat="NR" desc="Special entry"/>
      </datafield>
      <datafield tag="700" repeat="R" desc="Added entry — personal name">
        <ind1 values="013" desc="Type of personal name entry element"/>
        <ind2 values=" 2" desc="Type of added entry"/>
        <subfield code="a" repeat="NR" desc="Personal name"/>
        <subfield code="b" repeat="NR" desc="Numeration"/>
        <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
        <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="j" repeat="R" desc="Attribution qualifier"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Fuller form of name"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="710" repeat="R" desc="Added entry — corporate name">
        <ind1 values="012" desc="Type of corporate name entry element"/>
        <ind2 values=" 2" desc="Type of added entry"/>
        <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
        <subfield code="b" repeat="R" desc="Subordinate unit"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="711" repeat="R" desc="Added entry — meeting name">
        <ind1 values="012" desc="Type of meeting name entry element"/>
        <ind2 values=" 2" desc="Type of added entry"/>
        <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="NR" desc="Date of meeting"/>
        <subfield code="e" repeat="R" desc="Subordinate unit"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="j" repeat="R" desc="Relator term"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="720" repeat="R" desc="Added entry — uncontrolled name">
        <ind1 values=" 12" desc="Type of name"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="4" repeat="R" desc="Relator code"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="730" repeat="R" desc="Added entry — uniform title">
        <ind1 values="0-9" desc="Nonfiling characters"/>
        <ind2 values=" 2" desc="Type of added entry"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="740" repeat="R" desc="Added entry — uncontrolled related/analytical title">
        <ind1 values="0-9" desc="Nonfiling characters"/>
        <ind2 values=" 2" desc="Type of added entry"/>
        <subfield code="a" repeat="NR" desc="Uncontrolled related/analytical title"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="751" repeat="R" desc="Added entry — geographic name">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Geographic name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="752" repeat="R" desc="Added entry — hierarchical place name">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Country or larger entity"/>
        <subfield code="b" repeat="NR" desc="First-order political jurisdiction"/>
        <subfield code="c" repeat="NR" desc="Intermediate political jurisdiction"/>
        <subfield code="d" repeat="NR" desc="City"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="R" desc="City subsection"/>
        <subfield code="g" repeat="R" desc="Other nonjurisdictional geographic region and feature"/>
        <subfield code="h" repeat="R" desc="Extraterrestrial area"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="753" repeat="R" desc="System details access to computer files">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Make and model of machine"/>
        <subfield code="b" repeat="NR" desc="Programming language"/>
        <subfield code="c" repeat="NR" desc="Operating system"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="754" repeat="R" desc="Added entry — taxonomic identification">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Taxonomic name"/>
        <subfield code="c" repeat="R" desc="Taxonomic category"/>
        <subfield code="d" repeat="R" desc="Common or alternative name"/>
        <subfield code="x" repeat="R" desc="Non-public note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of taxonomic identification"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="758" repeat="R" desc="Resource identifier">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Label"/>
        <subfield code="i" repeat="R" desc="Relationship information"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="760" repeat="R" desc="Main series entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="762" repeat="R" desc="Subseries entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="765" repeat="R" desc="Original language entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="767" repeat="R" desc="Translation entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="770" repeat="R" desc="Supplement/special issue entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="772" repeat="R" desc="Supplement parent entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 08" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Stan dard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="773" repeat="R" desc="Host item entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="p" repeat="NR" desc="Abbreviated title"/>
        <subfield code="q" repeat="NR" desc="Enumeration and first page"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="774" repeat="R" desc="Constituent unit entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="775" repeat="R" desc="Other edition entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="e" repeat="NR" desc="Language code"/>
        <subfield code="f" repeat="NR" desc="Country code">
      <assert test="matches(., $marcCountryCodes)">Subfield $f must match a valid MARC country code</assert>
    </subfield>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="776" repeat="R" desc="Additional physical form entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="777" repeat="R" desc="Issued with entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="780" repeat="R" desc="Preceding entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values="0-7" desc="Type of relationship"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="785" repeat="R" desc="Succeeding entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values="0-8" desc="Type of relationship"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standa rd Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="786" repeat="R" desc="Data source entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="j" repeat="NR" desc="Period of content"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="p" repeat="NR" desc="Abbreviated title"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="v" repeat="NR" desc="Source Contribution"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="787" repeat="R" desc="Nonspecific relationship entry">
        <ind1 values="01" desc="Note controller"/>
        <ind2 values=" 8" desc="Display constant controller"/>
        <subfield code="a" repeat="NR" desc="Main entry heading"/>
        <subfield code="b" repeat="NR" desc="Edition"/>
        <subfield code="c" repeat="NR" desc="Qualifying information"/>
        <subfield code="d" repeat="NR" desc="Place, publisher, and date of publication"/>
        <subfield code="g" repeat="R" desc="Relationship information"/>
        <subfield code="h" repeat="NR" desc="Physical description"/>
        <subfield code="i" repeat="NR" desc="Relationship information"/>
        <subfield code="k" repeat="R" desc="Series data for related item"/>
        <subfield code="m" repeat="NR" desc="Material-specific details"/>
        <subfield code="n" repeat="R" desc="Note"/>
        <subfield code="o" repeat="R" desc="Other item identifier"/>
        <subfield code="r" repeat="R" desc="Report number"/>
        <subfield code="s" repeat="NR" desc="Uniform title"/>
        <subfield code="t" repeat="NR" desc="Title"/>
        <subfield code="u" repeat="NR" desc="Standard Technical Report Number"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="y" repeat="NR" desc="CODEN designation"/>
        <subfield code="z" repeat="R" desc="International Standard Book Number"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="800" repeat="R" desc="Series added entry — personal name">
        <ind1 values="013" desc="Type of personal name entry element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Personal name"/>
        <subfield code="b" repeat="NR" desc="Numeration"/>
        <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
        <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="j" repeat="R" desc="Attribution qualifier"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work "/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Fuller form of name"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="NR" desc="Volume/sequential designation "/>
        <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="810" repeat="R" desc="Series added entry — corporate name">
        <ind1 values="012" desc="Type of corporate name entry element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
        <subfield code="b" repeat="R" desc="Subordinate unit"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
        <subfield code="e" repeat="R" desc="Relator term"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="NR" desc="Volume/sequential designation"/>
        <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="811" repeat="R" desc="Series added entry — meeting name">
        <ind1 values="012" desc="Type of meeting name entry element"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
        <subfield code="c" repeat="NR" desc="Location of meeting"/>
        <subfield code="d" repeat="NR" desc="Date of meeting"/>
        <subfield code="e" repeat="R" desc="Subordinate unit"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="j" repeat="R" desc="Relator term"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="u" repeat="NR" desc="Affiliation"/>
        <subfield code="v" repeat="NR" desc="Volume/sequential designation"/>
        <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="830" repeat="R" desc="Series added entry — uniform title">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values="0-9" desc="Nonfiling characters"/>
        <subfield code="a" repeat="NR" desc="Uniform title"/>
        <subfield code="d" repeat="R" desc="Date of treaty signing"/>
        <subfield code="f" repeat="NR" desc="Date of a work"/>
        <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
        <subfield code="h" repeat="NR" desc="Medium"/>
        <subfield code="k" repeat="R" desc="Form subheading"/>
        <subfield code="l" repeat="NR" desc="Language of a work"/>
        <subfield code="m" repeat="R" desc="Medium of performance for music"/>
        <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
        <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
        <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
        <subfield code="r" repeat="NR" desc="Key for music"/>
        <subfield code="s" repeat="NR" desc="Version"/>
        <subfield code="t" repeat="NR" desc="Title of a work"/>
        <subfield code="v" repeat="NR" desc="Volume/sequential designation"/>
        <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
        <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="1" repeat="R" desc="Real World Object URI"/>
        <subfield code="2" repeat="NR" desc="Source of heading or term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="4" repeat="R" desc="Relationship"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Control subfield"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <!-- Datafields 841-845 typically occur in holdings, not bibliographic records -->
      <datafield tag="841" repeat="NR" desc="Holdings coded data values">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of record">
      <assert test="string-length(.) = 4">Subfield $a must match 4 characters</assert>
      <assert test="matches(substring(., 1, 1), '[acdefgijkmoprt]')">Bibl type code (char 1) must
        match a letter (a, c, d, e, f, g, i, j, k, m, o, p, r, or t)</assert>
      <assert test="matches(substring(., 2, 2), '[\p{Zs}]{2}')">Characters 2 and 3 must be blank</assert>
      <assert test="matches(substring(., 4, 1), '[\p{Zs}a]')">Type of control (char 4) must match a space or a letter (a)</assert>
    </subfield>
        <subfield code="b" repeat="NR" desc="Fixed-length data elements">
      <assert test="string-length(.) = 32">Subfield $b must match 32 characters</assert>
      <assert test="matches(substring(., 1, 6), '\d{6}')">Date entered (chars 1-6) must match 6 digits</assert>
      <assert test="matches(substring(., 7, 1), '[012345]')">Receipt or acquisition status (char 7) must match a digit (0-5)</assert>
      <assert test="matches(substring(., 8, 1), '[cdefglmnpquz]')">Method of acquisition (char 8) must match a letter (c, d, e, f, g, l, m, n, p, q, u, or z)</assert>
      <assert test="matches(substring(., 9, 4), '(\d{4}|\p{Zs}{4}|uuuu)')">Expected acquisition end date (chars 9-12) must match 4 digits, 4 spaces, or 'uuuu'</assert>
      <assert test="matches(substring(., 13, 1), '[012345678]')">General retention policy (char 13) must match a digit (0-8)</assert>
      <assert test="matches(substring(., 14, 3), '(\p{Zs}{3}|[lp][\p{Zs}1-9][mwyeis])')">Specific retention policy (chars 14-16) must match 3 spaces or a letter (l or p), followed by a space or a digit, followed by a letter (m, w, y, e, i, or s)</assert>
      <assert test="matches(substring(., 17, 1), '[01234]')">Completeness (char 17) must match a digit (0-4)</assert>
      <assert test="matches(substring(., 18, 3), '[01][0-9][0-9]')">Number of copies reported (chars 18-20) must match a number, left-justified with zeros</assert>
      <assert test="matches(substring(., 21, 1), '[abclu]')">Lending policy (char 20) must match a letter (a, b, c, l, or u)</assert>
      <assert test="matches(substring(., 22, 1), '[abu]')">Reproduction policy (char 21) must match a letter (a, b, or u)</assert>
      <assert test="matches(substring(., 23, 3), '(\p{Zs}{3}|und)')">Language (chars 23-25) must match 3 spaces or 'und'</assert>
      <assert test="matches(substring(., 26, 1), '[01]')">Separate or composite copy report (char 26) must match a digit (0-1)</assert>
      <assert test="matches(substring(., 27, 6), '\d{6}')">Date of report (chars 27-32) must match 6 digits</assert>
    </subfield>
        <subfield code="e" repeat="NR" desc="Encoding level">
      <assert test="matches(., '^[12345muz]$')">must match a digit (1-5) or a letter (m, u, or z)</assert>
    </subfield>
      </datafield>
      <datafield tag="842" repeat="NR" desc="Textual physical form designator">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Textual physical form designator"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="843" repeat="R" desc="Reproduction note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Type of reproduction"/>
        <subfield code="b" repeat="R" desc="Place of reproduction"/>
        <subfield code="c" repeat="R" desc="Agency responsible for reproduction"/>
        <subfield code="d" repeat="NR" desc="Date of reproduction"/>
        <subfield code="e" repeat="NR" desc="Physical description of reproduction"/>
        <subfield code="f" repeat="R" desc="Series statement of reproduction"/>
        <subfield code="m" repeat="R" desc="Dates and/or sequential designation of issues reproduced"/>
        <subfield code="n" repeat="R" desc="Note about reproduction"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Fixed-length data elements of reproduction">
      <assert test="matches(substring(., 1, 1), '[besikmptnqcdu]')">Type of date/publication status
    flag (char 7) must match a letter (b, e, s, i, k, m, p, t, n, q, c, d, or u)</assert>
      <assert test="matches(substring(., 2, 4), '[0-9]{4}|[\p{Zs}u\\\|]{4}|[0-9\p{Zs}u\\\|]{4}')">Date 1 (chars 2-5) must match 4 digits, 4 "fill characters" (space, backslash, pipe, or 'u')
    or 1 or more digits followed by "fill characters"</assert>
      <assert test="matches(substring(., 6, 4), '[0-9]{4}|[\p{Zs}u\\\|]{4}|[0-9\p{Zs}u\\\|]{4}')">Date 2 (chars 6-9) must match 4 digits, 4 "fill characters" (space, backslash, pipe, or
    'u') or 1 or more digits followed by "fill characters"</assert>
      <assert test="matches(substring(., 10, 3), '$marcCountryCodes')">Country code (chars 10-12) must
    match a valid MARC country code</assert>
      <assert test="matches(substring(., 13, 1), '[\p{Zs}a-kmnqtuwz]')">Frequency (char 13) must match a space or a letter (a-k, m-n, q, t, u,w, or z)</assert>
      <assert test="matches(substring(., 14, 1), '[\p{Zs}nrxu]')">Regularity (char 14) must match a space or a letter (n, r, x, or u)</assert>
      <assert test="matches(substring(., 15, 1), '[\p{Zs}a-dfoqrs\|]')">Form of item (char 15) must match a space, a letter (a-d, f, o, q, r, or s), or a pipe</assert>
    </subfield>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="844" repeat="NR" desc="Name of unit">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Name of unit"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="845" repeat="R" desc="Terms governing use and reproduction note">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Terms governing use and reproduction"/>
        <subfield code="b" repeat="NR" desc="Jurisdiction"/>
        <subfield code="c" repeat="NR" desc="Authorization"/>
        <subfield code="d" repeat="NR" desc="Authorized users"/>
        <subfield code="f" repeat="R" desc="Use and reproduction rights"/>
        <subfield code="g" repeat="R" desc="Availability date"/>
        <subfield code="q" repeat="NR" desc="Supplying agency"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="2" repeat="NR" desc="Source of term"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="5" repeat="R" desc="Institution to which field applies"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="850" repeat="R" desc="Holding institution">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Holding institution"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="852" repeat="R" desc="Location">
        <ind1 values=" 012345678" desc="Shelving scheme"/>
        <ind2 values=" 012" desc="Shelving order"/>
        <subfield code="a" repeat="NR" desc="Location"/>
        <subfield code="b" repeat="R" desc="Sublocation or collection"/>
        <subfield code="c" repeat="R" desc="Shelving location"/>
        <subfield code="d" repeat="R" desc="Former shelving location"/>
        <subfield code="e" repeat="R" desc="Address"/>
        <subfield code="f" repeat="R" desc="Coded location qualifier"/>
        <subfield code="g" repeat="R" desc="Non-coded location qualifier"/>
        <subfield code="h" repeat="NR" desc="Classification part"/>
        <subfield code="i" repeat="R" desc="Item part"/>
        <subfield code="j" repeat="NR" desc="Shelving control number"/>
        <subfield code="k" repeat="R" desc="Call number prefix"/>
        <subfield code="l" repeat="NR" desc="Shelving form of title"/>
        <subfield code="m" repeat="R" desc="Call number suffix"/>
        <subfield code="n" repeat="NR" desc="Country code">
      <assert test="matches(., $marcCountryCodes)">Subfield $n must match a valid MARC country code</assert>
    </subfield>
        <subfield code="p" repeat="NR" desc="Piece designation"/>
        <subfield code="q" repeat="NR" desc="Piece physical condition"/>
        <subfield code="s" repeat="R" desc="Copyright article-fee code"/>
        <subfield code="t" repeat="NR" desc="Copy number"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="Source of classification or shelving scheme"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Sequence number"/>
      </datafield>
      <!-- Datafields 853-855 typically occur in holdings, not bibliographic records -->
      <datafield tag="853" repeat="R" desc="Captions and pattern — basic bibliographic unit">
        <ind1 values="0123" desc="Compressibility and expandability"/>
        <ind2 values="0123" desc="Caption evaluation"/>
        <subfield code="a" repeat="NR" desc="First level of enumeration"/>
        <subfield code="b" repeat="NR" desc="Second level of enumeration"/>
        <subfield code="c" repeat="NR" desc="Third level of enumeration"/>
        <subfield code="d" repeat="NR" desc="Fourth level of enumeration"/>
        <subfield code="e" repeat="NR" desc="Fifth level of enumeration"/>
        <subfield code="f" repeat="NR" desc="Sixth level of enumeration"/>
        <subfield code="g" repeat="NR" desc="Alternative numbering scheme, first level of enumeration"/>
        <subfield code="h" repeat="NR" desc="Alternative numbering scheme, second level of enumeration"/>
        <subfield code="i" repeat="NR" desc="First level of chronology"/>
        <subfield code="j" repeat="NR" desc="Second level of chronology"/>
        <subfield code="k" repeat="NR" desc="Third level of chronology"/>
        <subfield code="l" repeat="NR" desc="Fourth level of chronology"/>
        <subfield code="m" repeat="NR" desc="Alternative numbering scheme, chronology"/>
        <subfield code="n" repeat="NR" desc="Pattern note"/>
        <subfield code="p" repeat="NR" desc="Number of pieces per issuance"/>
        <subfield code="u" repeat="R" desc="Bibliographic units per next higher level"/>
        <subfield code="v" repeat="R" desc="Numbering continuity"/>
        <subfield code="w" repeat="NR" desc="Frequency"/>
        <subfield code="x" repeat="NR" desc="Calendar change"/>
        <subfield code="y" repeat="R" desc="Regularity pattern"/>
        <subfield code="z" repeat="R" desc="Numbering scheme"/>
        <subfield code="o" repeat="R" desc="Type of unit"/>
        <subfield code="t" repeat="NR" desc="Cp[u"/>
        <subfield code="2" repeat="R" desc="Source of caption abbreviation"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="854" repeat="R" desc="Captions and pattern — supplementary material">
        <ind1 values="0123" desc="Compressibility and expandability"/>
        <ind2 values="0123" desc="Caption evaluation"/>
        <subfield code="a" repeat="NR" desc="First level of enumeration"/>
        <subfield code="b" repeat="NR" desc="Second level of enumeration"/>
        <subfield code="c" repeat="NR" desc="Third level of enumeration"/>
        <subfield code="d" repeat="NR" desc="Fourth level of enumeration"/>
        <subfield code="e" repeat="NR" desc="Fifth level of enumeration"/>
        <subfield code="f" repeat="NR" desc="Sixth level of enumeration"/>
        <subfield code="g" repeat="NR" desc="Alternative numbering scheme, first level of enumeration"/>
        <subfield code="h" repeat="NR" desc="Alternative numbering scheme, second level of enumeration"/>
        <subfield code="i" repeat="NR" desc="First level of chronology"/>
        <subfield code="j" repeat="NR" desc="Second level of chronology"/>
        <subfield code="k" repeat="NR" desc="Third level of chronology"/>
        <subfield code="l" repeat="NR" desc="Fourth level of chronology"/>
        <subfield code="m" repeat="NR" desc="Alternative numbering scheme, chronology"/>
        <subfield code="n" repeat="NR" desc="Pattern note"/>
        <subfield code="p" repeat="NR" desc="Number of pieces per issuance"/>
        <subfield code="u" repeat="R" desc="Bibliographic units per next higher level"/>
        <subfield code="v" repeat="R" desc="Numbering continuity"/>
        <subfield code="w" repeat="NR" desc="Frequency"/>
        <subfield code="x" repeat="NR" desc="Calendar change"/>
        <subfield code="y" repeat="R" desc="Regularity pattern"/>
        <subfield code="z" repeat="R" desc="Numbering scheme"/>
        <subfield code="o" repeat="R" desc="Type of unit"/>
        <subfield code="t" repeat="NR" desc="Cp[u"/>
        <subfield code="2" repeat="R" desc="Source of caption abbreviation"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="855" repeat="R" desc="Captions and pattern — indexes">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="First level of enumeration"/>
        <subfield code="b" repeat="NR" desc="Second level of enumeration"/>
        <subfield code="c" repeat="NR" desc="Third level of enumeration"/>
        <subfield code="d" repeat="NR" desc="Fourth level of enumeration"/>
        <subfield code="e" repeat="NR" desc="Fifth level of enumeration"/>
        <subfield code="f" repeat="NR" desc="Sixth level of enumeration"/>
        <subfield code="g" repeat="NR" desc="Alternative numbering scheme, first level of enumeration"/>
        <subfield code="h" repeat="NR" desc="Alternative numbering scheme, second level of enumeration"/>
        <subfield code="i" repeat="NR" desc="First level of chronology"/>
        <subfield code="j" repeat="NR" desc="Second level of chronology"/>
        <subfield code="k" repeat="NR" desc="Third level of chronology"/>
        <subfield code="l" repeat="NR" desc="Fourth level of chronology"/>
        <subfield code="m" repeat="NR" desc="Alternative numbering scheme, chronology"/>
        <subfield code="n" repeat="NR" desc="Pattern note"/>
        <subfield code="p" repeat="NR" desc="Number of pieces per issuance"/>
        <subfield code="u" repeat="R" desc="Bibliographic units per next higher level"/>
        <subfield code="v" repeat="R" desc="Numbering continuity"/>
        <subfield code="w" repeat="NR" desc="Frequency"/>
        <subfield code="x" repeat="NR" desc="Calendar change"/>
        <subfield code="y" repeat="R" desc="Regularity pattern"/>
        <subfield code="z" repeat="R" desc="Numbering scheme"/>
        <subfield code="o" repeat="R" desc="Type of unit"/>
        <subfield code="t" repeat="NR" desc="Cp[u"/>
        <subfield code="2" repeat="R" desc="Source of caption abbreviation"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="856" repeat="R" desc="Electronic location and access">
        <ind1 values=" 012347" desc="Access method"/>
        <ind2 values=" 0128" desc="Relationship"/>
        <subfield code="a" repeat="R" desc="Host name"/>
        <subfield code="b" repeat="R" desc="Access number"/>
        <subfield code="c" repeat="R" desc="Compression information"/>
        <subfield code="d" repeat="R" desc="Path"/>
        <subfield code="f" repeat="R" desc="Electronic name"/>
        <subfield code="h" repeat="NR" desc="Processor of request"/>
        <subfield code="i" repeat="R" desc="Instruction"/>
        <subfield code="j" repeat="NR" desc="Bits per second"/>
        <subfield code="k" repeat="NR" desc="Password"/>
        <subfield code="l" repeat="NR" desc="Logon"/>
        <subfield code="m" repeat="R" desc="Contact for access assistance"/>
        <subfield code="n" repeat="NR" desc="Name of location of host"/>
        <subfield code="o" repeat="NR" desc="Operating system"/>
        <subfield code="p" repeat="NR" desc="Port"/>
        <subfield code="q" repeat="NR" desc="Electronic format type"/>
        <subfield code="r" repeat="NR" desc="Settings"/>
        <subfield code="s" repeat="R" desc="File size"/>
        <subfield code="t" repeat="R" desc="Terminal emulation"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
        <subfield code="v" repeat="R" desc="Hours access method available"/>
        <subfield code="w" repeat="R" desc="Record control number"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="y" repeat="R" desc="Link text"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="Access method"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="7" repeat="NR" desc="Access status"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <!-- Datafields 863-878 do not occur in bibliographic records -->
      <datafield tag="863" repeat="R" desc="Enumeration and chronology — basic bibliographic unit">
        <ind1 values=" 345" desc="Field encoding level" repeat=""/>
        <ind2 values=" 01234" desc="Form of holdings" repeat=""/>
        <subfield code="a" desc="First level of enumeration" repeat="NR"/>
        <subfield code="b" desc="Second level of enumeration" repeat="NR"/>
        <subfield code="c" desc="Third level of enumeration" repeat="NR"/>
        <subfield code="d" desc="Fourth level of enumeration" repeat="NR"/>
        <subfield code="e" desc="Fifth level of enumeration" repeat="NR"/>
        <subfield code="f" desc="Sixth level of enumeration" repeat="NR"/>
        <subfield code="g" desc="Alternative numbering scheme, first level of enumeration" repeat="NR"/>
        <subfield code="h" desc="Alternative numbering scheme, second level of enumeration" repeat="NR"/>
        <subfield code="i" desc="First level of chronology" repeat="NR"/>
        <subfield code="j" desc="Second level of chronology" repeat="NR"/>
        <subfield code="k" desc="Third level of chronology" repeat="NR"/>
        <subfield code="l" desc="Fourth level of chronology" repeat="NR"/>
        <subfield code="m" desc="Alternative numbering scheme, chronology" repeat="NR"/>
        <subfield code="v" desc="Issuing date" repeat="R"/>
        <subfield code="n" desc="Converted Gregorian year" repeat="NR"/>
        <subfield code="o" desc="Title of unit" repeat="R"/>
        <subfield code="p" desc="Piece designation" repeat="NR"/>
        <subfield code="q" desc="Piece physical condition" repeat="NR"/>
        <subfield code="s" desc="Copyright article-fee code" repeat="R"/>
        <subfield code="t" desc="Copy number" repeat="NR"/>
        <subfield code="w" desc="Break indicator" repeat="NR"/>
        <subfield code="x" desc="Nonpublic note" repeat="R"/>
        <subfield code="z" desc="Public note" repeat="R"/>
        <subfield code="6" desc="Linkage" repeat="NR"/>
        <subfield code="8" desc="Field link and sequence number" repeat="NR"/>
      </datafield>
      <datafield tag="864" repeat="R" desc="Enumeration and chronology — supplementary material">
        <ind1 values=" 345" desc="Field encoding level" repeat=""/>
        <ind2 values=" 01234" desc="Form of holdings" repeat=""/>
        <subfield code="a" desc="First level of enumeration" repeat="NR"/>
        <subfield code="b" desc="Second level of enumeration" repeat="NR"/>
        <subfield code="c" desc="Third level of enumeration" repeat="NR"/>
        <subfield code="d" desc="Fourth level of enumeration" repeat="NR"/>
        <subfield code="e" desc="Fifth level of enumeration" repeat="NR"/>
        <subfield code="f" desc="Sixth level of enumeration" repeat="NR"/>
        <subfield code="g" desc="Alternative numbering scheme, first level of enumeration" repeat="NR"/>
        <subfield code="h" desc="Alternative numbering scheme, second level of enumeration" repeat="NR"/>
        <subfield code="i" desc="First level of chronology" repeat="NR"/>
        <subfield code="j" desc="Second level of chronology" repeat="NR"/>
        <subfield code="k" desc="Third level of chronology" repeat="NR"/>
        <subfield code="l" desc="Fourth level of chronology" repeat="NR"/>
        <subfield code="m" desc="Alternative numbering scheme, chronology" repeat="NR"/>
        <subfield code="v" desc="Issuing date" repeat="R"/>
        <subfield code="n" desc="Converted Gregorian year" repeat="NR"/>
        <subfield code="o" desc="Title of unit" repeat="R"/>
        <subfield code="p" desc="Piece designation" repeat="NR"/>
        <subfield code="q" desc="Piece physical condition" repeat="NR"/>
        <subfield code="s" desc="Copyright article-fee code" repeat="R"/>
        <subfield code="t" desc="Copy number" repeat="NR"/>
        <subfield code="w" desc="Break indicator" repeat="NR"/>
        <subfield code="x" desc="Nonpublic note" repeat="R"/>
        <subfield code="z" desc="Public note" repeat="R"/>
        <subfield code="6" desc="Linkage" repeat="NR"/>
        <subfield code="8" desc="Field link and sequence number" repeat="NR"/>
      </datafield>
      <datafield tag="865" repeat="R" desc="Enumeration and chronology — indexes">
        <ind1 values=" 345" desc="Field encoding level" repeat=""/>
        <ind2 values=" 01234" desc="Form of holdings" repeat=""/>
        <subfield code="a" desc="First level of enumeration" repeat="NR"/>
        <subfield code="b" desc="Second level of enumeration" repeat="NR"/>
        <subfield code="c" desc="Third level of enumeration" repeat="NR"/>
        <subfield code="d" desc="Fourth level of enumeration" repeat="NR"/>
        <subfield code="e" desc="Fifth level of enumeration" repeat="NR"/>
        <subfield code="f" desc="Sixth level of enumeration" repeat="NR"/>
        <subfield code="g" desc="Alternative numbering scheme, first level of enumeration" repeat="NR"/>
        <subfield code="h" desc="Alternative numbering scheme, second level of enumeration" repeat="NR"/>
        <subfield code="i" desc="First level of chronology" repeat="NR"/>
        <subfield code="j" desc="Second level of chronology" repeat="NR"/>
        <subfield code="k" desc="Third level of chronology" repeat="NR"/>
        <subfield code="l" desc="Fourth level of chronology" repeat="NR"/>
        <subfield code="m" desc="Alternative numbering scheme, chronology" repeat="NR"/>
        <subfield code="v" desc="Issuing date" repeat="R"/>
        <subfield code="n" desc="Converted Gregorian year" repeat="NR"/>
        <subfield code="o" desc="Title of unit" repeat="R"/>
        <subfield code="p" desc="Piece designation" repeat="NR"/>
        <subfield code="q" desc="Piece physical condition" repeat="NR"/>
        <subfield code="s" desc="Copyright article-fee code" repeat="R"/>
        <subfield code="t" desc="Copy number" repeat="NR"/>
        <subfield code="w" desc="Break indicator" repeat="NR"/>
        <subfield code="x" desc="Nonpublic note" repeat="R"/>
        <subfield code="z" desc="Public note" repeat="R"/>
        <subfield code="6" desc="Linkage" repeat="NR"/>
        <subfield code="8" desc="Field link and sequence number" repeat="NR"/>
      </datafield>
      <datafield tag="866" repeat="R" desc="Textual holdings — basic bibliographic unit">
        <ind1 values=" 345" desc="Field encoding level"/>
        <ind2 values="0127" desc="Type of notation"/>
        <subfield code="a" repeat="NR" desc="Textual holdings"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="Source of notation"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="867" repeat="R" desc="Textual holdings — supplementary material">
        <ind1 values=" 345" desc="Field encoding level"/>
        <ind2 values="0127" desc="Type of notation"/>
        <subfield code="a" repeat="NR" desc="Textual holdings"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="Source of notation"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="868" repeat="R" desc="Textual holdings — indexes">
        <ind1 values=" 345" desc="Field encoding level"/>
        <ind2 values="0127" desc="Type of notation"/>
        <subfield code="a" repeat="NR" desc="Textual holdings"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="2" repeat="NR" desc="Source of notation"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="876" repeat="R" desc="Item information — basic bibliographic unit">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Internal item number"/>
        <subfield code="b" repeat="R" desc="Invalid or conceled internal item number"/>
        <subfield code="c" repeat="R" desc="Cost"/>
        <subfield code="d" repeat="R" desc="Date acquired"/>
        <subfield code="e" repeat="R" desc="Source of acquisition"/>
        <subfield code="h" repeat="R" desc="Use restrictions"/>
        <subfield code="j" repeat="R" desc="Item status"/>
        <subfield code="l" repeat="R" desc="Temporary location"/>
        <subfield code="p" repeat="R" desc="Piece designation"/>
        <subfield code="r" repeat="R" desc="Invalid or canceled piece designation"/>
        <subfield code="t" repeat="NR" desc="Copy number"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="877" repeat="R" desc="Item information — supplementary material">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Internal item number"/>
        <subfield code="b" repeat="R" desc="Invalid or conceled internal item number"/>
        <subfield code="c" repeat="R" desc="Cost"/>
        <subfield code="d" repeat="R" desc="Date acquired"/>
        <subfield code="e" repeat="R" desc="Source of acquisition"/>
        <subfield code="h" repeat="R" desc="Use restrictions"/>
        <subfield code="j" repeat="R" desc="Item status"/>
        <subfield code="l" repeat="R" desc="Temporary location"/>
        <subfield code="p" repeat="R" desc="Piece designation"/>
        <subfield code="r" repeat="R" desc="Invalid or canceled piece designation"/>
        <subfield code="t" repeat="NR" desc="Copy number"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="878" repeat="R" desc="Item information — indexes">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Internal item number"/>
        <subfield code="b" repeat="R" desc="Invalid or conceled internal item number"/>
        <subfield code="c" repeat="R" desc="Cost"/>
        <subfield code="d" repeat="R" desc="Date acquired"/>
        <subfield code="e" repeat="R" desc="Source of acquisition"/>
        <subfield code="h" repeat="R" desc="Use restrictions"/>
        <subfield code="j" repeat="R" desc="Item status"/>
        <subfield code="l" repeat="R" desc="Temporary location"/>
        <subfield code="p" repeat="R" desc="Piece designation"/>
        <subfield code="r" repeat="R" desc="Invalid or canceled piece designation"/>
        <subfield code="t" repeat="NR" desc="Copy number"/>
        <subfield code="x" repeat="R" desc="Nonpublic note"/>
        <subfield code="z" repeat="R" desc="Public note"/>
        <subfield code="3" repeat="NR" desc="Materials specified"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="NR" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="880" repeat="R" desc="Alternate graphic representation">
        <!-- Field 880 should obey the rules of the field to which it is linked via its
      subfield $6 -->
        <ind1 values=" 0-9" desc="Same as associated field"/>
        <ind2 values=" 0-9" desc="Same as associated field"/>
        <subfield code="a-z0-9" repeat="R" desc="Same as associated field"/>
        <subfield code="6" repeat="NR" desc="Linkage" occurs="M"/>
      </datafield>
      <datafield tag="882" repeat="NR" desc="Replacement record information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Replacement title"/>
        <subfield code="i" repeat="R" desc="Explanatory text"/>
        <subfield code="w" repeat="R" desc="Replacement bibliographic record control number"/>
        <subfield code="6" repeat="NR" desc="Linkage"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="883" repeat="R" desc="Metadata provenance">
        <ind1 values=" 012" desc="Method of assignment"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Creation process"/>
        <subfield code="c" repeat="NR" desc="Confidence value"/>
        <subfield code="d" repeat="NR" desc="Creation date"/>
        <subfield code="q" repeat="NR" desc="Assigning or generating agency"/>
        <subfield code="x" repeat="NR" desc="Validity end date"/>
        <subfield code="u" repeat="NR" desc="Uniform Resource Identifier"/>
        <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
        <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
        <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      </datafield>
      <datafield tag="884" repeat="R" desc="Description conversion information">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Conversion process"/>
        <subfield code="g" repeat="NR" desc="Conversion date"/>
        <subfield code="k" repeat="NR" desc="Identifier of source metadata"/>
        <subfield code="q" repeat="NR" desc="Conversion agency"/>
        <subfield code="u" repeat="R" desc="Uniform Resource Identifier"/>
      </datafield>
      <datafield tag="886" repeat="R" desc="Foreign MARC information field">
        <ind1 values="012" desc="Type of field"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="R" desc="Tag of the foreign MARC field"/>
        <subfield code="b" repeat="R" desc="Content of the foreign MARC field"/>
        <subfield code="c" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="d" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="e" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="f" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="g" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="h" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="i" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="j" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="k" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="l" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="m" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="n" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="o" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="p" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="q" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="r" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="s" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="t" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="u" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="v" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="w" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="x" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="y" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="z" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="0" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="1" repeat="R" desc="Foreign MARC subfield"/>
        <subfield code="2" repeat="R" desc="Source of data"/>
        <subfield code="3" repeat="R" desc="Source of data"/>
        <subfield code="4" repeat="R" desc="Source of data"/>
        <subfield code="5" repeat="R" desc="Source of data"/>
        <subfield code="6" repeat="R" desc="Source of data"/>
        <subfield code="7" repeat="R" desc="Source of data"/>
        <subfield code="8" repeat="R" desc="Source of data"/>
        <subfield code="9" repeat="R" desc="Source of data"/>
      </datafield>
      <datafield tag="887" repeat="R" desc="Non-MARC information field">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Content of non-MARC field"/>
        <subfield code="2" repeat="NR" desc="Source of data"/>
      </datafield>
      <datafield tag="999" repeat="R" desc="Local data">
        <ind1 values=" " desc="Undefined"/>
        <ind2 values=" " desc="Undefined"/>
        <subfield code="a" repeat="NR" desc="Item call number" occurs="M"/>
        <subfield code="v" repeat="NR" desc="Volume number"/>
        <subfield code="w" repeat="NR" desc="Call number sort type" occurs="M"/>
        <subfield code="c" repeat="NR" desc="Copy number"/>
        <subfield code="h" repeat="NR" desc="Holding code"/>
        <subfield code="i" repeat="NR" desc="Item identifier" occurs="M"/>
        <subfield code="m" repeat="NR" desc="Library" occurs="M"/>
        <subfield code="d" repeat="NR" desc="Last activity"/>
        <subfield code="e" repeat="NR" desc="Date last charged"/>
        <subfield code="f" repeat="NR" desc="Date inventoried"/>
        <subfield code="g" repeat="NR" desc="Time inventoried"/>
        <subfield code="j" repeat="NR" desc="Number of pieces"/>
        <subfield code="k" repeat="NR" desc="Checkout status"/>
        <subfield code="l" repeat="NR" desc="Item location" occurs="M"/>
        <subfield code="n" repeat="NR" desc="Total charges"/>
        <subfield code="o" repeat="R" desc="Item notes or comments"/>
        <subfield code="p" repeat="NR" desc="Price"/>
        <subfield code="q" repeat="NR" desc="In-house charges"/>
        <subfield code="r" repeat="NR" desc="Circulate flag"/>
        <subfield code="s" repeat="NR" desc="Permanent flag"/>
        <subfield code="t" repeat="NR" desc="Item type" occurs="M"/>
        <subfield code="u" repeat="NR" desc="Acquisitions date"/>
        <subfield code="x" repeat="NR" desc="Item category 1"/>
        <subfield code="z" repeat="NR" desc="Item category 2"/>
        <subfield code="0" repeat="NR" desc="Item category 3"/>
        <subfield code="1" repeat="NR" desc="Item category 4"/>
        <subfield code="2" repeat="NR" desc="Item category 5"/>
      </datafield>
    </marcDesc>
  </xsl:variable>

  <!-- ======================================================================= -->
  <!-- UTILITIES / NAMED TEMPLATES                                             -->
  <!-- ======================================================================= -->

  <!-- Join non-repeatable subfields into a single subfield -->
  <xsl:template name="compressSubfields">
    <xsl:param name="tag"/>
    <xsl:param name="subfieldList"/>
    <!-- First subfield on the "stack" in $subfieldList -->
    <xsl:variable name="left">
      <xsl:value-of select="$subfieldList//*:subfield[1]/@code"/>
    </xsl:variable>
    <!-- Repeatability of the first subfield -->
    <xsl:variable name="repeat">
      <xsl:value-of
        select="$marcDatafieldDesc//*:datafield[@tag = $tag]/*:subfield[@code = $left]/@repeat"/>
    </xsl:variable>
    <xsl:choose>
      <!-- Non-repeatable subfield -->
      <xsl:when test="$repeat = 'NR'">
        <subfield>
          <xsl:attribute name="code">
            <xsl:value-of select="$left"/>
          </xsl:attribute>
          <xsl:variable name="separator">
            <xsl:choose>
              <xsl:when test="$subfieldList//*:subfield[@code = $left][matches(normalize-space(.), '[\.,;:/]$')]">
                <xsl:text>&#32;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>;&#32;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="string-join($subfieldList//*:subfield[@code = $left], $separator)"/>
        </subfield>
      </xsl:when>
      <!-- Repeatable subfield -->
      <xsl:otherwise>
        <subfield>
          <xsl:attribute name="code">
            <xsl:value-of select="$left"/>
          </xsl:attribute>
          <xsl:value-of select="$subfieldList//*:subfield[1]"/>
        </subfield>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Adjust list of remaining subfields based on repeatability of the subfield just processed -->
    <xsl:variable name="remainingSubfields">
      <xsl:choose>
        <xsl:when test="$repeat = 'NR'">
          <xsl:copy-of select="$subfieldList//*:subfield[position() &gt; 1 and @code != $left]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$subfieldList//*:subfield[position() &gt; 1]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- If there are subfields remaining, recurse -->
    <xsl:if test="$remainingSubfields//*:subfield">
      <xsl:call-template name="compressSubfields">
        <xsl:with-param name="tag">
          <xsl:value-of select="$tag"/>
        </xsl:with-param>
        <xsl:with-param name="subfieldList">
          <xsl:copy-of select="$remainingSubfields"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Create 008 based on type of material -->
  <xsl:template name="materialSpecific008">
    <xsl:choose>
      <!-- BK -->
      <xsl:when
        test="matches(substring(../*:leader, 7, 1), '[at]') and matches(substring(../*:leader, 8, 1), '[acdm]')">
        <xsl:variable name="illus">
          <xsl:choose>
            <!-- Keep letters, fill remaining positions with spaces -->
            <xsl:when
              test="matches(substring(., 19, 4), '\p{Zs}{4}|\|{4}|[a-mop]{4}|[a-mop]{3}\p{Zs}|[a-mop]{2}\p{Zs}{2}|[a-mop]\p{Zs}{3}')">
              <xsl:value-of select="substring(., 19, 4)"/>
            </xsl:when>
            <!-- Fill with 'no attempt to code' value -->
            <xsl:otherwise>
              <xsl:text>||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <!-- Keep compliant value -->
            <xsl:when test="matches(substring(., 23, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 23, 1)"/>
            </xsl:when>
            <!-- Fill with 'no attempt to code' value -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 24, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 24, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:choose>
            <!-- Keep letters, fill remaining positions with spaces -->
            <xsl:when
              test="matches(substring(., 25, 4), '[a-gij-wyz256]{4}|\|{4}|\p{Zs}{4}|[a-gij-wyz256]{3}(\p{Zs}|\|)|[a-gij-wyz256]{2}(\p{Zs}{2}|\|{2})|[a-gij-wyz256](\p{Zs}{3}|\|{3})')">
              <xsl:value-of select="substring(., 25, 4)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 29, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 29, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 30, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 30, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="festschrift">
          <xsl:choose>
            <xsl:when test="matches(substring(., 31, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 31, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:choose>
            <xsl:when test="matches(substring(., 32, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 32, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef33">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="litForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 34, 1), '[01defhijmpsu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 34, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="biography">
          <xsl:choose>
            <xsl:when test="matches(substring(., 35, 1), '[\p{Zs}a-d\|]')">
              <xsl:value-of select="substring(., 35, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of
          select="concat($illus, $audience, $itemForm, $contentNature, $govPub, $confPub, $festschrift, $index, $undef33, $litForm, $biography)"
        />
      </xsl:when>
      <!-- CF -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[m]')">
        <xsl:variable name="undef19">
          <xsl:text>||||</xsl:text>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <xsl:when test="matches(substring(., 23, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 23, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 24, 1), '[\p{Zs}oq\|]')">
              <xsl:value-of select="substring(., 24, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef25">
          <xsl:text>||</xsl:text>
        </xsl:variable>
        <xsl:variable name="fileType">
          <xsl:choose>
            <xsl:when test="matches(substring(., 27, 1), '[a-jmuz\|]')">
              <xsl:value-of select="substring(., 27, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef28">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 29, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 29, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef30">
          <xsl:text>||||||</xsl:text>
        </xsl:variable>
        <xsl:value-of
          select="concat($undef19, $audience, $itemForm, $undef25, $fileType, $undef28, $govPub, $undef30)"
        />
      </xsl:when>
      <!-- MP -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[ef]')">
        <xsl:variable name="relief">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 19, 4), '[a-gijkmz]{4}|\|{4}|\p{Zs}{4}|[a-gijkmz]{3}\p{Zs}|[a-gijkmz]{2}\p{Zs}{2}|[a-gijkmz]\p{Zs}{3}')">
              <xsl:value-of select="substring(., 19, 4)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="projection">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 23, 2), '(\p{Zs}\p{Zs}|aa|ab|ac|ad|ae|af|ag|am|an|ap|au|az|ba|bb|bc|bd|be|bf|bg|bh|bi|bj|bk|bl|bo|br|bs|bu|bz|ca|cb|cc|ce|cp|cu|cz|da|db|dc|dd|de|df|dg|dh|dl|zz|\|\|)')">
              <xsl:value-of select="substring(., 23, 2)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef25">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="cartographicType">
          <xsl:choose>
            <xsl:when test="matches(substring(., 26, 1), '[a-guz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 26, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef27">
          <xsl:text>||</xsl:text>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 29, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 29, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 30, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 30, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef31">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:choose>
            <xsl:when test="matches(substring(., 32, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 32, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef33">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="specialFormat">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 34, 2), '[ejklnoprz]{2}|\|{2}|\p{Zs}{2}|[ejklnoprz]{1}\p{Zs}')">
              <xsl:value-of select="substring(., 34, 2)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of
          select="concat($relief, $projection, $undef25, $cartographicType, $undef27, $govPub, $itemForm, $undef31, $index, $undef33, $specialFormat)"
        />
      </xsl:when>
      <!-- MU -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[cdij]')">
        <xsl:variable name="compositionForm">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 19, 2), '(an|bd|bg|bl|bt|ca|cb|cc|cg|ch|cl|cn|co|cp|cr|cs|ct|cy|cz|df|dv|fg|fl|fm|ft|gm|hy|jz|mc|md|mi|mo|mp|mr|ms|mu|mz|nc|nn|op|or|ov|pg|pm|po|pp|pr|ps|pt|pv|rc|rd|rg|ri|rp|rq|sd|sg|sn|sp|st|su|sy|tc|tl|ts|uu|vi|vr|wz|za|zz|\|\||\p{Zs}\p{Zs})')">
              <xsl:value-of select="substring(., 19, 2)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="musicFormat">
          <xsl:choose>
            <xsl:when test="matches(substring(., 21, 1), '[a-eg-npuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 21, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="musicParts">
          <xsl:choose>
            <xsl:when test="matches(substring(., 22, 1), '[\p{Zs}defnu\|]')">
              <xsl:value-of select="substring(., 22, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <xsl:when test="matches(substring(., 23, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 23, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 24, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 24, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="accMatter">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 25, 6), '[a-ikrsz]{6}|[\p{Zs}\|]{6}|[a-ikrsz]{5}[\p{Zs}\|]|[a-ikrsz]{4}[\p{Zs}\|]{2}|[a-ikrsz]{3}[\p{Zs}\|]{3}|[a-ikrsz]{2}[\p{Zs}\|]{4}|[a-ikrsz][\p{Zs}\|]{5}')">
              <xsl:value-of select="substring(., 25, 6)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="literaryText">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 31, 2), '[a-prstz]{2}|\|{2}|\p{Zs}{2}|[a-prstz]\p{Zs}')">
              <xsl:value-of select="substring(., 31, 2)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef33">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="transpoArrangement">
          <xsl:choose>
            <xsl:when test="matches(substring(., 34, 1), '[\p{Zs}abcnu\|]')">
              <xsl:value-of select="substring(., 34, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef35">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:value-of
          select="concat($compositionForm, $musicFormat, $musicParts, $audience, $itemForm, $accMatter, $literaryText, $undef33, $transpoArrangement, $undef35)"
        />
      </xsl:when>
      <!-- CR -->
      <xsl:when
        test="matches(substring(../*:leader, 7, 1), '[a]') and matches(substring(../*:leader, 8, 1), '[bis]')">
        <xsl:variable name="frequency">
          <xsl:choose>
            <xsl:when test="matches(substring(., 19, 1), '[\p{Zs}a-kmqstuwz\|]')">
              <xsl:value-of select="substring(., 19, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="regularity">
          <xsl:choose>
            <xsl:when test="matches(substring(., 20, 1), '[nrux\|\p{Zs}]')">
              <xsl:value-of select="substring(., 20, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef21">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="resourceType">
          <xsl:choose>
            <xsl:when test="matches(substring(., 22, 1), '[\p{Zs}dlmnpw\|]')">
              <xsl:value-of select="substring(., 22, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="originalForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 23, 1), '[\p{Zs}a-foqs\|]')">
              <xsl:value-of select="substring(., 23, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 24, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 24, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="workNature">
          <xsl:choose>
            <xsl:when test="matches(substring(., 25, 1), '[\p{Zs}a-ik-wyz56\|]')">
              <xsl:value-of select="substring(., 25, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 26, 3), '[a-ik-wyz56]{3}|\|{3}|\p{Zs}{3}|[a-ik-wyz56]{2}\p{Zs}|[a-ik-wyz56]\p{Zs}{2}')">
              <xsl:value-of select="substring(., 26, 3)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 29, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 29, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 30, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 30, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef31">
          <xsl:text>|||</xsl:text>
        </xsl:variable>
        <xsl:variable name="alphaScript">
          <xsl:choose>
            <xsl:when test="matches(substring(., 34, 1), '[\p{Zs}a-luz\|]')">
              <xsl:value-of select="substring(., 34, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="entryConvention">
          <xsl:choose>
            <xsl:when test="matches(substring(., 35, 1), '[012\|\p{Zs}]')">
              <xsl:value-of select="substring(., 35, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of
          select="concat($frequency, $regularity, $undef21, $resourceType, $originalForm, $itemForm, $workNature, $contentNature, $govPub, $confPub, $undef31, $alphaScript, $entryConvention)"
        />
      </xsl:when>
      <!-- VM -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[gkor]')">
        <xsl:variable name="runningTime">
          <xsl:choose>
            <xsl:when
              test="matches(substring(., 19, 3), '(nnn|\|\|\||00[0-9]|0[1-9][0-9]|[1-9][0-9][0-9])')">
              <xsl:value-of select="substring(., 19, 3)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef22">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <xsl:when test="matches(substring(., 23, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 23, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef24">
          <xsl:text>|||||</xsl:text>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <xsl:when test="matches(substring(., 29, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 29, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 30, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 30, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef31">
          <xsl:text>|||</xsl:text>
        </xsl:variable>
        <xsl:variable name="materialType">
          <xsl:choose>
            <xsl:when test="matches(substring(., 34, 1), '[a-dfgik-tvwz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 34, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="technique">
          <xsl:choose>
            <xsl:when test="matches(substring(., 35, 1), '[aclnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 35, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of
          select="concat($runningTime, $undef22, $audience, $undef24, $govPub, $itemForm, $undef31, $materialType, $technique)"
        />
      </xsl:when>
      <!-- MX -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[p]')">
        <xsl:variable name="undef19">
          <xsl:text>|||||</xsl:text>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <xsl:when test="matches(substring(., 24, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 24, 1)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef26">
          <xsl:text>|||||||||||</xsl:text>
        </xsl:variable>
        <xsl:value-of select="concat($undef19, $itemForm, $undef26)"/>
      </xsl:when>
      <!-- Unknown material -->
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Split over-long 041 subfields into multiple subfields -->
  <xsl:template name="split041subfield">
    <xsl:param name="thisValue"/>
    <xsl:variable name="thisSubfield">
      <xsl:value-of select="@code"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($thisValue) &gt; 3">
        <subfield code="{$thisSubfield}">
          <!-- Fix common incorrect value for Japanese -->
          <xsl:value-of select="replace(substring($thisValue, 1, 3), 'jap', 'jpn')"/>
        </subfield>
        <xsl:variable name="remainder">
          <xsl:value-of select="substring($thisValue, 4)"/>
        </xsl:variable>
        <xsl:call-template name="split041subfield">
          <xsl:with-param name="thisValue">
            <xsl:value-of select="$remainder"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <subfield code="{$thisSubfield}">
          <xsl:value-of select="replace($thisValue, 'jap', 'jpn')"/>
        </subfield>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ======================================================================= -->
  <!-- MAIN OUTPUT TEMPLATE                                                    -->
  <!-- ======================================================================= -->

  <xsl:template match="/">
    <xsl:variable name="phase1">
      <xsl:apply-templates mode="phase1"/>
    </xsl:variable>
    <xsl:apply-templates select="$phase1" mode="phase2"/>
  </xsl:template>

  <!-- ======================================================================= -->
  <!-- MATCH TEMPLATES (phase 1)                                               -->
  <!-- ======================================================================= -->

  <!-- Leader -->
  <xsl:template match="*:leader" mode="phase1">
    <xsl:variable name="recordLength">
      <xsl:value-of select="substring(., 1, 5)"/>
    </xsl:variable>
    <xsl:variable name="recordStatus">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 6, 1), '[acdnp]', 'i'))">n</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 6, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="recordType">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 7, 1), '[acdefgijkmoprt]', 'i'))">|</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 7, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="bibLevel">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 8, 1), '[abcdims]', 'i'))">|</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 8, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="controlType">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 9, 1), '[\sa]', 'i'))">
          <xsl:text>&#32;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 9, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="charCodeScheme">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 10, 1), '[\sa]', 'i'))">
          <xsl:text>a</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 10, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Constant -->
    <xsl:variable name="indicatorCount">
      <xsl:text>2</xsl:text>
    </xsl:variable>
    <xsl:variable name="subfieldCodeCount">
      <xsl:text>2</xsl:text>
    </xsl:variable>
    <xsl:variable name="baseAddress">
      <xsl:value-of select="substring(., 13, 5)"/>
    </xsl:variable>
    <xsl:variable name="encodingLevel">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 18, 1), '[\s1234578uzIJKM]', 'i'))">u</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="translate(substring(., 18, 1), 'UZijkm', 'uzIJKM')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="descriptiveForm">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 19, 1), '[\sacinu]', 'i'))">u</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 19, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="multipleResourceLevel">
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., 20, 1), '[\sabc]', 'i'))">&#32;</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., 20, 1))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <leader>
      <xsl:value-of select="concat($recordLength, $recordStatus, $recordType, $bibLevel, $controlType, $charCodeScheme, $indicatorCount, $subfieldCodeCount, $baseAddress, $encodingLevel, $descriptiveForm, $multipleResourceLevel, '4500')"/>
    </leader>
  </xsl:template>

  <!-- 006 -->
  <xsl:template match="*:controlfield[@tag = '006']" mode="phase1">
    <xsl:choose>
      <!-- BK -->
      <xsl:when test="matches(substring(., 1, 1), '[at]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="illus">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 2, 4), '\p{Zs}{4}|\|{4}|[a-mop]{4}|[a-mop]{3}\p{Zs}|[a-mop]{2}\p{Zs}{2}|[a-mop]\p{Zs}{3}')">
              <xsl:value-of select="substring(., 2, 4)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 2, 4), '[a-mop]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 2, 4), '[^a-mop]', '')"/>
              </xsl:variable>
              <xsl:value-of select="substring(concat($codes, '&#32;&#32;&#32;&#32;'), 1, 4)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 8, 4), '[a-gij-wyz256]{4}|\|{4}|\p{Zs}{4}|[a-gij-wyz256]{3}(\p{Zs}|\|)|[a-gij-wyz256]{2}(\p{Zs}{2}|\|{2})|[a-gij-wyz256](\p{Zs}{3}|\|{3})')">
              <xsl:value-of select="substring(., 8, 4)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 8, 4), '[a-gij-wyz256]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 8, 4), '[^a-gij-wyz256]', '')"/>
              </xsl:variable>
              <xsl:value-of select="substring(concat($codes, '&#32;&#32;&#32;&#32;'), 1, 4)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="festschrift">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 14, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 14, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 15, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 15, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef16">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="litForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 17, 1), '[01defhijmpsu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 17, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="biography">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 18, 1), '[\p{Zs}a-d\|]')">
              <xsl:value-of select="substring(., 18, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $illus, $audience, $itemForm, $contentNature, $govPub, $confPub, $festschrift, $index, $undef16, $litForm, $biography)"/>
        </controlfield>
      </xsl:when>
      <!-- CF -->
      <xsl:when test="matches(substring(., 1, 1), '[m]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef2">
          <xsl:text>||||</xsl:text>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}oq\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef8">
          <xsl:text>||</xsl:text>
        </xsl:variable>
        <xsl:variable name="fileType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 10, 1), '[a-jmuz\|]')">
              <xsl:value-of select="substring(., 10, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef11">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef14">
          <xsl:text>||||||</xsl:text>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $undef2, $audience, $itemForm, $undef8, $fileType, $undef11, $govPub, $undef14)"/>
        </controlfield>
      </xsl:when>
      <!-- MP -->
      <xsl:when test="matches(substring(., 1, 1), '[ef]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="relief">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when
              test="matches(substring(., 2, 4), '[a-gijkmz]{4}|\|{4}|\p{Zs}{4}|[a-gijkmz]{3}\p{Zs}|[a-gijkmz]{2}\p{Zs}{2}|[a-gijkmz]\p{Zs}{3}')">
              <xsl:value-of select="substring(., 2, 4)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 2, 4), '[a-gijkmz]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 2, 4), '[^a-gijkmz]', '')"/>
              </xsl:variable>
              <xsl:value-of select="substring(concat($codes, '&#32;&#32;&#32;&#32;'), 1, 4)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="projection">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 6, 2), '(\p{Zs}\p{Zs}|aa|ab|ac|ad|ae|af|ag|am|an|ap|au|az|ba|bb|bc|bd|be|bf|bg|bh|bi|bj|bk|bl|bo|br|bs|bu|bz|ca|cb|cc|ce|cp|cu|cz|da|db|dc|dd|de|df|dg|dh|dl|zz|\|\|)')">
              <xsl:value-of select="substring(., 6, 2)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef8">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="cartographicType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 9, 1), '[a-guz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 9, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef10">
          <xsl:text>||</xsl:text>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef14">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 15, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 15, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef16">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="specialFormat">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 17, 2), '[ejklnoprz]{2}|\|{2}|\p{Zs}{2}|[ejklnoprz]{1}\p{Zs}')">
              <xsl:value-of select="substring(., 17, 2)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $relief, $projection, $undef8, $cartographicType, $undef10, $govPub, $itemForm, $undef14, $index, $undef16, $specialFormat)"/>
        </controlfield>
      </xsl:when>
      <!-- MU -->
      <xsl:when test="matches(substring(., 1, 1), '[cdij]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="compositionForm">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 2, 2), '(an|bd|bg|bl|bt|ca|cb|cc|cg|ch|cl|cn|co|cp|cr|cs|ct|cy|cz|df|dv|fg|fl|fm|ft|gm|hy|jz|mc|md|mi|mo|mp|mr|ms|mu|mz|nc|nn|op|or|ov|pg|pm|po|pp|pr|ps|pt|pv|rc|rd|rg|ri|rp|rq|sd|sg|sn|sp|st|su|sy|tc|tl|ts|uu|vi|vr|wz|za|zz|\|\||\p{Zs}\p{Zs})')">
              <xsl:value-of select="substring(., 2, 2)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="musicFormat">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[a-eg-npuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="musicParts">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[\p{Zs}defnu\|]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="accMatter">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 8, 6), '[a-ikrsz]{6}|[\p{Zs}\|]{6}|[a-ikrsz]{5}[\p{Zs}\|]|[a-ikrsz]{4}[\p{Zs}\|]{2}|[a-ikrsz]{3}[\p{Zs}\|]{3}|[a-ikrsz]{2}[\p{Zs}\|]{4}|[a-ikrsz][\p{Zs}\|]{5}')">
              <xsl:value-of select="substring(., 8, 6)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 8, 6), '[a-ikrsz]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 8, 6), '[^a-ikrsz]', '')"/>
              </xsl:variable>
              <xsl:value-of
                select="substring(concat($codes, '&#32;&#32;&#32;&#32;&#32;&#32;'), 1, 6)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="literaryText">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 14, 2), '[a-prstz]{2}|\|{2}|\p{Zs}{2}|[a-prstz]\p{Zs}')">
              <xsl:value-of select="substring(., 14, 2)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef16">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="transpoArrangement">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 17, 1), '[\p{Zs}abcnu\|]')">
              <xsl:value-of select="substring(., 17, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef18">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $compositionForm, $musicFormat, $musicParts, $audience, $itemForm, $accMatter, $literaryText, $undef16, $transpoArrangement, $undef18)"/>
        </controlfield>
      </xsl:when>
      <!-- CR -->
      <xsl:when test="matches(substring(., 1, 1), '[s]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="frequency">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[\p{Zs}a-kmqstuwz\|]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="regularity">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 3, 1), '[nrux\|\p{Zs}]')">
              <xsl:value-of select="substring(., 3, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef4">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="resourceType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[\p{Zs}dlmnpw\|]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="originalForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}a-foqs\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="workNature">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[\p{Zs}a-ik-wyz56\|]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 9, 3), '[a-ik-wyz56]{3}|\|{3}|\p{Zs}{3}|[a-ik-wyz56]{2}\p{Zs}|[a-ik-wyz56]\p{Zs}{2}')">
              <xsl:value-of select="substring(., 9, 3)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 9, 3), '[a-ik-wyz56]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 9, 3), '[^a-ik-wyz56]', '')"/>
              </xsl:variable>
              <xsl:value-of select="substring(concat($codes, '&#32;&#32;&#32;'), 1, 3)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[01\|\p{Zs}]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef14">
          <xsl:text>|||</xsl:text>
        </xsl:variable>
        <xsl:variable name="alphaScript">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 17, 1), '[\p{Zs}a-luz\|]')">
              <xsl:value-of select="substring(., 17, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="entryConvention">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 18, 1), '[012\|\p{Zs}]')">
              <xsl:value-of select="substring(., 18, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $frequency, $regularity, $undef4, $resourceType, $originalForm, $itemForm, $workNature, $contentNature, $govPub, $confPub, $undef14, $alphaScript, $entryConvention)"/>
        </controlfield>
      </xsl:when>
      <!-- VM -->
      <xsl:when test="matches(substring(., 1, 1), '[gkor]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="runningTime">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 2, 3), '(nnn|\|\|\||00[0-9]|0[1-9][0-9]|[1-9][0-9][0-9])')">
              <xsl:value-of select="substring(., 2, 3)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef5">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}a-gj\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef7">
          <xsl:text>|||||</xsl:text>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[\p{Zs}acfilmosuz\|]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef14">
          <xsl:text>|||</xsl:text>
        </xsl:variable>
        <xsl:variable name="materialType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 17, 1), '[a-dfgik-tvwz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 17, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="technique">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 18, 1), '[aclnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 18, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $runningTime, $undef5, $audience, $undef7, $govPub, $itemForm, $undef14, $materialType, $technique)"/>
        </controlfield>
      </xsl:when>
      <!-- MX -->
      <xsl:when test="matches(substring(., 1, 1), '[p]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef2">
          <xsl:text>|||||</xsl:text>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}a-dfoqrs\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef8">
          <xsl:text>|||||||||||</xsl:text>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $undef2, $itemForm, $undef8)"/>
        </controlfield>
      </xsl:when>
      <!-- Unknown material; leave in place -->
      <xsl:otherwise>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="."/>
        </controlfield>
        <xsl:variable name="recordIdentifier">
          <xsl:choose>
            <xsl:when test="../*:controlfield[@tag = '001']">
              <xsl:value-of select="../*:controlfield[@tag = '001']"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="position()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:message>record <xsl:value-of select="$recordIdentifier"/>: Unknown value '<xsl:value-of
          select="substring(., 1, 1)"/>' in 006/1</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 007 -->
  <xsl:template match="*:controlfield[@tag = '007']" mode="phase1">
    <xsl:choose>
      <!-- Map -->
      <xsl:when test="matches(substring(., 1, 1), '[a]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[dgjkqrsuyz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[ac\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="physMedium">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[a-gijlnp-z\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reproType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[fnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="prodDetails">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[a-duz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[abmn\|\p{Zs}]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $physMedium, $reproType, $prodDetails, $posNeg)"/>
        </controlfield>
      </xsl:when>
      <!-- Electronic resource -->
      <xsl:when test="matches(substring(., 1, 1), '[c]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[a-fhjkmoruz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 3, 1), '[\p{Zs}\|]')">
              <xsl:value-of select="substring(., 3, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[abcgmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[aegijnouvz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="sound">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}au\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="bitDepth">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when test="matches(substring(., 7, 3), '\d{3}|mmm|nnn|---|\|\|\||[\p{Zs}]{3}')">
              <xsl:value-of select="substring(., 7, 3)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="fileFormat">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 10, 1), '[amu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 10, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="qualityTarget">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 11, 1), '[anpu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 11, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="anteSource">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[a-dmnu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="compression">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[abdmu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reformatQuality">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 14, 1), '[anpru\|\p{Zs}]')">
              <xsl:value-of select="substring(., 14, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $dimensions, $sound, $bitDepth, $fileFormat, $qualityTarget, $anteSource, $compression, $reformatQuality)"/>
        </controlfield>
      </xsl:when>
      <!-- Globe -->
      <xsl:when test="matches(substring(., 1, 1), '[d]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[a-ceuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[ac\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="physMedium">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[a-gijlnpu-z\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reproType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[fnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $physMedium, $reproType)"/>
        </controlfield>
      </xsl:when>
      <!-- Tactile material -->
      <xsl:when test="matches(substring(., 1, 1), '[f]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[a-duz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="brailleClass">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when test="matches(substring(., 4, 2), '[a-emnuz][a-emnuz\p{Zs}]|\|{2}')">
              <xsl:value-of select="substring(., 4, 2)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 4, 2), '[a-emnuz]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 4, 2), '[^a-emnuz]', '')"/>
              </xsl:variable>
              <xsl:value-of select="substring(concat($codes, '&#32;&#32;'), 1, 2)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contractionLevel">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[abmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="brailleMusicFormat">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when test="matches(substring(., 7, 3), '[a-lnuz][a-lnuz\p{Zs}]{2}|\|{3}')">
              <xsl:value-of select="substring(., 7, 3)"/>
            </xsl:when>
            <!-- Keep existing codes, fill remaining positions with spaces -->
            <xsl:when test="matches(substring(., 7, 3), '[a-lnuz]')">
              <xsl:variable name="codes">
                <xsl:value-of select="replace(substring(., 7, 3), '[^a-lnuz]', '')"/>
              </xsl:variable>
              <xsl:value-of select="substring(concat($codes, '&#32;&#32;&#32;'), 1, 3)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="specialChar">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 10, 1), '[abnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 10, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $brailleClass, $contractionLevel, $brailleMusicFormat, $specialChar)"/>
        </controlfield>
      </xsl:when>
      <!-- Projected graphic -->
      <xsl:when test="matches(substring(., 1, 1), '[g]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[cdfos-uz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[a-chmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="emulsionBase">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[dejkmou\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="soundOnMedium">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[abu\p{Zs}\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="mediumOfSound">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[a-iuz\p{Zs}\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[a-gjks-z\|\p{Zs}]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="support">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 9, 1), '[c-ehjkmuz\p{Zs}\|]')">
              <xsl:value-of select="substring(., 9, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $emulsionBase, $soundOnMedium, $mediumOfSound, $dimensions, $support)"/>
        </controlfield>
      </xsl:when>
      <!-- Microform -->
      <xsl:when test="matches(substring(., 1, 1), '[h]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[a-hjuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[abmu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[adfghlmopuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reductionRange">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[a-euv\|\p{Zs}]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reductionRatio">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when test="matches(substring(., 7, 3), '\p{Zs}{3}|\d{3}|\d{2}-|\d--|-{3}')">
              <xsl:value-of select="substring(., 7, 3)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 10, 1), '[bcmuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 10, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="emulsion">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 11, 1), '[abcmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 11, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="generation">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[abcmu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="filmBase">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[acdimnprtuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $posNeg, $dimensions, $reductionRange, $reductionRatio, $color, $emulsion, $generation, $filmBase)"/>
        </controlfield>
      </xsl:when>
      <!-- Nonprojected graphic -->
      <xsl:when test="matches(substring(., 1, 1), '[k]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[ac-ln-suvz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[abchm\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="supportPrimary">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[a-il-wz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="supportSecondary">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}a-il-wz\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $supportPrimary, $supportSecondary)"/>
        </controlfield>
      </xsl:when>
      <!-- Motion picture -->
      <xsl:when test="matches(substring(., 1, 1), '[m]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[cforuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[bchmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="presentationFormat">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[a-fuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="soundOnMedium">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}abu\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="mediumOfSound">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}a-iuz]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[a-guz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="playbackChannels">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 9, 1), '[kmnqsuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 9, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="productionElements">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 10, 1), '[a-gnz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 10, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 11, 1), '[abnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 11, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="generation">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[deoruz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="filmBase">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[acdimnprtuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="refinedColor">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 14, 1), '[a-np-vz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 14, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="colorStock">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 15, 1), '[a-dnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 15, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="deterioration">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 16, 1), '[a-hklm\|\p{Zs}]')">
              <xsl:value-of select="substring(., 16, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="completeness">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 17, 1), '[cinu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 17, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="inspectionDate">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when test="matches(substring(., 18, 6), '([0-9]{4}([0-9]{2}|[\-]{2}))|[\-]{6}')">
              <xsl:value-of select="substring(., 18, 6)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||||||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $presentationFormat, $soundOnMedium, $mediumOfSound, $dimensions, $playbackChannels, $productionElements, $posNeg, $generation, $filmBase, $refinedColor, $colorStock, $deterioration, $completeness, $inspectionDate)"/>
        </controlfield>
      </xsl:when>
      <!-- Kit -->
      <xsl:when test="matches(substring(., 1, 1), '[o]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[u\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Notated music -->
      <xsl:when test="matches(substring(., 1, 1), '[q]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[u\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Remote-sensing image -->
      <xsl:when test="matches(substring(., 1, 1), '[r]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[u\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="sensorAlt">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[abcnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="sensorAtt">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[abcnu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="cloudCover">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[0-9nu\|\p{Zs}]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="platformConstruction">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[a-inuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="platformUse">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[abcmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="sensorType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 9, 1), '[abuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 9, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dataType">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 10, 2), '(aa|da|db|dc|dd|de|df|dv|dz|ga|gb|gc|gd|ge|gf|gg|gu|gz|ja|jb|jc|jv|ma|mb|mm|nn|pa|pb|pc|pd|pe|pz|ra|rb|rc|rd|sa|ta|uu|zz|\|\|)')">
              <xsl:value-of select="substring(., 10, 2)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>||</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $sensorAlt, $sensorAtt, $cloudCover, $platformConstruction, $platformUse, $sensorType, $dataType)"/>
        </controlfield>
      </xsl:when>
      <!-- Sound recording -->
      <xsl:when test="matches(substring(., 1, 1), '[s]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[degiqstuwz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="speed">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[a-fhiklmopruz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="channelConfig">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[mqsuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="groovePitch">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[mnsuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[a-gjosnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="tapeWidth">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[l-puz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="tapeConfig">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 9, 1), '[a-fnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 9, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="discCylinderTapeType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 10, 1), '[abdimnrstuz\|]')">
              <xsl:value-of select="substring(., 10, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="materialType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 11, 1), '[abcgilmnprswuz\|]')">
              <xsl:value-of select="substring(., 11, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="cuttingType">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 12, 1), '[hlnu\|]')">
              <xsl:value-of select="substring(., 12, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="specialPlayback">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 13, 1), '[a-hnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 13, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="captureStorage">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 14, 1), '[abdeuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 14, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $speed, $channelConfig, $groovePitch, $dimensions, $tapeWidth, $tapeConfig, $discCylinderTapeType, $materialType, $cuttingType, $specialPlayback, $captureStorage)"/>
        </controlfield>
      </xsl:when>
      <!-- Text -->
      <xsl:when test="matches(substring(., 1, 1), '[t]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[a-duz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Videorecording -->
      <xsl:when test="matches(substring(., 1, 1), '[v]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[acdfnruz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Undefined = 'no attempt to code' -->
        <xsl:variable name="undef3">
          <xsl:text>|</xsl:text>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 4, 1), '[bcmnuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 4, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="format">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 5, 1), '[a-km-qsuvz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 5, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="soundOnMedium">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 6, 1), '[\p{Zs}abu\|]')">
              <xsl:value-of select="substring(., 6, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="mediumOfSound">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 7, 1), '[\p{Zs}a-iuz\|]')">
              <xsl:value-of select="substring(., 7, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 8, 1), '[amo-ruz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 8, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="channelConfig">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 9, 1), '[kmnqsuz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 9, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd, $undef3, $color, $format, $soundOnMedium, $mediumOfSound, $dimensions, $channelConfig)"/>
        </controlfield>
      </xsl:when>
      <!-- Unspecified -->
      <xsl:when test="matches(substring(., 1, 1), '[z]', 'i')">
        <xsl:variable name="materialCode">
          <xsl:value-of select="lower-case(substring(., 1, 1))"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <!-- Code is valid -->
            <xsl:when test="matches(substring(., 2, 1), '[muz\|\p{Zs}]')">
              <xsl:value-of select="substring(., 2, 1)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:text>|</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="concat($materialCode, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Unknown material; leave in place -->
      <xsl:otherwise>
        <controlfield>
          <xsl:apply-templates select="@*"/>
          <xsl:value-of select="."/>
        </controlfield>
        <xsl:variable name="recordIdentifier">
          <xsl:choose>
            <xsl:when test="../*:controlfield[@tag = '001']">
              <xsl:value-of select="../*:controlfield[@tag = '001']"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="position()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:message>record <xsl:value-of select="$recordIdentifier"/>: Unknown value '<xsl:value-of
          select="substring(., 1, 1)"/>' in 007/1</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 008 -->
  <xsl:template match="*:controlfield[@tag = '008']" mode="phase1">
    <xsl:variable name="dateEntered">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when test="matches(substring(., 1, 6), '[0-9]{6}')">
          <xsl:value-of select="substring(., 1, 6)"/>
        </xsl:when>
        <!-- Replace non-digit w/ '0' -->
        <xsl:otherwise>
          <xsl:value-of select="replace(substring(., 1, 6), '\D', '0')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pubStatus">
      <xsl:choose>
        <!-- Code is valid -->
        <xsl:when test="matches(substring(., 7, 1), '[bcdeikmnpqrstu\|]', 'i')">
          <xsl:value-of select="lower-case(substring(., 7, 1))"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:text>|</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="date1">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when
          test="matches(substring(., 8, 4), '[0-9]{4}|[\p{Zs}u\\\|]{4}|[0-9\p{Zs}u\\\|]{4}', 'i')">
          <xsl:value-of select="lower-case(substring(., 8, 4))"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:text>||||</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="date2">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when
          test="matches(substring(., 12, 4), '[0-9]{4}|[\p{Zs}u\\\|]{4}|[0-9\p{Zs}u\\\|]{4}', 'i')">
          <xsl:value-of select="lower-case(substring(., 12, 4))"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:text>||||</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pubPlace">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when test="matches(substring(., 16, 3), '[a-z]{2}[a-z\s]', 'i')">
          <xsl:value-of select="lower-case(substring(., 16, 3))"/>
        </xsl:when>
        <!-- Replace w/ 'unknown' -->
        <xsl:otherwise>
          <xsl:text>xx&#32;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="language">
      <xsl:choose>
        <!-- Code is minimally valid -->
        <xsl:when test="matches(substring(., 36, 3), '[a-z]{3}|\p{Zs}{3}', 'i')">
          <!-- Fix common errors -->
          <xsl:value-of select="replace(lower-case(substring(., 36, 3)), 'jap', 'jpn')"/>
        </xsl:when>
        <!-- Replace w/ blanks -->
        <xsl:otherwise>
          <xsl:text>&#32;&#32;&#32;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="recordMod">
      <xsl:choose>
        <!-- Code is valid -->
        <xsl:when test="matches(substring(., 39, 1), '[\p{Zs}\\\|dorsx]', 'i')">
          <xsl:value-of select="lower-case(substring(., 39, 1))"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:text>|</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="catalogSource">
      <xsl:choose>
        <!-- Code is valid -->
        <xsl:when test="matches(substring(., 40, 1), '[\p{Zs}\\\|cdu]', 'i')">
          <xsl:value-of select="lower-case(substring(., 40, 1))"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:text>|</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <controlfield>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="concat($dateEntered, $pubStatus, $date1, $date2, $pubPlace)"/>
      <xsl:call-template name="materialSpecific008"/>
      <xsl:value-of select="concat($language, $recordMod, $catalogSource)"/>
    </controlfield>
  </xsl:template>

  <!-- Remove the following datafields -->
  <xsl:template match="*:datafield[@tag = '066']" priority="2" mode="phase1"/>
  <xsl:template match="*:datafield[@tag = '092']" priority="2" mode="phase1"/>

  <!-- Delete datafields that have no subfields or no content in their subfields -->
  <xsl:template match="*:datafield[not(*:subfield)] | *:datafield[normalize-space(.) eq '']"
    priority="2" mode="phase1"/>

  <!-- Join illegal subfields to preceding sibling in datafield 880 -->
  <xsl:template match="*:datafield[@tag = '880']" priority="2" mode="phase1">
    <datafield>
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="sourceTag">
        <xsl:value-of select="substring-before(*:subfield[@code = '6'], '-')"/>
      </xsl:variable>
      <!-- Compress subfields -->
      <xsl:variable name="pass1">
        <xsl:call-template name="compressSubfields">
          <xsl:with-param name="tag">
            <xsl:value-of select="$sourceTag"/>
          </xsl:with-param>
          <xsl:with-param name="subfieldList">
            <xsl:for-each select="*:subfield">
              <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:copy>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="okSubfields">
        <xsl:value-of
          select="concat('[', string-join($marcDatafieldDesc//*:datafield[@tag = $sourceTag]/*:subfield/@code, ' '), ']')"
        />
      </xsl:variable>
      <xsl:choose>
        <!--There are valid subfields to append to -->
        <xsl:when test="count(*:subfield[matches(@code, $okSubfields)]) &gt; 0">
          <xsl:variable name="groupedSubfields">
            <xsl:for-each-group select="$pass1/*:subfield"
              group-starting-with="*:subfield[matches(@code, $okSubfields)]">
              <group>
                <xsl:copy-of select="current-group()"/>
              </group>
            </xsl:for-each-group>
          </xsl:variable>
          <xsl:for-each
            select="$groupedSubfields/*:group[*:subfield[matches(@code, $okSubfields)]]/*:subfield[1]">
            <subfield>
              <xsl:apply-templates select="@*"/>
              <xsl:value-of select="."/>
              <xsl:if test="following-sibling::*:subfield">
                <xsl:value-of select="concat(' ', string-join(following-sibling::*:subfield, ' '))"/>
              </xsl:if>
              <xsl:if test="position() = last() and ../preceding-sibling::*[count(*:subfield[matches(@code, $okSubfields)]) = 0]">
                <xsl:value-of select="concat(' ', string-join(../preceding-sibling::*[count(*:subfield[matches(@code, $okSubfields)]) = 0]/*:subfield, ' '))"/>
              </xsl:if>
            </subfield>
          </xsl:for-each>
        </xsl:when>
        <!-- No valid subfields; output the invalid subfields -->
        <xsl:otherwise>
          <xsl:apply-templates select="*:subfield" mode="phase2"/>
        </xsl:otherwise>
      </xsl:choose>
    </datafield>
  </xsl:template>

  <!-- Join illegal subfields to preceding sibling in datafields other than 880 and 9xx -->
  <xsl:template
    match="*:datafield[not(matches(@tag, '9'))] | *:datafield[matches(@tag, '019|029|049|090|092|096|098|099|490|539|590|591|592|593|594|595|596|597|598|599|690|691|695|696|697|698|699')]"
    mode="phase1">
    <datafield>
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="thisTag">
        <xsl:value-of select="@tag"/>
      </xsl:variable>
      <!-- Compress subfields -->
      <xsl:variable name="pass1">
        <xsl:call-template name="compressSubfields">
          <xsl:with-param name="tag">
            <xsl:value-of select="$thisTag"/>
          </xsl:with-param>
          <xsl:with-param name="subfieldList">
            <xsl:for-each select="*:subfield">
              <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:copy>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="okSubfields">
        <xsl:variable name="definedSubfields">
          <xsl:value-of
            select="string-join($marcDatafieldDesc//*:datafield[@tag = $thisTag]/*:subfield/@code, ' ')"
          />
        </xsl:variable>
        <xsl:if test="$definedSubfields ne ''">
          <xsl:value-of select="concat('[', $definedSubfields, ']')"/>
        </xsl:if>
      </xsl:variable>
      <xsl:choose>
        <!--There are valid subfields to append to -->
        <xsl:when test="count(*:subfield[matches(@code, $okSubfields)]) &gt; 0">
          <xsl:variable name="groupedSubfields">
            <xsl:for-each-group select="$pass1/*:subfield"
              group-starting-with="*:subfield[matches(@code, $okSubfields)]">
              <group>
                <xsl:copy-of select="current-group()"/>
              </group>
            </xsl:for-each-group>
          </xsl:variable>
          <xsl:for-each
            select="$groupedSubfields/*:group[*:subfield[matches(@code, $okSubfields)]]/*:subfield[1]">
            <subfield>
              <xsl:apply-templates select="@*"/>
              <xsl:value-of select="."/>
              <xsl:if test="following-sibling::*:subfield">
                <xsl:value-of select="concat(' ', string-join(following-sibling::*:subfield, ' '))"/>
              </xsl:if>
              <xsl:if test="position() = last() and ../preceding-sibling::*[count(*:subfield[matches(@code, $okSubfields)]) = 0]">
                <xsl:value-of select="concat(' ', string-join(../preceding-sibling::*[count(*:subfield[matches(@code, $okSubfields)]) = 0]/*:subfield, ' '))"/>
              </xsl:if>
            </subfield>
          </xsl:for-each>
        </xsl:when>
        <!-- No valid subfields; output the invalid subfields -->
        <xsl:otherwise>
          <xsl:apply-templates select="*:subfield" mode="phase2"/>
        </xsl:otherwise>
      </xsl:choose>
    </datafield>
  </xsl:template>

  <!-- ======================================================================= -->
  <!-- MATCH TEMPLATES (phase 2)                                               -->
  <!-- ======================================================================= -->

  <!-- Repair @ind1 -->
  <!-- Replace ind1="[Oo]" w/ "0" (zero) -->
  <xsl:template match="@ind1[matches(., 'O', 'i')]" priority="2" mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Fixed value = ' ' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(010|013|015|017|018|019|020|025|026|027|030|031|032|035|036|038|040|042|043|044|046|047|048|051|061|066|071|072|074|084|085|088|090|096|099|222|250|251|254|255|256|257|258|261|262|263|300|306|310|321|336|337|338|340|343|344|345|346|347|348|351|352|357|365|366|370|377|380|381|383|385|386|440|500|501|502|504|507|508|513|514|515|518|525|530|533|534|536|538|539|540|546|547|550|552|562|563|580|584|585|591|592|593|594|595|596|597|598|647|648|651|656|657|658|662|691|751|752|753|754|758|830|841|842|843|844|845|850|855|876|877|878|882|884|887|910|936|938|987|994|999)')]/@ind1[not(matches(., '&#32;'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Fixed value = '0' -->
  <xsl:template match="*:datafield[matches(@tag, '(510|511)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Best-guess value = '&#32;' -->
  <xsl:template match="*:datafield[matches(@tag, '(260)')]/@ind1[not(matches(., '[\s23]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Series traced/untraced -->
  <xsl:template match="*:datafield[matches(@tag, '(490)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Series traced -->
        <xsl:when test="../*:datafield[matches(@tag, '(800|810|811|830)')]">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Series untraced -->
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>
  <!-- Best-guess value = '0' -->
  <xsl:template match="*:datafield[matches(@tag, '(505)')]/@ind1[not(matches(., '[0128]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="*:datafield[matches(@tag, '(773)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Best-guess value = '1' -->
  <xsl:template match="*:datafield[matches(@tag, '(362)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="*:datafield[matches(@tag, '(535)')]/@ind1[not(matches(., '[12]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair @ind2 -->
  <!-- Replace ind2="[Oo]" w/ "0" (zero) -->
  <xsl:template match="@ind2[matches(., 'O', 'i')]" priority="2" mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Fixed value = ' ' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(010|013|015|016|018|019|020|022|025|026|027|029|030|031|032|035|036|037|038|040|042|043|044|045|046|051|052|061|066|070|071|074|080|083|084|085|086|088|090|092|096|100|110|111|130|250|251|254|255|256|257|258|260|261|262|263|300|306|307|310|321|336|337|338|340|341|343|344|345|346|347|348|351|352|355|357|362|365|366|370|380|381|383|384|385|386|388|490|500|501|502|504|506|507|508|510|511|513|514|515|516|518|520|521|522|524|525|526|530|532|533|534|535|536|538|539|540|541|542|544|545|546|547|550|552|555|556|561|562|563|565|567|580|581|583|584|585|586|588|590|591|592|593|594|595|596|597|598|654|658|662|720|751|752|753|754|758|800|810|811|841|842|843|844|845|850|855|876|877|878|882|883|884|886|887|910|936|938|987|994|999)')]/@ind2[not(matches(., '&#32;'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Replace non-compliant value with fixed value -->
  <xsl:template match="*:datafield[matches(@tag, '(653)')]/@ind2[not(matches(., '[\s0-6]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="*:datafield[matches(@tag, '(656|657)')]/@ind2[not(matches(., '7'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>7</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <!-- Replace non-compliant value with best-guess value -->
  <xsl:template
    match="*:datafield[matches(@tag, '600|610|611|630|647|648|650|651|655')]/@ind2[not(matches(., '[07]'))]"
    mode="phase2">
    <xsl:choose>
      <xsl:when test="../*:subfield[@code = '2']">
        <xsl:attribute name="ind2">
          <xsl:text>7</xsl:text>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="ind2">
          <xsl:text>0</xsl:text>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template
    match="*:datafield[matches(@tag, '(700|710|711|730|740)')]/@ind2[not(matches(., '[\s2]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="*:datafield[matches(@tag, '866')]/@ind2[not(matches(., '[0127]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- 035 -->
  <xsl:template match="*:datafield[@tag = '035']" mode="phase2">
    <!-- Compress subfields -->
    <xsl:variable name="pass1">
      <xsl:variable name="thisTag">
        <xsl:value-of select="@tag"/>
      </xsl:variable>
      <xsl:call-template name="compressSubfields">
        <xsl:with-param name="tag">
          <xsl:value-of select="$thisTag"/>
        </xsl:with-param>
        <xsl:with-param name="subfieldList">
          <xsl:for-each select="*:subfield">
            <xsl:copy>
              <xsl:copy-of select="@*"/>
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:copy>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <datafield>
      <xsl:apply-templates select="@*"/>
      <!-- Replace subfield 9 with subfield z -->
      <xsl:for-each select="$pass1//*:subfield">
        <subfield>
          <xsl:attribute name="code">
            <xsl:choose>
              <xsl:when test="@code = '9'">
                <xsl:text>z</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@code"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="."/>
        </subfield>
      </xsl:for-each>
    </datafield>
  </xsl:template>

  <!-- 041 -->
  <xsl:template match="*:datafield[@tag = '041']/*:subfield[matches(@code, '[abdefghjkmnpqr]')]"
    mode="phase2">
    <xsl:choose>
      <!-- Split multiple codes without separators into multiple subfields -->
      <xsl:when test="matches(., '^[a-z]+$')">
        <xsl:call-template name="split041subfield">
          <xsl:with-param name="thisValue">
            <!-- Replace common errors -->
            <xsl:value-of
              select="replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn')"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <!-- Split multiple codes with separators into multiple subfields -->
      <xsl:when test="matches(., '([a-z]{3})+')">
        <xsl:variable name="thisSubfield">
          <xsl:value-of select="@code"/>
        </xsl:variable>
        <xsl:analyze-string select="replace(normalize-space(.), '[^a-zA-Z]+$', '')" regex="[^a-z]+">
          <xsl:non-matching-substring>
            <subfield code="{$thisSubfield}">
              <!-- Replace common errors -->
              <xsl:value-of select="replace(., 'jap', 'jpn')"/>
            </subfield>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- Single code -->
      <xsl:otherwise>
        <xsl:copy>
          <!-- Replace common errors -->
          <xsl:value-of
            select="replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn')"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Join all 049s into a single datafield -->
  <xsl:template match="*:datafield[matches(@tag, '049')][1]" mode="phase2">
    <datafield>
      <xsl:apply-templates select="@*" mode="phase2"/>
      <xsl:apply-templates select="*:subfield" mode="phase2"/>
      <xsl:apply-templates select="following-sibling::*:datafield[matches(@tag, '049')]/*:subfield"
        mode="phase2"/>
    </datafield>
  </xsl:template>
  <!-- Ignore 049s other than the first -->
  <xsl:template match="*:datafield[matches(@tag, '049')][position() &gt; 1]" mode="phase2"/>

  <!-- In 110, 111, 610, 611, 710, and 711 replace ind1 = "&#32;" (space) with ind1="0" -->
  <xsl:template
    match="*:datafield[matches(@tag, '110|111|610|611|710|711')]/@ind1[matches(., '(&#32;|2)')]"
    mode="phase2">
    <xsl:attribute name="ind1">0</xsl:attribute>
  </xsl:template>

  <!-- Repair @ind1 on 100, 600, and 700 -->
  <xsl:template match="*:datafield[matches(@tag, '100|600|700')]/@ind1[not(matches(., '[013]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Family name -->
        <xsl:when test="matches(../*:subfield[@code = 'a'], 'family', 'i')">
          <xsl:text>3</xsl:text>
        </xsl:when>
        <!-- Surname -->
        <xsl:when test="matches(../*:subfield[@code = 'a'], ', .*', 'i')">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Forename -->
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Since 245 isn't repeatable, convert occurrences after the first to 246? -->
  <!--<xsl:template match="*:datafield[matches(@tag, '245')][position() &gt; 1]">
    
  </xsl:template>-->

  <!-- Repair 245 indicators -->
  <xsl:template match="*:datafield[matches(@tag, '245')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="*:datafield[matches(@tag, '245')]/@ind2[not(matches(., '[0-9]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Replace 506$s with $a -->
  <xsl:template match="*:datafield[@tag = '506']/*:subfield[@code = 's']" mode="phase2">
    <subfield code="a">
      <xsl:value-of select="."/>
    </subfield>
  </xsl:template>

  <!-- In 600 keep only allowed subfields -->
  <xsl:template match="*:datafield[@tag = '600']" mode="phase2">
    <datafield>
      <xsl:apply-templates select="@*" mode="phase2"/>
      <xsl:copy-of select="*:subfield[matches(@code, '[abcdefghjklmnopqrstuvxyz0123468]')]"/>
    </datafield>
  </xsl:template>

  <!-- In 653 keep $6 & $8, make all other subfields $a -->
  <xsl:template match="*:datafield[@tag = '653']" mode="phase2">
    <datafield>
      <xsl:apply-templates select="@*"/>
      <xsl:for-each select="*:subfield">
        <subfield>
          <xsl:attribute name="code">
            <xsl:choose>
              <xsl:when test="matches(@code, '6|8')">
                <xsl:value-of select="@code"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>a</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="."/>
        </subfield>
      </xsl:for-each>
    </datafield>
  </xsl:template>

  <!-- 773 -->
  <xsl:template match="*:datafield[@tag = '773']" mode="phase2">
    <!-- Create a look-up table of library names -->
    <xsl:variable name="libraries">
      <xsl:copy-of select="../*:datafield[@tag = '999']/*:subfield[@code = 'm']"/>
    </xsl:variable>
    <!-- Capture $a -->
    <xsl:variable name="heading">
      <xsl:value-of select="upper-case(normalize-space(*:subfield[@code = 'a']))"/>
    </xsl:variable>
    <xsl:choose>
      <!-- Don't process the 773 if $a matches a library name -->
      <xsl:when test="$libraries//*:subfield[. eq $heading]"/>
      <xsl:otherwise>
        <datafield>
          <xsl:apply-templates select="@*"/>
          <xsl:apply-templates/>
        </datafield>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- On 017, 76x, 77x, and 78x, set incorrect ind2 value to ' ' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(017|760|762|765|767|770|773|774|775|776|777|786|787)')]/@ind2[not(matches(., '[\s8]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- On 810, set incorrect ind2 value to '2' -->
  <xsl:template match="*:datafield[matches(@tag, '810')]/@ind1[not(matches(., '[012]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>2</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair non-compliant 880/$6 -->
  <xsl:template match="*:datafield[@tag = '880']/*:subfield[@code = '6']" mode="phase2">
    <!-- Tokenize $6 on '/' -->
    <subfield code="6">
      <xsl:choose>
        <!-- 3 tokens (2 slashes) -->
        <xsl:when test="count(tokenize(normalize-space(.), '/')) = 3">
          <xsl:variable name="linkedTag">
            <xsl:value-of select="normalize-space(tokenize(., '/')[1])"/>
          </xsl:variable>
          <xsl:variable name="script">
            <xsl:value-of select="normalize-space(tokenize(., '/')[2])"/>
          </xsl:variable>
          <xsl:variable name="direction">
            <xsl:value-of select="normalize-space(tokenize(., '/')[3])"/>
          </xsl:variable>
          <!-- Output the component tokens -->
          <!-- Tag linked to -->
          <xsl:value-of select="$linkedTag"/>
          <!-- Script code -->
          <xsl:choose>
            <!-- MARC-compliant script code -->
            <xsl:when test="matches($script, '^(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})$')">
              <xsl:value-of select="concat('/', $script)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>/Zyyy</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <!-- Direction -->
          <xsl:if test="normalize-space($direction) ne ''">
            <xsl:text>/r</xsl:text>
          </xsl:if>
        </xsl:when>
        <!-- 2 tokens (1 slash) -->
        <xsl:when test="count(tokenize(normalize-space(.), '/')) = 2">
          <xsl:variable name="linkedTag">
            <xsl:value-of select="normalize-space(tokenize(., '/')[1])"/>
          </xsl:variable>
          <xsl:variable name="token2">
            <xsl:value-of select="normalize-space(tokenize(., '/')[2])"/>
          </xsl:variable>
          <xsl:value-of select="$linkedTag"/>
          <xsl:choose>
            <!-- $token2 contains script code -->
            <xsl:when test="matches($token2, '^(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})$')">
              <xsl:value-of select="concat('/', $token2)"/>
            </xsl:when>
            <!-- $token2 contains direction indicator -->
            <xsl:otherwise>
              <xsl:text>/Zyyy/r</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- 1 token (no slashes) -->
        <xsl:when test="count(tokenize(normalize-space(.), '/')) = 1">
          <xsl:analyze-string select="." regex="^(\d\d\d-\d\d)(.*)$">
            <xsl:matching-substring>
              <xsl:value-of select="regex-group(1)"/>
              <xsl:choose>
                <!-- script code & direction present -->
                <xsl:when test="matches(regex-group(2), '^.+r$')">
                  <xsl:value-of select="concat('/', substring-before(regex-group(2), 'r'), '/r')"/>
                </xsl:when>
                <!-- script code missing, direction present -->
                  <xsl:when test="matches(regex-group(2), '^r$')">
                  <xsl:text>/Zyyy/r</xsl:text>
                </xsl:when>
                <!-- script code present, direction missing -->
                <xsl:when test="matches(regex-group(2), '.+')">
                  <xsl:value-of select="concat('/', regex-group(2))"/>
                </xsl:when>
              </xsl:choose>
            </xsl:matching-substring>
          </xsl:analyze-string>
        </xsl:when>
        <!-- More than 3 tokens: pass the error along -->
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </subfield>
  </xsl:template>

  <!-- ======================================================================= -->
  <!-- DEFAULT TEMPLATE                                                        -->
  <!-- ======================================================================= -->

  <!-- Identity template -->
  <xsl:template match="element() | processing-instruction() | comment() | @*" mode="#all">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
