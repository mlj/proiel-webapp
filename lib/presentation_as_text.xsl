<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
  <xsl:output
          method="text"
          encoding="UTF-8"/>

  <xsl:template match="/presentation"><xsl:apply-templates/></xsl:template>

  <!-- Elements that represent a difference between presented text and
       tokenized text. -->
  <xsl:template match="num">
    <xsl:value-of select="@value"/>
  </xsl:template>

  <xsl:template match="expan|corr|reg|segmented">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Tokenization -->
  <xsl:template match="w">
    <xsl:apply-templates/>
    <!-- A space to force tokenization. -->
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- Editorial mark-up -->
  <xsl:template match="add|unclear">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="gap|del"/>

  <!-- Reference systems -->
  <xsl:template match="milestone"/>

  <!-- Speakers etc. -->
  <xsl:template match="speaker"/>

  <!-- Typography -->
  <xsl:template match="lb"/>
</xsl:stylesheet>
