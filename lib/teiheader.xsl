<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE xsl:stylesheet [
	<!ENTITY tooltip '<xsl:attribute xmlns:xsl="http://www.w3.org/1999/XSL/Transform" name="title">TEI &lt;<xsl:value-of select="local-name(.)"/>&gt;</xsl:attribute>'>
	<!ENTITY table-summary 'Table listing fields in the &lt;{local-name(.)}&gt; section of the header'>
	
	<!-- Namespace declarations: workaround for MSXML. Cfr. Jeni Tennison, "The trouble is that MSXML merges XML parsing with namespace parsing, so it tries to view the entity that you declare as a little piece of XML, and interpret as such, so the namespace prefix on the xsl:text gets it confused. (...) The solution is to add a namespace declaration to the xsl:text in your entity." (http://www.biglist.com/lists/xsl-list/archives/200104/msg01503.html) -->

<!ENTITY and '&amp;'>
<!ENTITY eds '(Eds.)'>
<!ENTITY ed '(Ed.)'>

]>
	
<!-- ========================================================================== -->
<!-- TEI header TO XHTML conversion -->
<!-- ========================================================================== -->
<!--
     This stylesheet extracts information from a TEI header and generates a detailed XHTML report.

     Given the complexity of the TEI DTD, it's not easy to write generic stylesheets that produce high-quality reports for every possible document. This stylesheet does NOT pretend to do that. It is a first draft, written for a specific set of documents. Not every single item in the header is supported and some templates expect a subset of what's allowed by the TEI DTD, reflecting local policies or choices. On the other hand, it might produce acceptable output for other documents and could easily be modified or extended.

     Revision history:
     [2004-03-12] First draft
     [2004-03-17] Substantially revised draft
     [2006-09-26] Minor changes to the output HTML

		The stylesheet was developed for the Wulfila Project (http://www.wulfila.be) in March 2004 and is freely available for academic and non-commercial purposes. A link to the original file would of course be appreciated.
		
		(author: Tom De Herdt)

   This stylesheet was modified for the PROIEL web application by Marius L. Jøhndal. The changes made are the following:
     - modified for inclusion inside another document
     - removed footer; attribution and link to the original stylesheet source should be displayed
       somewhere else
     - changed styling so that it does not interfere with the rest of the page
-->
<!-- ========================================================================== -->

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
	version="1.0">

<xsl:output
	method="xml"
	encoding="UTF-8"
	doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
	doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
	indent="yes"/>
	
	<xsl:param name="timestamp"/>
	<xsl:param name="doc"/><!-- URI of the TEI document -->
	
	<xsl:template match="/">
 <style type="text/css">
div#metadata h3 {
  margin-bottom: 0em;
  background-color: #EEEEEE;
  padding: 0.2em;
}
div#metadata h4 { margin-bottom: 0em; }

div#metadata q { font-style: italic;}
div#metadata span.title { font-style: italic;}
div#metadata span.index { color: #FF5200;}
div#metadata var.attribute {
	font-style: normal;
	font-weight: bold;}

div#metadata div p {
	margin-left: 1em;
	margin-top: 0.5em;}
div#metadata td p {
	margin-left: 0em;
	margin-top: 0.5em;}
div#metadata div div { margin-bottom: 2em;}
div#metadata table { width: 100%; }
div#metadata tr.head td { border: none;}
div#metadata td {
	vertical-align: top;
	text-align: justify;
	line-height: 120%;
	padding: 0.4em;}
div#metadata td.label {
	width: 25%;
	color: navy;
	text-align: left;}
div#metadata td p {
	margin-top: 0em;
	margin-bottom: 0em;
	line-height: 120%;}

div#metadata p {
	text-align: justify;
	line-height: 120%;}

div#metadata a img { border: none;}

div#metadata div#header {
	border-top: 1px solid #DDDDDD;
	border-bottom: 1px solid #DDDDDD;
	margin-left: 0;
	margin-bottom: 1em;
	padding-left: 0;}
div#metadata div#header p {
	margin-left: 0;}
div#metadata div#footer, div#metadata .small {
	font-size: smaller;}

