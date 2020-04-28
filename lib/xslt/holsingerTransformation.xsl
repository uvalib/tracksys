<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xpath-default-namespace="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:nuds="http://nomisma.org/nuds" xmlns:nmo="http://nomisma.org/ontology#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" exclude-result-prefixes="mods fn xs nuds rdf skos nmo xlink">

	<!-- UVA-LIB stylesheet for converting Holsinger Collection MODS to SOLR -->
	<!-- created by M. Stephens (ms3uf) on Jan 14/2010 	-->
	<!-- modified by Andrew Curley (aec6v) on November 10, 2011 -->
	<!-- modified by Jocelyn Triplett (jbo3d) June 4, 2014 -->

	<!-- Required Parameters -->
	<xsl:param name="pid" required="yes" />
	
	<!-- A URL to get the IIIF presentation metadata -->
	<xsl:param name="iiifManifest" required="yes"/>
	
	<xsl:param name="iiifRoot" required="yes" />
	
	<xsl:param name="flipped" required="no" />
	
	<!-- 
		In order to allow reuse of the mappings from the MODS metadata to SOLR fields
		this parameter results in an incomplete SOLR document that does not make any
		calls to get content from external sources.  The result should NOT be used by
		SOLR and will indeed contain information to that effect.  Setting this to any
		value is sufficient to enable this mode.
	  -->
	<xsl:param name="excludeExternallyGenerated" required="no" />
	
	<xsl:param name="permanentUrl" />

	<!-- A base URL, for which when a page pid is appended will provide an endpoint to 
    	 download a large copy of the given image with citation and rights information embedded.-->
	<xsl:param name="rightsWrapperServiceUrl" required="yes" />

        <xsl:param name="exemplarPid">
                <xsl:value-of select="false()"/>
        </xsl:param>
	
	<!-- Datetime that this index record was produced.  Defaults to now. Format:YYYYMMDDHHMM -->
	<xsl:param name="dateIngestNow" >
		<xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001][M01][D01][H01][m01]')"/>
	</xsl:param>
	
	<xsl:param name="policyFacet" />
	
	<xsl:param name="useRightsString" required="yes" />
	
	<xsl:param name="rightsstatementURI" required="no">
		<xsl:value-of select="$rightsstatementMapping[1]/*[*[local-name() = 'string']/text()=$useRightsString]/*[local-name()='uri']/text()" />
	</xsl:param>
	
	<!-- Date DL Ingest for the object being indexed for the creation of date_received_facet and date_received_text -->
	<xsl:param name="dateReceived" />

	<!-- Facet use for blacklight to group digital objects.  Default value: 'UVA Library Digital Repository'. -->
	<xsl:param name="sourceFacet">
		<xsl:value-of select="'UVA Library Digital Repository'"/>
	</xsl:param>

	<!-- While this can be passed to the stylesheet as a params, this method of determination is to be supplanted by an investiagtion of the descMetadata (as written below).  This param is to be deprecated. -->
	<xsl:param name="shadowedItem" />

	<!-- If this item belongs to a specific collection of objects, that information should be encoded in the above mentioned XPath location. -->
	<!--<xsl:param name="collectionName"
		select="//relatedItem[@type='series' and @displayLabel='Part of']/titleInfo[1]/title[1]"/>-->

	<!-- Global Variables -->
	<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz    '"/>
	<!-- whitespace in select is meaningful -->
	<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ,;-:.'"/>
	
	<xsl:variable name='newline'><xsl:text>
