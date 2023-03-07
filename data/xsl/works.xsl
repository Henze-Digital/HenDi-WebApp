<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" exclude-result-prefixes="xs" version="2.0">
    
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
    
    <xsl:template match="mei:eventList|tei:listEvent">
        <xsl:element name="dl">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:event[parent::mei:eventList]|tei:event[parent::tei:listEvent]">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="mei:head|tei:desc"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="node() except (mei:head|tei:desc)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:creation">
        <xsl:element name="p">
            <xsl:value-of select="wega:getLanguageString('dateOfOrigin', $lang)"/>
            <xsl:text>: </xsl:text>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:annot|tei:note">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:biblStruct">
        <xsl:element name="br"/>
        <xsl:element name="span"><xsl:value-of select="wega:getLanguageString(@type, $lang)"/></xsl:element>
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