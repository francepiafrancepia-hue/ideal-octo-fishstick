# Institutional XML Master Record System

This repository implements an institutional XML master record system with XSLT transformations for backward compatibility and bidirectional traceability.

## Overview

The system consists of:

- **Institutional Master Record Schema** - The authoritative XML schema that serves as the master record format
- **Source/Legacy Schemas** - Schemas representing legacy or external data formats
- **XSLT Transformations** - Bidirectional transformations between source and institutional formats
- **Traceability System** - Mechanisms to maintain element-level mapping between formats

## Key Features

✅ **Institutional XML as Master Record** - All data is transformed to and stored in a standardized institutional format  
✅ **XSLT Transformation References** - Explicit references to transformation stylesheets for backward compatibility  
✅ **Bidirectional Traceability** - Complete mapping between source and institutional XML elements  
✅ **Lossless Round-Trip** - Transform from source → institutional → source without data loss  
✅ **Extensible Design** - Easy to add new source formats with additional transformation pairs

## Directory Structure

```
.
├── schemas/                    # XML Schema definitions
│   ├── institutional-master.xsd   # Master record schema (authoritative)
│   └── source-legacy.xsd          # Legacy source format schema
├── transforms/                 # XSLT transformation stylesheets
│   ├── source-to-institutional.xsl    # Forward transformation
│   └── institutional-to-source.xsl    # Backward transformation
├── examples/                   # Example XML files
│   ├── source-example.xml         # Sample source record
│   └── institutional-example.xml  # Sample institutional record
└── docs/                       # Documentation
    └── TRACEABILITY.md            # Bidirectional traceability guide
```

## Quick Start

### Prerequisites

- XML processor with XSLT 1.0 support (e.g., `xsltproc`, Saxon)
- XML validator (e.g., `xmllint`)

### Transform Source to Institutional Format

```bash
xsltproc transforms/source-to-institutional.xsl examples/source-example.xml > output.xml
```

### Transform Institutional to Source Format (Backward Compatibility)

```bash
xsltproc transforms/institutional-to-source.xsl examples/institutional-example.xml > output.xml
```

### Validate XML Against Schema

```bash
# Validate source format
xmllint --schema schemas/source-legacy.xsd examples/source-example.xml --noout

# Validate institutional format
xmllint --schema schemas/institutional-master.xsd examples/institutional-example.xml --noout
```

## Institutional Master Record Schema

The institutional master record schema (`institutional-master.xsd`) defines the authoritative format for all data. Key elements include:

### Core Structure

```xml
<InstitutionalRecord version="1.0" recordId="...">
  <Metadata>
    <CreatedDate>...</CreatedDate>
    <ModifiedDate>...</ModifiedDate>
    <Source>...</Source>
    <TransformationRef>source-to-institutional.xsl</TransformationRef>
  </Metadata>
  <Entity>
    <Identifier type="..." sourceId="...">...</Identifier>
    <Name sourceName="...">...</Name>
    <Description>...</Description>
    <Attributes>
      <Attribute name="..." sourceField="...">...</Attribute>
    </Attributes>
  </Entity>
  <Traceability>
    <SourceMapping institutionalElement="..." sourceElement="..." transformationRule="..."/>
  </Traceability>
</InstitutionalRecord>
```

### Traceability Features

1. **Transformation Reference** - `<TransformationRef>` identifies which XSLT was used
2. **Source Attributes** - `sourceId`, `sourceName`, `sourceField` preserve original values
3. **Explicit Mappings** - `<Traceability>` section documents element-to-element mappings
4. **Transformation Rules** - Each mapping specifies how data was transformed

## Bidirectional Traceability

The system maintains complete bidirectional traceability through multiple mechanisms:

### 1. Inline Traceability Attributes

Institutional records preserve source values in attributes:
- `sourceId` - Original identifier
- `sourceName` - Original name/title
- `sourceField` - Original field name

### 2. Explicit Mapping Section

The `<Traceability>` element provides a complete mapping table:

```xml
<SourceMapping 
    institutionalElement="Entity/Identifier" 
    sourceElement="SourceRecord/@id" 
    transformationRule="direct-copy"/>
```

### 3. Transformation Reference

The `<TransformationRef>` element identifies which XSLT stylesheet performed the transformation, enabling reverse transformation.

See [TRACEABILITY.md](docs/TRACEABILITY.md) for detailed documentation.

## Backward Compatibility

The reverse XSLT transformation (`institutional-to-source.xsl`) ensures backward compatibility by:

1. Using traceability attributes to restore original source values
2. Providing graceful fallback when attributes are missing
3. Maintaining semantic equivalence with original source data
4. Supporting round-trip transformation without data loss

## Usage Examples

### Example 1: Basic Transformation

```bash
# Convert legacy source to institutional format
xsltproc transforms/source-to-institutional.xsl examples/source-example.xml > institutional.xml

# Validate the result
xmllint --schema schemas/institutional-master.xsd institutional.xml --noout
```

### Example 2: Round-Trip Validation

```bash
# Start with source
cp examples/source-example.xml original.xml

# Transform to institutional
xsltproc transforms/source-to-institutional.xsl original.xml > institutional.xml

# Transform back to source
xsltproc transforms/institutional-to-source.xsl institutional.xml > recovered.xml

# Compare (should be identical or semantically equivalent)
diff original.xml recovered.xml
```

### Example 3: Accessing Traceability Information

```bash
# Extract transformation reference
xmllint --xpath "//inst:TransformationRef/text()" institutional.xml

# View source mappings
xmllint --xpath "//inst:SourceMapping" institutional.xml
```

## Extending the System

To add support for a new source format:

1. **Create source schema** - Define XSD for the new format in `schemas/`
2. **Create forward transform** - Build XSLT (source → institutional) in `transforms/`
3. **Create backward transform** - Build XSLT (institutional → source) in `transforms/`
4. **Add traceability** - Include source attributes and mapping section
5. **Create examples** - Provide sample XML files in `examples/`
6. **Document mappings** - Update `docs/TRACEABILITY.md` with element mappings

## Schema Validation

All XML files should be validated against their respective schemas:

```bash
# Validate source XML
xmllint --schema schemas/source-legacy.xsd examples/source-example.xml --noout

# Validate institutional XML
xmllint --schema schemas/institutional-master.xsd examples/institutional-example.xml --noout
```

## Transformation Rules

The system uses several transformation rules documented in the `<Traceability>` section:

- **direct-copy** - Value copied without modification
- **key-to-name-mapping** - Attribute name transformation with source preservation

See [TRACEABILITY.md](docs/TRACEABILITY.md) for complete rule documentation.

## Design Principles

1. **Institutional XML is Authoritative** - The master record format is the single source of truth
2. **Preserve Source Context** - Always maintain references to original source elements
3. **Enable Round-Trip** - Transformations should be reversible without data loss
4. **Document Transformations** - Every transformation should be traceable and documented
5. **Validate Everything** - Use XML schemas to ensure data integrity
6. **Extensibility** - Design for easy addition of new source formats

## Contributing

When contributing transformations or schemas:

1. Follow the established naming conventions
2. Include comprehensive traceability information
3. Provide example XML files
4. Document element mappings
5. Validate all XML against schemas
6. Test round-trip transformations

## License

This system is designed for institutional data management and transformation.