</xsl:text></xsl:variable>
	
	<xsl:variable name="rightsstatementMapping">
		<statement>
			<uri>http://rightsstatements.org/vocab/CNE/1.0/</uri>
			<string>Copyright Not Evaluated</string>
			<wrapperText>
				<xsl:text>The UVA Library has not evaluated the copyright status of this work.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/NKC/1.0/</uri>
			<string>No Known Copyright</string>
			<use>Educational Use Permitted</use>
			<use>Modifications Permitted</use>
			<use>Commercial Use Permitted</use>
			<wrapperText>
				<xsl:text>The UVA Library is not aware of any copyright interest in this work.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research. You are responsible for making a rights determination for your own uses.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/InC/1.0/</uri>
			<string>In Copyright</string>
			<wrapperText>
				<xsl:text>The UVA Library has determined that this work is in-copyright.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/InC-EDU/1.0/</uri>
			<string>In Copyright Educational Use Permitted</string>
			<use>Educational Use Permitted</use>
			<wrapperText>
				<xsl:text>The UVA Library has determined that this work is in-copyright.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/InC-NC/1.0/</uri>
			<string>In Copyright Non-Commercial Use Permitted</string>
			<use>Educational Use Permitted</use>
			<wrapperText>
				<xsl:text>The UVA Library has determined that this work is in-copyright.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/InC-RUU/1.0/</uri>
			<string>In Copyright Rights Holder Unlocatable</string>
			<wrapperText>
				<xsl:text>The UVA Library has not determined the copyright status of this work.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/NoC-OKLR/1.0/</uri>
			<string>No Copyright Other Known Legal Restrictions</string>
			<wrapperText>
				<xsl:text>The UVA Library is not aware of any copyright interest in this work, but other legal restrictions apply.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Legal restrictions may apply to further use of this image.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/NoC-US/1.0/</uri>
			<string>No Copyright United States</string>
			<use>Educational Use Permitted</use>
			<use>Modifications Permitted</use>
			<use>Commercial Use Permitted</use>
			<wrapperText>
				<xsl:text>The UVA Library is not aware of any copyright interest in this work.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research. You are responsible for making a rights determination for your own uses.</xsl:text>
			</wrapperText>
		</statement>
		<statement>
			<uri>http://rightsstatements.org/vocab/UND/1.0/</uri>
			<string>Copyright Undetermined</string>
			<wrapperText>
				<xsl:text>The UVA Library has been unable to determine the copyright status of this work.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
				<xsl:value-of select="$newline" />
				<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
			</wrapperText>
		</statement>
	</xsl:variable>

	<xsl:output byte-order-mark="no" encoding="UTF-8" media-type="text/xml" xml:space="preserve" indent="yes"/>

	<xsl:template match="/">

		<add>
			<doc>
				<xsl:if test="$excludeExternallyGenerated">
					<note>
						This solr record is INCOMPLETE because it was requested to be generated that way using the "excludeExternallyGenerated" parameter.
					</note>
				</xsl:if>
				
				<field name="id">
					<xsl:value-of select="$pid"/>
				</field>
				<!-- At this time, no Holsinger items will have MARC in them, so this value can be set to false -->
		                <field name="marc_display_facet">false</field>
				<xsl:for-each select="//relatedItem[@type='series' and @displayLabel='Part of']/titleInfo/title">
				<field name="digital_collection_facet">
					<xsl:value-of select="."/>
				</field>
				<field name="digital_collection_text">
					<xsl:value-of select="."/>
				</field>
					</xsl:for-each>
				<xsl:if test="$policyFacet != 'false'">
					<field name="policy_facet">
						<xsl:value-of select="$policyFacet"/>
					</field>
				</xsl:if>
				<field name="source_facet">UVA Library Digital Repository</field>
				<xsl:if test="$flipped">
					<field name="thumbnail_url_display"><xsl:value-of select="$iiifRoot" /><xsl:value-of select="$exemplarPid" />/full/!125,125/!0/default.jpg</field>
				</xsl:if>
				<xsl:if test="not($flipped)">
					<field name="thumbnail_url_display"><xsl:value-of select="$iiifRoot" /><xsl:value-of select="$exemplarPid" />/full/!125,125/0/default.jpg</field>
				</xsl:if>
				<xsl:if test="not($excludeExternallyGenerated)">
					<field name="feature_facet">iiif</field>
					<field name="feature_facet">dl_metadata</field>
					<field name="iiif_presentation_metadata_display">
						<xsl:value-of select="unparsed-text($iiifManifest)" />
					</field>
				</xsl:if>
				
				<!-- The "right_wrapper" feature indicates that we should provide page-level links
					 that include rights information and specifically that that rights information will be
					 stored in the "rights_wrapper_display" field, and a service URL will be included in the
					 rights_wrapper_url_display field to which just the page pid should be appended.
			     -->
				<xsl:if test="$rightsWrapperServiceUrl">
					<field name="feature_facet">rights_wrapper</field>
					<field name="rights_wrapper_url_display"><xsl:value-of select="$rightsWrapperServiceUrl" /></field>
					
					<xsl:variable name="citation">
						<xsl:variable name="title">
							<xsl:choose>
								<xsl:when test="//mods:mods/mods:titleInfo/mods:title[@type='uniform']">
									<xsl:value-of select="//mods:mods/mods:titleInfo/mods:title[@type='uniform'][1]/text()" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="//mods:mods/mods:titleInfo/mods:title[1]/text()" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:value-of select="normalize-space($title)" />
						<xsl:variable name="callNumber" select="normalize-space(//mods:mods/mods:classification[1]/text())" />
						<xsl:if test="$callNumber != ''">
							<xsl:text>, </xsl:text>
							<xsl:value-of select="$callNumber" />
						</xsl:if>
						<xsl:variable name="location">
							<xsl:choose>
								<xsl:when test="//mods:mods/mods:location/mods:physicalLocation">
									<xsl:value-of select="normalize-space((//mods:mods/mods:location/mods:physicalLocation)[1])" />
								</xsl:when>
								<xsl:when test="//mods:mods/mods:location/mods:holdingSimple/mods:copyInformation[mods:subLocation/text() = 'SPEC-COLL']">
									<xsl:text>Special Collections, University of Virginia Library, Charlottesville, Va.</xsl:text>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:if test="$location != ''">
							<xsl:text>, </xsl:text>
							<xsl:value-of select="$location" />
						</xsl:if>
					</xsl:variable>

					<field name="rs_uri_display"><xsl:value-of select="$rightsstatementURI"/></field>
					<xsl:for-each select="$rightsstatementMapping[1]/*[*[local-name()='uri']/text()=$rightsstatementURI]/*[local-name()='use']">
						<field name="use_facet"><xsl:value-of select="text()"/></field>
					</xsl:for-each>

					<xsl:comment select="concat('Use Rights: ', $useRightsString, ' (', $rightsstatementURI, ')')" />
					<field name="rights_wrapper_display">
						<xsl:value-of select="$citation" />
						<xsl:value-of select="$newline" />
						<xsl:if test="$permanentUrl">
							<xsl:value-of select="$permanentUrl" />
							<xsl:value-of select="$newline" />
						</xsl:if>
						<xsl:value-of select="$newline" />
						<xsl:variable name="rightsSummary">
							<xsl:value-of select="$rightsstatementMapping[1]/*[*[local-name()='uri']/text()=$rightsstatementURI]/*[local-name()='wrapperText']/text()"/>
						</xsl:variable>
						<xsl:value-of select="$rightsSummary"/>
						<xsl:if test="$rightsSummary  = ''">
							<xsl:value-of select="$rightsstatementMapping[1]/*[1]/*[local-name()='wrapperText']/text()" />
						</xsl:if>
						
						<xsl:value-of select="$newline" />
						<xsl:text>Find more information about permission to use the library's materials at http://search.lib.virginia.edu/terms.html</xsl:text>
					</field>
				</xsl:if>
				
				<!-- date indexed -->
				
				<field name="date_indexed_facet">
					<xsl:value-of select="$dateIngestNow"/>
				</field>
				
				<!-- call number -->

				
				<xsl:for-each select="//mods:identifier">
					<xsl:if test="//mods:identifier/text() and @type='accessionNumber'">
						<field name="call_number_display">
							<xsl:value-of select="current()"/>
						</field>
						<field name="call_number_text">
							<xsl:value-of select="current()"/>
						</field>
					</xsl:if>
				</xsl:for-each>

				<!-- title -->
				<xsl:for-each select="//mods:title">
					<xsl:if test="position() = 1 or @type='uniform'">
						<field name="main_title_display">
							<xsl:value-of select="current()"/>
						</field>
						<!-- there can be only one! title facet will BREAK solr sorting if multiple values found -->
						<field name="title_facet">
							<xsl:value-of select="current()"/>
						</field>
						<field name="title_text">
							<xsl:value-of select="current()"/>
						</field>
						<field name="title_display">
							<xsl:value-of select="current()"/>
						</field>
						<field name="title_sort_facet">
							<xsl:value-of select="translate(current(), $uppercase, $lowercase)"/>
						</field>
					</xsl:if>
				</xsl:for-each>
