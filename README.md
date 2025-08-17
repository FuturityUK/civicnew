# US House Contacts JSON

This space generates a single JSON file with contact details for all current members of the U.S. House of Representatives, using the canonical `unitedstates/congress-legislators` dataset.

- Output: `data/house-contacts.json`
- Source: https://github.com/unitedstates/congress-legislators
- Update cadence: daily via GitHub Actions, or on-demand

## How to generate locally

1. Install Node.js 18+ (20+ recommended)
2. Install dependencies:
   ```
   npm ci
   ```
3. Build:
   ```
   npm run build
   ```
4. The JSON will be written to `data/house-contacts.json`.

## JSON structure

```json
{
  "last_updated": "2025-01-01T12:34:56.000Z",
  "source": "https://github.com/unitedstates/congress-legislators",
  "members": [
    {
      "id": {
        "bioguide": "A000001",
        "govtrack": 412000,
        "opensecrets": "N00000000",
        "fec": ["H0XX00000"],
        "thomas": "01800",
        "cspan": 1000,
        "wikipedia": "Jane Doe",
        "wikidata": "Q123456"
      },
      "name": {
        "official_full": "Jane Q. Doe",
        "first": "Jane",
        "last": "Doe",
        "middle": "Q.",
        "nickname": null,
        "suffix": null
      },
      "party": "R",
      "state": "TX",
      "district": 7,
      "role": "Representative",
      "term": {
        "start": "2025-01-03",
        "end": "2027-01-03"
      },
      "contact": {
        "capitol_office": {
          "office": "1229 Longworth House Office Building",
          "address": "1229 LHOB; Washington, DC 20515",
          "phone": "(202) 225-1234",
          "fax": null
        },
        "district_offices": [
          {
            "address": "123 Main St",
            "city": "Houston",
            "state": "TX",
            "zip": "77002",
            "phone": "(713) 555-1234",
            "fax": null,
            "latitude": 29.7604,
            "longitude": -95.3698,
            "suite": "Ste 100"
          }
        ],
        "contact_form": "https://doe.house.gov/contact",
        "website": "https://doe.house.gov"
      },
      "social": {
        "twitter": "RepJaneDoe",
        "twitter_id": "1234567890",
        "facebook": "RepJaneDoe",
        "youtube": "UCabcdef...",
        "youtube_id": "abcdef",
        "instagram": "repjanedoe",
        "mastodon": "@repjanedoe@mastodon.social",
        "threads": "repjanedoe"
      }
    }
  ]
}
```

- `role` reflects whether the member is a Representative, Delegate, or Resident Commissioner (PR).
- `capitol_office` comes from the member’s current term.
- `district_offices` are pulled from the `legislators-district-offices.yaml` dataset when available.
- Social handles are merged from `legislators-social-media.yaml`.

## Automation

A scheduled GitHub Action (`.github/workflows/update-house-contacts.yml`) runs daily to refresh the JSON and commit changes if any.

If you prefer, you can also trigger it manually via "Run workflow".