<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    
    <xsl:strip-space elements="*"/>
	<xsl:preserve-space elements="tei:p tei:dateline tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:footnote tei:head tei:orgName tei:note tei:q tei:quote tei:provenance tei:acquisition tei:bibl"/>
    
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <!--    <xsl:preserve-space elements="tei:persName"/>-->

    <!--<xsl:template match="/">
        <xsl:apply-templates/>
        </xsl:template>-->

    <xsl:template match="tei:msDesc">
        <xsl:choose>
            <xsl:when test="parent::tei:witness">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>                
                    <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:msIdentifier">
        <xsl:call-template name="createMsIdentifier">
            <xsl:with-param name="node" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Sonderregel für msIdentifier mit msName, außerhalb von msFrag -->
    <xsl:template match="tei:msIdentifier[tei:msName][not(parent::tei:msFrag)]">
        <!-- msNames außerhalb von msFrag werden vorab als Titel gesetzt -->
        <xsl:apply-templates select="tei:msName"/>
        <xsl:if test="* except tei:msName">
            <!-- Wenn weitere Elemente (eine vollständige bibliogr. Angabe) folgen, 
                wird hier noch ein Umbruch erzwungen und dann der Rest ausgegeben -->
            <xsl:element name="br"/>
            <xsl:call-template name="createMsIdentifier">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:msFrag">
        <xsl:element name="div">
            <xsl:attribute name="class">tei_msFrag apparatus-block</xsl:attribute>
            <xsl:element name="h4">
                <xsl:value-of select="concat(wega:getLanguageString('fragment', $lang), ' ', count(preceding-sibling::tei:msFrag) +1)"/>
                <xsl:choose>
                   <xsl:when test="tei:msIdentifier/tei:msName">
                       <xsl:value-of select="concat(': ', tei:msIdentifier/tei:msName)"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:element>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createMsIdentifier">
        <xsl:param name="node"/>
        <!--<xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('repository', $lang)"/>
        </xsl:element>-->
        <xsl:element name="span">
            <!--<xsl:attribute name="class">media-heading</xsl:attribute>-->            
