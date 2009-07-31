<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
  <xsl:output
          method="xml"
          encoding="UTF-8"
          omit-xml-declaration="yes"
          indent="yes"/>

  <xsl:template match="/presentation">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="span[@class='milestone']">
    <milestone n="{@n}" unit="{@unit}"/>
  </xsl:template>

  <xsl:template match="span[@class='reg']">
    <reg orig="{@orig}"><xsl:apply-templates/></reg>
  </xsl:template>

  <xsl:template match="span[@class='expan']">
    <expan orig="{@abbr}"><xsl:apply-templates/></expan>
  </xsl:template>

  <xsl:template match="span[@class='segmented']">
    <segmented orig="{@orig}"><xsl:apply-templates/></segmented>
  </xsl:template>

  <xsl:template match="span[@class='gap']">
    <gap/>
  </xsl:template>

  <xsl:template match="span[@class='w' or @class='w selected' or @class='selected w']">
    <w><xsl:value-of select="."/></w>
  </xsl:template>

  <xsl:template match="span[@class='pc']">
    <pc><xsl:value-of select="."/></pc>
  </xsl:template>

  <xsl:template match="span[@class='s']">
    <s><xsl:value-of select="."/></s>
  </xsl:template>

  <xsl:template match="text()"/>
</xsl:stylesheet>
