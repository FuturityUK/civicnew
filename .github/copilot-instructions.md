# US House Contacts JSON Generator

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

This is a Node.js-based tool that generates a JSON file containing contact details for all current members of the U.S. House of Representatives by fetching and processing data from the canonical `unitedstates/congress-legislators` dataset.

## Working Effectively

### Bootstrap and Build Process
- **Prerequisites**: Node.js 18+ (Node.js 20+ recommended)
- **Install dependencies**: `npm ci` -- takes 1 second. NEVER CANCEL.
- **Generate data**: `npm run build` -- takes 2 seconds. NEVER CANCEL.
- **Output location**: `data/house-contacts.json` (contains ~437 House members)

### Exact Commands to Run
```bash
# Check Node.js version (requires 18+)
node --version

# Install dependencies (creates node_modules with yaml package only)  
npm ci

# Generate the House contacts JSON file
npm run build

# Validate the output
ls -la data/
jq '.members | length' data/house-contacts.json
```

### Timing Expectations
- `npm ci`: ~1 second (installs only the `yaml` dependency)
- `npm run build`: ~2 seconds (fetches 3 YAML datasets from GitHub and processes them)
- **NEVER CANCEL**: All commands complete quickly, but set timeout to 60+ seconds for network resilience

## Validation

### Manual Validation Requirements
After building, ALWAYS validate the output:

```bash
# Verify JSON structure and member count
jq '.members | length' data/house-contacts.json
jq -r '.last_updated' data/house-contacts.json

# Check first member structure
jq '.members[0]' data/house-contacts.json

# Verify required fields exist
jq '.members[0] | keys' data/house-contacts.json
```

**Expected Results**:
- Member count: ~437 current House representatives  
- `last_updated`: Current ISO timestamp
- Each member has: `id`, `name`, `party`, `state`, `district`, `role`, `term`, `contact`, `social`

### Complete End-to-End Scenario
1. Start from fresh clone: `git clone <repo-url>`
2. Install Node.js 20+
3. Run `npm ci` 
4. Run `npm run build`
5. Verify `data/house-contacts.json` exists with current timestamp
6. Validate member count is reasonable (430-450 range)
7. Spot-check a few members for complete contact info

## Repository Structure

```
civicnew/
├── .github/
│   └── workflows/
│       └── update-house-contacts.yml    # Daily automation
├── data/
│   └── house-contacts.json              # Generated output (437 members)
├── scripts/
│   └── fetch-house-contacts.mjs         # Main generation script
├── package.json                         # Project config (build script only)
└── README.md                            # Usage documentation
```

### Key Files
- **`scripts/fetch-house-contacts.mjs`**: Main script that fetches YAML from `unitedstates/congress-legislators` and converts to JSON
- **`package.json`**: Defines `npm run build` command and `yaml` dependency
- **`.github/workflows/update-house-contacts.yml`**: Scheduled GitHub Action (runs daily at 05:17 UTC)

## Common Tasks

### Data Sources and External Dependencies
The build fetches live data from these URLs:
- `https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-current.yaml`  
- `https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml`
- `https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-district-offices.yaml`

**Internet connectivity required** - build will fail without network access.

### Build Process Details
1. **Fetches 3 YAML datasets** in parallel from external GitHub repository
2. **Processes and filters** to current House representatives only
3. **Combines data** from legislators, social media, and district offices datasets  
4. **Sorts members** by state, then district, then last name
5. **Outputs JSON** with timestamp and source attribution

### Manual Testing Scenarios
After making changes to the script:

```bash
# Test clean build (removes output first)
rm -rf data/
npm run build

# Test JSON validity
jq '.' data/house-contacts.json > /dev/null && echo "Valid JSON"

# Test member data completeness
jq '.members[] | select(.contact.capitol_office.phone == null) | .name.official_full' data/house-contacts.json
```

### No Testing Infrastructure
- **No unit tests present** - validate changes manually using above scenarios
- **No linting configuration** - follow existing code style in `fetch-house-contacts.mjs`  
- **No CI validation** besides the daily workflow

## Troubleshooting

### Common Issues
- **Network failures**: Build requires internet to fetch YAML datasets
- **Node.js version**: Requires Node.js 18+ for ES modules and fetch API
- **Missing data directory**: Script creates `data/` directory automatically
- **YAML parsing errors**: Usually indicate upstream data format changes

### GitHub Actions Workflow
- **Schedule**: Runs daily at 05:17 UTC  
- **Manual trigger**: Available via "Run workflow" button
- **Permissions**: Requires `contents: write` to commit updated JSON
- **Failure modes**: Usually network timeouts or upstream data changes

## Frequently Accessed Information

### Package.json Contents
```json
{
  "name": "house-contacts",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "node scripts/fetch-house-contacts.mjs"
  },
  "dependencies": {
    "yaml": "^2.4.2"
  }
}
```

### JSON Output Structure Example
```json
{
  "last_updated": "2025-08-18T13:17:37.812Z", 
  "source": "https://github.com/unitedstates/congress-legislators",
  "members": [
    {
      "id": { "bioguide": "B001323", "govtrack": 456970, ... },
      "name": { "official_full": "Nicholas J. Begich III", ... },
      "party": "Republican",
      "state": "AK", 
      "district": 0,
      "role": "Representative",
      "term": { "start": "2025-01-03", "end": "2027-01-03" },
      "contact": {
        "capitol_office": { "office": "153 Cannon House...", ... },
        "district_offices": [...],
        "website": "https://begich.house.gov"
      },
      "social": { "twitter": "repnickbegich", ... }
    }
  ]
}
```

### Repository Root Contents
```
ls -la /
total 28
drwxr-xr-x 7 runner docker  4096 Aug 18 13:17 .
drwxr-xr-x 1 root   root    4096 Aug 18 13:14 ..
drwxr-xr-x 8 runner docker  4096 Aug 18 13:17 .git
drwxr-xr-x 3 runner docker  4096 Aug 18 13:17 .github
-rw-r--r-- 1 runner docker   137 Aug 18 13:14 .gitignore  
-rw-r--r-- 1 runner docker  3078 Aug 18 13:14 README.md
drwxr-xr-x 2 runner docker  4096 Aug 18 13:17 data
-rw-r--r-- 1 runner docker 75539 Aug 18 13:14 package-lock.json
-rw-r--r-- 1 runner docker   157 Aug 18 13:14 package.json
drwxr-xr-x 2 runner docker  4096 Aug 18 13:14 scripts
```