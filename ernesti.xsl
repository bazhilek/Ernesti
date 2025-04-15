<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:local="http://ijp.pan.pl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
    <xsl:mode on-no-match="shallow-copy"/>
    <xsl:function name="local:parse_slash" as="node()*">
        <xsl:param name="text" as="text()"/>
        <xsl:variable name="join" select="'left'"/>
        <xsl:variable name="force" select="'weak'"/>
        <xsl:choose>
            <xsl:when test="not(matches($text,'/'))">
                <xsl:value-of select="$text"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="tokens" select="tokenize($text,'/')"/>
                <xsl:for-each select="1 to count($tokens)">
                    <xsl:choose>
                        <xsl:when test=". = 1">
                            <xsl:value-of select="$tokens[1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Process remaining tokens -->
                            <xsl:for-each select="2 to count($tokens)">
                                <xsl:variable name="pos" select="."/>
                                <xsl:variable name="current" select="$tokens[$pos]"/>
                                <!-- Find the first preceding token with an article -->
                                <xsl:variable name="article_token_pos">
                                    <xsl:for-each select="reverse(1 to $pos - 1)">
                                        <xsl:variable name="check_pos" select="."/>
                                        <xsl:if test="matches(normalize-space($tokens[$check_pos]), '^(die|das|der|den|des|ein|eine)\s')">
                                            <xsl:value-of select="$check_pos"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:variable>
                                
                                <xsl:variable name="has_preceding_article" select="string-length($article_token_pos) > 0"/>
                                <xsl:variable name="preceding_article_token" select="if ($has_preceding_article) then $tokens[number($article_token_pos)] else ''"/>
                                
                                <xsl:choose>
                                    <!-- adjective chains (die flatte/ schlechte Rinde) -->
                                    <xsl:when test="matches(normalize-space($current), '^[a-z]') and 
                                        not(matches(normalize-space($current), '^(der|die|das|den|des|ein|eine)\s'))">
                                        <xsl:element name="pc">
                                            <xsl:attribute name="force" select="'strong'"/>
                                            <xsl:attribute name="norm" select="''"/>
                                            <xsl:value-of select="'/'"/>
                                        </xsl:element>
                                        <xsl:value-of select="$current"/>
                                    </xsl:when>
                                    <!-- proper noun phrases (die Kirchen Ceremonien/ Gebrauch) -->
                                    
                                    <!-- noun chains with an article in any preceding token -->
                                    <xsl:when test="$has_preceding_article">
                                        <xsl:variable name="prev_article" select="replace(
                                            normalize-space($preceding_article_token), 
                                            '^(die|das|der|den|des|ein|eine)\s.*$', 
                                            '$1'
                                            )">
                                        </xsl:variable>
                                        <xsl:choose>
                                            <xsl:when test="not(matches(normalize-space($current), '^(die|das|der|ein|eine)\s'))">
                                                <xsl:element name="pc">
                                                    <xsl:attribute name="force" select="'strong'"/>
                                                    <xsl:attribute name="norm" select="','"/>
                                                    <xsl:value-of select="'/'"/>
                                                </xsl:element>
                                                <xsl:element name="supplied">
                                                    <xsl:value-of select="$prev_article"/>    
                                                </xsl:element>
                                                <xsl:value-of select="$current"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:element name="pc">
                                                    <xsl:attribute name="force" select="'strong'"/>
                                                    <xsl:attribute name="norm" select="','"/>
                                                    <xsl:value-of select="'/'"/>
                                                </xsl:element>
                                                <xsl:value-of select="$current"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- Default case -->
                                    <xsl:otherwise>
                                        <xsl:element name="pc">
                                            <xsl:attribute name="force" select="'strong'"/>
                                            <xsl:attribute name="norm" select="','"/>
                                            <xsl:value-of select="'/'"/>
                                        </xsl:element>
                                        <xsl:value-of select="$current"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>                            
                        </xsl:otherwise>
                    </xsl:choose>
                    </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- proper noun phrases (die Kirchen Ceremonien/ Gebrauch) -->
        <!-- adjective chains (die flatte schlechte Rinde) -->
        <!-- noun chains (
            without preceding article:
                Milch Peltz/ Milch Haut
                Erwerb/ erworben Geld
                
            with preceding article:
                die Brautwerber/ Brautfuehrer;
                das Geschlecht/ der Stamm;
                ein Fosige/ ein Fosig Wagen
                )
        -->
    </xsl:function>
    <xsl:template match="//*:sense//*:orth[matches(.,'/')]">
        <xsl:copy>
        <xsl:copy-of select="@*"/>
            <xsl:copy-of select="local:parse_slash(text())"/>
        <!--<xsl:analyze-string select="text()" regex="/">
            <xsl:matching-substring>
                <xsl:element name="pc">
                    <xsl:attribute name="type" select="'separator'"/>
                    <xsl:attribute name="subtype" select="'slash'"/>
                    <xsl:attribute name="force" select="'weak'"/>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>-->
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>