@media print {
	div#metadata body {
		margin-left: 5%;
		margin-top: 2%;
		margin-right: 2%;
		margin-bottom: 2%;
		font-size: small;}
	div#metadata h3 {
		margin-top: 0em;}
}
</style>
				<xsl:if test="$doc">
					<div id="header">
						<p>Document: <a href="{$doc}"><xsl:value-of select="$doc"/></a></p>
						<p>The document is encoded using the <acronym title="Text Encoding Initiative">TEI</acronym> <a href="http://www.tei-c.org/P4X/" title="Guidelines for Electronic Text Encoding and Interchange">P4 DTD</a>.</p>
						<!--<p>Note: derived and related text files are available at <a href="http://www.wulfila.be/gothic/download/">http://www.wulfila.be/gothic/download</a>.</p>-->
					</div>
				</xsl:if>
				<xsl:apply-templates select="TEI.2/teiHeader"/>
	</xsl:template>
	
	
<!-- ========================================================================== -->
<!-- [1] FILE DESCRIPTION <fileDesc> -->
<!-- ========================================================================== -->

	<xsl:template match="fileDesc">
		<div id="{local-name(.)}" class="level2">
			<h2>&tooltip;1. File description</h2>
			<xsl:apply-templates/>
		</div>
	</xsl:template>

<!-- .......................................................................... -->
<!-- [1.1] <titleStmt> -->
	
	<xsl:template match="fileDesc/titleStmt">
		<div>
			<h3>&tooltip;Title statement</h3>
			<table border="0" cellspacing="0"  summary="&table-summary;">
				<!-- Process the children in this particular order: -->
				<xsl:apply-templates select="title" mode="titleStmt"/>
				<xsl:apply-templates select="author" mode="titleStmt"/>
				<xsl:apply-templates select="editor" mode="titleStmt"/>
				<xsl:apply-templates select="sponsor" mode="titleStmt"/>
				<xsl:apply-templates select="funder" mode="titleStmt"/>
				<xsl:apply-templates select="principal" mode="titleStmt"/>
				<xsl:apply-templates select="respStmt" mode="titleStmt"/>
			</table>
		</div>
	</xsl:template>

	<xsl:template match="author|editor|sponsor|funder|principal|respStmt" mode="titleStmt">
		<xsl:variable name="label">
			<xsl:choose>
				<xsl:when test="self::title">Title</xsl:when>
				<xsl:when test="self::author">Author</xsl:when>
				<xsl:when test="self::editor">Editor</xsl:when>
				<xsl:when test="self::sponsor">Sponsor</xsl:when>
				<xsl:when test="self::funder">Funder</xsl:when>
				<xsl:when test="self::principal">Principal researcher</xsl:when>
				<xsl:when test="self::respStmt">Responsibility</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">
				&tooltip;
				<xsl:value-of select="$label"/>
				<xsl:if test="last()&gt;1">
					<xsl:text> </xsl:text>
					<span class="index">[<xsl:value-of select="position()"/>]</span>
				</xsl:if>
			</td>
			<td><xsl:apply-templates/></td>
		</tr>
	</xsl:template>
	
	<xsl:template match="title" mode="titleStmt">
		<tr>
			<td class="label">
				&tooltip;
				<xsl:text>Title</xsl:text>
				<xsl:if test="last()&gt;1">
					<xsl:text> </xsl:text>
					<span class="index">[<xsl:value-of select="position()"/>]</span>
				</xsl:if>
			</td>
			<td><strong><xsl:apply-templates/></strong></td>
		</tr>
	</xsl:template>
		
	<xsl:template match="resp|respStmt/name">
	<!-- problematic -->
		<xsl:for-each select=".">
			<xsl:apply-templates/><xsl:text> </xsl:text>
		</xsl:for-each>
	</xsl:template>


