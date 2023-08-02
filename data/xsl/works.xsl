<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" exclude-result-prefixes="xs" version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes"/>
    
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    
    <xsl:template match="mei:p|tei:p">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:lb|tei:lb">
        <xsl:element name="br"/>
    </xsl:template>
    
    <!-- suppress links within titles (for popovers etc.) -->
    <xsl:template match="mei:persName[parent::mei:title]|tei:persName[parent::tei:title]" priority="4">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:eventList|tei:listEvent|mei:notesStmt">
        <xsl:element name="dl">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:perfResList[not(parent::mei:perfResList)]|mei:castList">
        <xsl:element name="dl">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="node() except (mei:head)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:event[parent::mei:eventList]">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:value-of select="wega:getLanguageString(@type, $lang)"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:text>Am </xsl:text>
            <xsl:value-of select="mei:date/@isodate"/>
            <xsl:text> in </xsl:text>
            <xsl:value-of select="mei:settlement"/>
            <xsl:element name="dl">
                <xsl:apply-templates select="@xml:id"/>
                <xsl:for-each select="mei:persName|mei:corpName">
                    <xsl:element name="dt">
                        <xsl:apply-templates select="@xml:id"/>
                        <xsl:choose>
                            <xsl:when test="wega:getLanguageString(@role, $lang)"><xsl:value-of select="wega:getLanguageString(@role, $lang)"/></xsl:when>
                            <xsl:otherwise><xsl:value-of select="@role"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:element>
                    <xsl:element name="dd">
                        <xsl:apply-templates select="@xml:id"/>
                        <xsl:value-of select="text()"/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:event[parent::tei:listEvent]">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="tei:desc"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="node() except (tei:desc)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:creation">
        <xsl:element name="p">
            <xsl:value-of select="wega:getLanguageString('dateOfOrigin', $lang)"/>
            <xsl:text>: </xsl:text>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:perfResList[parent::mei:perfMedium]">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:value-of select="mei:perfRes"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:castItem">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:value-of select="mei:role"/>
            <xsl:if test="mei:roleDesc != ''"><xsl:text>, </xsl:text><xsl:element name="i"><xsl:value-of select="mei:roleDesc"/></xsl:element></xsl:if>
            <xsl:if test="mei:perfRes != ''"><xsl:text> (</xsl:text><xsl:value-of select="mei:perfRes"/><xsl:text>)</xsl:text></xsl:if>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="mei:annot|tei:note">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:if test="@type='pageSchott'"><xsl:text>Seite im Schott Verzeichnis: </xsl:text></xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:biblStruct">
        <xsl:element name="br"/>
        <xsl:element name="span">
            <xsl:value-of select="wega:getLanguageString(@type, $lang)"/>
        </xsl:element>
        <xsl:element name="br"/>
        <xsl:apply-templates select="tei:monogr"/>
    </xsl:template>
    
    <xsl:template match="tei:monogr">
        <xsl:apply-templates select="tei:imprint"/>
    </xsl:template>
    
    <xsl:template match="tei:author">
        <xsl:call-template name="createLink"/>
    </xsl:template>
    
    <xsl:template match="tei:imprint">
        <xsl:element name="span">
            <xsl:value-of select="tei:pubPlace"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="tei:date/@when"/>
        </xsl:element>
        <xsl:element name="br"/>
        <xsl:element name="span">
            <xsl:value-of select="tei:publisher"/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>