# Contributing to Texas Settlements Data

## Overview

This document outlines conventions for updating the Texas settlements dataset (`data/texas.csv`).

## Data Schema

The CSV file contains the following columns:
- `name`: Settlement name (normalized Title Case, trimmed whitespace)
- `population`: Population count (integer) or empty string if unknown
- `type`: Settlement type, must be one of: `city`, `town`, `village`, `CDP`, `unincorporated`
- `source_year`: Year of data source (e.g., 2020 for Census data) or empty for undated sources

## Data Sources

### Primary Sources (Phase 1)
- **2020 U.S. Decennial Census**: For incorporated places and Census Designated Places (CDPs)
  - All entries should have `source_year: 2020`
  - Population data is required for Census-derived entries
  - Types: `city`, `town`, `village`, `CDP`

### Secondary Sources (Phase 2)  
- **Geographic Names Information System (GNIS)**: For unincorporated communities
  - Historical entries are excluded
  - Variant names are deduplicated  
  - Population may be left blank if no official figure exists
  - Type: `unincorporated`
  - `source_year` can be empty/null if not applicable

## Data Conventions

### Name Formatting
- Use Title Case (e.g., "San Antonio", not "SAN ANTONIO" or "san antonio")
- Trim leading/trailing whitespace
- Remove state suffixes (e.g., "Houston" not "Houston, Texas")

### Type Classification
- `city`: Most incorporated places in Texas
- `town`: Specifically incorporated as towns
- `village`: Specifically incorporated as villages  
- `CDP`: Census Designated Places (unincorporated but Census-tracked)
- `unincorporated`: GNIS communities without incorporation

### Population Data
- Use integer values without commas (e.g., `1234567` not `1,234,567`)
- Leave empty (not `0` or `null`) when population is unknown
- For Census data, population is required

## File Format
- CSV with comma separators
- Headers: `name,population,type,source_year`
- File must end with a newline character
- Escape commas in data values with double quotes if needed

## Update Process

### Using the Build Script
```bash
npm run build:texas
```

This generates the complete dataset by:
1. Loading 2020 Census data for incorporated places and CDPs
2. Adding GNIS unincorporated communities  
3. Removing duplicates based on name+type combination
4. Sorting alphabetically by name
5. Writing to `data/texas.csv`

### Manual Updates
If adding individual entries manually:
1. Follow the data conventions above
2. Maintain alphabetical sorting
3. Ensure no duplicates (same name + type combination)
4. Validate CSV format

## Data Quality Checks

Before committing updates:
1. Verify CSV has proper headers
2. Check for required fields in Census entries (name, population, type=2020)
3. Ensure file ends with newline
4. Validate no duplicate name+type combinations
5. Confirm proper escape sequences for special characters

## Future Enhancements

Planned improvements include:
- Automated CI validation of CSV schema
- Integration with live Census and GNIS APIs  
- Geocoding coordinates for settlements
- Additional metadata fields (county, coordinates, etc.)