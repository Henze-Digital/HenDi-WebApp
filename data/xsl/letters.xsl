<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" xmlns:hendi="http://henze-digital.zenmem.de/ns/1.0" version="2.0">
	<xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
	<xsl:strip-space elements="*"/>
	<xsl:preserve-space elements="tei:quote tei:item tei:cell tei:p tei:head tei:dateline tei:closer tei:opener tei:addrLine tei:settlement tei:rs tei:name tei:persName tei:placeName tei:country tei:district tei:bloc tei:seg tei:l tei:head tei:salute tei:subst tei:add tei:lem tei:rdg tei:provenance tei:acquisition tei:damage tei:note"/>
	<xsl:include href="common_link.xsl"/>
	<xsl:include href="common_main.xsl"/>
	<xsl:include href="apparatus.xsl"/>
	
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:body">
		<xsl:variable name="hasEnvelope">
		    <xsl:if test="parent::tei:text/@type='envelope'">
				<xsl:value-of select="wega:getLanguageString('physDesc.objectDesc.form.envelope', $lang)"/>
		    </xsl:if>
		</xsl:variable>
		<xsl:variable name="hasScript">
		    <xsl:if test="not(contains(parent::tei:text/@type,'document')) and $doc//tei:handNote[1]/@script">
				<xsl:value-of select="wega:getLanguageString(concat('handNoteHead',  functx:capitalize-first($doc//tei:handNote[1]/@script)), $lang)"/>
			</xsl:if>
		</xsl:variable>
		<xsl:if test="$hasScript != ''">
			<xsl:element name="h4">
				<xsl:attribute name="style" select="'padding-top: 2em; padding-bottom: 0.5em;'"/>
			    <xsl:text>[</xsl:text>
			    <xsl:value-of select="string-join(($hasEnvelope[normalize-space(.) != ''], $hasScript),', ')"/>
			    <xsl:text>]</xsl:text>
		    </xsl:element>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="parent::tei:text[@type='envelope' or @type='telegram' or starts-with(@type,'card')]">
				<xsl:for-each select="element()">
					<xsl:choose>
					    <xsl:when test="self::tei:div">
					        <xsl:element name="div">
        						<xsl:attribute name="class" select="'box_outer'"/>
        						<xsl:apply-templates/>
					        </xsl:element>
					    </xsl:when>
					    <xsl:when test="self::tei:pb">
					        <xsl:call-template name="render-pb"/>
					    </xsl:when>
					    <xsl:otherwise>
					    	<xsl:apply-templates/>
					    </xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="ancestor::tei:text[@type='letter']">
			    <xsl:element name="div">
			        <xsl:attribute name="class" select="'teiLetter_body'"/>
    				<xsl:attribute name="style" select="'display: inline-grid; min-width: 80%;'"/>
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
		<xsl:call-template name="createApparatus"/>
	</xsl:template>
	
	<xsl:template match="tei:div[@type='row']">
		<xsl:element name="div">
			<xsl:attribute name="class">
    			<xsl:text>row justify-content-center</xsl:text>
    			<xsl:if test="ancestor::tei:text/@type = 'telegram'">
        			<xsl:choose>
        				<xsl:when test="@rend='nobox'"> box_none</xsl:when>
        				<xsl:otherwise> box_inner_solid</xsl:otherwise>
        			</xsl:choose>
    			</xsl:if>
    		</xsl:attribute>
			<xsl:apply-templates select="./tei:div"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:div[parent::tei:div[@type='row']]">
		<xsl:element name="div">
			<xsl:attribute name="class">
    			<xsl:choose>
    				<xsl:when test="contains(@type, 'col-')">
    					<xsl:value-of select="@type"/>
    				</xsl:when>
    				<xsl:otherwise>col</xsl:otherwise>
    			</xsl:choose>
				<xsl:if test="ancestor::tei:text/@type = 'telegram'"> box_telegram box_inner_dotted</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:div[not(@type='row') and not(parent::tei:div[@type='row'])]">
		<xsl:element name="div">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:variable name="boxing">
			    <xsl:choose>
					<xsl:when test="@rend='box'">box_inner_solid</xsl:when>
					<xsl:when test="@rend='nobox'">box_none</xsl:when>
					<xsl:otherwise/>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="rotation">
			    <xsl:if test="@hendi:rotation"><xsl:text>tei_hi_borderBloc</xsl:text></xsl:if>
			</xsl:variable>
			<xsl:attribute name="class">
				<xsl:value-of select="string-join(($rotation, $boxing),' ')"/>
			</xsl:attribute>
			<xsl:if test="@hendi:rotation">
    			<xsl:call-template name="popover"/>
			</xsl:if>
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
				<xsl:element name="span">
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
		<xsl:variable name="fw-classes-bold" select="'tei_fw tei_fw_smaller tei_hi_bold'"/>
		<xsl:variable name="fw-classes-boxed" select="'tei_fw border-top border-bottom'"/>
		<xsl:choose>
			<xsl:when test="ancestor::tei:div[@type='row'] or @type='pageNum' or ancestor::tei:text[@type='envelope']">
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
					<xsl:if test="@hendi:rotation">
					    <xsl:call-template name="popover"/>
					</xsl:if>
					<xsl:apply-templates/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="div">
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
					<xsl:if test="@hendi:rotation">
					    <xsl:call-template name="popover"/>
					</xsl:if>
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
			<xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tei:addrLine | tei:opener[@rend] | tei:dateline[@rend] | tei:signed[@rend]">
		<xsl:element name="span">
			<xsl:attribute name="class">
				<xsl:if test="@rend=('inlineApart','right','left','center')">
					<xsl:text>d-flex</xsl:text>
				</xsl:if>
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
			<xsl:element name="span">
				<xsl:apply-templates/>
			</xsl:element>
			<xsl:if test="self::tei:addrLine">
                <xsl:element name="br"/>
            </xsl:if>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:p">
		<xsl:variable name="p-rend">
			<xsl:if test="@rend">
				<xsl:value-of select="concat('textAlign-',@rend)"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="p-place">
			<xsl:if test="@place">
				<xsl:value-of select="concat('p-place-',replace(@place,'\.','-'))"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="inlineEnd">
			<xsl:if test="exists(following-sibling::element()[1][self::tei:closer[@rend='inline']])">
				<xsl:text>inlineEnd</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="address">
			<xsl:if test="exists(tei:address) and count(./node()) lt 4">
				<xsl:text>tei_address</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:element name="p">
			<xsl:attribute name="class">
				<xsl:value-of select="string-join(($p-rend, $p-place, $inlineEnd, $address),' ')"/>
			</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:seg[@type='strip']">
		<xsl:element name="span">
			<xsl:attribute name="class">tei_type_strip</xsl:attribute>
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
	
	<xsl:template match="tei:head[not(@type='sub')][parent::tei:div]">
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
			<xsl:apply-templates/>
		</xsl:element>
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
	
</xsl:stylesheet>