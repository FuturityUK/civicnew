# US House Contacts Data Generator

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

This is a Node.js data processing project that generates a JSON file containing contact details for all current members of the U.S. House of Representatives using the canonical `unitedstates/congress-legislators` dataset.

## Working Effectively
- Bootstrap and build the repository:
  - Requires Node.js 18+ (20+ recommended) - version 20.19.4 is pre-installed
  - Install dependencies: `npm ci` -- takes ~1 second (requires package-lock.json)
  - Alternative installation: `npm ci || npm install` -- fallback used in GitHub Actions
  - Build: `npm run build` -- takes ~2 seconds (network dependent)
  - Alternative: `node scripts/fetch-house-contacts.mjs` -- same timing, ~1.5 seconds
- No test suite exists - do not run `npm test` as it will fail with "Missing script: test"
- No linting tools configured - do not run `npm run lint` as it will fail with "Missing script: lint"

## Validation
- Always manually validate the build output after making changes:
  - Verify `data/house-contacts.json` is created and has recent timestamp
  - Check member count: `jq '.members | length' data/house-contacts.json` -- should return ~437 members
  - Validate JSON structure: `jq '.members[0] | keys' data/house-contacts.json` -- should show expected keys
  - Verify last_updated timestamp is recent: `jq '.last_updated' data/house-contacts.json`
- The script requires internet connectivity to fetch from external URLs
- Build will fail if network connectivity to github.com is unavailable

## Network Dependencies
The build process fetches data from these URLs:
- https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-current.yaml
- https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml
- https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-district-offices.yaml

## Common Tasks
The following are outputs from frequently run commands. Reference them instead of viewing, searching, or running bash commands to save time.

### Repository structure
```
.
├── .github/
│   └── workflows/
│       └── update-house-contacts.yml    # Daily automation workflow
├── data/
│   └── house-contacts.json              # Generated output (~874KB)
├── scripts/
│   └── fetch-house-contacts.mjs         # Main data processing script
├── .gitignore                          # Standard Node.js gitignore
├── README.md                           # Project documentation
├── package.json                        # Project configuration
└── package-lock.json                  # Dependency lock file
```

### package.json
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

### Expected build output
```
> build
> node scripts/fetch-house-contacts.mjs

Fetching datasets...
Wrote 437 members to /path/to/data/house-contacts.json
```

### JSON structure
The generated `data/house-contacts.json` contains:
- `last_updated`: ISO timestamp of generation
- `source`: Attribution to congress-legislators dataset
- `members`: Array of House member objects with fields:
  - `id`: Various identifier fields (bioguide, govtrack, etc.)
  - `name`: Name components (official_full, first, last, etc.)
  - `party`, `state`, `district`, `role`
  - `term`: Current term start/end dates
  - `contact`: Capitol and district offices, phones, websites
  - `social`: Social media handles (twitter, facebook, etc.)

## Automation
- GitHub Action runs daily at 05:17 UTC via `.github/workflows/update-house-contacts.yml`
- Workflow can be triggered manually via "Run workflow" button
- Uses Node.js 20, runs `npm ci || npm install`, then `npm run build`
- Auto-commits changes to `data/house-contacts.json` if data updates

## Error Handling
- Script will exit with error code 1 if network requests fail
- Build failures typically indicate network connectivity issues
- No graceful fallback - script requires successful fetching of all three YAML datasets