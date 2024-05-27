<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:teix="http://www.tei-c.org/ns/Examples" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:param name="createSecNos" select="false()"/>
    <xsl:param name="secNoOffset" select="0"/>
    <xsl:param name="uri"/>
    <xsl:param name="main-source-file" select="'/db/apps/HenDi-WebApp/guidelines/guidelines-de-hendiAll.compiled.xml'"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:q tei:quote tei:cell tei:p tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:code tei:eg tei:item tei:head tei:date tei:orgName tei:note tei:lem tei:rdg tei:add tei:bibl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>
	<!--<xsl:include href="tagdocs.xsl"/>-->
    <xsl:include href="apparatus.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- wird nie benutzt, oder?! -->
    <!--<xsl:template match="tei:text">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'docText'"/>
            <xsl:apply-templates select="./tei:body/tei:div[@xml:lang=$lang] | ./tei:body/tei:divGen"/>
        </xsl:element>
    </xsl:template>-->
    
    <xsl:template match="tei:body">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:back">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:divGen[@type='toc']">
        <xsl:call-template name="createToc">
            <xsl:with-param name="lang" select="$lang"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:divGen[@type='endNotes']">
        <xsl:call-template name="createEndnotesFromNotes"/>
    </xsl:template>
    
    <xsl:template match="tei:div">
        <xsl:variable name="uniqueID">
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="generate-id()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="div">
            <xsl:choose>
                <xsl:when test="not(parent::tei:div)">
                    <xsl:element name="div">
                        <xsl:attribute name="class"><!--card--> <xsl:if test="@type"><xsl:value-of select="@type"/></xsl:if></xsl:attribute>
                        <xsl:element name="div">
<!--                            <xsl:attribute name="class">card-header</xsl:attribute>-->
                            <xsl:attribute name="id"><xsl:value-of select="concat('heading-',$uniqueID)"/></xsl:attribute>
                            <xsl:element name="div">
                                <xsl:element name="button">
                                    <xsl:attribute name="class">btn btn-link btn-block text-left</xsl:attribute>
                                    <xsl:attribute name="type">button</xsl:attribute>
                                    <xsl:attribute name="data-toggle">collapse</xsl:attribute>
                                    <xsl:attribute name="data-target"><xsl:value-of select="concat('#collapse-',$uniqueID)"/></xsl:attribute>
                                    <xsl:attribute name="aria-expanded">true</xsl:attribute>
                                    <xsl:attribute name="aria-controls"><xsl:value-of select="concat('collapse-',$uniqueID)"/></xsl:attribute>
                                    <xsl:apply-templates select="tei:head"/>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                    <xsl:element name="div">
                        <xsl:attribute name="class">collapse</xsl:attribute>
                        <xsl:attribute name="id"><xsl:value-of select="concat('collapse-',$uniqueID)"/></xsl:attribute>
                        <xsl:attribute name="aria-labelledby"><xsl:value-of select="concat('heading-',$uniqueID)"/></xsl:attribute>
                        <xsl:attribute name="data-parent">#transcription</xsl:attribute>
                        <xsl:element name="div">
                            <xsl:attribute name="class">card-body</xsl:attribute>
                            <xsl:apply-templates select="node()[not(self::tei:head)]"/>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="div">
                        <xsl:attribute name="id" select="$uniqueID"/>
                        <xsl:if test="@type">
                            <xsl:attribute name="class" select="@type"/>
                        </xsl:if>
                        <xsl:if test="matches(@xml:id, '^para\d+$')">
                            <xsl:call-template name="create-para-label">
                                <xsl:with-param name="no" select="substring-after(@xml:id, 'para')"/>
                            </xsl:call-template>
                        </xsl:if>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:head[not(@type='sub')][parent::tei:div]">
