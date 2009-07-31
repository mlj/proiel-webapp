<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">
  <xsl:output
          method="xml"
          encoding="UTF-8"
          omit-xml-declaration="yes"
          indent="no"/>
  <xsl:preserve-space elements="*"/>

  <xsl:template match="/presentation">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="milestone">
    <span class="milestone" n="{@n}" unit="{@unit}"><xsl:value-of select="@n"/></span>
  </xsl:template>

  <xsl:template match="reg">
    <span class="reg" orig="{@orig}"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="expan">
    <span class="expan" abbr="{@abbr}"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="segmented">
    <span class="segmented" orig="{@orig}"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="gap">
    <span class="gap">...</span>
  </xsl:template>

  <xsl:template match="w">
    <span class="w"><xsl:value-of select="."/></span>
  </xsl:template>

  <xsl:template match="pc">
    <span class="pc"><xsl:value-of select="."/></span>
  </xsl:template>

  <xsl:template match="s">
    <span class="s"><xsl:value-of select="."/></span>
  </xsl:template>

  <xsl:template match="text()"/>
</xsl:stylesheet>
