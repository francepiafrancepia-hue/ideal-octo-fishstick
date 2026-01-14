# Bidirectional Traceability Guide

## Overview

This document explains how bidirectional traceability is maintained between source XML and institutional master records.

## Traceability Mechanisms

### 1. Inline Traceability Attributes

The institutional master record schema includes optional attributes that preserve references to source elements:

- **`sourceId`**: Preserves the original identifier from the source system
- **`sourceName`**: Preserves the original name/title from the source system
- **`sourceField`**: Preserves the original field name from the source system

### 2. Traceability Element

Each institutional record includes an optional `<Traceability>` section that explicitly maps institutional elements to source elements:

```xml
<inst:Traceability>
    <inst:SourceMapping 
        institutionalElement="Entity/Identifier" 
        sourceElement="SourceRecord/@id" 
        transformationRule="direct-copy"/>
    <!-- Additional mappings -->
</inst:Traceability>
```

### 3. Transformation Reference

The metadata section includes a `<TransformationRef>` element that specifies which XSLT stylesheet was used for transformation:

```xml
<inst:TransformationRef>source-to-institutional.xsl</inst:TransformationRef>
```

## Traceability Flow

### Forward Transformation (Source → Institutional)

1. Source XML is processed by `source-to-institutional.xsl`
2. Traceability attributes are populated with source values
3. Explicit mapping section is generated
4. Transformation reference is recorded

### Reverse Transformation (Institutional → Source)

1. Institutional XML is processed by `institutional-to-source.xsl`
2. Traceability attributes are used to restore original source values
3. Perfect reconstruction is achieved when traceability attributes are present
4. Graceful fallback to institutional values when attributes are missing

## Element Mapping Table

| Institutional Element | Source Element | Transformation Rule |
|----------------------|----------------|---------------------|
| `InstitutionalRecord/@recordId` | `SourceRecord/@id` | direct-copy |
| `Metadata/CreatedDate` | `RecordInfo/Created` | direct-copy |
| `Metadata/ModifiedDate` | `RecordInfo/Updated` | direct-copy |
| `Metadata/Source` | `RecordInfo/Origin` | direct-copy |
| `Entity/Identifier` | `SourceRecord/@id` | direct-copy |
| `Entity/Identifier/@sourceId` | `Item/ItemId` | direct-copy |
| `Entity/Name` | `Item/Title` | direct-copy |
| `Entity/Name/@sourceName` | `Item/Title` | direct-copy |
| `Entity/Description` | `Item/Details` | direct-copy |
| `Entity/Attributes/Attribute` | `Item/Properties/Property` | key-to-name-mapping |
| `Entity/Attributes/Attribute/@sourceField` | `Item/Properties/Property/@key` | direct-copy |

## Transformation Rules

### direct-copy
Value is copied directly without modification from source to institutional format.

### key-to-name-mapping
The source attribute name (`@key`) becomes the institutional attribute name (`@name`), with the original preserved in `@sourceField`.

## Validation

### Verifying Bidirectional Consistency

To verify that transformations maintain bidirectional consistency:

1. Start with source XML
2. Transform to institutional format using `source-to-institutional.xsl`
3. Transform back to source format using `institutional-to-source.xsl`
4. Compare the result with the original source XML

The result should be identical or semantically equivalent to the original.

## Best Practices

1. **Always populate traceability attributes** when transforming from source to institutional format
2. **Include the Traceability element** for explicit mapping documentation
3. **Reference the transformation stylesheet** in the TransformationRef element
4. **Use meaningful transformation rule names** that describe the transformation logic
5. **Validate against schemas** before and after transformation
6. **Document any custom transformation rules** in the traceability section

## Example Workflow

```bash
# Transform source to institutional
xsltproc transforms/source-to-institutional.xsl examples/source-example.xml > output-institutional.xml

# Transform back to source
xsltproc transforms/institutional-to-source.xsl output-institutional.xml > output-source.xml

# Validate results
xmllint --schema schemas/source-legacy.xsd output-source.xml
xmllint --schema schemas/institutional-master.xsd output-institutional.xml
```

## Extending the System

When adding new source formats:

1. Create a new source schema (`.xsd`)
2. Create forward transformation XSLT (source → institutional)
3. Create backward transformation XSLT (institutional → source)
4. Document element mappings and transformation rules
5. Add traceability attributes for new fields
6. Update the mapping table in this document