<!-- .......................................................................... -->
<!-- [1.2] <editionStmt> -->

	<xsl:template match="fileDesc/editionStmt">
		<div>
			<h3>&tooltip;Edition statement</h3>
			<table border="0" cellspacing="0"  summary="&table-summary;">
				<tr>
					<td class="label">&tooltip;Edition</td>
					<td><xsl:apply-templates/></td>
				</tr>
			</table>
		</div>
	</xsl:template>
	
	<xsl:template match="fileDesc/editionStmt/edition">
		<xsl:apply-templates/>
		<xsl:if test="not(substring(normalize-space(.), string-length(normalize-space(.)))='.')">.</xsl:if>
		<xsl:text> </xsl:text>
	</xsl:template>
	<xsl:template match="fileDesc/editionStmt/respStmt"><xsl:apply-templates/><xsl:text> </xsl:text></xsl:template>


<!-- .......................................................................... -->
<!-- [1.3] <extent> -->

	<xsl:template match="extent">		
		<div>
			<h3>&tooltip;Extent</h3>
			<table border="0" cellspacing="0"  summary="&table-summary;">
				<tr>
					<td class="label">Size</td>
					<td><xsl:apply-templates/></td>
				</tr>
			</table>
		</div>
	</xsl:template>
	
	<xsl:template match="measure">
		<xsl:value-of select="concat(., ' ', @type)"/>
	</xsl:template>


<!-- .......................................................................... -->
<!-- [1.4] <publicationStmt> -->

	<xsl:template match="fileDesc/publicationStmt">
		<div>
			<h3>&tooltip;Publication statement</h3>
			<xsl:choose>
				<xsl:when test="p">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<table border="0" cellspacing="0"  summary="&table-summary;">
						<xsl:apply-templates mode="publicationStmt"/>
					</table>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>
	
	<xsl:template match="publisher|distributor|authority|pubPlace|idno|date" mode="publicationStmt">
		<xsl:variable name="label">
			<xsl:choose>
				<xsl:when test="self::publisher">Publisher</xsl:when>
				<xsl:when test="self::distributor">Distributor</xsl:when>
				<xsl:when test="self::authority">Authority</xsl:when>
				<xsl:when test="self::pubPlace">Publication place</xsl:when>
				<xsl:when test="self::idno">
					<xsl:choose>
						<xsl:when test="@type"><xsl:value-of select="@type"/></xsl:when>
						<xsl:otherwise>Identification number</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="self::date">Date</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">
				&tooltip;
				<xsl:value-of select="$label"/>
			</td>
			<td><xsl:apply-templates/></td>
		</tr>
	</xsl:template>

	<xsl:template match="availability" mode="publicationStmt">
		<!-- ATTRIBUTE: status -->
		<xsl:variable name="status">
			<xsl:value-of select="@status"/>
			<xsl:if test="not(@status)">unknown</xsl:if>
		</xsl:variable>
		<xsl:variable name="status-tooltip">
			<xsl:choose>
				<xsl:when test="$status='free'">the text is freely available</xsl:when>
				<xsl:when test="$status='unknown'">the status of the text is unknown</xsl:when>
				<xsl:when test="$status='restricted'">the text is not freely available</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">&tooltip;Availability</td>
			<td>
				<p class="attributes">
					<var class="attribute">status</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$status-tooltip}"><xsl:value-of select="$status"/></span>
				</p>
				<xsl:apply-templates/>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="address" mode="publicationStmt">
		<tr>
			<td class="label">&tooltip;Address</td>
			<td>
				<address>
					<xsl:for-each select="addrLine|name|street|postCode|postBox">
						<xsl:apply-templates/><xsl:if test="not(position()=last())">, </xsl:if>
					</xsl:for-each>
				</address>
			</td>
		</tr>
	</xsl:template>

<!-- .......................................................................... -->
<!-- [1.5] <seriesStmt> *** NOT (YET) IMPLEMENTED *** -->
	
	<xsl:template match="seriesStmt"/>


<!-- .......................................................................... -->
<!-- [1.6] <notesStmt> -->
	
	<xsl:template match="fileDesc/notesStmt">
		<div>
			<h3>&tooltip;Notes</h3>
			<table border="0" cellspacing="0"  summary="&table-summary;">
				<xsl:for-each select="note">
					<tr>
						<td class="label" style="text-align: right;">[<xsl:value-of select="position()"/>]</td>
						<td><xsl:apply-templates/></td>
					</tr>
				</xsl:for-each>
			</table>
		</div>
	</xsl:template>

