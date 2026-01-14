# XSLT Transformation Reference

## Overview

This document provides reference information for the XSLT transformation stylesheets used to transform between source and institutional XML formats.

## Transformation Stylesheets

### 1. source-to-institutional.xsl

**Purpose**: Transforms legacy source XML to institutional master record format

**Input**: Source XML conforming to `source-legacy.xsd`  
**Output**: Institutional XML conforming to `institutional-master.xsd`  
**XSLT Version**: 1.0

**Key Features**:
- Populates all traceability attributes (`sourceId`, `sourceName`, `sourceField`)
- Generates complete `<Traceability>` mapping section
- Records transformation reference in metadata
- Preserves all source information for bidirectional compatibility

**Usage**:
```bash
xsltproc transforms/source-to-institutional.xsl input-source.xml > output-institutional.xml
```

### 2. institutional-to-source.xsl

**Purpose**: Transforms institutional master record back to legacy source format

**Input**: Institutional XML conforming to `institutional-master.xsd`  
**Output**: Source XML conforming to `source-legacy.xsd`  
**XSLT Version**: 1.0

**Key Features**:
- Uses traceability attributes for perfect reconstruction
- Provides graceful fallback when attributes are missing
- Ensures backward compatibility with legacy systems
- Supports round-trip transformation

**Usage**:
```bash
xsltproc transforms/institutional-to-source.xsl input-institutional.xml > output-source.xml
```

## Template Reference

### source-to-institutional.xsl Templates

#### Root Template
```xsl
<xsl:template match="/src:SourceRecord">
```
Matches the root `SourceRecord` element and creates the institutional record structure.

**Outputs**:
- `<InstitutionalRecord>` with version and recordId attributes
- Complete `<Metadata>` section with transformation reference
- Full `<Entity>` structure with traceability attributes
- Comprehensive `<Traceability>` mapping section

#### Property Template
```xsl
<xsl:template match="src:Property">
```
Transforms individual source properties to institutional attributes.

**Transformation**:
- `@key` → `@name` and `@sourceField`
- Text content preserved directly

### institutional-to-source.xsl Templates

#### Root Template
```xsl
<xsl:template match="/inst:InstitutionalRecord">
```
Matches the root `InstitutionalRecord` element and creates the source record structure.

**Logic**:
- Uses `<xsl:choose>` to prefer traceability attributes over institutional values
- Ensures perfect reconstruction when attributes are present
- Provides fallback for missing attributes

#### Attribute Template
```xsl
<xsl:template match="inst:Attribute">
```
Transforms institutional attributes back to source properties.

**Transformation**:
- `@sourceField` → `@key` (with fallback to `@name`)
- Text content preserved directly

## Traceability Attribute Usage

### sourceId Attribute
**Location**: `Entity/Identifier/@sourceId`  
**Source**: `Item/ItemId`  
**Used in reverse**: Yes - to reconstruct original ItemId

### sourceName Attribute
**Location**: `Entity/Name/@sourceName`  
**Source**: `Item/Title`  
**Used in reverse**: Yes - to reconstruct original Title

### sourceField Attribute
**Location**: `Entity/Attributes/Attribute/@sourceField`  
**Source**: `Item/Properties/Property/@key`  
**Used in reverse**: Yes - to reconstruct original property keys

## Element Mapping Details

### Metadata Mappings

| Institutional | Source | Bidirectional | Notes |
|--------------|--------|---------------|-------|
| `Metadata/CreatedDate` | `RecordInfo/Created` | Yes | Direct copy |
| `Metadata/ModifiedDate` | `RecordInfo/Updated` | Yes | Direct copy |
| `Metadata/Source` | `RecordInfo/Origin` | Yes | Direct copy |
| `Metadata/TransformationRef` | N/A | No | Added during transformation |

### Entity Mappings

| Institutional | Source | Bidirectional | Notes |
|--------------|--------|---------------|-------|
| `Entity/Identifier` | `SourceRecord/@id` | Yes | Stored in @recordId |
| `Entity/Identifier/@sourceId` | `Item/ItemId` | Yes | Traceability attribute |
| `Entity/Name` | `Item/Title` | Yes | Direct copy |
| `Entity/Name/@sourceName` | `Item/Title` | Yes | Traceability attribute |
| `Entity/Description` | `Item/Details` | Yes | Direct copy |

### Attribute Mappings

