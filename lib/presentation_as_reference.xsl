<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
  <xsl:output
          method="text"
          encoding="UTF-8"/>

  <xsl:template match="/presentation">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="milestone|lb">
    <xsl:value-of select="@unit"/>
    <xsl:text>=</xsl:text>
    <xsl:value-of select="@n"/>
    <xsl:text>,</xsl:text>
  </xsl:template>

  <xsl:template match="text()"/>
</xsl:stylesheet>