<!--  deleted 10/26/16 at request from jtb4t
				<xsl:if
					test="not(//mods/*[1][local-name() = 'titleInfo']/*[local-name() = 'title'])">
					<field name="alternate_title_display">untitled</field>
				</xsl:if>
-->

				<!-- searchable legacy identifier -->

				<xsl:for-each select="//mods/identifier[(@displayLabel='Negative Number' or @displayLabel='Prints Number' or @displayLabel='Originating Collection' or @displayLabel='Artifact Number' or @displayLabel='Retrieval ID' or @displayLabel='retrieval ID')]">
					<xsl:variable name="boxnbr" select="//mods/location/shelfLocator"/>
					<field name="media_retrieval_id_display">
						<xsl:if test="$boxnbr">
							<xsl:value-of select="$boxnbr"/>
							<xsl:text>, </xsl:text>
						</xsl:if>
						<xsl:value-of select="current()"/>
					</field>
					<field name="media_retrieval_id_facet">
						<xsl:value-of select="current()"/>
					</field>
					<field name="media_retrieval_id_text">
						<xsl:value-of select="current()"/>
					</field>
				</xsl:for-each>

				<!-- SOLR can take only one year_multisort_i field, so we need to choose which mods element to utilize -->
				<xsl:for-each select="/mods/originInfo[1]">
					<xsl:choose>
						<xsl:when test="current()/dateIssued[@keyDate='yes'][1]">
							<xsl:call-template name="build-dates">
								<xsl:with-param name="date-node"
									select="current()/dateIssued[@keyDate='yes'][1]"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="current()/dateCreated[@keyDate='yes'][1]">
							<xsl:call-template name="build-dates">
								<xsl:with-param name="date-node"
									select="current()/dateCreated"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="current()/dateCaptured[@keyDate='yes'][1]">
							<xsl:call-template name="build-dates">
								<xsl:with-param name="date-node"
									select="current()/dateCaptured[@keyDate='yes'][1]"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="current()/dateValid[@keyDate='yes'][1]">
							<xsl:call-template name="build-dates">
								<xsl:with-param name="date-node"
									select="current()/dateValid[@keyDate='yes'][1]"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="current()/copyrightDate[@keyDate='yes'][1]">
							<xsl:call-template name="build-dates">
								<xsl:with-param name="date-node"
									select="current()/copyrightDate[@keyDate='yes'][1]"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="current()/dateOther[@keyDate='yes'][1]">
							<xsl:call-template name="build-dates">
								<xsl:with-param name="date-node"
									select="current()/dateOther[@keyDate='yes'][1]"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:for-each>

				<!-- subject text -->
				<xsl:for-each select="//subject">
					<xsl:variable name="text-content">
					<xsl:choose>
						<xsl:when test="current()/child::*/local-name() = 'hierarchicalGeographic'"/>
						<xsl:otherwise>
							<xsl:for-each select="./descendant::text()[matches(., '[\w]+')]">
								<xsl:if test="matches(current(), '[\w]+')">
									<!-- add double dash to all trailing subfields -->
									<xsl:if test="position() != 1">
										<xsl:text> -- </xsl:text>
									</xsl:if>
									<xsl:copy-of select="normalize-space(current())"/>
								</xsl:if>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
					</xsl:variable>

					<xsl:choose>
						<xsl:when test="not($text-content = '')">
							<field name="subject_text">
								<xsl:value-of select="$text-content"/>
							</field>
							<field name="subject_facet">
								<xsl:value-of select="$text-content"/>
							</field>
							<field name="subject_genre_facet">
								<xsl:value-of select="$text-content"/>
							</field>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:for-each>

		
