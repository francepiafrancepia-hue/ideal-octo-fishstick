<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:src="http://legacy.example.org/source"
                xmlns:inst="http://institution.example.org/master"
                exclude-result-prefixes="src">
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <!-- 
        Source to Institutional Master Record Transformation
        This XSLT transforms legacy source XML to institutional master record format.
        Maintains bidirectional traceability through source attributes.
    -->
    
    <!-- Root template -->
    <xsl:template match="/src:SourceRecord">
        <inst:InstitutionalRecord version="1.0" recordId="{@id}">
            <inst:Metadata>
                <inst:CreatedDate>
                    <xsl:value-of select="src:RecordInfo/src:Created"/>
                </inst:CreatedDate>
                <inst:ModifiedDate>
                    <xsl:value-of select="src:RecordInfo/src:Updated"/>
                </inst:ModifiedDate>
                <inst:Source>
                    <xsl:value-of select="src:RecordInfo/src:Origin"/>
                </inst:Source>
                <inst:TransformationRef>source-to-institutional.xsl</inst:TransformationRef>
            </inst:Metadata>
            
            <inst:Entity>
                <inst:Identifier type="institutional" sourceId="{src:Item/src:ItemId}">
                    <xsl:value-of select="@id"/>
                </inst:Identifier>
                <inst:Name sourceName="{src:Item/src:Title}">
                    <xsl:value-of select="src:Item/src:Title"/>
                </inst:Name>
                <xsl:if test="src:Item/src:Details">
                    <inst:Description>
                        <xsl:value-of select="src:Item/src:Details"/>
                    </inst:Description>
                </xsl:if>
                <xsl:if test="src:Item/src:Properties/src:Property">
                    <inst:Attributes>
                        <xsl:apply-templates select="src:Item/src:Properties/src:Property"/>
                    </inst:Attributes>
                </xsl:if>
            </inst:Entity>
            
            <!-- Bidirectional traceability mapping -->
            <inst:Traceability>
                <inst:SourceMapping institutionalElement="InstitutionalRecord/@recordId" 
                                   sourceElement="SourceRecord/@id" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Metadata/CreatedDate" 
                                   sourceElement="RecordInfo/Created" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Metadata/ModifiedDate" 
                                   sourceElement="RecordInfo/Updated" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Metadata/Source" 
                                   sourceElement="RecordInfo/Origin" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Entity/Identifier" 
                                   sourceElement="SourceRecord/@id" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Entity/Identifier/@sourceId" 
                                   sourceElement="Item/ItemId" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Entity/Name" 
                                   sourceElement="Item/Title" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Entity/Description" 
                                   sourceElement="Item/Details" 
                                   transformationRule="direct-copy"/>
                <inst:SourceMapping institutionalElement="Entity/Attributes/Attribute" 
                                   sourceElement="Item/Properties/Property" 
                                   transformationRule="key-to-name-mapping"/>
            </inst:Traceability>
        </inst:InstitutionalRecord>
    </xsl:template>
    
    <!-- Property template -->
    <xsl:template match="src:Property">
        <inst:Attribute name="{@key}" sourceField="{@key}">
            <xsl:value-of select="."/>
        </inst:Attribute>
    </xsl:template>
    
</xsl:stylesheet>
