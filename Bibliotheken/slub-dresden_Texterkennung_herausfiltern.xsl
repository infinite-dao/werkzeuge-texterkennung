<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="yes" indent="no"/>

<xsl:template match="/">
<SeiteTexterkennung>
<xsl:for-each select="//*[local-name()='TextBlock']">
<xsl:text>&#xa;</xsl:text>
<p>
  <xsl:for-each select="descendant::*[local-name()='TextLine']">
  <xsl:text>&#xa;</xsl:text><!-- newline/Zeilenumbruch -->
      <Zeile>
        <xsl:value-of select="descendant::*[local-name()='String']/@CONTENT" separator=" "/>
      </Zeile>
  <!--<xsl:choose>
    <xsl:when test="count(../*[local-name()='TextLine']) &gt; 1 and position() &lt; count(../*[local-name()='TextLine'])">
    <xsl:text>&#xa;</xsl:text>
    </xsl:when>
      <xsl:otherwise>
    </xsl:otherwise>
  </xsl:choose>-->
  </xsl:for-each>
</p>
<xsl:text>&#xa;</xsl:text>
</xsl:for-each>
</SeiteTexterkennung>
<xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>
</xsl:stylesheet>