<!-- get Geographic Places facet from subject/hierarchicalGeographic -->

				<xsl:for-each select="//subject">
					<xsl:choose>
						<!-- only use standalone geographical children -->
						<xsl:when test="*[2]"/>
						<xsl:otherwise>
							<xsl:choose>
							<xsl:when test="current()/child::*/local-name() = 'hierarchicalGeographic'">
								<xsl:variable name="placeList">
									<xsl:for-each select="./descendant::text()[matches(., '[\w]+')]">
										<!-- add double dash to all trailing subfields -->
                                                       	         		<xsl:if test="position() != 1">
                                                       	                 		<xsl:text> -- </xsl:text>
                                                       	         		</xsl:if>
                                                       	         		<xsl:copy-of select="normalize-space(current())"/>
									</xsl:for-each>
								</xsl:variable>
								<xsl:if test="$placeList">
									<field name="region_facet">
										<xsl:value-of select="$placeList"/>
									</field>	
		
								</xsl:if>
							</xsl:when>
							<xsl:when test="current()/geographic/text()">
								<field name="region_facet">
									<xsl:value-of select="current()/geographic/text()"/>
								</field>
							</xsl:when>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>

				<!-- library facet -->
				<xsl:for-each select="/mods/location/physicalLocation[not(@authority='oclcorg')]">
					<xsl:if test="current()/text() != ' '">
						<field name="location_display">
							<xsl:value-of select="current()/text()"/>
						</field>
					</xsl:if>
					<xsl:variable name="normalizedLibraryName">
						<xsl:choose>
							<xsl:when
								test="./text()='Special Collections, University of Virginia Library, Charlottesville, Va.'"
								>Special Collections</xsl:when>
							
							<xsl:when
								test="./text()='Historical Collections &amp; Services, Claude Moore Health Sciences Library, Charlottesville, Va.'"
								>Health Sciences</xsl:when>
							<xsl:when
								test="./text()='Special Collections, Arthur J. Morris Law Library, Charlottesville, Va.'"
								>Law School</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$normalizedLibraryName != ''">
						<field name="library_facet">
							<xsl:value-of select="$normalizedLibraryName"/>
						</field>
					</xsl:if>
				</xsl:for-each>
				

				<!-- creator -->
				
				<!-- handle names without identifying type -->
				<xsl:for-each select="//mods/name[not(@type)]">
					<xsl:variable name="dfltName">
						<xsl:value-of select="current()/namePart/text()"/>
					</xsl:variable>
					<xsl:if test="normalize-space($dfltName) != ''">
						<field name="author_display">
						<xsl:value-of select="$dfltName"/>
					</field>
					<field name="author_facet">
						<xsl:value-of select="$dfltName"/>
					</field>
					<field name="author_text">
						<xsl:value-of select="$dfltName"/>
					</field>
					</xsl:if>
				</xsl:for-each>
				
				<!-- added corporate info to accommodate Online Artifacts records -->
				<xsl:for-each select="//mods/name[@type='corporate']">
						<xsl:variable name="corpName">
							<xsl:value-of select="current()/namePart/text()"/>
						</xsl:variable>
						<xsl:if test="normalize-space($corpName) != ''">
							<field name="author_display">
							<xsl:value-of select="$corpName"/>
							</field>
							<field name="author_facet">
								<xsl:value-of select="$corpName"/>
							</field>
							<field name="author_text">
								<xsl:value-of select="$corpName"/>
							</field>
						</xsl:if>
				</xsl:for-each>
				
				<xsl:for-each select="//mods/name[@type='personal']">
					<xsl:variable name="fname">
						<xsl:choose>
							<xsl:when
								test="current()/namePart[@type='family'] and current()/namePart[@type='family'][substring-before(., ',')!='']">
								<xsl:value-of
									select="substring-before(current()/namePart[@type='family'], ',')"
								/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="current()/namePart[@type='family']"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="gname">
						<xsl:choose>
							<xsl:when
								test="current()/namePart[@type='given'] and current()/namePart[@type='given'][substring-before(., ',')!='']">
								<xsl:value-of
									select="substring-before(current()/namePart[@type='given'], ',')"
								/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="current()/namePart[@type='given']"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="term-of-address">
						<xsl:choose>
							<xsl:when
								test="current()/namePart[@type='termsOfAddress'] and current()/namePart[@type='termsOfAddress'][substring-before(., ',')!='']">
								<xsl:value-of
									select="substring-before(current()/namePart[@type='termsOfAddress'], ',')"
								/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="current()/namePart[@type='termsOfAddress']"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="nameFull">
						<xsl:choose>
							<xsl:when
								test="current()/namePart[@type='family'] and current()/namePart[@type='given']">
								<xsl:value-of select="$fname"/>
								<xsl:text>, </xsl:text>
								<xsl:value-of select="$gname"/>
							</xsl:when>
							<xsl:when
								test="current()/namePart[@type='family'] and current()/namePart[@type='termsOfAddress']">
								<xsl:value-of select="$fname"/>
								<xsl:text>, </xsl:text>
								<xsl:value-of select="$term-of-address"/>
							</xsl:when>
							<xsl:when
								test="current()/namePart[@type='given'] and current()/namePart[@type='termsOfAddress']">
								<xsl:value-of select="$gname"/>
								<xsl:text>, </xsl:text>
								<xsl:value-of select="$term-of-address"/>
							</xsl:when>
							<xsl:when
								test="contains(current()/namePart[not(@type = 'date')][not(@type = 'termsOfAddress')][1], ',') and count(current()/namePart) = 1">
								<xsl:value-of select="current()/namePart[1]"/>
							</xsl:when>
							<xsl:when test="current()/namePart[not(@type = 'date')]">
								<xsl:for-each select="current()/namePart[not(@type = 'date')]">
									<xsl:choose>
										<xsl:when
											test="contains(., ',') and substring-after(., ',')=''">
											<xsl:value-of select="substring-before(., ',')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="."/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="current()"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:if test="normalize-space($nameFull) != ''" >
						<field name="author_facet">
						  <xsl:value-of select="$nameFull"/>
						</field>
						<field name="author_text">
						  <xsl:value-of select="$nameFull"/>
						</field>
						<xsl:choose>
						<xsl:when test="child::namePart[@type='date']">
							<field name="author_display"><xsl:value-of select="$nameFull"/>, <xsl:value-of select="child::namePart[@type='date']/text()"/>
						    </field>
						</xsl:when>
						<xsl:otherwise>
							<field name="author_display">
								<xsl:value-of select="$nameFull"/>
							</field>
						</xsl:otherwise>
						</xsl:choose>
					</xsl:if>

					<!-- The following is commented because the special-role is no longer needed.  11/10/11 -->
					<!--
					<xsl:variable name="special-role">
						<xsl:if test="current()/role/roleTerm[not(@type='code')][not(contains(., 'creator'))]"> (<xsl:value-of select="current()/role/roleTerm[not(@type='code')][not(contains(., 'creator'))]"/>)</xsl:if>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="child::namePart[@type='date']">
							<field name="author_display"><xsl:value-of select="$nameFull"/>, <xsl:value-of select="child::namePart[@type='date']/text()"/><xsl:value-of select="$special-role"/></field>
						</xsl:when>
						<xsl:otherwise>
							<field name="author_display"><xsl:value-of select="$nameFull"/><xsl:value-of select="$special-role"/></field>
						</xsl:otherwise>
					</xsl:choose>
					-->

					<xsl:choose>
						<xsl:when test="position() = 1 and child::mods:namePart[@type='date']">
							<field name="author_sort_facet">
								<xsl:value-of select="translate($nameFull, $uppercase, $lowercase)"/>
								<xsl:text> </xsl:text>
								<xsl:value-of select="translate(child::mods:namePart[@type='date']/text(), $uppercase, $lowercase)"/>
							</field>
						</xsl:when>
						<xsl:when test="position() = 1">
							<field name="author_sort_facet"><xsl:value-of select="translate($nameFull, $uppercase, $lowercase)"/></field>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:for-each>
				
				<!-- Publication information added for Bicentennial collection 9/2016-->
				
				<xsl:for-each select="//mods/originInfo/publisher">
					<xsl:choose>
						<xsl:when test="./text()">
							<field name="published_display">
								<xsl:value-of select="text()"/>
							</field>
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>

				<!-- series facet -->
				<xsl:for-each select="//mods/relatedItem[@type='series'][not(@displayLabel='Part of')]">
					<xsl:variable name="dateRange" xml:space="default">
						<xsl:choose>
							<xsl:when test="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='start'] and
								//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='end']"
								>, <xsl:value-of
									select="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='start']"
								/> - <xsl:value-of
									select="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='end']"
								/></xsl:when>
							<xsl:when
								test="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='start']"
								>, <xsl:value-of
									select="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='start']"
								/> - ?</xsl:when>
							<xsl:when
								test="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='end']"
								>, ? - <xsl:value-of
									select="//mods/relatedItem[1]/originInfo[1]/dateCreated[@point='end']"
								/>)</xsl:when>
							<xsl:otherwise/>
						</xsl:choose>
					</xsl:variable>
				    
				    <xsl:variable name="volume" xml:space="default">
				        <xsl:choose>
				            <xsl:when test="current()/part/detail[@type='volume']">
				                <xsl:value-of select="current()/part/detail[@type='volume']/number"/>
				            </xsl:when>
				            <xsl:otherwise/>
				        </xsl:choose>
				    </xsl:variable>
				    
				    <xsl:variable name="issue" xml:space="default">
				        <xsl:choose>
				            <xsl:when test="current()/part/detail[@type='issue']">
				                <xsl:value-of select="current()/part/detail[@type='issue']/number"/>
				            </xsl:when>
				            <xsl:otherwise/>
				        </xsl:choose>
				    </xsl:variable>
				    
					<field name="series_title_text">
						<xsl:for-each select="current()/titleInfo/descendant::*">
							<xsl:text> </xsl:text>
							<xsl:value-of select="."/>
						</xsl:for-each>
					</field>
					<field name="series_title_facet">
						<xsl:for-each select="current()/titleInfo/descendant::*[local-name() != 'nonSort']">
							<xsl:value-of select="."/>
							<xsl:if test="position() != last()">
								<xsl:text> </xsl:text>
							</xsl:if>
						</xsl:for-each>
					</field>
					<field name="series_title_display">
						<xsl:for-each select="current()/titleInfo/descendant::*[local-name() != 'nonSort']">
						    <xsl:value-of select="."/> 
						    <xsl:if test="$dateRange">
						        <xsl:value-of xml:space="default" select="$dateRange"/> 
						    </xsl:if>
						    <xsl:if test="$volume != ''">
						        <xsl:text>, Volume </xsl:text> <xsl:value-of xml:space="default" select="$volume"/> 
						    </xsl:if>
						    <xsl:if test="$issue != ''">
						        <xsl:text>, Issue </xsl:text> <xsl:value-of xml:space="default" select="$issue"/>
						    </xsl:if>
							<xsl:if test="position() != last()">
								<xsl:text> </xsl:text>
							</xsl:if>
						</xsl:for-each>
					</field>
				</xsl:for-each>

				<!-- date (range) -->
				<xsl:for-each select="/mods/relatedItem[1]/originInfo[1]">
					<field name="startDate_text">
						<xsl:value-of select="current()/dateCreated[@point='start']"/>
					</field>
					<field name="endDate_text">
						<xsl:value-of select="current()/dateCreated[@point='end']"/>
					</field>
				</xsl:for-each>

				<!-- format facet -->
				<field name="format_facet">Online</field>
				<field name="format_text">Online</field>
				<xsl:for-each select="//mods/typeOfResource">
					<xsl:choose>
						<!-- typeOfResource 'three dimensional object' -> Physical Object -->
						<xsl:when test="./text()='three dimensional object'">
							<field name="format_text">
								<xsl:value-of>Physical Object</xsl:value-of>
							</field>
							<field name="format_facet">
								<xsl:value-of>Physical Object</xsl:value-of>
							</field>
						</xsl:when>
						
						<!-- typeOfResource 'still image'  -> Visual Materials -->
						
						<xsl:when test="./text()='still image'">
							<field name="format_text">
								<xsl:value-of>Visual Materials</xsl:value-of>
							</field>
							<field name="format_facet">
								<xsl:value-of>Visual Materials</xsl:value-of>
							</field>
						</xsl:when>
						<xsl:otherwise>
			 			<field name="format_text">
							<xsl:value-of select="./text()"/>
						</field>
						<field name="format_facet">
							<xsl:value-of select="./text()"/>
						</field>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				
				<!-- Collection-specific Facets and Fields -->
				
				<!-- Vanity Fair -->
				<xsl:if test="//mods/relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title/text()='Cecil Lang Collection of Vanity Fair Illustrations'">
						<field name="has_optional_facet">category_facet</field>
						<field name="has_optional_facet">group_facet</field>
						<field name="has_optional_facet">signature_facet</field>
					<xsl:if test="//mods/note[@displayLabel='Category']/text()">
							<field name="category_facet">
								<xsl:value-of select="//mods/note[@displayLabel='Category']"/>
							</field>
							<field name="category_display">
								<xsl:value-of select="//mods/note[@displayLabel='Category']"/>
							</field>
					</xsl:if>
					<xsl:if test="//mods/note[@displayLabel='Group']/text()">
							<field name="group_facet">
								<xsl:value-of select="//mods/note[@displayLabel='Group']/substring-before(.,',')"/>
							</field>
							<field name="group_display">
								<xsl:value-of select="//mods/note[@displayLabel='Group']"/>
							</field>
					</xsl:if>
					<xsl:if test="//mods/note[@displayLabel='Signature']/text()">
							<field name="signature_facet">
								<xsl:value-of select="//mods/note[@displayLabel='Signature']"/>
							</field>
							<field name="signature_display">
								<xsl:value-of select="//mods/note[@displayLabel='Signature']"/>
							</field>
					</xsl:if>
				</xsl:if>
				
				<!-- End of Collection-specific Facets and Fields -->

				<!-- genre -->
				<xsl:for-each select="//mods/genre/text()">
					<field name="subject_text">
						<xsl:value-of select="current()"/>
					</field>
					<field name="subject_facet">
						<xsl:value-of select="current()"/>
					</field>
					<field name="subject_genre_facet">
						<xsl:value-of select="current()"/>
					</field>
				</xsl:for-each>

				<xsl:for-each select="//mods/abstract/text()">
					<field name="abstract_display">
						<xsl:value-of select="current()"/>
					</field>
					<field name="abstract_text">
						<xsl:value-of select="current()"/>
					</field>
				</xsl:for-each>

				<!-- physical description -->
				<!-- first put form subelement in Virgo Type -->
				<xsl:for-each select="//mods/physicalDescription/form/text()">
					<field name="genre_display">
						<xsl:value-of select="current()"/>
					</field>
					<field name="genre_facet">
						<xsl:value-of select="current()"/>
					</field>
				</xsl:for-each>

				<!--  then extent followed by note in Virgo Description -->
				<xsl:variable name="descriptionDisplay">
					<xsl:for-each select="//mods/physicalDescription/extent/text()">
						<xsl:value-of select="."/>
					<xsl:if test="//mods/physicalDescription/note">
                                                               <xsl:text>; </xsl:text>
					</xsl:if>

					</xsl:for-each>
					<xsl:for-each select="//mods/physicalDescription/note">
						<xsl:value-of select="./text()"/>
                                                       <xsl:if test="position() != last()">
                                                               <xsl:text>; </xsl:text>
                                                       </xsl:if>
					</xsl:for-each>
				</xsl:variable>
					
				<xsl:if test="$descriptionDisplay != ''">
					<field name="media_description_display">
						<xsl:value-of select="normalize-space($descriptionDisplay)"/>
					</field>
					<field name="desc_meta_file_display">
						<xsl:value-of select="normalize-space($descriptionDisplay)"/>
					</field>
					<field name="media_description_text">
						<xsl:value-of select="normalize-space ($descriptionDisplay)"/>
					</field>
				</xsl:if>


				<!-- staff note -->
				<xsl:for-each select="//mods/note[@displayLabel='staff']">
					<xsl:if test="./text() != ' '">
						<field name="note_text"><xsl:value-of select="current()"
							/></field>
						<!-- use if you want this data to be searchable -->
						<field name="note_display"><xsl:value-of select="current()"
							/></field>
						<!-- use if you want this data to be available for display in blacklight brief or full record -->
					</xsl:if>
				</xsl:for-each>

				<!-- use and access (rough version) -->
				<xsl:for-each select="//accessCondition[@type='restrictionOnAccess']">
					<xsl:variable name="accessRestriction">
						<!-- If access restriction element is empty, we will restrict object by default -->
						<xsl:choose>
							<xsl:when test="current()/text()">
								<xsl:value-of select="normalize-space(current())"/>
							</xsl:when>
							<xsl:otherwise>RESTRICTED</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<field name="access_display"><xsl:value-of select="current()/@displayLabel"/>: <xsl:value-of select="$accessRestriction"/></field>
					<field name="access_text">
						<xsl:value-of select="$accessRestriction"/>
					</field>
				</xsl:for-each>
				<xsl:for-each select="//accessCondition[@type='useAndReproduction']">
					<xsl:variable name="accessUse">
						<!-- If use restriction element is empty, we will restrict object by default -->
						<xsl:choose>
							<xsl:when test="current()/text()">
								<xsl:value-of select="normalize-space(current())"/>
							</xsl:when>
							<xsl:otherwise>RESTRICTED</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<field name="access_display"><xsl:value-of select="current()/@displayLabel"/>: <xsl:value-of select="$accessUse"/></field>
					<field name="access_text">
						<xsl:value-of select="$accessUse"/>
					</field>
				</xsl:for-each>
				<xsl:for-each select="//accessCondition[@type='local rights statements']">
					<field name="local_rights_statement_display"><xsl:value-of select="current()"/></field>
					<field name="local_rights_statement_text"><xsl:value-of select="current()"/></field>
				</xsl:for-each>

				<!-- 		this (arbitary) dateTime gets added to every record 			-->
				<!-- default blacklight behavior is to sort by this date (newest first) 			-->
				<!-- default behavior here is to plug in Feb 2, 2010 unless $ingestDate set	-->
				<xsl:choose>
					<xsl:when
						test="not($dateIngestNow) and //recordInfo/recordCreationDate[@encoding='marc']">
						<xsl:variable name="marcdate">
							<xsl:call-template name="format-marc-date">
								<xsl:with-param name="date"
									select="//recordInfo/recordCreationDate[@encoding='marc'][1]"/>
							</xsl:call-template>
						</xsl:variable>
						<field name="date_received_facet">
							<xsl:value-of select="$marcdate"/>
						</field>
					</xsl:when>
					<xsl:when test="not($dateIngestNow) and not($shadowedItem)">
						<field name="date_received_facet"><xsl:value-of
								select="fn:dateTime(xs:date('2010-02-01'), xs:time('12:00:00'))"
							/>Z</field>
					</xsl:when>
					<xsl:when test="not($dateIngestNow) and not($shadowedItem)">
						<!-- shadowed items get older timestamps so the don't come up first in Blacklight/Solr, whihc sorts on this field -->
						<field name="date_received_facet"><xsl:value-of
								select="fn:dateTime(xs:date('1999-12-31'), xs:time('23:59:59'))"
							/>Z</field>
					</xsl:when>
					<xsl:when test="//relatedItem[@type='series' and @displayLabel='Part of']/titleInfo[1]/title[1]/text() = 'Holsinger Studio Collection'">
						<field name="date_received_facet">2010-02-01T00:00:00Z</field>
					</xsl:when>
					<xsl:otherwise>
						<field name="date_received_facet">
							<xsl:value-of select="fn:current-dateTime()"/>
						</field>
					</xsl:otherwise>
				</xsl:choose>

				<!-- Test for deprecated method of determing whether the record is to be shadowed.  Otherwise, use newer method of relying upon descMetadata. -->
				<xsl:choose>
					<xsl:when test="$shadowedItem != 'false'">
						<field name="shadowed_location_facet">
							<xsl:value-of select="$shadowedItem"/>
						</field>
					</xsl:when>
					<xsl:when
						test="//mods:identifier[@displayLabel='Accessible index record displayed in VIRGO'][@invalid='yes']">
						<field name="shadowed_location_facet">HIDDEN</field>
					</xsl:when>
					<xsl:otherwise>
						<field name="shadowed_location_facet">VISIBLE</field>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:apply-templates select="*" />
			</doc>
		</add>
	</xsl:template>

    <xsl:template match="*">
    	<xsl:apply-templates select="*" />
    </xsl:template>
	
	<xsl:template match="*" mode="text">
	  <xsl:value-of select="text()" /><xsl:text> </xsl:text>
	  <xsl:apply-templates select="*" mode="text" />
	</xsl:template>
	
	<xsl:template match="nuds:nuds">
		<xsl:apply-templates select="*" />
		<xsl:variable name="notes"><xsl:apply-templates select="*" mode="text" /></xsl:variable>
		<field name="notes_text">
			<xsl:value-of select="normalize-space($notes)"/>
		</field>
	</xsl:template>
    	
    <xsl:template match="nuds:objectType">
    	<field name="format_facet">Physical Object</field>
    	<xsl:if test="not(text() = 'Coin')">
    		<field name="format_facet">Coin</field>    		
    	</xsl:if>
    	<field name="format_facet"><xsl:value-of select="text()"/></field>
    </xsl:template>	
    	
    <xsl:template match="nuds:title">
    	<field name="main_title_display">
    		<xsl:value-of select="current()"/>
    	</field>
    	<!-- there can be only one! title facet will BREAK solr sorting if multiple values found -->
    	<field name="title_facet">
    		<xsl:value-of select="current()"/>
    	</field>
    	<field name="title_text">
    		<xsl:value-of select="current()"/>
    	</field>
    	<field name="title_display">
    		<xsl:value-of select="current()"/>
    	</field>
    	<field name="title_sort_facet">
    		<xsl:value-of select="translate(current(), $uppercase, $lowercase)"/>
    	</field>
    </xsl:template>

    <xsl:template match="nuds:collection">
    	<xsl:variable name="collection"><xsl:value-of select="text()" /></xsl:variable>
    	<field name="source_facet"><xsl:value-of select="$collection" /></field>
    	<field name="location_facet"><xsl:value-of select="$collection" /></field>
    	<xsl:if test="starts-with($collection, 'The ')">
    		<field name="collection_facet">Coins of the <xsl:value-of select="substring-after($collection, 'The ')"/></field>    		
    	</xsl:if>
    	<xsl:if test="not(starts-with($collection, 'The '))">
    		<field name="collection_facet">Coins of <xsl:value-of select="$collection"/></field>
    	</xsl:if>
    </xsl:template>
	<xsl:template match="nuds:findspotDesc">
		<xsl:variable name="findspotUrl"><xsl:value-of select="@xlink:href"/><xsl:if test="starts-with(@xlink:href, 'http://nomisma.org')">.rdf</xsl:if></xsl:variable> 
		<xsl:comment>Retreived content from <xsl:value-of select="$findspotUrl" /></xsl:comment>
		<field name="collection_facet"><xsl:value-of select="document($findspotUrl)/rdf:RDF/nmo:Hoard/skos:prefLabel"/></field>
	</xsl:template>
	
	<xsl:template match="nuds:otherRecordId[@semantic = 'dcterms:replaces']">
		<field name="url_display"><xsl:value-of select="text()"/></field>
	</xsl:template>
	
	<xsl:template match="nuds:geogname">
		<field name="region_facet"><xsl:value-of select="text()" /></field>
	</xsl:template>
	
	<xsl:template match="nuds:geogname[@xlink:role='mint']">
		<field name="mint_display"><xsl:value-of select="text()"/></field>
	</xsl:template>
	
	<xsl:template match="nuds:denomination">
		<field name="denomination_display"><xsl:value-of select="text()"/></field>
	</xsl:template>
    
	<xsl:template match="nuds:material">
		<field name="material_display"><xsl:value-of select="text()"/></field>
	</xsl:template>
    
	<xsl:template match="nuds:persname">
		<field name="subject_facet"><xsl:value-of select="text()" /></field>
	</xsl:template>
	
	<xsl:template match="nuds:control/nuds:recordId">
		<field name="alternate_id_facet"><xsl:value-of select="concat('n', translate(text(), '.', '_'))"/></field>
		<field name="accession_display"><xsl:value-of select="text()"/></field>
	</xsl:template>
	
	<xsl:template match="nuds:typeDesc/nuds:dateRange/nuds:fromDate">
	    <xsl:call-template name="addDateFields"><xsl:with-param name="standardDate" select="@standardDate" /></xsl:call-template>
	</xsl:template>

	<xsl:template match="nuds:typeDesc/nuds:date">
		<xsl:call-template name="addDateFields"><xsl:with-param name="standardDate" select="@standardDate" /></xsl:call-template>
	</xsl:template>
	

    <xsl:template name="addDateFields">
    	<xsl:param name="standardDate" required="yes" />
    	<field name="year_multisort_i"><xsl:value-of select="$standardDate"/></field>
    </xsl:template>

	<xsl:template name="format-marc-date">
		<xsl:param name="date"/>
		<xsl:variable name="prefix">
			<xsl:choose>
				<xsl:when test="fn:substring($date, 1, 1) = '0'">
					<xsl:text>20</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>19</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="output">
			<xsl:text>20</xsl:text><xsl:value-of select="fn:substring($date, 1, 2)"/>-<xsl:value-of
				select="fn:substring($date, 3, 2)"/>-<xsl:value-of
				select="fn:substring($date, 5, 2)"/>
		</xsl:variable>
		<xsl:if test="fn:string-length($date) = 6">
			<xsl:value-of select="$output"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="build-dates">
		<xsl:param name="date-node" select="'No node sent to template build-dates'"/>
		<xsl:for-each select="$date-node[1]">
			<xsl:choose>
				<xsl:when test="matches(., '^\d{4}')">
					<xsl:variable name="yearOnly">
						<xsl:value-of select="substring(., 1, 4)"/>
					</xsl:variable>
			<!--		<field name="year_display">
					<xsl:value-of select="."/>
					</field>-->
					<!-- there can be only one year_multisort_i in a Solr record -->
					<xsl:if test="current()[@keyDate='yes']">
						<field name="year_multisort_i">
							<xsl:value-of select="$yearOnly"/>
						</field>
					</xsl:if>
					<!-- if dates available form a range, process elsewhere -->
					<xsl:choose>
						<xsl:when test="current()[@point='start'] and $date-node[@point='end']">
							<xsl:call-template name="build-daterange">
								<xsl:with-param name="date-pair" select="$date-node[@point='start' or @point='end']"></xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<field name="date_text">
								<xsl:value-of select="."/>
							</field>
							<field name="year_display">
								<xsl:if test="current()[@qualifier='approximate']">
									<xsl:text>circa </xsl:text>
								</xsl:if>
								<xsl:value-of select="."/>
							</field>
							<field name="published_date_display">
								<xsl:value-of select="."/>
							</field>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<!-- handle EDTF dates with u denoting uncertainty in digit - for display -->
				<!-- use first year in range for sorting, etc. 20161104 slb -->
				<xsl:when test="matches(., '^\d{3}u')">
					<xsl:variable name="yearOnly">
						<xsl:value-of select="substring(., 1, 4)"/>
					</xsl:variable>
					<field name="date_text">	
						<xsl:value-of select="."/>
					</field>
					<field name="year_display">	
						<xsl:value-of select="$yearOnly"/>
					</field>
					<xsl:if test="current()[@keyDate='yes']">
						<field name="year_multisort_i">
							<xsl:value-of select="replace($yearOnly,'u','0')"/>
						</field>
					</xsl:if>
					<field name="published_date_display">
						<xsl:value-of select="."/>
					</field>
				</xsl:when>
				<xsl:when test="matches(., '^\d{2}uu')">
					<xsl:variable name="yearOnly">
						<xsl:value-of select="substring(., 1, 4)"/>
					</xsl:variable>
					<field name="date_text">	
						<xsl:value-of select="."/>
					</field>
					<field name="year_display">
						<xsl:value-of select="$yearOnly"/>
					</field>
					<xsl:if test="current()[@keyDate='yes']">
						<field name="year_multisort_i">
							<xsl:value-of select="replace($yearOnly,'uu','00')"/>
						</field>
					</xsl:if>
					<field name="published_date_display">
						<xsl:value-of select="."/>
					</field>
				</xsl:when>
					
				<xsl:when test="./text() = 'Unknown Date' or ./text() = 'Unknown date'">
					<field name="published_date_display">
						<xsl:value-of select="."/>
					</field>
				</xsl:when>
				<xsl:otherwise>
					<field name="published_date_display">
						<xsl:value-of select="."/>
					</field>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="build-daterange">
		<xsl:param name="date-pair" select="'No nodes sent to template build-daterange'"/>
		<xsl:variable name="range-text">
			<xsl:value-of select="$date-pair[@point='start']"/> - <xsl:value-of select="$date-pair[@point='end']"/>
		</xsl:variable>
		<field name="year_display">
			<xsl:if test="$date-pair[@point='start'][@qualifier='approximate']"><xsl:text>circa </xsl:text></xsl:if>
			<xsl:value-of select="$range-text"/>
		</field>
		<field name="date_text">
			<xsl:value-of select="$range-text"/>
		</field>
	</xsl:template>
</xsl:stylesheet>