<!-- .......................................................................... -->
<!-- [1.7] <sourceDesc> -->

	<xsl:template match="fileDesc/sourceDesc">
		<div>
			<h3>&tooltip;Source description</h3>
			<xsl:apply-templates select="biblStruct"/>
		</div>
	</xsl:template>
	
<!-- ========================================================================== -->
<!-- [2] ENCODING DESCRIPTION <encodingDesc> -->
<!-- ========================================================================== -->

	<xsl:template match="encodingDesc">
		<div id="{local-name(.)}" class="level2">
			<h2>&tooltip;2. Encoding</h2>
			<xsl:apply-templates select="*[not(self::p)]"/>
			<xsl:if test="p">
				<div>
					<h3>Additional notes</h3>
					<xsl:apply-templates select="p"/>
				</div>
			</xsl:if>
		</div>
	</xsl:template>

<!-- <!ELEMENT encodingDesc %om.RR; (projectDesc*, samplingDecl*, editorialDecl*,
                                     tagsDecl?, refsDecl*, classDecl*, metDecl*,
                                     fsdDecl*, variantEncoding*, p* )>  -->

<!-- .......................................................................... -->
<!-- [2.1] <projectDesc> -->

	<xsl:template match="projectDesc">
		<div>
			<h3>&tooltip;Project description<!--(*)--></h3>
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<!-- (*) Eventueel index toevoegen indien projectDesc meermaals voorkomt:
						<xsl:if test="count(../projectDesc)&gt;1">
							(<xsl:value-of select="count(preceding-sibling::projectDesc)+1"/>)
						</xsl:if> -->

<!-- .......................................................................... -->
<!-- [2.2] <samplingDecl> -->

	<xsl:template match="samplingDecl">
		<div>
			<h3>&tooltip;Sampling declaration</h3>
			<xsl:apply-templates/>
		</div>
	</xsl:template>

<!-- .......................................................................... -->
<!-- [2.3] <editorialDecl> -->

	<xsl:template match="editorialDecl">
		<div>
			<h3>&tooltip;Editorial declarations</h3>
			<xsl:choose>
				<xsl:when test="not(correction | normalization | quotation | hyphenation | interpretation | segmentation | stdVals)">
				<!-- contains paragraphs only: -->
					<xsl:apply-templates select="p"/>
				</xsl:when>
				<xsl:otherwise>
				<!-- contains specific items and optionally paragraphs at the end: -->
					<table border="0" cellspacing="0"  summary="&table-summary;">
						<xsl:apply-templates select="correction | normalization | quotation | hyphenation | interpretation | segmentation | stdVals"/>
					</table>
					<xsl:apply-templates select="p"/>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>
	
