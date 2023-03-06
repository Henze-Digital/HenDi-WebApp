<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" version="2.0">
	<xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
	<xsl:strip-space elements="*"/>
	<xsl:preserve-space elements="tei:q tei:quote tei:item tei:cell tei:p tei:dateline tei:closer tei:opener tei:hi tei:addrLine tei:persName tei:rs tei:name tei:placeName tei:seg tei:l tei:head tei:salute tei:date tei:subst tei:add tei:note tei:orgName tei:lem tei:rdg tei:provenance tei:acquisition tei:damage"/>
	<xsl:include href="common_link.xsl"/>
	<xsl:include href="common_main.xsl"/>
	<xsl:include href="apparatus.xsl"/>
	
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:body">
		<xsl:element name="div">
			<xsl:attribute name="class" select="'teiLetter_body'"/>
			<xsl:choose>
				<xsl:when test="parent::tei:text/@type='envelope'">
					<xsl:element name="h4">
						<xsl:attribute name="style" select="'padding-top: 2em; padding-bottom: 0.5em;'"/>
						[<xsl:value-of select="wega:getLanguageString('physDesc.objectDesc.form.envelope', $lang)"/>:]</xsl:element>
					<xsl:element name="div">
						<xsl:attribute name="style" select="'border: solid;'"/>
						<xsl:apply-templates/>		
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="//tei:note[@place='bottom']">
				<xsl:call-template name="createEndnotes"/>
			</xsl:if>
		</xsl:element>
		<xsl:call-template name="createApparatus"/>
	</xsl:template>
	
	<xsl:template match="tei:div[@type='row']">
		<xsl:element name="div">
			<xsl:attribute name="class" select="'row justify-content-center'"/>
			<xsl:if test="ancestor::tei:text/@type = 'telegram'">
				<xsl:attribute name="style" select="'border: solid;'"/>
			</xsl:if>
			<xsl:apply-templates select="./tei:div"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:div[parent::tei:div[@type='row']]">
		<xsl:element name="div">
			<xsl:choose>
				<xsl:when test="contains(@type, 'col-')">
					<xsl:attribute name="class" select="@type"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="class" select="'col'"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="ancestor::tei:text/@type = 'telegram'">
				<xsl:attribute name="style" select="'border: 0.5pt dashed; overflow-x: scroll; white-space: nowrap;'"/>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:div[not(@type='row') and not(parent::tei:div[@type='row'])]">
		<xsl:element name="div">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:choose>
				<xsl:when test="@type='writingSession'">
					<xsl:attribute name="class" select="'writingSession'"/>
					<!--<xsl:if test="following-sibling::tei:div[1][@rend='inline'] or ./@rend='inline'">
                    <xsl:attribute name="style" select="'display:inline'"/>
                </xsl:if>-->
					<xsl:apply-templates/>
					<xsl:if test="not(following-sibling::tei:div)">
						<xsl:element name="p">
							<xsl:attribute name="class" select="'clearer'"/>
						</xsl:element>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:opener">
		<xsl:element name="div">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:attribute name="class">
				<xsl:value-of select="'teiLetter_opener'"/>
			</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:head[parent::tei:div[@type='writingSession']]" priority="1">
		<xsl:element name="h2">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:salute">
		<xsl:choose>
			<xsl:when test="parent::node()/name() = 'opener'">
				<xsl:element name="p">
					<xsl:apply-templates select="@xml:id"/>
					<xsl:attribute name="class">teiLetter_salute</xsl:attribute>
					<xsl:choose>
						<xsl:when test="@rend='inline'">
							<xsl:attribute name="style">display:inline;</xsl:attribute>
						</xsl:when>
						<xsl:when test="@rend='right'">
							<xsl:attribute name="style">text-align:right;</xsl:attribute>
						</xsl:when>
						<xsl:when test="@rend='left'">
							<xsl:attribute name="style">text-align:left;</xsl:attribute>
						</xsl:when>
						<!--<xsl:otherwise>
                            <p class="teiLetter_undefined">
                            <xsl:apply-templates />
                            </p>
                            </xsl:otherwise>-->
					</xsl:choose>
					<xsl:apply-templates/>
				</xsl:element>
			</xsl:when>
			<xsl:when test="parent::node()/name() = 'closer'">
				<xsl:apply-templates/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!--<xsl:template match="tei:rdg"/>
    <xsl:template match="tei:lem">
        <xsl:apply-templates/>
    </xsl:template>-->
	
	<!--<xsl:template match="tei:app">
        <xsl:variable name="appInlineID">
            <xsl:number level="any"/>
        </xsl:variable>
        <xsl:choose>
            <!-\-    tei:rdg[@cause='kein_Absatz'] nicht existent in den Daten. Dieser Zweig kann entfallen.       -\->
            <xsl:when test="./tei:rdg[@cause='kein_Absatz']">
                <span class="teiLetter_noteDefinitionMark" onmouseout="UnTip()">
                    <xsl:attribute name="onmouseover">
                        <xsl:text>TagToTip('</xsl:text>
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                        <xsl:text>')</xsl:text>
                    </xsl:attribute>
                    <xsl:text>*</xsl:text>
                </span>
                <span class="teiLetter_noteInline">
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                    </xsl:attribute>
                    <xsl:text>Lesart ohne Absatz</xsl:text>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="teiLetter_lem" onmouseout="UnTip()">
                    <xsl:attribute name="onmouseover">
                        <xsl:text>TagToTip('</xsl:text>
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                        <xsl:text>')</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="./tei:lem"/>
                </span>
                <span class="teiLetter_noteInline">
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                    </xsl:attribute>
                    <xsl:text>Lesart(en): </xsl:text>
                    <xsl:for-each select="./tei:rdg">
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:if test="position()!=last()">
                            <xsl:text>; </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
	
	<!--<xsl:template match="tei:title[@level='a']">
        <xsl:apply-templates/>
    </xsl:template>-->
	<xsl:template match="text()[parent::tei:title]">
		<xsl:choose>
			<xsl:when test="$lang eq 'en'">
				<xsl:value-of select="functx:replace-multi(., (' in ', ' an '), (lower-case(wega:getLanguageString('in', $lang)), lower-case(wega:getLanguageString('to', $lang))))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:fw">
		<xsl:variable name="fw-classes-bold" select="'tei_fw tei_hi_bold'"/>
		<xsl:variable name="fw-classes-boxed" select="'tei_fw border-top border-bottom'"/>
		<xsl:choose>
			<xsl:when test="ancestor::tei:div[@type='row'] or @type='pageNum'">
				<xsl:element name="p">
					<xsl:attribute name="class">
						<xsl:choose>
							<xsl:when test="@rend">
								<xsl:value-of select="concat($fw-classes-bold, ' textAlign-', @rend)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$fw-classes-bold"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:apply-templates/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="p">
					<xsl:attribute name="class">
						<xsl:choose>
							<xsl:when test="@rend">
								<xsl:value-of select="concat($fw-classes-boxed, ' textAlign-', @rend)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$fw-classes-boxed"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:apply-templates/>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:address">
		<xsl:choose>
			<xsl:when test="@rend">
				<xsl:element name="span">
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="@rend='right'">
							<xsl:text> justify-content-end</xsl:text>
						</xsl:when>
						<xsl:when test="@rend='left'">
							<xsl:text> justify-content-start</xsl:text>
						</xsl:when>
						<xsl:when test="@rend='center'">
							<xsl:text> justify-content-center</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:apply-templates/>
			</xsl:element>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:addrLine">
		<xsl:element name="span">
			<xsl:attribute name="class">
				<xsl:text>d-flex</xsl:text>
				<xsl:choose>
					<xsl:when test="@rend='inlineApart'">
						<xsl:attribute name="style"> justify-content-between</xsl:attribute>
					</xsl:when>
					<xsl:when test="@rend='right'">
						<xsl:text> justify-content-end</xsl:text>
					</xsl:when>
					<xsl:when test="@rend='left'">
						<xsl:text> justify-content-start</xsl:text>
					</xsl:when>
					<xsl:when test="@rend='center'">
						<xsl:text> justify-content-center</xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:p">
		<xsl:element name="p">
			<xsl:if test="@rend">
				<xsl:attribute name="class">
					<xsl:value-of select="concat('textAlign-',@rend)"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:space[@unit='indent']">
		<xsl:element name="span">
			<xsl:for-each select="1 to @quantity">
				<span class="tei_indent-space"/>
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
	
</xsl:stylesheet>