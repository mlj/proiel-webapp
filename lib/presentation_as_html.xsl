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
  <xsl:template match="num">
    <abbr title="@{value}"><xsl:apply-templates/></abbr>
  </xsl:template>

  <xsl:template match="expan">
    <abbr><xsl:value-of select="@abbr"/></abbr>
  </xsl:template>

  <xsl:template match="corr">
    <abbr><xsl:value-of select="@sic"/></abbr>
  </xsl:template>

  <xsl:template match="reg|segmented">
    <abbr><xsl:value-of select="@orig"/></abbr>
  </xsl:template>

  <!-- Tokenization -->
  <xsl:template match="w">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Editorial mark-up -->
  <xsl:template match="add">
    <xsl:text>&lt;</xsl:text><xsl:apply-templates/><xsl:text>&gt;</xsl:text>
  </xsl:template>

  <xsl:template match="del">
    <xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="unclear">
    <xsl:text>(</xsl:text><xsl:apply-templates/><xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="gap">
    <xsl:text>&#x2026;</xsl:text>
  </xsl:template>

  <!-- Reference systems -->
  <xsl:template match="milestone">
    <span class="{@unit}-number" lang="{$default_language_code}"><xsl:value-of select="@n"/></span>
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- Speakers etc. -->
  <xsl:template match="speaker">
    <span class="speaker"><xsl:apply-templates/>: </span>
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- Typography -->
  <xsl:template match="lb">
    <br/>
  </xsl:template>
</xsl:stylesheet>