<!-- <!ELEMENT editorialDecl %om.RO; ( p+ | ((correction | normalization | quotation | hyphenation | interpretation
       | segmentation | stdVals)+, p*))> -->
	
	<xsl:template match="correction">
		<!-- ATTRIBUTE: status -->
		<xsl:variable name="status">
			<xsl:value-of select="@status"/>
			<xsl:if test="not(@status)">unknown</xsl:if><!-- apply default value when using a non-validating parser -->
		</xsl:variable>
		<xsl:variable name="status-tooltip">
			<xsl:choose>
				<xsl:when test="$status='high'">the text has been thoroughly checked and proofread</xsl:when>
				<xsl:when test="$status='medium'">the text has been checked at least once</xsl:when>
				<xsl:when test="$status='low'">the text has not been checked</xsl:when>
				<xsl:when test="$status='unknown'">the correction status of the text is unknown</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<!-- ATTRIBUTE: method -->
		<xsl:variable name="method">
			<xsl:value-of select="@method"/>
			<xsl:if test="not(@method)">silent</xsl:if>
		</xsl:variable>
		<xsl:variable name="method-tooltip">
			<xsl:choose>
				<xsl:when test="$method='silent'">corrections have been made silently</xsl:when>
				<xsl:when test="$method='tags'">corrections have been represented using editorial tags</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">&tooltip;Corrections</td>
			<td>
				<p class="attributes">
					<var class="attribute">status</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$status-tooltip}"><xsl:value-of select="$status"/></span>
					<xsl:text>, </xsl:text>
					<var class="attribute">method</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$method-tooltip}"><xsl:value-of select="$method"/></span>
				</p>
				<xsl:apply-templates/>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="normalization">
		<!-- ATTRIBUTE: method -->
		<xsl:variable name="method">
			<xsl:value-of select="@method"/>
			<xsl:if test="not(@method)">silent</xsl:if>
		</xsl:variable>
		<xsl:variable name="method-tooltip">
			<xsl:choose>
				<xsl:when test="$method='silent'">normalization made silently</xsl:when>
				<xsl:when test="$method='tags'">normalization represented using editorial tags</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">&tooltip;Normalization</td>
			<td>
				<p class="attributes">
					<xsl:if test="@source">
						<var class="attribute">source</var>
						<xsl:text> = </xsl:text>
						<span class="attribute-value" title="indicates the authority for any normalization carried out"><xsl:value-of select="@source"/></span>
						<xsl:text>, </xsl:text>
					</xsl:if>
					<var class="attribute">method</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$method-tooltip}"><xsl:value-of select="$method"/></span>
				</p>
				<xsl:apply-templates/>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="quotation">
		<!-- ATTRIBUTE: marks -->
		<xsl:variable name="marks">
			<xsl:value-of select="@marks"/>
			<xsl:if test="not(@marks)">all</xsl:if><!-- apply default value when using a non-validating parser -->
		</xsl:variable>
		<xsl:variable name="marks-tooltip">
			<xsl:choose>
				<xsl:when test="$marks='none'">no quotation marks have been retained</xsl:when>
				<xsl:when test="$marks='some'">some quotation marks have been retained</xsl:when>
				<xsl:when test="$marks='all'">all quotation marks have been retained</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<!-- ATTRIBUTE: form -->
		<xsl:variable name="form">
			<xsl:value-of select="@form"/>
			<xsl:if test="not(@form)">unknown</xsl:if>
		</xsl:variable>
		<xsl:variable name="form-tooltip">
			<xsl:choose>
				<xsl:when test="$form='data'">quotation marks are retained as data</xsl:when>
				<xsl:when test="$form='rend'">the rendition attribute is consistently used to indicate the form of quotation marks</xsl:when>
				<xsl:when test="$form='std'">use of quotation marks has been standardized</xsl:when>
				<xsl:when test="$form='nonstd'">quotation marks are represented inconsistently</xsl:when>
				<xsl:when test="$form='unknown'">use of quotation marks is unknown</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">&tooltip;Quotations</td>
			<td>
				<p class="attributes">
					<var class="attribute">marks</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$marks-tooltip}"><xsl:value-of select="$marks"/></span>
					<xsl:text>, </xsl:text>
					<var class="attribute">form</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$form-tooltip}"><xsl:value-of select="$form"/></span>
				</p>
				<xsl:apply-templates/>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="hyphenation">
		<!-- ATTRIBUTE: eol -->
		<xsl:variable name="eol">
			<xsl:value-of select="@eol"/>
			<xsl:if test="not(@eol)">some</xsl:if><!-- apply default value when using a non-validating parser -->
		</xsl:variable>
		<xsl:variable name="eol-tooltip">
			<xsl:choose>
				<xsl:when test="$eol='all'">all end-of-line hyphenation has been retained, even though the lineation of the original may not have been</xsl:when>
				<xsl:when test="$eol='some'">end-of-line hyphenation has been retained in some cases</xsl:when>
				<xsl:when test="$eol='none'">all end-of-line hyphenation has been removed: any remaining hyphenation occurred within the line</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td class="label">&tooltip;Hyphenation</td>
			<td>
				<p class="attributes">
					<var class="attribute">eol</var>
					<xsl:text> = </xsl:text>
					<span class="attribute-value" title="{$eol-tooltip}"><xsl:value-of select="$eol"/></span>
				</p>
				<xsl:apply-templates/>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="segmentation">
		<tr>
			<td class="label">&tooltip;Segmentation</td>
			<td><xsl:apply-templates/></td>
		</tr>
	</xsl:template>
	
	<xsl:template match="interpretation">
		<tr>
			<td class="label">&tooltip;Interpretation</td>
			<td><xsl:apply-templates/></td>
		</tr>
	</xsl:template>
	
	<xsl:template match="stdVals">
		<tr>
			<td class="label">&tooltip;Standardization</td>
			<td><xsl:apply-templates/></td>
		</tr>
	</xsl:template>
	