<!--            <xsl:if test="$node/ancestor-or-self::tei:msDesc/@rend">
                <xsl:value-of select="wega:getLanguageString($node/ancestor-or-self::tei:msDesc/@rend, $lang)"/>
                <xsl:text>: </xsl:text>
            </xsl:if>-->
            <xsl:if test="$node/tei:settlement != ''">
                <xsl:apply-templates select="tei:settlement"/>
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:country != ''">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="tei:country"/>
                <xsl:text>), </xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:repository != ''">
                <xsl:apply-templates select="$node/tei:repository"/>
            </xsl:if>
            <xsl:if test="$node/tei:repository/@n">
                <xsl:text> (</xsl:text>
                <xsl:value-of select="$node/tei:repository/@n"/>
                <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:collection != ''">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="$node/tei:collection"/>
            </xsl:if>
            <xsl:if test="$node/tei:idno != ''">
                <xsl:element name="br"/>
                <xsl:element name="i">
                    <xsl:apply-templates select="wega:getLanguageString('shelfMark', $lang)"/>
                </xsl:element>
                <xsl:text>: </xsl:text>
                <xsl:apply-templates select="$node/tei:idno"/>
            </xsl:if>
            <xsl:if test="$node/tei:altIdentifier != ''">
                <xsl:variable name="altIdentifier" as="element()">
                    <xsl:call-template name="createMsIdentifier">
                        <xsl:with-param name="node" select="$node/tei:altIdentifier"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:element name="br"/>
                <xsl:element name="i">
                    <xsl:value-of select="wega:getLanguageString('formerly', $lang)"/>
                </xsl:element>
                <xsl:text>: </xsl:text>
                <xsl:element name="span">
                    <xsl:attribute name="class">tei_altIdentifier</xsl:attribute>
                    <xsl:copy-of select="$altIdentifier/node()"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:physDesc">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('physicalDescription', $lang)"/>
        </xsl:element>
        <xsl:if test="tei:p">
        <xsl:element name="ul">
            <xsl:for-each select="tei:p">
                <xsl:element name="li">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
        </xsl:if>
        <xsl:if test="tei:objectDesc">
            <xsl:variable name="objectDescN" select="count(tei:objectDesc)"/>
            <xsl:for-each select="tei:objectDesc">
                <xsl:element name="ul">
                    <xsl:if test="@form">
                        <xsl:element name="li">
                            <xsl:value-of select="wega:getLanguageString('physDesc.objectDesc.form', $lang)"/>
                            <xsl:if test="$objectDescN > 1">
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="position()"/>
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                            <xsl:text>: </xsl:text>
                            <xsl:value-of select="wega:getLanguageString(concat('physDesc.objectDesc.form.', @form), $lang)"/>
                        </xsl:element>
                    </xsl:if>
                    <xsl:apply-templates select="."/>
                </xsl:element>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="tei:accMat">
            <xsl:element name="h4">
                <xsl:attribute name="class">media-heading</xsl:attribute>
                <xsl:value-of select="wega:getLanguageString('accMat', $lang)"/>
            </xsl:element>
            <xsl:element name="ul">
                <xsl:for-each select="tei:accMat">
                    <xsl:element name="li">
                        <xsl:apply-templates select="tei:desc"/>
                    </xsl:element>
                    <xsl:if test="tei:dimensions">
                        <xsl:element name="li">
                            <xsl:apply-templates select="tei:dimensions"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:for-each>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:history">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('provenance', $lang)"/> 
        </xsl:element>
        <xsl:element name="ul">
            <!-- make tei:acquisition appear on top of the list -->
            <xsl:for-each select="tei:acquisition, tei:provenance">
                <xsl:element name="li">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:additional">
        <!--<xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('prints', $lang)"/>
        </xsl:element>
        <xsl:apply-templates/>-->
    </xsl:template>

    <!--<xsl:template match="tei:listBibl">
        <xsl:element name="ul">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>-->

    <!--<xsl:template match="tei:bibl[parent::tei:listBibl]">
        <xsl:element name="li">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>-->
    
    <xsl:template match="tei:creation">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:note[@type=('summary', 'editorial')]" priority="1">
        <xsl:element name="div">
            <xsl:choose>
                <xsl:when test="tei:p">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="p">
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:note[@type='incipit']">
        <xsl:element name="div">
            <xsl:choose>
                <xsl:when test="tei:p">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="p">
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:supplied">
        <xsl:element name="span">
            <xsl:attribute name="class" select="concat('tei_', local-name())"/>
            <!--<xsl:attribute name="id" select="wega:createID(.)"/>-->
            <xsl:element name="span"><xsl:attribute name="class">brackets_supplied</xsl:attribute><xsl:text>[</xsl:text></xsl:element>
            <xsl:apply-templates/>
            <xsl:element name="span"><xsl:attribute name="class">brackets_supplied</xsl:attribute><xsl:text>]</xsl:text></xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:sic">
        <xsl:element name="span">
            <xsl:attribute name="class" select="concat('tei_', local-name())"/>
            <xsl:apply-templates/>
            <xsl:text>&#x00A0;[sic!]</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <!-- hide corr within choice because we'll only print the sic -->
    <xsl:template match="tei:corr[parent::tei:choice]"/>
    
    <!--<xsl:template match="tei:biblStruct[parent::tei:listBibl]">
        <xsl:sequence select="wega:printCitation(., 'li', $lang)"/>
    </xsl:template>-->


    <!--<xsl:template match="tei:quote">
        <xsl:text>"</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>"</xsl:text>
    </xsl:template>-->
    
    <xsl:template match="tei:support">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('physDesc.material', $lang)"/>
        </xsl:element>
            <xsl:for-each select="tei:material">
                <xsl:element name="li">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="tei:dimensions">
    	<xsl:value-of select="wega:getLanguageString('physDesc.dimensions', $lang)"/><xsl:text>: </xsl:text>
    	<xsl:value-of select="./tei:height/@quantity"/>
    	<xsl:if test="not(./tei:height/@quantity)">0</xsl:if> <!-- for debugging -->
    	<xsl:text>x</xsl:text>
    	<xsl:value-of select="./tei:width/@quantity"/>
    	<xsl:if test="not(./tei:width/@quantity)">0</xsl:if> <!-- for debugging -->
    	<xsl:text> [</xsl:text>
    	<xsl:value-of select="string-join(distinct-values(./tei:height/@unit | ./tei:width/@unit), '/')"/>
    	<xsl:text>]</xsl:text>
    	<xsl:text> (</xsl:text>
    	<xsl:value-of select="wega:getLanguageString('physDesc.height.short', $lang)"/>
    	<xsl:text>x</xsl:text>
    	<xsl:value-of select="wega:getLanguageString('physDesc.width.short', $lang)"/>
    	<xsl:text>)</xsl:text>
    </xsl:template>
	
    <xsl:template match="tei:extent">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('physDesc.extent', $lang)"/>
        </xsl:element>
        <xsl:element name="li">
            <xsl:value-of select="tei:measure[@unit='folio']"/>
            <xsl:if test="tei:measure[@unit='folio'] = ''">0</xsl:if> <!-- for debugging -->
            <xsl:text> </xsl:text>
            <xsl:choose>
                <xsl:when test="tei:measure[@unit='folio'] = '1'">
                    <xsl:value-of select="wega:getLanguageString('physDesc.folio', $lang)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="wega:getLanguageString('physDesc.folios', $lang)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <xsl:element name="li">
            <xsl:value-of select="tei:measure[@unit='pages' and @type='written']"/>
            <xsl:if test="tei:measure[@unit='pages' and @type='written'] = ''">0</xsl:if> <!-- for debugging -->
            <xsl:text> </xsl:text>
            <xsl:choose>
                <xsl:when test="tei:measure[@unit='pages' and @type='written'] = '1'">
                    <xsl:value-of select="wega:getLanguageString('physDesc.written.page', $lang)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="wega:getLanguageString('physDesc.written.pages', $lang)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <xsl:element name="li">
            <xsl:apply-templates select="tei:dimensions"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:condition">
    	<xsl:if test=". != ''">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
<xsl:value-of select="wega:getLanguageString('physDesc.condition', $lang)"/>
        </xsl:element>
        <xsl:element name="li">
<!--            <xsl:if test=". != ''">-->
                <xsl:value-of select="./text()"/>
<!--            </xsl:if>-->
            <!--<xsl:if test=". = ''">
                <xsl:element name="i">
                    <xsl:value-of select="wega:getLanguageString('physDesc.noConditionAvailable', $lang)"/>
                </xsl:element>
            </xsl:if>-->
        </xsl:element>
    	</xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:layoutDesc">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
<xsl:value-of select="wega:getLanguageString('physDesc.layout', $lang)"/>
        </xsl:element>
        <xsl:for-each select="tei:layout">
            <xsl:element name="li">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>