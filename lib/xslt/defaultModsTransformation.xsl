<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:uva="http://fedora.lib.virginia.edu/relationships#">

    <xsl:param name="debug" required="no" select="false()" />

	<!-- Required Parameters -->

	<!-- Unique identifier for object -->
	<xsl:param name="pid">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<!-- level of Solr publication for this object. -->
	<xsl:param name="destination">
		<xsl:value-of select="false()"/>
	</xsl:param>
     
        <!-- Date DL Ingest for the object being indexed for the creation of date_received_facet and date_received_text -->
	<xsl:param name="dateReceived">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<!-- Datetime that this index record was produced.  Format:YYYYMMDDHHMM -->
	<xsl:param name="dateIngestNow">
		<xsl:value-of select="false()"/>
	</xsl:param>
	
	<xsl:param name="policyFacet">
		<xsl:value-of select="false()"/>
	</xsl:param>
	
	<xsl:param name="useRightsString" required="yes" />

	<!-- Facet use for blacklight to group digital objects.  Default value: 'UVA Library Digital Repository'. -->
	<xsl:param name="sourceFacet">
		<xsl:value-of select="'UVA Library Digital Repository'"/>
	</xsl:param>

	<!-- A URL to get the IIIF presentation metadata -->
	<xsl:param name="iiifManifest">
		<xsl:value-of select="false()"/>
	</xsl:param>
	
	<xsl:param name="iiifRoot">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<xsl:param name="pdfServiceUrl" />
	
	<xsl:param name="pageCount" />
	
	<xsl:param name="permanentUrl">
		<xsl:value-of select="false()" />
	</xsl:param>
	
    <!-- A base URL, for which when a page pid is appended will provide an endpoint to 
    	 download a large copy of the given image with citation and rights information embedded.-->
	<xsl:param name="rightsWrapperServiceUrl" />
	
	<xsl:param name="exemplarPid">
		<xsl:value-of select="false()"/>
	</xsl:param>
	
	<!-- Will contain the transcription text of one object (in the case of an image object), or a concatenated string of all transcription text belonging to children objects (in the case of a bibliographic or colelction object). -->
	<xsl:param name="totalTranscriptions">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<!-- like "totalTranscriptions" but a URL at which the transcriptions can be fetched in plain text. -->
	<xsl:param name="transcriptionUrl" />

	<!-- Will contain the title text of one object (in the case of an image object), or a concatenated string of all title text belonging to children objects (in the case of a bibliographic or colelction object). -->
	<xsl:param name="totalTitles">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<!-- Will contain the description text of one object (in the case of an image object), or a concatenated string of all description text belonging to children objects (in the case of a bibliographic or colelction object). -->
	<xsl:param name="totalDescriptions">
		<xsl:value-of select="false()"/>
	</xsl:param>
		
	<!-- like "totalDescriptions" but a URL at which the descriptions can be fetched in plain text. -->
	<xsl:param name="descriptionUrl" />

	<!-- While this can be passed to the stylesheet as a params, this method of determination is to be supplanted by an investiagtion of the descMetadata (as written below).  This param is to be deprecated. -->
	<xsl:param name="shadowedItem">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<!-- Import object's solr record for the analog equivalent to build format_facet fields. -->
	<xsl:param name="analogSolrRecord">
		<xsl:value-of select="false()"/>
	</xsl:param>

	<!-- Optional Parameters -->
	<!-- If this is a child object, we will need many of the fields of the parent included in the child (if it is going to be made uniquely discoverable). -->
	<xsl:param name="parentModsRecord">
		<xsl:value-of select="false()"/>
	</xsl:param>


	<!-- If this item belongs to a specific collection of objects, that information should be encoded in the above mentioned XPath location. -->
	<xsl:param name="digitalCollectionFacet"
		select="//relatedItem[@type='series']/titleInfo[1]/title[1]"/>

	<!-- Global Variables -->
	<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz    '"/>
	<!-- whitespace in select is meaningful -->
	<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ,;-:'"/>
	
	<!-- AC added this to remove trailing periods from $special-role  -->
	<xsl:variable name="periods" select="'.'"/>
	<xsl:variable name="noperiods" select="' '"/>
	<xsl:variable name='newline'><xsl:text>