<!-- .......................................................................... -->
<!-- [2.4] <tagsDecl> -->

	<xsl:template match="tagsDecl">
		<div>
			<h3>&tooltip;Tagging declaration</h3>
			<xsl:if test="rendition">
				<h4 title="TEI &lt;rendition&gt;">Renditions:</h4>
				<table border="0" cellspacing="0"  summary="&table-summary;">
					<xsl:apply-templates select="rendition"/>
				</table>
			</xsl:if>
			<xsl:if test="tagUsage">
				<h4 title="TEI &lt;tagUsage&gt;">Elements:</h4>
				<table border="0" cellspacing="0"  summary="&table-summary;">
					<xsl:apply-templates select="tagUsage"/>
				</table>
			</xsl:if>
			<xsl:if test="tagUsage"></xsl:if>
		</div>
	</xsl:template>
	
<!-- <!ELEMENT tagsDecl %om.RO; (rendition*, tagUsage*) >  -->
	
	<xsl:template match="rendition">
		<tr>
			<td class="label">ID <code><xsl:value-of select="@id"/></code></td>
			<td><p><xsl:apply-templates/></p></td>
		</tr>
	</xsl:template>
	
	<xsl:template match="tagUsage">
		<tr>
			<td class="label"><code>&lt;<xsl:value-of select="@gi"/>&gt;</code></td>
			<td>
				<xsl:if test="@occurs|@render|@ident">
					<p class="attributes">
						<xsl:for-each select="@occurs|@render|@ident">
							<var class="attribute"><xsl:value-of select="local-name(.)"/></var>
							<xsl:text> = </xsl:text>
							<span class="attribute-value"><xsl:value-of select="."/></span>
							<xsl:if test="not(position()=last())">, </xsl:if>
						</xsl:for-each>
					</p>
				</xsl:if>
				<p><xsl:apply-templates/></p>
			</td>
		</tr>
	</xsl:template>

<!-- .......................................................................... -->
<!-- [2.5] <refsDecl> -->

<!-- <!ELEMENT refsDecl %om.RO; (p+ | step+ | state+)> -->
<!-- "specifies how canonical references are constructed for this text" -->
	
	<xsl:template match="refsDecl">
		<div>
			<h3>&tooltip;Reference system declaration</h3>
			<xsl:apply-templates select="p"/><!-- step|state not supported -->
		</div>
	</xsl:template>
	
<!-- .......................................................................... -->
<!-- [2.6] <classDecl> -->

<!-- .......................................................................... -->
<!-- [2.7] <fsdDecl> -->

<!-- .......................................................................... -->
<!-- [2.8] <metDecl> -->

<!-- .......................................................................... -->
<!-- [2.9] <variantEncoding> -->
	
	<xsl:template match="variantEncoding">
		<div>
			<h3>&tooltip;Variant encoding</h3>
			<table border="0" cellspacing="0"  summary="&table-summary;">
				<tr>
					<td class="label">Method</td>
					<td><xsl:value-of select="@method"/></td>
				</tr>
				<tr>
					<td class="label">Location</td>
					<td><xsl:value-of select="@location"/></td>
				</tr>
			</table>
		</div>
	</xsl:template>
	

<!-- ========================================================================== -->
<!-- [3] PROFILE DESCRIPTION <profileDesc> -->
<!-- ========================================================================== -->

	<xsl:template match="profileDesc">
		<div id="{local-name(.)}" class="level2">
			<h2>&tooltip;3. Text profile</h2>
			<xsl:apply-templates/>
		</div>
	</xsl:template>

