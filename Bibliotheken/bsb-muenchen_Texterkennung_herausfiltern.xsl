<xsl:stylesheet version="2.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
>
<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="yes" indent="no"/>
<!-- <xsl:param name="XMLproducts" select="saxon:parse($products)"></xsl:param> -->

<xsl:template match="xhtml:html">
<SeiteTexterkennung>
<xsl:for-each select="//xhtml:p[@class='ocr_par']">
<xsl:text>&#xa;</xsl:text>
<p>
<!-- <xsl:value-of select="concat('Anzahl ocr_line: ', count(xhtml:span[@class='ocr_line']))" /> -->
  <xsl:for-each select="xhtml:span[@class='ocr_line']">
    <!-- if-Zweig -->
    <Zeile>
      <xsl:value-of select="xhtml:span[@class='ocrx_word']" separator=" "/>
<!--       <xsl:value-of select="concat('Anzahl ocr_line: ', count(../xhtml:span[@class='ocr_line']))" /> -->
<!--       <xsl:value-of select="concat('position ocr_line: ', position())" /> -->

    </Zeile>
  <xsl:choose>
    <xsl:when test="count(../xhtml:span[@class='ocr_line']) &gt; 1 and position() &lt; count(../xhtml:span[@class='ocr_line'])">
    <xsl:text>&#xa;</xsl:text>
    </xsl:when>
      <xsl:otherwise>
    </xsl:otherwise>
  </xsl:choose>
  </xsl:for-each>
</p>
<xsl:text>&#xa;</xsl:text>
</xsl:for-each>

</SeiteTexterkennung>
<xsl:text>&#xa;&#xa;</xsl:text>
<!--<xsl:for-each select="//xhtml:span[@class='ocrx_word']">
  <xsl:value-of select="." separator=" "/>
</xsl:for-each>-->

</xsl:template>
</xsl:stylesheet>