</xsl:text></xsl:variable>
	
	<xsl:param name="publishedDateFacet">
		<xsl:value-of select="'More than 50 years ago'"/>
	</xsl:param>

	<xsl:output encoding="UTF-8" media-type="text/xml" xml:space="preserve" indent="yes"/>
	<xsl:strip-space elements="*"/>
	<xsl:template match="text()"/>
	<xsl:template match="/">
		<xsl:variable name="mode" select="'primary'"/>
		<add>
			<doc>
				<field name="id" source="{$mode}">
					<xsl:value-of select="$pid"/>
				</field>
				<field name="date_indexed_facet" source="{$mode}">
					<xsl:value-of select="$dateIngestNow"/>
				</field>
				<field name="date_received_facet" source="{$mode}">
					<xsl:value-of select="$dateReceived"/>
				</field>
				<field name="date_received_text" source="{$mode}">
					<xsl:value-of select="$dateReceived"/>
				</field>
				<field name="released_facet" source="{$mode}">
					<xsl:value-of select="$destination"/>
				</field>
				
				<xsl:if test="$policyFacet != 'false'">
					<field name="policy_facet" source="{$mode}">
						<xsl:value-of select="$policyFacet"/>
					</field>
				</xsl:if>

				<field name="source_facet" source="{$mode}">
					<xsl:value-of select="$sourceFacet"/>
				</field>
				
				<field name="published_date_facet" source="{$mode}">
					<xsl:value-of select="$publishedDateFacet"/>
				</field>

				<xsl:if test="$digitalCollectionFacet != ''">
					<field name="digital_collection_facet" source="{$mode}">
						<xsl:value-of select="$digitalCollectionFacet"/>
					</field>
				</xsl:if>
				
				<xsl:if test="$pdfServiceUrl">
					<xsl:if test="not($pageCount = '1')">
						<field name="feature_facet">pdf_service</field>
						<field name="pdf_url_display"><xsl:value-of select="$pdfServiceUrl"/></field>
					</xsl:if>
				</xsl:if>
				<field name="thumbnail_url_display"><xsl:value-of select="$iiifRoot" /><xsl:value-of select="$exemplarPid" />/full/!125,125/0/default.jpg</field>
				<field name="feature_facet">iiif</field>
				<field name="feature_facet">dl_metadata</field>
				<field name="iiif_presentation_metadata_display">
					<xsl:value-of select="unparsed-text($iiifManifest)" />
				</field>

				<xsl:if test="$totalTranscriptions != 'false'">
					<field name="transcription_fulltext" source="{$mode}">
						<xsl:value-of select="$totalTranscriptions"/>
					</field>
				</xsl:if>
				<xsl:if test="$transcriptionUrl">
					<field name="transcription_fulltext" source="{$mode}">
						<xsl:value-of select="unparsed-text($transcriptionUrl)"/>
					</field>
				</xsl:if>

				<xsl:if test="$totalDescriptions != 'false'">
					<field name="descriptions_fulltext" source="{$mode}">
						<xsl:value-of select="$totalDescriptions"/>
					</field>
				</xsl:if>
				<xsl:if test="$descriptionUrl">
					<field name="descriptions_fulltext" source="{$mode}">
						<xsl:value-of select="unparsed-text($descriptionUrl)"/>
					</field>
				</xsl:if>

				<xsl:if test="$totalTitles != 'false'">
					<field name="titles_fulltext" source="{$mode}">
						<xsl:value-of select="$totalTitles"/>
					</field>
				</xsl:if>

				<xsl:call-template name="getTitle">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>
				<xsl:call-template name="getDescription">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>
				<xsl:call-template name="getLanguageNote">
					<xsl:with-param name="mode" select="primary"/>
				</xsl:call-template>
				<xsl:call-template name="getLocalNote">
					<xsl:with-param name="mode" select="primary"/>
				</xsl:call-template>				
				<xsl:call-template name="getPublishedDate">
					<xsl:with-param name="mode" select="primary"/>
				</xsl:call-template>
				<xsl:call-template name="getSubjects">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>
				<xsl:call-template name="getAuthor">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>
				<xsl:call-template name="getLanguage">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>
				<xsl:call-template name="getSeries">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>
				<xsl:call-template name="getCopyInformation">
					<xsl:with-param name="mode" select="'primary'"/>
				</xsl:call-template>

				<!-- Test for deprecated method of determing whether the record is to be shadowed.  Otherwise, use newer method of relying upon descMetadata. -->
				<xsl:choose>
					<xsl:when test="$shadowedItem != 'false'">
						<field name="shadowed_location_facet" source="{$mode}">
							<xsl:value-of select="$shadowedItem"/>
						</field>
					</xsl:when>
					<xsl:when
						test="//mods:identifier[@displayLabel='Accessible index record displayed in VIRGO'][@invalid='yes']">
						<field name="shadowed_location_facet" source="{$mode}">HIDDEN</field>
					</xsl:when>
					<xsl:otherwise>
						<field name="shadowed_location_facet" source="{$mode}">VISIBLE</field>
					</xsl:otherwise>
				</xsl:choose>

				<!-- PARENT RECORD TRANSFORMATION -->
				<xsl:if test="$parentModsRecord != 'false'">
					<xsl:apply-templates select="document($parentModsRecord)/*[local-name()='mods']"
						mode="secondary"/>
				</xsl:if>

				<!-- ANALOG SOLR RECORD TRANSFORMATION -->
				<xsl:variable name="solrRecord" select="document($analogSolrRecord)" />
				<xsl:apply-templates select="$solrRecord" mode="quaternary"/>

				<!-- The "right_wrapper" feature indicates that we should provide page-level links
					 that include rights information and specifically that that rights information will be
					 stored in the "rights_wrapper_display" field, and a service URL will be included in the
					 rights_wrapper_url_display field to which just the page pid should be appended.
			     -->
				<xsl:if test="$rightsWrapperServiceUrl">
					<field name="feature_facet">rights_wrapper</field>
					<field name="rights_wrapper_url_display"><xsl:value-of select="$rightsWrapperServiceUrl" /></field>
					<xsl:variable name="marcCitation">
						<xsl:call-template name="extractMarcSubfield">
							<xsl:with-param name="marcCDATA" select="$solrRecord//doc/str[@name='marc_display']" />
							<xsl:with-param name="datafield" select="524" />
							<xsl:with-param name="subfield" select="a" />
						</xsl:call-template>
					</xsl:variable>
					
					<xsl:variable name="citation">
						<xsl:choose>
							<xsl:when test="$marcCitation != ''">
								<xsl:value-of select="$marcCitation" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="titleFields">
									<xsl:call-template name="getTitle">
										<xsl:with-param name="mode" select="'primary'"/>
									</xsl:call-template>
								</xsl:variable>
								<xsl:value-of select="$titleFields/field[@name='main_title_display']/text()" />
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
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:comment select="concat('Use Rights: ', $useRightsString)" />
					<field name="rights_wrapper_display">
						<xsl:value-of select="$citation" />
						<xsl:value-of select="$newline" />
						<xsl:if test="$permanentUrl">
							<xsl:value-of select="$permanentUrl" />
							<xsl:value-of select="$newline" />
						</xsl:if>
						<xsl:value-of select="$newline" />
						<xsl:choose>
							<xsl:when test="$useRightsString = 'In Copyright'">
								<xsl:text>The UVA Library has determined that this work is in-copyright.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>See the full Virgo Terms of Use at http://search.lib.virginia.edu/terms.html for more information.</xsl:text>
							</xsl:when>
							<xsl:when test="$useRightsString = 'No Known Copyright'">
								<xsl:text>The UVA Library is not aware of any copyright interest in this work.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>This single copy was produced for purposes of private study, scholarship, or research. You are responsible for making a rights determination for your own uses.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>See the full Virgo Terms of Use at http://search.lib.virginia.edu/terms.html for more information.</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<!-- Default to Copyright Not Evaluated -->
								<xsl:text>The UVA Library has not evaluated the copyright status of this work.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>Copyright and other restrictions may apply to any further use of this image.</xsl:text>
								<xsl:value-of select="$newline" />
								<xsl:text>See the full Virgo Terms of Use at http://search.lib.virginia.edu/terms.html for more information.</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</field>
				</xsl:if>

			</doc>
		</add>
	</xsl:template>
	
	<xsl:template name="extractMarcSubfield">
		<xsl:param name="marcCDATA" required="yes" />
		<xsl:param name="datafield" required="yes" />
		<xsl:param name="subfield" required="yes" />
		<xsl:variable name="open" select="concat('datafield tag=&quot;', $datafield)" />
		<xsl:variable name="firstAfter" select="substring-after($marcCDATA, $open)" />
		<xsl:variable name="datafieldText" select="substring-before(substring-after(substring-before(substring-after($firstAfter, '&gt;'), '&lt;/datafield&gt;'), '&gt;'), '&lt;')"/>
		<xsl:if test="$debug">
		  <xsl:message select="concat('marc: ', $marcCDATA)" />
		  <xsl:message select="concat('open: ', $open)" />
		  <xsl:message select="concat('firstAfter: ', $firstAfter)" />
		  <xsl:message select="concat('Datafield Text: ', $datafieldText)" />
		</xsl:if>
        <xsl:value-of select="$datafieldText" />
	</xsl:template>

	<xsl:template match="mods:mods" mode="secondary">
		<xsl:variable name="mode" select="secondary"/>

		<xsl:call-template name="getTitle">
			<xsl:with-param name="mode" select="'secondary'"/>
		</xsl:call-template>

		<xsl:call-template name="getAuthor">
			<xsl:with-param name="mode" select="'secondary'"/>
		</xsl:call-template>

		<xsl:call-template name="getSubjects">
			<xsl:with-param name="mode" select="'secondary'"/>
		</xsl:call-template>

		<xsl:call-template name="getLanguage">
			<xsl:with-param name="mode" select="'secondary'"/>
		</xsl:call-template>

		<xsl:call-template name="getCopyInformation">
			<xsl:with-param name="mode" select="'secondary'"/>
		</xsl:call-template>

		<xsl:call-template name="getSeries">
			<xsl:with-param name="mode" select="'secondary'"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="doc" mode="quaternary">
		<xsl:variable name="mode" select="quaternary"/>
		<xsl:call-template name="getFormatFacet">
			<xsl:with-param name="mode" select="'quaternary'"/>
		</xsl:call-template>
		<xsl:call-template name="getMarcDisplay">
			<xsl:with-param name="mode" select="'quaternary'"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="getTitle">
		<xsl:param name="mode"/>

		<!-- Get and process the main title, not the uniform or alternate.  The title from the primary document is used to create the main_title_display and the title_facet -->
		<xsl:choose>
			<xsl:when test="$mode != 'secondary'">
				<field name="main_title_display" source="{$mode}">
					<xsl:for-each select="//mods:mods/mods:titleInfo[not(@type)]/descendant::*">
						<xsl:if test="name()='mods:subTitle'">
							<xsl:text> : </xsl:text>
						</xsl:if>
						<xsl:value-of select="current()[normalize-space()]"/>
					</xsl:for-each>
				</field>
				<!-- there can be only one! title facet will BREAK solr sorting if multiple values found -->
				<field name="title_facet" source="{$mode}">
					<xsl:for-each select="//mods:mods/mods:titleInfo[not(@type)]/descendant::*">
						<xsl:value-of select="translate(current(), $uppercase, $lowercase)"/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</field>
				<field name="title_sort_facet" source="{$mode}">
					<xsl:for-each select="//mods:mods/mods:titleInfo[not(@type)]/descendant::*">
						<xsl:value-of select="translate(current(), $uppercase, $lowercase)"/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</field>
			</xsl:when>
		</xsl:choose>

		<!-- All titles get title_text and title_display -->
		<field name="title_text" source="{$mode}">
			<xsl:for-each select="//mods:mods/mods:titleInfo[not(@type)]/descendant::*">
				<xsl:if test="name()='mods:subTitle'">
					<xsl:text> : </xsl:text>
				</xsl:if>
				<xsl:value-of select="current()[normalize-space()]"/>
			</xsl:for-each>
		</field>
		<field name="title_display" source="{$mode}">
			<xsl:for-each select="//mods:mods/mods:titleInfo[not(@type)]/descendant::*">
				<xsl:if test="name()='mods:subTitle'">
					<xsl:text> : </xsl:text>
				</xsl:if>
				<xsl:value-of select="current()[normalize-space()]"/>
			</xsl:for-each>
		</field>

	</xsl:template>

	<xsl:template name="getAuthor">
		<xsl:param name="mode"/>
		<!-- creator -->
		<xsl:for-each select="//mods:mods/mods:name[@type='personal']">
			<xsl:variable name="fname">
				<xsl:choose>
					<xsl:when
						test="current()/mods:namePart[@type='family'] and current()/mods:namePart[@type='family'][substring-before(., ',')!='']">
						<xsl:value-of
							select="substring-before(current()/mods:namePart[@type='family'], ',')"
						/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="current()/mods:namePart[@type='family']"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="gname">
				<xsl:choose>
					<xsl:when
						test="current()/mods:namePart[@type='given'] and current()/mods:namePart[@type='given'][substring-before(., ',')!='']">
						<xsl:value-of
							select="substring-before(current()/namePart[@type='given'], ',')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="current()/namePart[@type='given']"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="term-of-address">
				<xsl:choose>
					<xsl:when
						test="current()/mods:namePart[@type='termsOfAddress'] and current()/mods:namePart[@type='termsOfAddress'][substring-before(., ',')!='']">
						<xsl:value-of
							select="substring-before(current()/mods:namePart[@type='termsOfAddress'], ',')"
						/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="current()/mods:namePart[@type='termsOfAddress']"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="nameFull">
				<xsl:choose>
					<xsl:when
						test="current()/mods:namePart[@type='family'] and current()/mods:namePart[@type='given']">
						<xsl:value-of select="$fname"/>
						<xsl:text>, </xsl:text>
						<xsl:value-of select="$gname"/>
					</xsl:when>
					<xsl:when
						test="current()/namePart[@type='family'] and current()/mods:namePart[@type='termsOfAddress']">
						<xsl:value-of select="$fname"/>
						<xsl:text>, </xsl:text>
						<xsl:value-of select="$term-of-address"/>
					</xsl:when>
					<xsl:when
						test="current()/mods:namePart[@type='given'] and current()/mods:namePart[@type='termsOfAddress']">
						<xsl:value-of select="$gname"/>
						<xsl:text>, </xsl:text>
						<xsl:value-of select="$term-of-address"/>
					</xsl:when>
				  <xsl:when test="current()/mods:namePart[not(@type)]">
				    <xsl:value-of select="current()/mods:namePart[not(@type)]" />
				    <xsl:if test="current()/mods:namePart[@type='termsOfAddress']">
				      <xsl:text>, </xsl:text>
				      <xsl:value-of select="$term-of-address"/>
				    </xsl:if>
				  </xsl:when>
					<xsl:when
						test="contains(current()/mods:namePart[not(@type = 'date')][not(@type = 'termsOfAddress')][1], ',') and count(current()/mods:namePart) = 1">
						<xsl:value-of select="current()/mods:namePart[1]"/>
					</xsl:when>
					<xsl:when test="current()/mods:namePart[not(@type = 'date')]">
						<xsl:for-each select="current()/mods:namePart[not(@type = 'date')]">
							<xsl:choose>
								<xsl:when test="contains(., ',') and substring-after(., ',')=''">
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
			<field name="author_text" source="{$mode}">
				<xsl:value-of select="$nameFull"/>
			</field>
			<xsl:variable name="special-role">
				<xsl:if	test="current()/mods:role/mods:roleTerm[not(@type='code')][not(contains(., 'creator'))]"> 
					<xsl:value-of select="translate((current()/mods:role/mods:roleTerm[not(@type='code')][not(contains(., 'creator'))])[1], $periods, $noperiods)"/>
					<!--  If there are multiple roles, we're only using the first here. Need to review if that's OK or should they be appended? -->
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="authorDisplayFacet">
				<xsl:choose>
					<xsl:when test="child::mods:namePart[@type='date']">
						<xsl:if test="$special-role != ''">
							<xsl:value-of select="$nameFull"/>,	<xsl:value-of select="child::mods:namePart[@type='date']/text()"/>, <xsl:value-of select="$special-role"/>
						</xsl:if>
						<xsl:if test="$special-role = ''">
							<xsl:value-of select="$nameFull"/>,	<xsl:value-of select="child::mods:namePart[@type='date']/text()"/>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="$special-role != ''">
							<xsl:value-of select="$nameFull"/>, <xsl:value-of select="$special-role"/>
						</xsl:if>
						<xsl:if test="$special-role = ''">
							<xsl:value-of select="$nameFull"/>
						</xsl:if>
					</xsl:otherwise>					
				</xsl:choose>
			</xsl:variable>
			<field name="author_facet" source="{$mode}"><xsl:value-of select="normalize-space($authorDisplayFacet)"/></field>
			<xsl:if test="current()[@usage='primary']">	
				<field name="author_display" source="{$mode}"><xsl:value-of select="normalize-space($authorDisplayFacet)"/></field>
				<xsl:choose>
					<xsl:when test="position() = 1 and child::mods:namePart[@type='date']">
						<field name="author_sort_facet" source="{$mode}">
							<xsl:value-of select="translate($nameFull, $uppercase, $lowercase)"/>
							<xsl:text> </xsl:text>
							<xsl:value-of
								select="translate(child::mods:namePart[@type='date']/text(), $uppercase, $lowercase)"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="$special-role"
							/>
						</field>
					</xsl:when>
					<xsl:when test="position() = 1">
						<field name="author_sort_facet" source="{$mode}">
							<xsl:value-of select="translate($nameFull, $uppercase, $lowercase)"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="$special-role"
							/>
						</field>
					</xsl:when>
					<xsl:otherwise/>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
		<!-- corporate author -->
		<xsl:for-each select="//mods:mods/mods:name[@type='corporate']">
			<xsl:variable name="corporateName">
				<xsl:value-of select="current()/mods:namePart/text()"/>
			</xsl:variable>
			<xsl:variable name="corporateRoleTerm">
				<xsl:value-of select="current()/mods:role/mods:roleTerm/text()"/>
			</xsl:variable>
			<field name="author_facet"><xsl:value-of select="$corporateName"/><xsl:text>, </xsl:text><xsl:value-of select="translate($corporateRoleTerm, $periods, $noperiods)"/></field>
			<field name="author_text"><xsl:value-of select="$corporateName"/><xsl:text>, </xsl:text><xsl:value-of select="translate($corporateRoleTerm, $periods, $noperiods)"/></field>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getDescription">
		<xsl:param name="mode"/>
		<xsl:for-each select="//mods:note[@type='description']">
			<field name="note_text" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<field name="note_display" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<xsl:choose>
				<xsl:when test="$mode = 'secondary'"> </xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getLanguageNote">
		<xsl:param name="mode"/>
		<xsl:for-each select="//mods:note[@type='language']">
			<field name="language_note_text" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<field name="language_note_display" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<xsl:choose>
				<xsl:when test="$mode = 'secondary'"> </xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getLocalNote">
		<xsl:param name="mode"/>
		<xsl:for-each select="//mods:note[@type='local']">
			<field name="local_note_text" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<field name="local_note_display" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<xsl:choose>
				<xsl:when test="$mode = 'secondary'"> </xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="getPublishedDate">
		<xsl:param name="mode"/>
		
		<!-- SOLR can take only one year_multisort_i field, so we need to choose which mods element to utilize -->
		<xsl:for-each select="//mods:mods/mods:originInfo[1]">
			<xsl:choose>
				<xsl:when test="current()/mods:dateIssued[@encoding='marc'][1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="mode" select="primary"/>
						<xsl:with-param name="date-node"
							select="current()/mods:dateIssued[@encoding='marc'][1]"/>
						
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="current()/mods:dateIssued[1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="date-node"
							select="current()/mods:dateIssued[1]"/>
						<xsl:with-param name="mode" select="primary"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="current()/mods:dateCreated[1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="date-node"
							select="current()/mods:dateCreated[1]"/>
						<xsl:with-param name="mode" select="primary"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="current()/mods:dateCaptured[1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="date-node"
							select="current()/mods:dateCaptured[1]"/>
						<xsl:with-param name="mode" select="primary"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="current()/mods:dateValid[1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="date-node"
							select="current()/mods:dateValid[1]"/>
						<xsl:with-param name="mode" select="primary"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="current()/mods:copyrightDate[1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="date-node"
							select="current()/mods:copyrightDate[1]"/>
						<xsl:with-param name="mode" select="primary"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="current()/mods:dateOther[1]">
					<xsl:call-template name="build-dates">
						<xsl:with-param name="date-node"
							select="current()/mods:dateOther[1]"/>
						<xsl:with-param name="mode" select="primary"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getSubjects">
		<xsl:param name="mode"/>
		<xsl:for-each select="//mods:subject">
			<xsl:variable name="text-content">
				<xsl:for-each select="./descendant::node()/text()[normalize-space()]">
					<!-- add double dash to all trailing subfields -->
					<xsl:if test="position() != 1">
						<xsl:text> -- </xsl:text>
					</xsl:if>
					<xsl:copy-of select="normalize-space(current())"/>
				</xsl:for-each>
			</xsl:variable>
			<field name="subject_text" source="{$mode}">
				<xsl:value-of select="$text-content"/>
			</field>
			<field name="subject_facet" source="{$mode}">
				<xsl:value-of select="$text-content"/>
			</field>
			<field name="subject_genre_facet" source="{$mode}">
				<xsl:value-of select="$text-content"/>
			</field>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getCopyInformation">
		<xsl:param name="mode"/>
		<xsl:for-each select="//mods:mods/mods:location/mods:holdingSimple/mods:copyInformation">
			<xsl:variable name="normalizedLibraryName">
				<xsl:choose>
					<xsl:when test="mods:subLocation = 'ALDERMAN'">Alderman</xsl:when>
					<xsl:when test="mods:subLocation = 'ASTRONOMY'">Astronomy</xsl:when>
					<xsl:when test="mods:subLocation = 'ATSEA'">Semester at Sea</xsl:when>
					<xsl:when test="mods:subLocation = 'BIO-PSYCH'">Biology &amp;
						Psychology</xsl:when>
					<xsl:when test="mods:subLocation = 'BLANDY'">Blandy Experimental Farm</xsl:when>
					<xsl:when test="mods:subLocation = 'CHEMISTRY'">Chemistry</xsl:when>
					<xsl:when test="mods:subLocation = 'CLEMONS'">Clemons</xsl:when>
					<xsl:when test="mods:subLocation = 'EDUCATION'">Education</xsl:when>
					<xsl:when test="mods:subLocation = 'DARDEN'">Darden Business School</xsl:when>
					<xsl:when test="mods:subLocation = 'HEALTHSCI'">Health Sciences</xsl:when>
					<xsl:when test="mods:subLocation = 'FINE-ARTS'">Fine Arts</xsl:when>
					<xsl:when test="mods:subLocation = 'IVY'">Ivy Stacks</xsl:when>
					<xsl:when test="mods:subLocation = 'LAW'">Law School</xsl:when>
					<xsl:when test="mods:subLocation = 'MATH'">Mathematics</xsl:when>
					<xsl:when test="mods:subLocation = 'MEDIA-CTR'">Robertson Media
						Center</xsl:when>
					<xsl:when test="mods:subLocation = 'MT-LAKE'">Mountain Lake</xsl:when>
					<xsl:when test="mods:subLocation = 'MUSIC'">Music </xsl:when>
					<xsl:when test="mods:subLocation = 'PHYSICS'">Physics</xsl:when>
					<xsl:when test="mods:subLocation = 'SCI-ENG'">Brown SEL</xsl:when>
					<xsl:when test="mods:subLocation = 'SPEC-COLL'">Special Collections</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<field name="library_facet" source="{$mode}">
				<xsl:value-of select="$normalizedLibraryName"/>
			</field>
			<!-- This is intentionally omitted because it was requested that
				 we not show locations like "MCGR-VAULT" -->
			<!--
			<field name="location_facet" source="{$mode}">
				<xsl:value-of select="$normalizedLibraryName"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="mods:shelfLocator"/>
			</field>
			-->
			<field name="barcode_facet" source="{$mode}">
				<xsl:value-of select="mods:note[@type='barcode']"/>
			</field>
			<field name="call_number_display" source="{$mode}">
				<xsl:value-of select="mods:note[@type='call_number']"/>
			</field>
			<field name="call_number_text" source="{$mode}">
				<xsl:value-of select="mods:note[@type='call_number']"/>
			</field>
			<field name="call_number_sort_facet" source="{$mode}">
				<xsl:value-of select="mods:note[@type='call_number_sort']"/>
				<xsl:text>:</xsl:text>
				<xsl:value-of select="mods:note[@type='call_number']"/>
			</field>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getSeries">
		<xsl:param name="mode"/>
		<xsl:for-each select="/mods:mods/mods:relatedItem[@type='series']/mods:titleInfo/mods:title">
			<field name="series_title_facet" source="{$mode}">
				<xsl:value-of select="current()[normalize-space()]"/>
			</field>
			<field name="series_title_text" source="{$mode}">
				<xsl:value-of select="current()[normalize-space()]"/>
			</field>
			<field name="series_title_display" source="{$mode}">
				<xsl:value-of select="current()[normalize-space()]"/>
			</field>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getLanguage">
		<xsl:param name="mode"/>
		<xsl:for-each select="//mods:language/mods:languageTerm">
			<xsl:variable name="langCode" select="text()"/>
			<xsl:if test="not($langCode='zxx')">
				<field name="language_facet" source="{$mode}">
					<xsl:choose>
						<xsl:when test="$langCode='???'">null</xsl:when>
						<xsl:when test="$langCode='adrar'">Afar</xsl:when>
						<xsl:when test="$langCode='abk'">Abkhaz</xsl:when>
						<xsl:when test="$langCode='ace'">Achinese</xsl:when>
						<xsl:when test="$langCode='ach'">Acoli</xsl:when>
						<xsl:when test="$langCode='ada'">Adangme</xsl:when>
						<xsl:when test="$langCode='ady'">Adygei</xsl:when>
						<xsl:when test="$langCode='afa'">Afroasiatic (Other)</xsl:when>
						<xsl:when test="$langCode='afh'">Afrihili (Artificial language)</xsl:when>
						<xsl:when test="$langCode='afr'">Afrikaans</xsl:when>
						<xsl:when test="$langCode='ajm'">Aljamia</xsl:when>
						<xsl:when test="$langCode='aka'">Akan</xsl:when>
						<xsl:when test="$langCode='akk'">Akkadian</xsl:when>
						<xsl:when test="$langCode='alb'">Albanian</xsl:when>
						<xsl:when test="$langCode='ale'">Aleut</xsl:when>
						<xsl:when test="$langCode='alg'">Algonquian (Other)</xsl:when>
						<xsl:when test="$langCode='amh'">Amharic</xsl:when>
						<xsl:when test="$langCode='ang'">English, Old (ca. 450-1100)</xsl:when>
						<xsl:when test="$langCode='apa'">Apache languages</xsl:when>
						<xsl:when test="$langCode='ara'">Arabic</xsl:when>
						<xsl:when test="$langCode='arc'">Aramaic</xsl:when>
						<xsl:when test="$langCode='arg'">Aragonese Spanish</xsl:when>
						<xsl:when test="$langCode='arm'">Armenian</xsl:when>
						<xsl:when test="$langCode='arn'">Mapuche</xsl:when>
						<xsl:when test="$langCode='arp'">Arapaho</xsl:when>
						<xsl:when test="$langCode='art'">Artificial (Other)</xsl:when>
						<xsl:when test="$langCode='arw'">Arawak</xsl:when>
						<xsl:when test="$langCode='asm'">Assamese</xsl:when>
						<xsl:when test="$langCode='ast'">Bable</xsl:when>
						<xsl:when test="$langCode='ath'">Athapascan (Other)</xsl:when>
						<xsl:when test="$langCode='aus'">Australian languages</xsl:when>
						<xsl:when test="$langCode='ava'">Avaric</xsl:when>
						<xsl:when test="$langCode='ave'">Avestan</xsl:when>
						<xsl:when test="$langCode='awa'">Awadhi</xsl:when>
						<xsl:when test="$langCode='aym'">Aymara</xsl:when>
						<xsl:when test="$langCode='aze'">Azerbaijani</xsl:when>
						<xsl:when test="$langCode='bad'">Banda</xsl:when>
						<xsl:when test="$langCode='bai'">Bamileke languages</xsl:when>
						<xsl:when test="$langCode='bak'">Bashkir</xsl:when>
						<xsl:when test="$langCode='bal'">Baluchi</xsl:when>
						<xsl:when test="$langCode='bam'">Bambara</xsl:when>
						<xsl:when test="$langCode='ban'">Balinese</xsl:when>
						<xsl:when test="$langCode='baq'">Basque</xsl:when>
						<xsl:when test="$langCode='bas'">Basa</xsl:when>
						<xsl:when test="$langCode='bat'">Baltic (Other)</xsl:when>
						<xsl:when test="$langCode='bej'">Beja</xsl:when>
						<xsl:when test="$langCode='bel'">Belarusian</xsl:when>
						<xsl:when test="$langCode='bem'">Bemba</xsl:when>
						<xsl:when test="$langCode='ben'">Bengali</xsl:when>
						<xsl:when test="$langCode='ber'">Berber (Other)</xsl:when>
						<xsl:when test="$langCode='bho'">Bhojpuri</xsl:when>
						<xsl:when test="$langCode='bih'">Bihari</xsl:when>
						<xsl:when test="$langCode='bik'">Bikol</xsl:when>
						<xsl:when test="$langCode='bin'">Edo</xsl:when>
						<xsl:when test="$langCode='bis'">Bislama</xsl:when>
						<xsl:when test="$langCode='bla'">Siksika</xsl:when>
						<xsl:when test="$langCode='bnt'">Bantu (Other)</xsl:when>
						<xsl:when test="$langCode='bos'">Bosnian</xsl:when>
						<xsl:when test="$langCode='bra'">Braj</xsl:when>
						<xsl:when test="$langCode='bre'">Breton</xsl:when>
						<xsl:when test="$langCode='btk'">Batak</xsl:when>
						<xsl:when test="$langCode='bua'">Buriat</xsl:when>
						<xsl:when test="$langCode='bug'">Bugis</xsl:when>
						<xsl:when test="$langCode='bul'">Bulgarian</xsl:when>
						<xsl:when test="$langCode='bur'">Burmese</xsl:when>
						<xsl:when test="$langCode='cad'">Caddo</xsl:when>
						<xsl:when test="$langCode='cai'">Central American Indian (Other)</xsl:when>
						<xsl:when test="$langCode='cam'">Khmer</xsl:when>
						<xsl:when test="$langCode='car'">Carib</xsl:when>
						<xsl:when test="$langCode='cat'">Catalan</xsl:when>
						<xsl:when test="$langCode='cau'">Caucasian (Other)</xsl:when>
						<xsl:when test="$langCode='ceb'">Cebuano</xsl:when>
						<xsl:when test="$langCode='cel'">Celtic (Other)</xsl:when>
						<xsl:when test="$langCode='cha'">Chamorro</xsl:when>
						<xsl:when test="$langCode='chb'">Chibcha</xsl:when>
						<xsl:when test="$langCode='che'">Chechen</xsl:when>
						<xsl:when test="$langCode='chg'">Chagatai</xsl:when>
						<xsl:when test="$langCode='chi'">Chinese</xsl:when>
						<xsl:when test="$langCode='chk'">Truk</xsl:when>
						<xsl:when test="$langCode='chm'">Mari</xsl:when>
						<xsl:when test="$langCode='chn'">Chinook jargon</xsl:when>
						<xsl:when test="$langCode='cho'">Choctaw</xsl:when>
						<xsl:when test="$langCode='chp'">Chipewyan</xsl:when>
						<xsl:when test="$langCode='chr'">Cherokee</xsl:when>
						<xsl:when test="$langCode='chu'">Church Slavic</xsl:when>
						<xsl:when test="$langCode='chv'">Chuvash</xsl:when>
						<xsl:when test="$langCode='chy'">Cheyenne</xsl:when>
						<xsl:when test="$langCode='cmc'">Chamic languages</xsl:when>
						<xsl:when test="$langCode='cop'">Coptic</xsl:when>
						<xsl:when test="$langCode='cor'">Cornish</xsl:when>
						<xsl:when test="$langCode='cos'">Corsican</xsl:when>
						<xsl:when test="$langCode='cpe'">Creoles and Pidgins, English-based
							(Other)</xsl:when>
						<xsl:when test="$langCode='cpf'">Creoles and Pidgins, French-based
							(Other)</xsl:when>
						<xsl:when test="$langCode='cpp'">Creoles and Pidgins, Portuguese-based
							(Other)</xsl:when>
						<xsl:when test="$langCode='cre'">Cree</xsl:when>
						<xsl:when test="$langCode='crh'">Crimean Tatar</xsl:when>
						<xsl:when test="$langCode='crp'">Creoles and Pidgins (Other)</xsl:when>
						<xsl:when test="$langCode='cus'">Cushitic (Other)</xsl:when>
						<xsl:when test="$langCode='cze'">Czech</xsl:when>
						<xsl:when test="$langCode='dak'">Dakota</xsl:when>
						<xsl:when test="$langCode='dan'">Danish</xsl:when>
						<xsl:when test="$langCode='dar'">Dargwa</xsl:when>
						<xsl:when test="$langCode='day'">Dayak</xsl:when>
						<xsl:when test="$langCode='del'">Delaware</xsl:when>
						<xsl:when test="$langCode='den'">Slave</xsl:when>
						<xsl:when test="$langCode='dgr'">Dogrib</xsl:when>
						<xsl:when test="$langCode='din'">Dinka</xsl:when>
						<xsl:when test="$langCode='div'">Divehi</xsl:when>
						<xsl:when test="$langCode='doi'">Dogri</xsl:when>
						<xsl:when test="$langCode='dra'">Dravidian (Other)</xsl:when>
						<xsl:when test="$langCode='dua'">Duala</xsl:when>
						<xsl:when test="$langCode='dum'">Dutch, Middle (ca. 1050-1350)</xsl:when>
						<xsl:when test="$langCode='dut'">Dutch</xsl:when>
						<xsl:when test="$langCode='dyu'">Dyula</xsl:when>
						<xsl:when test="$langCode='dzo'">Dzongkha</xsl:when>
						<xsl:when test="$langCode='efi'">Efik</xsl:when>
						<xsl:when test="$langCode='egy'">Egyptian</xsl:when>
						<xsl:when test="$langCode='eka'">Ekajuk</xsl:when>
						<xsl:when test="$langCode='elx'">Elamite</xsl:when>
						<xsl:when test="$langCode='eng'">English</xsl:when>
						<xsl:when test="$langCode='enm'">English, Middle (1100-1500)</xsl:when>
						<xsl:when test="$langCode='epo'">Esperanto</xsl:when>
						<xsl:when test="$langCode='esk'">Eskimo languages</xsl:when>
						<xsl:when test="$langCode='esp'">Esperanto</xsl:when>
						<xsl:when test="$langCode='est'">Estonian</xsl:when>
						<xsl:when test="$langCode='eth'">Ethiopic</xsl:when>
						<xsl:when test="$langCode='ewe'">Ewe</xsl:when>
						<xsl:when test="$langCode='ewo'">Ewondo</xsl:when>
						<xsl:when test="$langCode='fan'">Fang</xsl:when>
						<xsl:when test="$langCode='fao'">Faroese</xsl:when>
						<xsl:when test="$langCode='far'">Faroese</xsl:when>
						<xsl:when test="$langCode='fat'">Fanti</xsl:when>
						<xsl:when test="$langCode='fij'">Fijian</xsl:when>
						<xsl:when test="$langCode='fin'">Finnish</xsl:when>
						<xsl:when test="$langCode='fiu'">Finno-Ugrian (Other)</xsl:when>
						<xsl:when test="$langCode='fon'">Fon</xsl:when>
						<xsl:when test="$langCode='fre'">French</xsl:when>
						<xsl:when test="$langCode='fri'">Frisian</xsl:when>
						<xsl:when test="$langCode='frm'">French, Middle (ca. 1400-1600)</xsl:when>
						<xsl:when test="$langCode='fro'">French, Old (ca. 842-1400)</xsl:when>
						<xsl:when test="$langCode='fry'">Frisian</xsl:when>
						<xsl:when test="$langCode='ful'">Fula</xsl:when>
						<xsl:when test="$langCode='fur'">Friulian</xsl:when>
						<xsl:when test="$langCode='gaa'">Ga</xsl:when>
						<xsl:when test="$langCode='gae'">Scottish Gaelic</xsl:when>
						<xsl:when test="$langCode='gag'">Galician</xsl:when>
						<xsl:when test="$langCode='gal'">Oromo</xsl:when>
						<xsl:when test="$langCode='gay'">Gayo</xsl:when>
						<xsl:when test="$langCode='gba'">Gbaya</xsl:when>
						<xsl:when test="$langCode='gem'">Germanic (Other)</xsl:when>
						<xsl:when test="$langCode='geo'">Georgian</xsl:when>
						<xsl:when test="$langCode='ger'">German</xsl:when>
						<xsl:when test="$langCode='gez'">Ethiopic</xsl:when>
						<xsl:when test="$langCode='gil'">Gilbertese</xsl:when>
						<xsl:when test="$langCode='gla'">Scottish Gaelic</xsl:when>
						<xsl:when test="$langCode='gle'">Irish</xsl:when>
						<xsl:when test="$langCode='glg'">Galician</xsl:when>
						<xsl:when test="$langCode='glv'">Manx</xsl:when>
						<xsl:when test="$langCode='gmh'">German, Middle High (ca.
							1050-1500)</xsl:when>
						<xsl:when test="$langCode='goh'">German, Old High (ca. 750-1050)</xsl:when>
						<xsl:when test="$langCode='gon'">Gondi</xsl:when>
						<xsl:when test="$langCode='gor'">Gorontalo</xsl:when>
						<xsl:when test="$langCode='got'">Gothic</xsl:when>
						<xsl:when test="$langCode='grb'">Grebo</xsl:when>
						<xsl:when test="$langCode='grc'">Greek, Ancient (to 1453)</xsl:when>
						<xsl:when test="$langCode='gre'">Greek, Modern (1453- )</xsl:when>
						<xsl:when test="$langCode='grn'">Guarani</xsl:when>
						<xsl:when test="$langCode='gua'">Guarani</xsl:when>
						<xsl:when test="$langCode='guj'">Gujarati</xsl:when>
						<xsl:when test="$langCode='gwi'">Gwich'in</xsl:when>
						<xsl:when test="$langCode='hai'">Haida</xsl:when>
						<xsl:when test="$langCode='hat'">Haitian French Creole</xsl:when>
						<xsl:when test="$langCode='hau'">Hausa</xsl:when>
						<xsl:when test="$langCode='haw'">Hawaiian</xsl:when>
						<xsl:when test="$langCode='heb'">Hebrew</xsl:when>
						<xsl:when test="$langCode='her'">Herero</xsl:when>
						<xsl:when test="$langCode='hil'">Hiligaynon</xsl:when>
						<xsl:when test="$langCode='him'">Himachali</xsl:when>
						<xsl:when test="$langCode='hin'">Hindi</xsl:when>
						<xsl:when test="$langCode='hit'">Hittite</xsl:when>
						<xsl:when test="$langCode='hmn'">Hmong</xsl:when>
						<xsl:when test="$langCode='hmo'">Hiri Motu</xsl:when>
						<xsl:when test="$langCode='hun'">Hungarian</xsl:when>
						<xsl:when test="$langCode='hup'">Hupa</xsl:when>
						<xsl:when test="$langCode='iba'">Iban</xsl:when>
						<xsl:when test="$langCode='ibo'">Igbo</xsl:when>
						<xsl:when test="$langCode='ice'">Icelandic</xsl:when>
						<xsl:when test="$langCode='ido'">Ido</xsl:when>
						<xsl:when test="$langCode='iii'">Sichuan Yi</xsl:when>
						<xsl:when test="$langCode='ijo'">Ijo</xsl:when>
						<xsl:when test="$langCode='iku'">Inuktitut</xsl:when>
						<xsl:when test="$langCode='ile'">Interlingue</xsl:when>
						<xsl:when test="$langCode='ilo'">Iloko</xsl:when>
						<xsl:when test="$langCode='ina'">Interlingua (International Auxiliary
							Language Association)</xsl:when>
						<xsl:when test="$langCode='inc'">Indic (Other)</xsl:when>
						<xsl:when test="$langCode='ind'">Indonesian</xsl:when>
						<xsl:when test="$langCode='ine'">Indo-European (Other)</xsl:when>
						<xsl:when test="$langCode='inh'">Ingush</xsl:when>
						<xsl:when test="$langCode='int'">Interlingua (International Auxiliary
							Language Association)</xsl:when>
						<xsl:when test="$langCode='ipk'">Inupiaq</xsl:when>
						<xsl:when test="$langCode='ira'">Iranian (Other)</xsl:when>
						<xsl:when test="$langCode='iri'">Irish</xsl:when>
						<xsl:when test="$langCode='iro'">Iroquoian (Other)</xsl:when>
						<xsl:when test="$langCode='ita'">Italian</xsl:when>
						<xsl:when test="$langCode='jav'">Javanese</xsl:when>
						<xsl:when test="$langCode='jpn'">Japanese</xsl:when>
						<xsl:when test="$langCode='jpr'">Judeo-Persian</xsl:when>
						<xsl:when test="$langCode='jrb'">Judeo-Arabic</xsl:when>
						<xsl:when test="$langCode='kaa'">Kara-Kalpak</xsl:when>
						<xsl:when test="$langCode='kab'">Kabyle</xsl:when>
						<xsl:when test="$langCode='kac'">Kachin</xsl:when>
						<xsl:when test="$langCode='kal'">Kalatdlisut</xsl:when>
						<xsl:when test="$langCode='kam'">Kamba</xsl:when>
						<xsl:when test="$langCode='kan'">Kannada</xsl:when>
						<xsl:when test="$langCode='kar'">Karen</xsl:when>
						<xsl:when test="$langCode='kas'">Kashmiri</xsl:when>
						<xsl:when test="$langCode='kau'">Kanuri</xsl:when>
						<xsl:when test="$langCode='kaw'">Kawi</xsl:when>
						<xsl:when test="$langCode='kaz'">Kazakh</xsl:when>
						<xsl:when test="$langCode='kbd'">Kabardian</xsl:when>
						<xsl:when test="$langCode='kha'">Khasi</xsl:when>
						<xsl:when test="$langCode='khi'">Khoisan (Other)</xsl:when>
						<xsl:when test="$langCode='khm'">Khmer</xsl:when>
						<xsl:when test="$langCode='kho'">Khotanese</xsl:when>
						<xsl:when test="$langCode='kik'">Kikuyu</xsl:when>
						<xsl:when test="$langCode='kin'">Kinyarwanda</xsl:when>
						<xsl:when test="$langCode='kir'">Kyrgyz</xsl:when>
						<xsl:when test="$langCode='kmb'">Kimbundu</xsl:when>
						<xsl:when test="$langCode='kok'">Konkani</xsl:when>
						<xsl:when test="$langCode='kom'">Komi</xsl:when>
						<xsl:when test="$langCode='kon'">Kongo</xsl:when>
						<xsl:when test="$langCode='kor'">Korean</xsl:when>
						<xsl:when test="$langCode='kos'">Kusaie</xsl:when>
						<xsl:when test="$langCode='kpe'">Kpelle</xsl:when>
						<xsl:when test="$langCode='kro'">Kru</xsl:when>
						<xsl:when test="$langCode='kru'">Kurukh</xsl:when>
						<xsl:when test="$langCode='kua'">Kuanyama</xsl:when>
						<xsl:when test="$langCode='kum'">Kumyk</xsl:when>
						<xsl:when test="$langCode='kur'">Kurdish</xsl:when>
						<xsl:when test="$langCode='kus'">Kusaie</xsl:when>
						<xsl:when test="$langCode='kut'">Kutenai</xsl:when>
						<xsl:when test="$langCode='lad'">Ladino</xsl:when>
						<xsl:when test="$langCode='lah'">Lahnda</xsl:when>
						<xsl:when test="$langCode='lam'">Lamba</xsl:when>
						<xsl:when test="$langCode='lan'">Occitan (post-1500)</xsl:when>
						<xsl:when test="$langCode='lao'">Lao</xsl:when>
						<xsl:when test="$langCode='lap'">Sami</xsl:when>
						<xsl:when test="$langCode='lat'">Latin</xsl:when>
						<xsl:when test="$langCode='lav'">Latvian</xsl:when>
						<xsl:when test="$langCode='lez'">Lezgian</xsl:when>
						<xsl:when test="$langCode='lim'">Limburgish</xsl:when>
						<xsl:when test="$langCode='lin'">Lingala</xsl:when>
						<xsl:when test="$langCode='lit'">Lithuanian</xsl:when>
						<xsl:when test="$langCode='lol'">Mongo-Nkundu</xsl:when>
						<xsl:when test="$langCode='loz'">Lozi</xsl:when>
						<xsl:when test="$langCode='ltz'">Letzeburgesch</xsl:when>
						<xsl:when test="$langCode='lua'">Luba-Lulua</xsl:when>
						<xsl:when test="$langCode='lub'">Luba-Katanga</xsl:when>
						<xsl:when test="$langCode='lug'">Ganda</xsl:when>
						<xsl:when test="$langCode='lui'">Luiseno</xsl:when>
						<xsl:when test="$langCode='lun'">Lunda</xsl:when>
						<xsl:when test="$langCode='luo'">Luo (Kenya and Tanzania)</xsl:when>
						<xsl:when test="$langCode='lus'">Lushai</xsl:when>
						<xsl:when test="$langCode='mac'">Macedonian</xsl:when>
						<xsl:when test="$langCode='mad'">Madurese</xsl:when>
						<xsl:when test="$langCode='mag'">Magahi</xsl:when>
						<xsl:when test="$langCode='mah'">Marshallese</xsl:when>
						<xsl:when test="$langCode='mai'">Maithili</xsl:when>
						<xsl:when test="$langCode='mak'">Makasar</xsl:when>
						<xsl:when test="$langCode='mal'">Malayalam</xsl:when>
						<xsl:when test="$langCode='man'">Mandingo</xsl:when>
						<xsl:when test="$langCode='mao'">Maori</xsl:when>
						<xsl:when test="$langCode='map'">Austronesian (Other)</xsl:when>
						<xsl:when test="$langCode='mar'">Marathi</xsl:when>
						<xsl:when test="$langCode='mas'">Masai</xsl:when>
						<xsl:when test="$langCode='max'">Manx</xsl:when>
						<xsl:when test="$langCode='may'">Malay</xsl:when>
						<xsl:when test="$langCode='mdr'">Mandar</xsl:when>
						<xsl:when test="$langCode='men'">Mende</xsl:when>
						<xsl:when test="$langCode='mga'">Irish, Middle (ca. 1100-1550)</xsl:when>
						<xsl:when test="$langCode='mic'">Micmac</xsl:when>
						<xsl:when test="$langCode='min'">Minangkabau</xsl:when>
						<xsl:when test="$langCode='mis'">Miscellaneous languages</xsl:when>
						<xsl:when test="$langCode='mkh'">Mon-Khmer (Other)</xsl:when>
						<xsl:when test="$langCode='mla'">Malagasy</xsl:when>
						<xsl:when test="$langCode='mlg'">Malagasy</xsl:when>
						<xsl:when test="$langCode='mlt'">Maltese</xsl:when>
						<xsl:when test="$langCode='mnc'">Manchu</xsl:when>
						<xsl:when test="$langCode='mni'">Manipuri</xsl:when>
						<xsl:when test="$langCode='mno'">Manobo languages</xsl:when>
						<xsl:when test="$langCode='moh'">Mohawk</xsl:when>
						<xsl:when test="$langCode='mol'">Moldavian</xsl:when>
						<xsl:when test="$langCode='mon'">Mongolian</xsl:when>
						<xsl:when test="$langCode='mos'">Moore</xsl:when>
						<xsl:when test="$langCode='mul'">Multiple languages</xsl:when>
						<xsl:when test="$langCode='mun'">Munda (Other)</xsl:when>
						<xsl:when test="$langCode='mus'">Creek</xsl:when>
						<xsl:when test="$langCode='mwr'">Marwari</xsl:when>
						<xsl:when test="$langCode='myn'">Mayan languages</xsl:when>
						<xsl:when test="$langCode='nah'">Nahuatl</xsl:when>
						<xsl:when test="$langCode='nai'">North American Indian (Other)</xsl:when>
						<xsl:when test="$langCode='nap'">Neapolitan Italian</xsl:when>
						<xsl:when test="$langCode='nau'">Nauru</xsl:when>
						<xsl:when test="$langCode='nav'">Navajo</xsl:when>
						<xsl:when test="$langCode='nbl'">Ndebele (South Africa)</xsl:when>
						<xsl:when test="$langCode='nde'">Ndebele (Zimbabwe)</xsl:when>
						<xsl:when test="$langCode='ndo'">Ndonga</xsl:when>
						<xsl:when test="$langCode='nds'">Low German</xsl:when>
						<xsl:when test="$langCode='nep'">Nepali</xsl:when>
						<xsl:when test="$langCode='new'">Newari</xsl:when>
						<xsl:when test="$langCode='nia'">Nias</xsl:when>
						<xsl:when test="$langCode='nic'">Niger-Kordofanian (Other)</xsl:when>
						<xsl:when test="$langCode='niu'">Niuean</xsl:when>
						<xsl:when test="$langCode='nno'">Norwegian (Nynorsk)</xsl:when>
						<xsl:when test="$langCode='nob'">Norwegian (Bokmal)</xsl:when>
						<xsl:when test="$langCode='nog'">Nogai</xsl:when>
						<xsl:when test="$langCode='non'">Old Norse</xsl:when>
						<xsl:when test="$langCode='nor'">Norwegian</xsl:when>
						<xsl:when test="$langCode='nso'">Northern Sotho</xsl:when>
						<xsl:when test="$langCode='nub'">Nubian languages</xsl:when>
						<xsl:when test="$langCode='nya'">Nyanja</xsl:when>
						<xsl:when test="$langCode='nym'">Nyamwezi</xsl:when>
						<xsl:when test="$langCode='nyn'">Nyankole</xsl:when>
						<xsl:when test="$langCode='nyo'">Nyoro</xsl:when>
						<xsl:when test="$langCode='nzi'">Nzima</xsl:when>
						<xsl:when test="$langCode='oci'">Occitan (post-1500)</xsl:when>
						<xsl:when test="$langCode='oji'">Ojibwa</xsl:when>
						<xsl:when test="$langCode='ori'">Oriya</xsl:when>
						<xsl:when test="$langCode='orm'">Oromo</xsl:when>
						<xsl:when test="$langCode='osa'">Osage</xsl:when>
						<xsl:when test="$langCode='oss'">Ossetic</xsl:when>
						<xsl:when test="$langCode='ota'">Turkish, Ottoman</xsl:when>
						<xsl:when test="$langCode='oto'">Otomian languages</xsl:when>
						<xsl:when test="$langCode='paa'">Papuan (Other)</xsl:when>
						<xsl:when test="$langCode='pag'">Pangasinan</xsl:when>
						<xsl:when test="$langCode='pal'">Pahlavi</xsl:when>
						<xsl:when test="$langCode='pam'">Pampanga</xsl:when>
						<xsl:when test="$langCode='pan'">Panjabi</xsl:when>
						<xsl:when test="$langCode='pap'">Papiamento</xsl:when>
						<xsl:when test="$langCode='pau'">Palauan</xsl:when>
						<xsl:when test="$langCode='peo'">Old Persian (ca. 600-400 B.C.)</xsl:when>
						<xsl:when test="$langCode='per'">Persian</xsl:when>
						<xsl:when test="$langCode='phi'">Philippine (Other)</xsl:when>
						<xsl:when test="$langCode='phn'">Phoenician</xsl:when>
						<xsl:when test="$langCode='pli'">Pali</xsl:when>
						<xsl:when test="$langCode='pol'">Polish</xsl:when>
						<xsl:when test="$langCode='pon'">Ponape</xsl:when>
						<xsl:when test="$langCode='por'">Portuguese</xsl:when>
						<xsl:when test="$langCode='pra'">Prakrit languages</xsl:when>
						<xsl:when test="$langCode='pro'">Provencal (to 1500)</xsl:when>
						<xsl:when test="$langCode='pus'">Pushto</xsl:when>
						<xsl:when test="$langCode='que'">Quechua</xsl:when>
						<xsl:when test="$langCode='raj'">Rajasthani</xsl:when>
						<xsl:when test="$langCode='rap'">Rapanui</xsl:when>
						<xsl:when test="$langCode='rar'">Rarotongan</xsl:when>
						<xsl:when test="$langCode='roa'">Romance (Other)</xsl:when>
						<xsl:when test="$langCode='roh'">Raeto-Romance</xsl:when>
						<xsl:when test="$langCode='rom'">Romani</xsl:when>
						<xsl:when test="$langCode='rum'">Romanian</xsl:when>
						<xsl:when test="$langCode='run'">Rundi</xsl:when>
						<xsl:when test="$langCode='rus'">Russian</xsl:when>
						<xsl:when test="$langCode='sad'">Sandawe</xsl:when>
						<xsl:when test="$langCode='sag'">Sango (Ubangi Creole)</xsl:when>
						<xsl:when test="$langCode='sah'">Yakut</xsl:when>
						<xsl:when test="$langCode='sai'">South American Indian (Other)</xsl:when>
						<xsl:when test="$langCode='sal'">Salishan languages</xsl:when>
						<xsl:when test="$langCode='sam'">Samaritan Aramaic</xsl:when>
						<xsl:when test="$langCode='san'">Sanskrit</xsl:when>
						<xsl:when test="$langCode='sao'">Samoan</xsl:when>
						<xsl:when test="$langCode='sas'">Sasak</xsl:when>
						<xsl:when test="$langCode='sat'">Santali</xsl:when>
						<xsl:when test="$langCode='scc'">Serbian</xsl:when>
						<xsl:when test="$langCode='sco'">Scots</xsl:when>
						<xsl:when test="$langCode='scr'">Croatian</xsl:when>
						<xsl:when test="$langCode='sel'">Selkup</xsl:when>
						<xsl:when test="$langCode='sem'">Semitic (Other)</xsl:when>
						<xsl:when test="$langCode='sga'">Irish, Old (to 1100)</xsl:when>
						<xsl:when test="$langCode='sgn'">Sign languages</xsl:when>
						<xsl:when test="$langCode='shn'">Shan</xsl:when>
						<xsl:when test="$langCode='sho'">Shona</xsl:when>
						<xsl:when test="$langCode='sid'">Sidamo</xsl:when>
						<xsl:when test="$langCode='sin'">Sinhalese</xsl:when>
						<xsl:when test="$langCode='sio'">Siouan (Other)</xsl:when>
						<xsl:when test="$langCode='sit'">Sino-Tibetan (Other)</xsl:when>
						<xsl:when test="$langCode='sla'">Slavic (Other)</xsl:when>
						<xsl:when test="$langCode='slo'">Slovak</xsl:when>
						<xsl:when test="$langCode='slv'">Slovenian</xsl:when>
						<xsl:when test="$langCode='sma'">Southern Sami</xsl:when>
						<xsl:when test="$langCode='sme'">Northern Sami</xsl:when>
						<xsl:when test="$langCode='smi'">Sami</xsl:when>
						<xsl:when test="$langCode='smj'">Lule Sami</xsl:when>
						<xsl:when test="$langCode='smn'">Inari Sami</xsl:when>
						<xsl:when test="$langCode='smo'">Samoan</xsl:when>
						<xsl:when test="$langCode='sms'">Skolt Sami</xsl:when>
						<xsl:when test="$langCode='sna'">Shona</xsl:when>
						<xsl:when test="$langCode='snd'">Sindhi</xsl:when>
						<xsl:when test="$langCode='snh'">Sinhalese</xsl:when>
						<xsl:when test="$langCode='snk'">Soninke</xsl:when>
						<xsl:when test="$langCode='sog'">Sogdian</xsl:when>
						<xsl:when test="$langCode='som'">Somali</xsl:when>
						<xsl:when test="$langCode='son'">Songhai</xsl:when>
						<xsl:when test="$langCode='sot'">Sotho</xsl:when>
						<xsl:when test="$langCode='spa'">Spanish</xsl:when>
						<xsl:when test="$langCode='srd'">Sardinian</xsl:when>
						<xsl:when test="$langCode='srr'">Serer</xsl:when>
						<xsl:when test="$langCode='ssa'">Nilo-Saharan (Other)</xsl:when>
						<xsl:when test="$langCode='sso'">Sotho</xsl:when>
						<xsl:when test="$langCode='ssw'">Swazi</xsl:when>
						<xsl:when test="$langCode='suk'">Sukuma</xsl:when>
						<xsl:when test="$langCode='sun'">Sundanese</xsl:when>
						<xsl:when test="$langCode='sus'">Susu</xsl:when>
						<xsl:when test="$langCode='sux'">Sumerian</xsl:when>
						<xsl:when test="$langCode='swa'">Swahili</xsl:when>
						<xsl:when test="$langCode='swe'">Swedish</xsl:when>
						<xsl:when test="$langCode='swz'">Swazi</xsl:when>
						<xsl:when test="$langCode='syr'">Syriac</xsl:when>
						<xsl:when test="$langCode='tag'">Tagalog</xsl:when>
						<xsl:when test="$langCode='tah'">Tahitian</xsl:when>
						<xsl:when test="$langCode='tai'">Tai (Other)</xsl:when>
						<xsl:when test="$langCode='taj'">Tajik</xsl:when>
						<xsl:when test="$langCode='tam'">Tamil</xsl:when>
						<xsl:when test="$langCode='tar'">Tatar</xsl:when>
						<xsl:when test="$langCode='tat'">Tatar</xsl:when>
						<xsl:when test="$langCode='tel'">Telugu</xsl:when>
						<xsl:when test="$langCode='tem'">Temne</xsl:when>
						<xsl:when test="$langCode='ter'">Terena</xsl:when>
						<xsl:when test="$langCode='tet'">Tetum</xsl:when>
						<xsl:when test="$langCode='tgk'">Tajik</xsl:when>
						<xsl:when test="$langCode='tgl'">Tagalog</xsl:when>
						<xsl:when test="$langCode='tha'">Thai</xsl:when>
						<xsl:when test="$langCode='tib'">Tibetan</xsl:when>
						<xsl:when test="$langCode='tig'">Tigre</xsl:when>
						<xsl:when test="$langCode='tir'">Tigrinya</xsl:when>
						<xsl:when test="$langCode='tiv'">Tiv</xsl:when>
						<xsl:when test="$langCode='tkl'">Tokelauan</xsl:when>
						<xsl:when test="$langCode='tli'">Tlingit</xsl:when>
						<xsl:when test="$langCode='tmh'">Tamashek</xsl:when>
						<xsl:when test="$langCode='tog'">Tonga (Nyasa)</xsl:when>
						<xsl:when test="$langCode='ton'">Tongan</xsl:when>
						<xsl:when test="$langCode='tpi'">Tok Pisin</xsl:when>
						<xsl:when test="$langCode='tru'">Truk</xsl:when>
						<xsl:when test="$langCode='tsi'">Tsimshian</xsl:when>
						<xsl:when test="$langCode='tsn'">Tswana</xsl:when>
						<xsl:when test="$langCode='tso'">Tsonga</xsl:when>
						<xsl:when test="$langCode='tsw'">Tswana</xsl:when>
						<xsl:when test="$langCode='tuk'">Turkmen</xsl:when>
						<xsl:when test="$langCode='tum'">Tumbuka</xsl:when>
						<xsl:when test="$langCode='tup'">Tupi languages</xsl:when>
						<xsl:when test="$langCode='tur'">Turkish</xsl:when>
						<xsl:when test="$langCode='tut'">Altaic (Other)</xsl:when>
						<xsl:when test="$langCode='tvl'">Tuvaluan</xsl:when>
						<xsl:when test="$langCode='twi'">Twi</xsl:when>
						<xsl:when test="$langCode='tyv'">Tuvinian</xsl:when>
						<xsl:when test="$langCode='udm'">Udmurt</xsl:when>
						<xsl:when test="$langCode='uga'">Ugaritic</xsl:when>
						<xsl:when test="$langCode='uig'">Uighur</xsl:when>
						<xsl:when test="$langCode='ukr'">Ukrainian</xsl:when>
						<xsl:when test="$langCode='umb'">Umbundu</xsl:when>
						<xsl:when test="$langCode='und'">Undetermined</xsl:when>
						<xsl:when test="$langCode='urd'">Urdu</xsl:when>
						<xsl:when test="$langCode='uzb'">Uzbek</xsl:when>
						<xsl:when test="$langCode='vai'">Vai</xsl:when>
						<xsl:when test="$langCode='ven'">Venda</xsl:when>
						<xsl:when test="$langCode='vie'">Vietnamese</xsl:when>
						<xsl:when test="$langCode='vol'">Volapuk</xsl:when>
						<xsl:when test="$langCode='vot'">Votic</xsl:when>
						<xsl:when test="$langCode='wak'">Wakashan languages</xsl:when>
						<xsl:when test="$langCode='wal'">Walamo</xsl:when>
						<xsl:when test="$langCode='war'">Waray</xsl:when>
						<xsl:when test="$langCode='was'">Washo</xsl:when>
						<xsl:when test="$langCode='wel'">Welsh</xsl:when>
						<xsl:when test="$langCode='wen'">Sorbian languages</xsl:when>
						<xsl:when test="$langCode='wln'">Walloon</xsl:when>
						<xsl:when test="$langCode='wol'">Wolof</xsl:when>
						<xsl:when test="$langCode='xal'">Kalmyk</xsl:when>
						<xsl:when test="$langCode='xho'">Xhosa</xsl:when>
						<xsl:when test="$langCode='yao'">Yao (Africa)</xsl:when>
						<xsl:when test="$langCode='yap'">Yapese</xsl:when>
						<xsl:when test="$langCode='yid'">Yiddish</xsl:when>
						<xsl:when test="$langCode='yor'">Yoruba</xsl:when>
						<xsl:when test="$langCode='ypk'">Yupik languages</xsl:when>
						<xsl:when test="$langCode='zap'">Zapotec</xsl:when>
						<xsl:when test="$langCode='zen'">Zenaga</xsl:when>
						<xsl:when test="$langCode='zha'">Zhuang</xsl:when>
						<xsl:when test="$langCode='znd'">Zande</xsl:when>
						<xsl:when test="$langCode='zul'">Zulu</xsl:when>
						<xsl:when test="$langCode='zun'">Zuni</xsl:when>
					</xsl:choose>
				</field>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getFormatFacet">
		<xsl:param name="mode"/>
		<!-- As per cataloging and UX instructions, all objects ingested by Tracksys will contain the format_facet of Online -->
		<field name="format_facet" source="static_value">Online</field>
		<field name="format_text" source="static_value">Online</field>
		<xsl:for-each select="arr[@name='format_facet']/str">
			<field name="format_facet" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
			<field name="format_text" source="{$mode}">
				<xsl:value-of select="current()"/>
			</field>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="getMarcDisplay">
		<xsl:param name="mode"/>
		<!-- Will want to put in conditional test at some point -->
		<field name="marc_display" source="{$mode}">
			<xsl:value-of select="str[@name='marc_display']"/>
		</field>
		<field name="marc_display_facet" source="{$mode}">true</field>
	</xsl:template>


	<xsl:template mode="secondary" match="text()"/>
	<xsl:template mode="quaternary" match="text()"/>

	<!-- NAMED TEMPLATES -->
	<xsl:template name="normalizeKeywords">
		<xsl:param name="node-given"/>
		<xsl:for-each select="$node-given/descendant::text()">
			<!-- add double dash to all trailing subfields -->
			<xsl:choose>
				<xsl:when test="normalize-space(current()) = ' '"> </xsl:when>
				<xsl:when test="normalize-space(current()) != ' ' and position() != 1">
					<xsl:text> -- </xsl:text>
					<xsl:copy-of select="normalize-space(current())"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="normalize-space(current())"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="build-dates">
		<xsl:param name="date-node" select="'No node sent to template build-dates'"/>
		<xsl:param name="mode" select="'primary'"/>
		<xsl:for-each select="$date-node">
			<xsl:variable name="yearOnly">
				<xsl:choose>
					<xsl:when test="matches(., '^\d{4}')">
						<xsl:value-of select="substring(., 1, 4)"/>
					</xsl:when>
					<xsl:otherwise>Unknown Date</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>			
			<field name="published_date_display" source="{$mode}">
				<xsl:value-of select="$yearOnly"/>
			</field>
			<xsl:if test="$yearOnly != 'Unknown Date'">
				<field name="year_multisort_i" source="{$mode}">
					<xsl:value-of select="$yearOnly"/>
				</field>
			</xsl:if>
			<field name="year_display" source="{$mode}">
				<xsl:value-of select="$yearOnly"/>
			</field>
			<field name="date_text" source="{$mode}">
				<xsl:value-of select="$yearOnly"/>
			</field>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