<!-- <!ELEMENT profileDesc %om.RR;  (creation?, langUsage*, textDesc*,particDesc*, settingDesc*, handList*, textClass*)>  -->

<!-- .......................................................................... -->
<!-- [3.1] <creation> -->

	<xsl:template match="creation">
		<div>
			<h3>&tooltip;Creation</h3>
			<p><xsl:apply-templates/></p>
		</div>
	</xsl:template>
	
<!-- .......................................................................... -->
<!-- [3.2] <langUsage> -->
	
	<!-- <!ELEMENT langUsage %om.RO; (p | language)+> -->
	
	<xsl:template match="langUsage">
		<div>
			<h3>&tooltip;Language</h3>
			<!-- subsetting to (p+|(p*, language+)): -->
			<xsl:apply-templates select="p"/>
			<xsl:if test="language">
				<ul>
					<xsl:apply-templates select="language"/>
				</ul>
			</xsl:if>
		</div>
	</xsl:template>
	
	<xsl:template match="language">
		<li>
			<xsl:text>[</xsl:text>
			<a href="http://www.ethnologue.com/show_iso639.asp?code={@id}">
				<xsl:value-of select="@id"/>
			</a>
			<xsl:text>] </xsl:text>
			<xsl:value-of select="."/>
		</li>
	</xsl:template>

<!-- .......................................................................... -->
<!-- The remaining items are not used in this project: -->

	<xsl:template match="textDesc|particDesc|settingDesc|handList|textClass">
		<xsl:comment>
			There's currently no template defined for element "<xsl:value-of select="local-name(.)"/>".
		</xsl:comment>
	</xsl:template>


<!-- ========================================================================== -->
<!-- [4] REVISION DESCRIPTION <revisionDesc> -->
<!-- ========================================================================== -->

	<xsl:template match="revisionDesc">
		<div id="{local-name(.)}" class="level2">
			<h2>&tooltip;4. Revision history</h2>
			<xsl:choose>
				<xsl:when test="list">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<table border="0" cellspacing="0"  summary="&table-summary;">
						<xsl:apply-templates select="change"/>
					</table>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>

<!-- <!ELEMENT revisionDesc %om.RR; (list | change+)> -->

	<xsl:template match="change">
		<tr>
			<td class="label"><xsl:if test="@n">[<xsl:value-of select="@n"/>] </xsl:if><xsl:apply-templates select="date"/></td>
			<td>
				<xsl:apply-templates select="item" mode="change"/> (<xsl:apply-templates select="respStmt" mode="change"/>)
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="respStmt" mode="change">
		<xsl:apply-templates/>
	</xsl:template>
		
	<xsl:template match="item" mode="change">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- <list> handled by generic templates below -->
	

<!-- ========================================================================== -->
<!-- GENERIC TEMPLATES -->
<!-- ========================================================================== -->

	<xsl:template match="list">
		<ul>
			<xsl:apply-templates select="item"/>
		</ul>
	</xsl:template>
	
	<xsl:template match="item">
		<li><xsl:apply-templates/></li>
	</xsl:template>
	
	<xsl:template match="ref">
		<a href="#{@target}"><xsl:apply-templates/></a>
	</xsl:template>
	
	<xsl:template match="xref">
		<a href="{unparsed-entity-uri(@doc)}"><xsl:value-of select="."/></a></xsl:template>
	
	<xsl:template match="p">
		<p><xsl:apply-templates/></p>
	</xsl:template>
	
	<xsl:template match="mentioned|foreign">
		<em><xsl:apply-templates/></em>
	</xsl:template>
	
	<xsl:template match="cit">
		<xsl:apply-templates select="quote"/> (<xsl:apply-templates select="bibl"/>)
	</xsl:template>
	
	<xsl:template match="quote">
		<q><xsl:apply-templates/></q>
	</xsl:template>
	
	<xsl:template match="emph|hi">
		<em><xsl:apply-templates/></em>
	</xsl:template>
	
	<xsl:template match="emph[@rend='bold']|hi[@rend='bold']">
		<strong><xsl:apply-templates/></strong>
	</xsl:template>
	
	<xsl:template match="hi[@rend='monospace']"><code><xsl:apply-templates/></code></xsl:template>
	
	<xsl:template match="lb"><br/></xsl:template>
	
	<xsl:template match="abbr"><abbr title="{@expan}"><xsl:apply-templates/></abbr></xsl:template>
	
	