| Institutional | Source | Bidirectional | Notes |
|--------------|--------|---------------|-------|
| `Attribute/@name` | `Property/@key` | Yes | Via @sourceField |
| `Attribute/@sourceField` | `Property/@key` | Yes | Traceability attribute |
| `Attribute/text()` | `Property/text()` | Yes | Direct copy |

## Transformation Rules

### Rule: direct-copy
**Description**: Value is copied directly without any modification

**Example**:
```xml
<!-- Source -->
<Created>2026-01-14T10:00:00Z</Created>

<!-- Institutional -->
<CreatedDate>2026-01-14T10:00:00Z</CreatedDate>
```

### Rule: key-to-name-mapping
**Description**: Attribute name is transformed but original is preserved

**Example**:
```xml
<!-- Source -->
<Property key="category">Research</Property>

<!-- Institutional -->
<Attribute name="category" sourceField="category">Research</Attribute>
```

## Namespace Handling

### Source Namespace
- **URI**: `http://legacy.example.org/source`
- **Prefix**: `src`
- **Schema**: `source-legacy.xsd`

### Institutional Namespace
- **URI**: `http://institution.example.org/master`
- **Prefix**: `inst`
- **Schema**: `institutional-master.xsd`

### XSLT Configuration
Both stylesheets use `exclude-result-prefixes` to prevent namespace pollution in output documents.

## Testing Transformations

### Validation Workflow

1. **Validate Source Input**
   ```bash
   xmllint --schema schemas/source-legacy.xsd examples/source-example.xml --noout
   ```

2. **Perform Forward Transformation**
   ```bash
   xsltproc transforms/source-to-institutional.xsl examples/source-example.xml > test-inst.xml
   ```

3. **Validate Institutional Output**
   ```bash
   xmllint --schema schemas/institutional-master.xsd test-inst.xml --noout
   ```

4. **Perform Reverse Transformation**
   ```bash
   xsltproc transforms/institutional-to-source.xsl test-inst.xml > test-source.xml
   ```

5. **Validate Source Output**
   ```bash
   xmllint --schema schemas/source-legacy.xsd test-source.xml --noout
   ```

6. **Compare Results**
   ```bash
   diff examples/source-example.xml test-source.xml
   ```

### Expected Results
- Forward transformation should produce valid institutional XML
- Reverse transformation should produce valid source XML
- Round-trip should preserve all data (identical or semantically equivalent)

## Customization Guide

### Adding New Field Mappings

1. Update the source schema with new element
2. Update the institutional schema with corresponding element
3. Add transformation logic in forward XSLT
4. Add reverse transformation logic in backward XSLT
5. Add traceability attributes if needed
6. Update `<Traceability>` section generation
7. Document the new mapping in this reference

### Example: Adding a New Field

**Step 1**: Add to source schema
```xml
<xs:element name="Author" type="xs:string"/>
```

**Step 2**: Add to institutional schema
```xml
<xs:element name="Creator" type="xs:string"/>
```

**Step 3**: Add to forward transformation
```xsl
<inst:Creator>
    <xsl:value-of select="src:Item/src:Author"/>
</inst:Creator>
```

**Step 4**: Add to backward transformation
```xsl
<src:Author>
    <xsl:value-of select="inst:Entity/inst:Creator"/>
</src:Author>
```

**Step 5**: Add traceability mapping
```xsl
<inst:SourceMapping 
    institutionalElement="Entity/Creator" 
    sourceElement="Item/Author" 
    transformationRule="direct-copy"/>
```

## Troubleshooting

### Common Issues

**Issue**: Namespace errors in output
- **Cause**: Missing namespace declarations
- **Solution**: Ensure both input and XSLT have correct namespace declarations

**Issue**: Empty output or transformation failure
- **Cause**: XPath expressions don't match due to namespace issues
- **Solution**: Use correct namespace prefixes in all XPath expressions

**Issue**: Data loss in round-trip transformation
- **Cause**: Missing traceability attributes
- **Solution**: Ensure forward transformation populates all source* attributes

**Issue**: Validation errors
- **Cause**: Output doesn't conform to target schema
- **Solution**: Verify element names, namespaces, and required attributes

## Performance Considerations

- Both stylesheets use XSLT 1.0 for maximum compatibility
- Template matching is efficient with specific XPath expressions
- No complex recursion or iteration (linear performance)
- Suitable for batch processing of large record sets

## Version History

**Version 1.0** (2026-01-14)
- Initial implementation
- Support for basic entity records
- Full bidirectional traceability
- Complete metadata preservation
