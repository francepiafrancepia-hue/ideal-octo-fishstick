<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:inst="http://institution.example.org/master"
                xmlns:src="http://legacy.example.org/source"
                exclude-result-prefixes="inst">
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <!-- 
        Institutional Master Record to Source Transformation
        This XSLT transforms institutional master record back to legacy source format.
        Ensures backward compatibility by using traceability attributes.
    -->
    
    <!-- Root template -->
    <xsl:template match="/inst:InstitutionalRecord">
        <src:SourceRecord id="{@recordId}">
            <src:RecordInfo>
                <src:Created>
                    <xsl:value-of select="inst:Metadata/inst:CreatedDate"/>
                </src:Created>
                <src:Updated>
                    <xsl:value-of select="inst:Metadata/inst:ModifiedDate"/>
                </src:Updated>
                <src:Origin>
                    <xsl:value-of select="inst:Metadata/inst:Source"/>
                </src:Origin>
            </src:RecordInfo>
            
            <src:Item>
                <src:ItemId>
                    <xsl:choose>
                        <!-- Use sourceId if available for perfect traceability -->
                        <xsl:when test="inst:Entity/inst:Identifier/@sourceId">
                            <xsl:value-of select="inst:Entity/inst:Identifier/@sourceId"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@recordId"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </src:ItemId>
                <src:Title>
                    <xsl:choose>
                        <!-- Use sourceName if available for perfect traceability -->
                        <xsl:when test="inst:Entity/inst:Name/@sourceName">
                            <xsl:value-of select="inst:Entity/inst:Name/@sourceName"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="inst:Entity/inst:Name"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </src:Title>
                <xsl:if test="inst:Entity/inst:Description">
                    <src:Details>
                        <xsl:value-of select="inst:Entity/inst:Description"/>
                    </src:Details>
                </xsl:if>
                <xsl:if test="inst:Entity/inst:Attributes/inst:Attribute">
                    <src:Properties>
                        <xsl:apply-templates select="inst:Entity/inst:Attributes/inst:Attribute"/>
                    </src:Properties>
                </xsl:if>
            </src:Item>
        </src:SourceRecord>
    </xsl:template>
    
    <!-- Attribute template -->
    <xsl:template match="inst:Attribute">
        <src:Property>
            <xsl:attribute name="key">
                <xsl:choose>
                    <!-- Use sourceField if available for perfect traceability -->
                    <xsl:when test="@sourceField">
                        <xsl:value-of select="@sourceField"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@name"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </src:Property>
    </xsl:template>
    
</xsl:stylesheet>