<!-- ========================================================================== -->
<!-- BIBLIOGRAPHIC -->
<!-- ========================================================================== -->

<!-- UNDER CONSTRUCTION ! -->

	<xsl:template match="biblStruct">
		<p class="biblio">
			<xsl:apply-templates select="monogr"/>
			<xsl:apply-templates select="series|idno"/>
		</p>
	</xsl:template>
		
	<xsl:template match="monogr">
		<xsl:call-template name="process-authors"/>
		<xsl:apply-templates select="title"/>
		<xsl:apply-templates select="respStmt"/>
		<xsl:apply-templates select="edition"/>
		<xsl:apply-templates select="note"/>
		<xsl:apply-templates select="imprint"/>
	</xsl:template>
	
	
<!-- AUTHORS and EDITORS: -->
	<xsl:template name="process-authors">
		<xsl:call-template name="process-names"><xsl:with-param name="names" select="author"/></xsl:call-template>
		<xsl:if test="count(author)&gt;0 and count(editor)&gt;0"> / </xsl:if>
		<xsl:call-template name="process-names"><xsl:with-param name="names" select="editor"/></xsl:call-template>			
		<xsl:if test="count(editor)&gt;0">
			<xsl:choose>
				<xsl:when test="count(editor)=1"><xsl:text> </xsl:text>&ed;</xsl:when>
				<xsl:otherwise><xsl:text> </xsl:text>&eds;</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:text>. </xsl:text>
	</xsl:template>
	
	<xsl:template name="process-names">
		<xsl:param name="names"/>
		<xsl:for-each select="$names">
			<xsl:apply-templates select="current()"/>
			<xsl:if test="position()!=last()">
				<xsl:choose>
					<xsl:when test="position()=(last() - 1)"><xsl:text> &and; </xsl:text></xsl:when>
					<xsl:when test="position()&lt;(last() - 1)">, </xsl:when>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="title">
		<span class="title">
			<xsl:apply-templates/>
		</span>
	</xsl:template>
	
	<xsl:template match="biblStruct/monogr/title">
		<span class="title">
			<xsl:apply-templates/>
		</span>
		<xsl:text>. </xsl:text>
	</xsl:template>

	<xsl:template match="biblStruct/monogr/respStmt/resp">
		<xsl:apply-templates/>
		<xsl:text>. </xsl:text>
	</xsl:template>
	
	<xsl:template match="biblStruct/monogr/edition">
		<xsl:apply-templates/>
		<xsl:text>. </xsl:text>
	</xsl:template>
	
	<xsl:template match="biblStruct/monogr/note">
		<xsl:apply-templates/>
		<xsl:text>. </xsl:text>
	</xsl:template>
	
	<xsl:template match="biblStruct/monogr/imprint">
		<xsl:apply-templates select="publisher"/>,
		<xsl:apply-templates select="pubPlace"/>,
		<xsl:apply-templates select="date"/>.
	</xsl:template>
	
	<xsl:template match="series">
		<xsl:text> (</xsl:text>
		<xsl:apply-templates select="title"/>
		<xsl:apply-templates select="biblScope"/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	
	<xsl:template match="biblScope[@type='pages']">
		<xsl:text>, pp. </xsl:text>
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="biblScope[@type='volume']">
		<xsl:text>, vol. </xsl:text>
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="biblScope">
		<xsl:text>, </xsl:text>
		<xsl:if test="@type">
			<xsl:value-of select="@type"/>
			<xsl:text> </xsl:text>
		</xsl:if>
		<xsl:value-of select="."/>
	</xsl:template>

</xsl:stylesheet>
