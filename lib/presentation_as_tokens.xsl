<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
  <xsl:output
          method="text"
          encoding="UTF-8"/>

  <xsl:template match="/presentation"><xsl:apply-templates/></xsl:template>

  <xsl:template match="num">
    <xsl:value-of select="@value"/>
  </xsl:template>

  <xsl:template match="w">
    <xsl:apply-templates/>
    <xsl:text>#</xsl:text>
  </xsl:template>

  <xsl:template match="expan|corr|reg|segmented|add|unclear">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="gap|del|milestone|speaker|lb"/>

  <!-- Accept text within a w element unless matched by any of the
  above (typically by del) -->
  <xsl:template match="//w/text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- Ignore all text not caught by the w element template above. -->
  <xsl:template match="text()"/>
</xsl:stylesheet>
