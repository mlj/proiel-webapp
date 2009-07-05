<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     version="1.0">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:param name="identifier"/>
  <xsl:param name="language"/>
  <xsl:param name="title"/>
  <xsl:param name="abbrev"/>
  <xsl:param name="tracked_references"/>

  <xsl:template match="/">
    <source id="{$identifier}" language="{$language}">
      <title><xsl:value-of select="$title"/></title>
      <abbreviation><xsl:value-of select="$abbrev"/></abbreviation>
      <tei-header><xsl:copy-of select="/TEI.2/teiHeader/*"/></tei-header>
      <tracked-references><xsl:value-of select="$tracked_references"/></tracked-references>
      <reference-format><xsl:value-of select="$reference_format"/></reference-format>
      <xsl:apply-templates/>
    </source>
  </xsl:template>

  <xsl:template match="div1">
    <xsl:choose>
      <xsl:when test="@type='book' or @type='Book'">
        <xsl:choose>
          <xsl:when test="./div2/@type = 'chapter'">
            <!-- Leave this to div2 to handle. -->
            <xsl:apply-templates/>
          </xsl:when>
          <xsl:otherwise>
            <div>
              <title>Book <xsl:value-of select="@n"/></title>
              <abbreviation>Bk. <xsl:value-of select="@n"/></abbreviation>
              <unsegmented-text>
                <milestone unit="book" n="{@n}"/>
                <xsl:apply-templates/>
              </unsegmented-text>
            </div>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="@type='act'">
        <xsl:choose>
          <xsl:when test="./div2/@type = 'scene'">
            <!-- Leave this to div2 to handle. -->
            <xsl:apply-templates/>
          </xsl:when>
          <xsl:otherwise>
            <div>
              <title>Act <xsl:value-of select="@n"/></title>
              <abbreviation>Act <xsl:value-of select="@n"/></abbreviation>
              <unsegmented-text>
                <milestone unit="act" n="{@n}"/>
                <xsl:apply-templates/>
              </unsegmented-text>
            </div>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Unknown div1 type <xsl:value-of select="@type"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="div2">
    <xsl:choose>
      <xsl:when test="@type='chapter'">
        <xsl:choose>
          <xsl:when test="../@type='book' or ../@type='Book'">
            <div>
              <title>Book <xsl:value-of select="../@n"/>, chapter <xsl:value-of select="@n"/></title>
              <abbreviation>Bk. <xsl:value-of select="../@n"/>, chap. <xsl:value-of select="@n"/></abbreviation>
              <unsegmented-text>
                <milestone unit="book" n="{../@n}"/>
                <milestone unit="chapter" n="{@n}"/>
                <xsl:apply-templates/>
              </unsegmented-text>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>Unknown div1 and div2 type combination</xsl:message>
            <xsl:message>  div1 type: <xsl:value-of select="../@type"/>, n: <xsl:value-of select="../@n"/></xsl:message>
            <xsl:message>  div2 type: <xsl:value-of select="@type"/>, n: <xsl:value-of select="@n"/></xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="@type='scene'">
        <xsl:choose>
          <xsl:when test="../@type = 'act'">
            <div>
              <title>Act <xsl:value-of select="../@n"/>, scene <xsl:value-of select="@n"/></title>
              <abbreviation>Act <xsl:value-of select="../@n"/>, sc. <xsl:value-of select="@n"/></abbreviation>
              <unsegmented-text>
                <milestone unit="act" n="{../@n}"/>
                <milestone unit="scene" n="{@n}"/>
                <xsl:apply-templates/>
              </unsegmented-text>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>Unknown div1 and div2 type combination</xsl:message>
            <xsl:message>  div1 type: <xsl:value-of select="../@type"/>, n: <xsl:value-of select="../@n"/></xsl:message>
            <xsl:message>  div2 type: <xsl:value-of select="@type"/>, n: <xsl:value-of select="@n"/></xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Unknown div2 type</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Lines, paragraphs etc. -->
  <xsl:template match="lb">
    <lb/>
    <milestone unit="line" ed="{@ed}" n="{@n}"/>
  </xsl:template>

  <xsl:template match="lg"><xsl:apply-templates/></xsl:template>
  <xsl:template match="l"><xsl:apply-templates/></xsl:template>
  <xsl:template match="p"><xsl:apply-templates/></xsl:template>
  <xsl:template match="sp"><xsl:apply-templates/></xsl:template>

  <xsl:template match="speaker">
    <speaker><xsl:apply-templates/></speaker>
  </xsl:template>

  <!-- Editorial mark-up, abbreviations etc. -->
  <xsl:template match="num">
    <xsl:value-of select="translate(., 'ivxlcdm', 'ⅠⅤⅩⅬⅭⅮⅯ')"/>
  </xsl:template>

  <xsl:template match="gap"><gap/></xsl:template>

  <xsl:template match="abbr">
    <expan abbr="{.}"><xsl:value-of select="@expan"/></expan>
  </xsl:template>

  <!-- References -->
  <xsl:template match="milestone">
    <xsl:choose>
      <xsl:when test="@unit='chapter' or @unit='section'">
        <milestone unit="{@unit}" n="{@n}"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Complex stuff: citations and quotes. -->
  <xsl:template match="cit">
    <!-- Extract the quotation out from the citation. -->
    <xsl:apply-templates select="quote"/>
  </xsl:template>

  <!-- Headlines, headers etc. -->

  <xsl:template match="head"/>
  <xsl:template match="teiHeader"/>
</xsl:stylesheet>