<!--        <xsl:choose>-->
<!--            <xsl:when test="//tei:divGen">-->
                <!-- Überschrift h2 für Editionsrichtlinien und Weber-Biographie -->
                <xsl:element name="{concat('h', count(ancestor::tei:div) +1)}">
                    <xsl:attribute name="id">
                        <xsl:choose>
                            <xsl:when test="@xml:id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="generate-id()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:if test="$createSecNos and not(./following::tei:divGen)">
                        <xsl:call-template name="createSecNo">
                            <xsl:with-param name="div" select="parent::tei:div"/>
                            <xsl:with-param name="lang" select="$lang"/>
                        </xsl:call-template>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:element>
<!--            </xsl:when>-->
            <!--<xsl:otherwise>
                <!-\- Ebenfalls h2 für Indexseite und Impressum -\->
                <xsl:element name="{concat('h', count(ancestor::tei:div) +1)}">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>-->
        <!--</xsl:choose>-->
    </xsl:template>

    <xsl:template match="tei:head[@type='sub']">
        <xsl:element name="h3">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
	
	<xsl:template match="tei:head[@type='quote']">
		<xsl:element name="h4">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:attribute name="class">quote</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:p[starts-with($docID, 'A09')]">
		<xsl:element name="p">
			<xsl:attribute name="class">explNotes</xsl:attribute>
			<xsl:apply-templates select="@xml:id"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

    <xsl:template match="tei:ab">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:code">
        <xsl:element name="code">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:gloss[parent::tei:eg]">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'card-header'"/>
            <xsl:element name="h4">
                <xsl:attribute name="class" select="'card-title'"/>
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:address">
        <xsl:element name="ul">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'contactAddress'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:addrLine">
        <xsl:element name="li">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="@n='telephone'">
                    <xsl:value-of select="concat(wega:getLanguageString('tel',$lang), ': ')"/>
                    <xsl:element name="a">
                        <xsl:attribute name="href" select="concat('tel:', replace(normalize-space(.), '-|–|(\(0\))|\s', ''))"/>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:when>
                <xsl:when test="@n='fax'">
                    <xsl:value-of select="concat(wega:getLanguageString('fax',$lang), ': ', .)"/>
                </xsl:when>
                <xsl:when test="@n='email'">
                    <xsl:element name="a">
                        <xsl:attribute name="class" select="'obfuscate-email'"/>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:note[@type=('commentary','definition','textConst')]" priority="2">
        <xsl:call-template name="popover">
            <xsl:with-param name="marker" select="'arabic'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:listBibl">
        <xsl:element name="ul">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:bibl[parent::tei:listBibl]">
        <xsl:element name="li">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- Styling of code examples -->
    
    <xsl:template match="teix:egXML">
        <xsl:element name="pre">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">shadow-sm p-3 bg-light rounded</xsl:attribute>
            <xsl:element name="code">
                <xsl:apply-templates select="@xml:id"/>
                <xsl:attribute name="class">language-xml</xsl:attribute>
                <xsl:apply-templates select="./node()" mode="verbatim"/>
            </xsl:element>
        </xsl:element>
        <xsl:if test="@source">
            <xsl:element name="p">
                <xsl:attribute name="class">textAlign-right</xsl:attribute>
                <xsl:text>(Beispiel aus </xsl:text>
                    <xsl:value-of select="@source"/>
                <xsl:text>)</xsl:text>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <!-- Linking of named elements and attributes and values -->
    
    <xsl:template match="tei:gi">
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:value-of select="concat('Elemente/ref-', ., '.html')"/>
            </xsl:attribute>
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>&gt;</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:att">
        <xsl:element name="code">
            <xsl:text>@</xsl:text>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:val">
        <xsl:element name="code">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:tag">
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>&gt;</xsl:text>
    </xsl:template>
    
    <!-- this is a fix, very hendi specific ! -->
	<!-- needs a parameter that provides the current URL -->
	<!-- (for navigating to other gl-chapters) -->
	<xsl:template match="tei:ptr[starts-with(@target,'#')]">
        <xsl:variable name="ptrTargetID" select="./@target/substring-after(., '#')"/>
        <xsl:variable name="gl-chapter-url-substring">
            <xsl:choose>
                <xsl:when test="starts-with(./@target,'#DT')">docTypes</xsl:when>
                <xsl:when test="starts-with(./@target,'#eG')">encoding</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="gl-chapter-url" select="concat('/Projekt/Editionsrichtlinien/sec-', $gl-chapter-url-substring, '.html')"/>
        <xsl:element name="a">
            <xsl:attribute name="href" select="concat($gl-chapter-url, '#', $ptrTargetID)"/>
            <xsl:value-of select="wega:doc($main-source-file)//tei:div[@xml:id = $ptrTargetID]/tei:head[1]/text()"/>
        </xsl:element>
    </xsl:template>
	
	<!-- rendering of specLists -->
	<xsl:template match="tei:specList">
		<ul style="padding: 0.5em;">
			<xsl:for-each select="tei:specDesc">
				<li style="padding: 7px;">
                    <a href="{concat('/Projekt/Editionsrichtlinien/Elemente/ref-', @key, '.html')}">
					<div class="row">
						<div class="col-1">
                                <span style="border: solid 2pt #181c62;padding: 0.5em;">
                                    <i class="fa-solid fa-code"/>
                                </span>
                            </div>
						<div class="col-11">
                                <span style="margin-left: 0.5em;">
                                    <xsl:text>&lt;</xsl:text>
                                    <xsl:value-of select="@key"/>
                                    <xsl:text>&gt;</xsl:text>
                                </span>
                            </div>
					</div>
				</a>
                </li>
			</xsl:for-each>
		</ul>
	</xsl:template>
    
    <!-- Create section numbers for headings   -->
    <xsl:template name="createSecNo">
        <xsl:param name="div"/>
        <xsl:param name="lang"/>
        <xsl:param name="dot" select="false()"/>
        <xsl:variable name="offset" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$div/ancestor::tei:div">
                    <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$secNoOffset"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$div/parent::tei:div">
            <xsl:call-template name="createSecNo">
                <xsl:with-param name="div" select="$div/parent::tei:div"/>
                <xsl:with-param name="lang" select="$lang"/>
                <xsl:with-param name="dot" select="true()"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:value-of select="count($div/preceding-sibling::tei:div[not(following::tei:divGen)][tei:head][ancestor-or-self::tei:div/@xml:lang=$lang]) + 1 +$offset"/>
        <xsl:if test="$dot">
            <xsl:text>. </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Create table of contents   -->
    <xsl:template name="createToc">
        <xsl:param name="lang" as="xs:string?"/>
        <xsl:element name="div">
            <xsl:attribute name="id" select="'toc'"/>
            <xsl:element name="h2">
                <xsl:value-of select="wega:getLanguageString('toc', $lang)"/>
            </xsl:element>
            <xsl:element name="ul">
                <xsl:for-each select="//tei:head[not(@type='sub')][ancestor::tei:div/string(@xml:lang) = ($lang, '')][preceding::tei:divGen[@type='toc']][parent::tei:div] | //tei:divGen[@type='endNotes']">
                    <xsl:element name="li">
                    	<xsl:attribute name="class" select="concat('secLevel', count(ancestor::tei:div))"/>
                        <xsl:element name="a">
                            <xsl:attribute name="href">
                                <xsl:choose>
                                    <xsl:when test="parent::tei:div[@xml:id]">
                                        <xsl:value-of select="concat('#', parent::tei:div/@xml:id)"/>
                                    </xsl:when>
                                    <xsl:when test="self::tei:divGen">
                                        <xsl:value-of select="concat('#', @type)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat('#', generate-id())"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:if test="$createSecNos">
                                <xsl:call-template name="createSecNo">
                                    <xsl:with-param name="div" select="parent::tei:div"/>
                                    <xsl:with-param name="lang" select="$lang"/>
                                </xsl:call-template>
                                <xsl:text> </xsl:text>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="self::tei:divGen">
                                    <xsl:value-of select="wega:getLanguageString('endNotes', $lang)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template name="create-para-label">
        <!--<xsl:param name="lang" tunnel="yes"/>-->
        <xsl:param name="no"/>
        <xsl:element name="span">
            <xsl:attribute name="class" select="'para-label'"/>
            <xsl:value-of select="concat('§ ', $no)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="createEndnotesFromNotes">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'endNotes'"/>
            <xsl:element name="{concat('h', count(ancestor::tei:div) + 2)}">
                <xsl:value-of select="wega:getLanguageString('endNotes', $lang)"/>
            </xsl:element>
            <xsl:element name="ol">
                <xsl:attribute name="class">endNotes</xsl:attribute>
                <xsl:for-each select="//tei:note[@type=('commentary','definition','textConst')]">
                    <xsl:element name="li">
                        <xsl:attribute name="id" select="./@xml:id"/>
                        <xsl:attribute name="data-title" select="concat(wega:getLanguageString('endNote', $lang), ' ', position())"/>
                        <xsl:element name="a">
                            <xsl:attribute name="class">endnote_backlink</xsl:attribute>
                            <xsl:attribute name="href" select="concat('#ref-', @xml:id)"/>
                            <xsl:value-of select="position()"/>
                        </xsl:element>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="*" mode="verbatim">
        <xsl:param name="indent-increment" select="'   '"/>
        <xsl:param name="indent" select="'&#xA;'"/>
        
        <!-- indent the opening tag; unless it's the root element -->
        <xsl:if test="not(parent::teix:egXML)">
            <xsl:value-of select="$indent"/>
        </xsl:if>
        
        <!-- Begin opening tag -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        
        <!-- Namespaces -->
        <xsl:for-each select="namespace::*[not(starts-with(., 'http://www.tei-c.org') or . eq 'http://www.w3.org/XML/1998/namespace')]">
            <xsl:text> xmlns</xsl:text>
            <xsl:if test="name() != ''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="name()"/>
            </xsl:if>
            <xsl:text>='</xsl:text>
            <xsl:call-template name="verbatim-xml">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>'</xsl:text>
        </xsl:for-each>
        
        <!-- Attributes -->
        <xsl:for-each select="@*">
            <xsl:text> </xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>='</xsl:text>
            <xsl:call-template name="verbatim-xml">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>'</xsl:text>
        </xsl:for-each>
        
        <!-- End opening tag -->
        <xsl:text>&gt;</xsl:text>
        
        <!-- Content (child elements, text nodes, and PIs) -->
        <xsl:apply-templates select="node()" mode="verbatim">
            <xsl:with-param name="indent" select="concat($indent, $indent-increment)"/>
        </xsl:apply-templates>
        
        <xsl:if test="*">
            <xsl:value-of select="$indent"/>
        </xsl:if>
        
        <!-- Closing tag -->
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
    </xsl:template>
    
    <!--
        Need to add priority to overwrite default 
        template (with mode #add) in the commons module
    -->
    <xsl:template match="text()" mode="verbatim" priority="0.1">
        <xsl:call-template name="verbatim-xml">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="processing-instruction()" mode="verbatim">
        <xsl:text>&lt;?</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="verbatim-xml">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
        <xsl:text>?&gt;</xsl:text>
    </xsl:template>
    
    <xsl:template name="verbatim-xml">
        <xsl:param name="text"/>
        <xsl:if test="$text != ''">
            <xsl:variable name="head" select="substring($text, 1, 1)"/>
            <xsl:variable name="tail" select="substring($text, 2)"/>
            <xsl:choose>
                <xsl:when test="$head = '&amp;'">&amp;amp;</xsl:when>
                <xsl:when test="$head = '&lt;'">&amp;lt;</xsl:when>
                <xsl:when test="$head = '&gt;'">&amp;gt;</xsl:when>
                <xsl:when test="$head = '&#34;'">&amp;quot;</xsl:when>
                <xsl:when test="$head = &#34;'&#34;">&amp;apos;</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$head"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="verbatim-xml">
                <xsl:with-param name="text" select="$tail"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>