<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  exclude-result-prefixes="#all" version="2.0" xmlns:mods="http://www.loc.gov/mods/v3"
  xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">

  <xsl:import href="datePatterns.xsl"/>
  <xsl:import href="marcGeographicAreaCodes.xsl"/>
  <xsl:import href="marcLangList.xsl"/>

  <xsl:output method="xml" encoding="utf-8" indent="yes" media-type="text/xml"
    omit-xml-declaration="no"/>

  <!-- Program name -->
  <xsl:variable name="progName">
    <xsl:text>mods2SAOA</xsl:text>
  </xsl:variable>

  <!-- Program version -->
  <xsl:variable name="progVersion">
    <xsl:text>0.1</xsl:text>
  </xsl:variable>

  <!-- Record separator -->
  <xsl:variable name="recordSep">
    <xsl:text>&#xa;</xsl:text>
  </xsl:variable>

  <!-- Field separator -->
  <xsl:variable name="fieldSep">
    <xsl:text>,</xsl:text>
  </xsl:variable>

  <!-- Separator for multiple values in a single field -->
  <xsl:variable name="valueSep">
    <xsl:text>|</xsl:text>
  </xsl:variable>

  <!-- Column names -->
  <xsl:variable name="headerRow">
    <colName>SSID</colName>
    <colName>Filename</colName>
    <colName>Author</colName>
    <colName>Alternative Title</colName>
    <colName>Title</colName>
    <colName>Volume</colName>
    <colName>Issue</colName>
    <colName>Date</colName>
    <colName>Resource Type</colName>
    <colName>Description</colName>
    <colName>Subject</colName>
    <colName>Holding Institution</colName>
    <colName>Rights</colName>
    <colName>Country</colName>
    <colName>Publisher</colName>
    <colName>Contributor</colName>
    <colName>Format</colName>
    <colName>Language</colName>
    <colName>Local Identifier</colName>
    <colName>Relation</colName>
    <colName>Supplemental Holdings (Link)</colName>
    <colName>OCLC#</colName>
    <colName>Imprint</colName>
    <colName>Series</colName>
    <colName>Artstor Classification</colName>
    <colName>Artstor Latest Date</colName>
    <colName>Artstor Earliest Date</colName>
    <colName>City of Publication</colName>
    <colName>Other Data</colName>
    <colName>Exact Date</colName>
    <colName>Publication</colName>
    <colName>Theme</colName>
    <colName>Media URL</colName>
  </xsl:variable>

  <xsl:template match="/">
    <xmlData>
      <!-- Emit header row -->
      <xsl:for-each select="$headerRow//*:colName">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$fieldSep"/>
        </xsl:if>
        <xsl:variable name="thisValue">
          <xsl:value-of select="replace(., '&quot;', '&quot;&quot;')"/>
        </xsl:variable>
        <xsl:value-of select="concat('&quot;', normalize-space($thisValue), '&quot;')"/>
      </xsl:for-each>
      <xsl:value-of select="$recordSep"/>
      <!-- Emit records -->
      <xsl:apply-templates select="//*:mods"/>
    </xmlData>
  </xsl:template>

  <xsl:template match="*:mods">
    <!-- Collect data in variables for later processing -->
    <xsl:variable name="ssids">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <xsl:variable name="fileNames">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <xsl:variable name="authors">
      <xsl:choose>
        <!-- Use name[@usage='primary'] or name with primary creative role -->
        <xsl:when
          test="*:name[@usage = 'primary'] | *:name[matches(normalize-space(*:role), '^(author|aut|composer|cmp|creator|cre)$')]">
          <xsl:for-each select="distinct-values(*:name[@usage = 'primary'])">
            <xsl:if test="position() != 1">
              <xsl:value-of select="$valueSep"/>
            </xsl:if>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </xsl:for-each>
        </xsl:when>
        <!-- Use first name encountered -->
        <xsl:otherwise>
          <xsl:value-of select="replace(normalize-space(*:name[1]), '&quot;', '&quot;&quot;')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="altTitles">
      <xsl:for-each select="*:titleInfo[@type]">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="titles">
      <xsl:for-each select="*:titleInfo[not(@type)]">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="volumes">
      <!-- Only applies to serials -->
      <xsl:if test="*:originInfo/*:issuance[matches(., 'continuing|integrating resource|serial')]">
        <xsl:analyze-string
          select="*:location[*:holdingSimple]/*:holdingSimple/*:copyInformation/*:note[@type = 'call_number']"
          regex="\sv(ols?)?\.\s*[^\s]+">
          <xsl:matching-substring>
            <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="issues">
      <!-- Only applies to serials -->
      <xsl:if test="*:originInfo/*:issuance[matches(., 'continuing|integrating resource|serial')]">
        <xsl:analyze-string
          select="*:location[*:holdingSimple]/*:holdingSimple/*:copyInformation/*:note[@type = 'call_number']"
          regex="\snos?\.\s*[^\s]+">
          <xsl:matching-substring>
            <xsl:value-of select="."/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="dates">
      <!-- Only applies to serials -->
      <xsl:if test="*:originInfo/*:issuance[matches(., 'continuing|integrating resource|serial')]">
        <xsl:variable name="extractedDates">
          <xsl:for-each
            select="*:location/*:holdingSimple/*:copyInformation/*:note[@type = 'call_number']">
            <xsl:analyze-string select="." regex="{$datePatterns}" flags="i">
              <xsl:matching-substring>
                <date>
                  <xsl:value-of select="regex-group(0)"/>
                </date>
              </xsl:matching-substring>
            </xsl:analyze-string>
          </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($extractedDates//*:date)">
          <xsl:if test="position() != 1">
            <xsl:value-of select="$valueSep"/>
          </xsl:if>
          <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
        </xsl:for-each>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="resourceTypes">
      <xsl:for-each select="*:typeOfResource">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="descriptions">
      <xsl:for-each select="*:abstract | *:tableOfContents">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="subjects">
      <xsl:for-each select="*:subject[not(*:geographicCode)]">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:for-each select="*">
          <xsl:if test="position() != 1">
            <xsl:text>--</xsl:text>
          </xsl:if>
          <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="holdingInstitution">
      <xsl:text>University of Virginia Library</xsl:text>
    </xsl:variable>
    <xsl:variable name="rights">
      <xsl:choose>
        <xsl:when test="*:accessCondition[matches(@type, 'use and reproduction')]">
          <xsl:for-each
            select="distinct-values(*:accessCondition[matches(@type, 'use and reproduction')])">
            <xsl:if test="position() != 1">
              <xsl:value-of select="$valueSep"/>
            </xsl:if>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>http://rightsstatements.org/vocab/NoC-US/1.0/</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="countries">
      <xsl:variable name="countryNames">
        <!-- Translate code into area/country name -->
        <xsl:for-each select="distinct-values(*:subject/*:geographicCode)">
          <xsl:variable name="code">
            <xsl:value-of select="replace(normalize-space(.), '\-\-+', '')"/>
          </xsl:variable>
          <xsl:if test="$marcGeographicAreaCodes//*:area[@code = $code]">
            <country>
              <xsl:value-of select="$marcGeographicAreaCodes//*:area[@code = $code]"/>
            </country>
          </xsl:if>
        </xsl:for-each>
        <!-- Hierarchically-designated place -->
        <xsl:for-each select="distinct-values(*:subject/*:hierarchicalGeographic/*:country)">
          <country>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </country>
        </xsl:for-each>
        <!-- Geographic terms assumed to be hierarchial; i.e., country listed first -->
        <xsl:for-each select="distinct-values(*:subject/*:geographic[1])">
          <country>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </country>
        </xsl:for-each>
      </xsl:variable>
      <!-- Use unique names from $countryNames -->
      <xsl:for-each select="distinct-values($countryNames/*:country)">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="publishers">
      <xsl:for-each select="distinct-values(*:originInfo/*:publisher)">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of
          select="replace(replace(normalize-space(.), '[\.,;:]+$', ''), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="contributors">
      <xsl:choose>
        <!-- If name[@usage='primary'], use other names -->
        <xsl:when test="*:name[@usage = 'primary']">
          <xsl:for-each select="distinct-values(*:name[not(@usage = 'primary')])">
            <xsl:if test="position() != 1">
              <xsl:value-of select="$valueSep"/>
            </xsl:if>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </xsl:for-each>
        </xsl:when>
        <!-- Use unique names, not including the first one -->
        <xsl:otherwise>
          <xsl:for-each select="distinct-values(*:name)">
            <xsl:if test="position() != 1">
              <xsl:value-of select="$valueSep"/>
              <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="formats">
      <xsl:for-each select="*:physicalDescription">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:for-each select="*:extent">
          <xsl:if test="position() != 1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="languages">
      <xsl:for-each select="distinct-values(*:language/*:languageTerm)">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:choose>
          <!-- Perform look-up using coded value -->
          <xsl:when test="matches(normalize-space(.), '^[a-z]{3}$')">
            <xsl:variable name="thisCode">
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:variable>
            <xsl:value-of select="$marcLangList/*:lang[@code eq $thisCode]"/>
          </xsl:when>
          <!-- Use value "as is" -->
          <xsl:otherwise>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="localIdentifiers">
      <xsl:for-each
        select="
          *:identifier[@type = 'local'][matches(@displayLabel, 'Virgo')] |
          *:recordInfo/*:recordIdentifier[@source = 'SIRSI'] |
          *:recordInfo/*:note[@type = 'barcode']">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
        <xsl:choose>
          <xsl:when test="@displayLabel">
            <xsl:choose>
              <xsl:when test="matches(@displayLabel, 'Virgo', 'i')">
                <xsl:text> (VIRGO)</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of
                  select="concat(' (', replace(normalize-space(@displayLabel), '&quot;', '&quot;&quot;'), ')')"
                />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="@source">
            <xsl:value-of
              select="concat(' (', replace(normalize-space(@source), '&quot;', '&quot;&quot;'), ')')"
            />
          </xsl:when>
          <xsl:when test="@type">
            <xsl:value-of
              select="concat(' (', replace(normalize-space(@type), '&quot;', '&quot;&quot;'), ')')"
            />
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="relations">
      <xsl:for-each select="*:relatedItem[not(matches(@type, 'series'))]/*:titleInfo">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="supplementalHoldings">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <xsl:variable name="oclcNumbers">
      <xsl:for-each select="*:identifier[@type = 'oclc']">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="imprints">
      <xsl:for-each select="*:originInfo">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:if test="*:edition">
          <xsl:for-each select="distinct-values(*:edition)">
            <xsl:if test="position() != 1">
              <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
          </xsl:for-each>
          <xsl:text>. </xsl:text>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="*:publisher">
            <xsl:for-each select="distinct-values(*:publisher)">
              <xsl:if test="position() != 1">
                <xsl:text>/</xsl:text>
              </xsl:if>
              <xsl:value-of
                select="replace(replace(normalize-space(.), '[\.,;:]+$', ''), '&quot;', '&quot;&quot;')"
              />
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>[s.n.]</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> : </xsl:text>
        <xsl:choose>
          <xsl:when test="*:place/*:placeTerm[not(matches(@authority, 'marccountry'))]">
            <xsl:for-each
              select="distinct-values(*:place/*:placeTerm[not(matches(@authority, 'marccountry'))])">
              <xsl:if test="position() != 1">
                <xsl:text>--</xsl:text>
              </xsl:if>
              <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
            </xsl:for-each>
          </xsl:when>
          <!-- No place data found -->
          <xsl:otherwise>[s.l.]</xsl:otherwise>
        </xsl:choose>
        <xsl:text>, </xsl:text>
        <xsl:choose>
          <!-- Single issued/published date -->
          <xsl:when test="*:dateIssued[not(@point)]">
            <xsl:value-of
              select="replace(normalize-space(*:dateIssued[not(@point)][1]), '&quot;', '&quot;&quot;')"
            />
          </xsl:when>
          <!-- Date range -->
          <xsl:when test="*:dateIssued[@point]">
            <xsl:choose>
              <xsl:when test="matches(*:dateIssued[@point eq 'start'][1]/@qualifier, 'approximate')">
                <xsl:text>~</xsl:text>
              </xsl:when>
              <xsl:when test="matches(*:dateIssued[@point eq 'start'][1]/@qualifier, 'inferred')">
                <xsl:text>[</xsl:text>
              </xsl:when>
            </xsl:choose>
            <xsl:value-of
              select="replace(normalize-space(*:dateIssued[@point eq 'start'][1]), '&quot;', '&quot;&quot;')"/>
            <xsl:choose>
              <xsl:when test="matches(*:dateIssued[@point eq 'start'][1]/@qualifier, 'inferred')">
                <xsl:text>]</xsl:text>
              </xsl:when>
              <xsl:when
                test="matches(*:dateIssued[@point eq 'start'][1]/@qualifier, 'questionable')">
                <xsl:text>?</xsl:text>
              </xsl:when>
            </xsl:choose>
            <xsl:if test="*:dateIssued[@point eq 'end']">
              <xsl:text>-</xsl:text>
              <xsl:choose>
                <xsl:when test="matches(*:dateIssued[@point eq 'end'][1]/@qualifier, 'approximate')">
                  <xsl:text>~</xsl:text>
                </xsl:when>
                <xsl:when test="matches(*:dateIssued[@point eq 'end'][1]/@qualifier, 'inferred')">
                  <xsl:text>[</xsl:text>
                </xsl:when>
              </xsl:choose>
              <xsl:value-of
                select="replace(normalize-space(*:dateIssued[@point eq 'end'][1]), '&quot;', '&quot;&quot;')"/>
              <xsl:choose>
                <xsl:when test="matches(*:dateIssued[@point eq 'start'][1]/@qualifier, 'inferred')">
                  <xsl:text>]</xsl:text>
                </xsl:when>
                <xsl:when
                  test="matches(*:dateIssued[@point eq 'start'][1]/@qualifier, 'questionable')">
                  <xsl:text>?</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:if>
          </xsl:when>
          <!-- Copyright date -->
          <xsl:when test="*:copyrightDate">
            <xsl:value-of
              select="replace(normalize-space(*:copyrightDate[1]), '&quot;', '&quot;&quot;')"/>
          </xsl:when>
          <!-- Creation date -->
          <xsl:when test="*:dateCreated">
            <xsl:value-of
              select="replace(normalize-space(*:dateCreated[1]), '&quot;', '&quot;&quot;')"/>
          </xsl:when>
          <!-- Some other kind of date -->
          <xsl:when
            test="
              *[matches(local-name(),
              'dateCreated|dateModified|datevalid|dateOther')][not(normalize-space(.) = '')]">
            <xsl:value-of
              select="
                replace(normalize-space(*[matches(local-name(),
                'dateCreated|dateModified|datevalid|dateOther')][1]), '&quot;', '&quot;&quot;')"
            />
          </xsl:when>
          <!-- No date info found -->
          <xsl:otherwise>
            <xsl:text>[n.d.]</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="series">
      <xsl:for-each select="*:relatedItem[@type = 'series']/*:titleInfo">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="artstorClasses">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <xsl:variable name="artstorLatestDates">
      <xsl:for-each select="*:originInfo/*:dateIssued[@point = 'end']">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="artstorEarliestDates">
      <xsl:for-each select="*:originInfo/*:dateIssued[@point = 'start']">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="publicationCities">
      <xsl:for-each select="*:originInfo/*:place/*:placeTerm[not(@authority = 'marccountry')]">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="otherData">
      <xsl:for-each
        select="*:originInfo/*:frequency | descendant::*:note[not(matches(@type, 'local|call_number|barcode'))]">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="exactDates">
      <xsl:for-each select="*:originInfo/*:dateIssued[not(@point) and not(matches(., '-'))]">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$valueSep"/>
        </xsl:if>
        <xsl:value-of select="replace(normalize-space(.), '&quot;', '&quot;&quot;')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="publication">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <xsl:variable name="themes">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <xsl:variable name="mediaURLs">
      <!-- Nothing here yet -->
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>

    <!-- Emit each variable's contents wrapped in double quotes and terminated w/ $fieldSep value -->
    <!-- ssid -->
    <xsl:value-of select="concat('&quot;', normalize-space($ssids), '&quot;', $fieldSep)"/>
    <!-- filename -->
    <xsl:value-of select="concat('&quot;', normalize-space($fileNames), '&quot;', $fieldSep)"/>
    <!-- author -->
    <xsl:value-of select="concat('&quot;', normalize-space($authors), '&quot;', $fieldSep)"/>
    <!-- altTitle -->
    <xsl:value-of select="concat('&quot;', normalize-space($altTitles), '&quot;', $fieldSep)"/>
    <!-- title -->
    <xsl:value-of select="concat('&quot;', normalize-space($titles), '&quot;', $fieldSep)"/>
    <!-- volume -->
    <xsl:value-of select="concat('&quot;', normalize-space($volumes), '&quot;', $fieldSep)"/>
    <!-- issue -->
    <xsl:value-of select="concat('&quot;', normalize-space($issues), '&quot;', $fieldSep)"/>
    <!-- date -->
    <xsl:value-of select="concat('&quot;', normalize-space($dates), '&quot;', $fieldSep)"/>
    <!-- resourceType -->
    <xsl:value-of select="concat('&quot;', normalize-space($resourceTypes), '&quot;', $fieldSep)"/>
    <!-- description -->
    <xsl:value-of select="concat('&quot;', normalize-space($descriptions), '&quot;', $fieldSep)"/>
    <!-- subject -->
    <xsl:value-of select="concat('&quot;', normalize-space($subjects), '&quot;', $fieldSep)"/>
    <!-- holdingInstitution -->
    <xsl:value-of
      select="concat('&quot;', normalize-space($holdingInstitution), '&quot;', $fieldSep)"/>
    <!-- rights -->
    <xsl:value-of select="concat('&quot;', normalize-space($rights), '&quot;', $fieldSep)"/>
    <!-- country -->
    <xsl:value-of select="concat('&quot;', normalize-space($countries), '&quot;', $fieldSep)"/>
    <!-- publisher -->
    <xsl:value-of select="concat('&quot;', normalize-space($publishers), '&quot;', $fieldSep)"/>
    <!-- contributor -->
    <xsl:value-of select="concat('&quot;', normalize-space($contributors), '&quot;', $fieldSep)"/>
    <!-- format -->
    <xsl:value-of select="concat('&quot;', normalize-space($formats), '&quot;', $fieldSep)"/>
    <!-- language -->
    <xsl:value-of select="concat('&quot;', normalize-space($languages), '&quot;', $fieldSep)"/>
    <!-- localIdentifier -->
    <xsl:value-of select="concat('&quot;', normalize-space($localIdentifiers), '&quot;', $fieldSep)"/>
    <!-- relation -->
    <xsl:value-of select="concat('&quot;', normalize-space($relations), '&quot;', $fieldSep)"/>
    <!-- supplementalHoldings -->
    <xsl:value-of
      select="concat('&quot;', normalize-space($supplementalHoldings), '&quot;', $fieldSep)"/>
    <!-- oclcNum -->
    <xsl:value-of select="concat('&quot;', normalize-space($oclcNumbers), '&quot;', $fieldSep)"/>
    <!-- imprint -->
    <xsl:value-of select="concat('&quot;', normalize-space($imprints), '&quot;', $fieldSep)"/>
    <!-- series -->
    <xsl:value-of select="concat('&quot;', normalize-space($series), '&quot;', $fieldSep)"/>
    <!-- artstorClass -->
    <xsl:value-of select="concat('&quot;', normalize-space($artstorClasses), '&quot;', $fieldSep)"/>
    <!-- artstorLatestDate -->
    <xsl:value-of
      select="concat('&quot;', normalize-space($artstorLatestDates), '&quot;', $fieldSep)"/>
    <!-- artstorEarliestDate -->
    <xsl:value-of
      select="concat('&quot;', normalize-space($artstorEarliestDates), '&quot;', $fieldSep)"/>
    <!-- cityOfPublication -->
    <xsl:value-of
      select="concat('&quot;', normalize-space($publicationCities), '&quot;', $fieldSep)"/>
    <!-- otherData -->
    <xsl:value-of select="concat('&quot;', normalize-space($otherData), '&quot;', $fieldSep)"/>
    <!-- exactDate -->
    <xsl:value-of select="concat('&quot;', normalize-space($exactDates), '&quot;', $fieldSep)"/>
    <!-- publication -->
    <xsl:value-of select="concat('&quot;', normalize-space($publication), '&quot;', $fieldSep)"/>
    <!-- theme -->
    <xsl:value-of select="concat('&quot;', normalize-space($themes), '&quot;', $fieldSep)"/>
    <!-- mediaURL -->
    <xsl:value-of select="concat('&quot;', normalize-space($mediaURLs), '&quot;')"/>

    <!-- Emit $recordSep value to end CSV "record" -->
    <xsl:value-of select="$recordSep"/>

  </xsl:template>

  <xsl:template match="*:role">
    <xsl:value-of select="concat(' (', normalize-space(.), ')')"/>
  </xsl:template>

</xsl:stylesheet>
