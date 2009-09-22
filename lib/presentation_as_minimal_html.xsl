<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
  <xsl:output
          method="xml"
          encoding="UTF-8"
          omit-xml-declaration="yes"
          indent="yes"/>

  <xsl:param name="default_language_code"/>
  <xsl:param name="language_code">en</xsl:param>
  <xsl:param name="section_numbers"/>

  <xsl:template match="/presentation">
    <span lang="{$language_code}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- Elements that represent a difference between presented text and
       tokenized text. -->
  <xsl:template match="num"><xsl:apply-templates/></xsl:template>

  <xsl:template match="expan">
    <xsl:value-of select="@abbr"/>
  </xsl:template>

  <xsl:template match="corr">
    <xsl:value-of select="@sic"/>
  </xsl:template>

  <xsl:template match="reg|segmented">
    <xsl:value-of select="@orig"/>
  </xsl:template>

  <!-- Tokenization -->
  <xsl:template match="w">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Editorial mark-up -->
  <xsl:template match="add">
    <add><xsl:apply-templates/></add>
  </xsl:template>

  <xsl:template match="del">
    <del><xsl:apply-templates/></del>
  </xsl:template>

  <xsl:template match="unclear">
    <span class="unclear"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="gap">
    <xsl:text>&#x2026;</xsl:text>
  </xsl:template>

  <!-- Reference systems -->
  <xsl:template match="milestone"/>

  <!-- Speakers etc. -->
  <xsl:template match="speaker"/>

  <!-- Typography -->
  <xsl:template match="lb"/>
</xsl:stylesheet>
