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
    <xsl:value-of select="."/>
    <xsl:text>#</xsl:text>
  </xsl:template>

  <xsl:template match="expan|corr|reg|segmented|add|unclear">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="gap|del|milestone|speaker|lb"/>

  <xsl:template match="text()"/>
</xsl:stylesheet>
