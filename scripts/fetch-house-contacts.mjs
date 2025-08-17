import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const OUT_DIR = path.resolve(process.cwd(), 'data');
const OUT_FILE = path.join(OUT_DIR, 'house-contacts.json');

const LEGISLATORS_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-current.yaml';
const SOCIAL_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml';
const DISTRICT_OFFICES_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-district-offices.yaml';

const NON_VOTING_STATES = new Set(['DC', 'AS', 'GU', 'MP', 'PR', 'VI']);

async function fetchText(url) {
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) {
    throw new Error(`Failed to fetch ${url}: ${res.status} ${res.statusText}`);
  }
  return await res.text();
}

function latestTerm(terms) {
  if (!Array.isArray(terms) || terms.length === 0) return null;
  return terms[terms.length - 1];
}

function isCurrentTerm(term, now = new Date()) {
  if (!term) return false;
  const end = new Date(term.end);
  return end >= now;
}

function computeRole(state) {
  if (state === 'PR') return 'Resident Commissioner';
  if (new Set(['DC', 'AS', 'GU', 'MP', 'VI']).has(state)) return 'Delegate';
  return 'Representative';
}

function normalizePhone(p) {
  if (!p) return null;
  return p.replace(/\s+/g, ' ').trim();
}

function toMemberRecord(l, socialByBio, officesByBio) {
  const term = latestTerm(l.terms);
  const bio = l.id?.bioguide || null;

  const social = socialByBio.get(bio) || {};
  const districtOffices = officesByBio.get(bio) || [];

  const officialFull =
    l.name?.official_full ||
    [l.name?.first, l.name?.middle, l.name?.last, l.name?.suffix].filter(Boolean).join(' ').replace(/\s+/g, ' ').trim();

  const record = {
    id: {
      bioguide: l.id?.bioguide ?? null,
      govtrack: l.id?.govtrack ?? null,
      opensecrets: l.id?.opensecrets ?? null,
      fec: Array.isArray(l.id?.fec) ? l.id.fec : l.id?.fec ? [l.id.fec] : [],
      thomas: l.id?.thomas ?? null,
      cspan: l.id?.cspan ?? null,
      wikipedia: l.id?.wikipedia ?? null,
      wikidata: l.id?.wikidata ?? null
    },
    name: {
      official_full: officialFull || null,
      first: l.name?.first ?? null,
      last: l.name?.last ?? null,
      middle: l.name?.middle ?? null,
      nickname: l.name?.nickname ?? null,
      suffix: l.name?.suffix ?? null
    },
    party: term?.party ?? null,
    state: term?.state ?? null,
    district: term?.district ?? null,
    role: computeRole(term?.state),
    term: term
      ? {
          start: term.start ?? null,
          end: term.end ?? null
        }
      : null,
    contact: {
      capitol_office: {
        office: term?.office ?? null,
        address: term?.address ?? null,
        phone: normalizePhone(term?.phone) ?? null,
        fax: normalizePhone(term?.fax) ?? null
      },
      district_offices: districtOffices.map((o) => ({
        address: o.address ?? null,
        city: o.city ?? null,
        state: o.state ?? null,
        zip: o.zip ?? null,
        phone: normalizePhone(o.phone) ?? null,
        fax: normalizePhone(o.fax) ?? null,
        latitude: o.latitude ?? null,
        longitude: o.longitude ?? null,
        suite: o.suite ?? null
      })),
      contact_form: term?.contact_form ?? l.contact_form ?? null,
      website: term?.url ?? l.url ?? null
    },
    social: {
      twitter: social.twitter ?? null,
      twitter_id: social.twitter_id ?? null,
      facebook: social.facebook ?? null,
      youtube: social.youtube ?? null,
      youtube_id: social.youtube_id ?? null,
      instagram: social.instagram ?? null,
      mastodon: social.mastodon ?? null,
      threads: social.threads ?? null
    }
  };

  return record;
}

function compareMembers(a, b) {
  const stateCmp = (a.state || '').localeCompare(b.state || '');
  if (stateCmp !== 0) return stateCmp;

  const da = a.district ?? 9999;
  const db = b.district ?? 9999;
  if (da !== db) return da - db;

  return (a.name?.last || '').localeCompare(b.name?.last || '');
}

async function main() {
  console.log('Fetching datasets...');
  const [legislatorsText, socialText, officesText] = await Promise.all([
    fetchText(LEGISLATORS_URL),
    fetchText(SOCIAL_URL),
    fetchText(DISTRICT_OFFICES_URL)
  ]);

  const legislators = yaml.parse(legislatorsText) || [];
  const socialArr = yaml.parse(socialText) || [];
  const officesArr = yaml.parse(officesText) || [];

  const socialByBio = new Map(
    socialArr.map((entry) => [entry.id?.bioguide, entry.social || {}]).filter(([k]) => !!k)
  );

  const officesByBio = new Map(
    officesArr.map((entry) => [entry.id?.bioguide, Array.isArray(entry.offices) ? entry.offices : []]).filter(([k]) => !!k)
  );

  const now = new Date();

  const houseMembers = legislators
    .filter((l) => {
      const term = latestTerm(l.terms);
      return term && term.type === 'rep' && isCurrentTerm(term, now);
    })
    .map((l) => toMemberRecord(l, socialByBio, officesByBio))
    .sort(compareMembers);

  const payload = {
    last_updated: new Date().toISOString(),
    source: 'https://github.com/unitedstates/congress-legislators',
    members: houseMembers
  };

  await fs.mkdir(OUT_DIR, { recursive: true });
  await fs.writeFile(OUT_FILE, JSON.stringify(payload, null, 2) + '\n', 'utf8');

  console.log(`Wrote ${houseMembers.length} members to ${OUT_FILE}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});