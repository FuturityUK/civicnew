SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS dataset_info (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  last_updated DATETIME NULL,
  source_url VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS members (
  bioguide VARCHAR(16) NOT NULL,
  govtrack BIGINT UNSIGNED NULL,
  opensecrets VARCHAR(32) NULL,
  thomas VARCHAR(16) NULL,
  cspan BIGINT UNSIGNED NULL,
  wikipedia VARCHAR(255) NULL,
  wikidata VARCHAR(64) NULL,

  official_full VARCHAR(255) NULL,
  first VARCHAR(100) NULL,
  middle VARCHAR(100) NULL,
  last VARCHAR(100) NULL,
  nickname VARCHAR(100) NULL,
  suffix VARCHAR(32) NULL,

  party VARCHAR(32) NOT NULL,
  state CHAR(2) NOT NULL,
  district SMALLINT UNSIGNED NOT NULL,
  role VARCHAR(32) NOT NULL,

  term_start DATE NOT NULL,
  term_end DATE NOT NULL,

  contact_form VARCHAR(255) NULL,
  website VARCHAR(255) NULL,

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT pk_members PRIMARY KEY (bioguide),
  KEY idx_members_state_district (state, district),
  KEY idx_members_govtrack (govtrack)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS capitol_office (
  member_bioguide VARCHAR(16) NOT NULL,
  office VARCHAR(255) NULL,
  address VARCHAR(255) NULL,
  phone VARCHAR(32) NULL,
  fax VARCHAR(32) NULL,

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT pk_capitol_office PRIMARY KEY (member_bioguide),
  CONSTRAINT fk_capitol_office_member FOREIGN KEY (member_bioguide)
    REFERENCES members (bioguide)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS district_offices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  member_bioguide VARCHAR(16) NOT NULL,
  address VARCHAR(255) NULL,
  city VARCHAR(100) NULL,
  state CHAR(2) NULL,
  zip VARCHAR(20) NULL,
  phone VARCHAR(32) NULL,
  fax VARCHAR(32) NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  suite VARCHAR(100) NULL,

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT pk_district_offices PRIMARY KEY (id),
  KEY idx_district_offices_member (member_bioguide),
  CONSTRAINT fk_district_offices_member FOREIGN KEY (member_bioguide)
    REFERENCES members (bioguide)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS member_fec_ids (
  member_bioguide VARCHAR(16) NOT NULL,
  fec_id VARCHAR(32) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_member_fec_ids PRIMARY KEY (member_bioguide, fec_id),
  CONSTRAINT fk_member_fec_member FOREIGN KEY (member_bioguide)
    REFERENCES members (bioguide)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS social_profiles (
  member_bioguide VARCHAR(16) NOT NULL,
  twitter VARCHAR(100) NULL,
  twitter_id BIGINT UNSIGNED NULL,
  facebook VARCHAR(150) NULL,
  youtube VARCHAR(150) NULL,
  youtube_id VARCHAR(100) NULL,
  instagram VARCHAR(150) NULL,
  mastodon VARCHAR(255) NULL,
  threads VARCHAR(150) NULL,

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT pk_social_profiles PRIMARY KEY (member_bioguide),
  CONSTRAINT fk_social_profiles_member FOREIGN KEY (member_bioguide)
    REFERENCES members (bioguide)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Import procedure
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS import_house_contacts;
DELIMITER $$
CREATE PROCEDURE import_house_contacts(IN p_json JSON)
BEGIN
  DECLARE v_last_raw VARCHAR(64);
  DECLARE v_last_updated DATETIME;
  DECLARE v_source_url VARCHAR(255);

  -- Begin a transaction for consistency
  START TRANSACTION;

  -- Dataset metadata
  SET v_last_raw   = JSON_UNQUOTE(JSON_EXTRACT(p_json, '$.last_updated'));
  -- Convert ISO 8601 'YYYY-MM-DDTHH:MM:SS.sssZ' -> DATETIME (UTC), drop milliseconds/timezone
  SET v_last_updated = STR_TO_DATE(SUBSTRING(REPLACE(v_last_raw,'T',' '),1,19), '%Y-%m-%d %H:%i:%s');
  SET v_source_url   = JSON_UNQUOTE(JSON_EXTRACT(p_json, '$.source'));

  INSERT INTO dataset_info (id, last_updated, source_url)
  VALUES (1, v_last_updated, v_source_url)
  ON DUPLICATE KEY UPDATE
    last_updated = VALUES(last_updated),
    source_url   = VALUES(source_url);

  -- List of bioguide IDs present in this payload
  CREATE TEMPORARY TABLE tmp_members (
    bioguide VARCHAR(16) NOT NULL PRIMARY KEY
  ) ENGINE=Memory;

  INSERT INTO tmp_members (bioguide)
  SELECT bioguide
  FROM JSON_TABLE(p_json, '$.members[*]'
    COLUMNS (
      bioguide VARCHAR(16) PATH '$.id.bioguide' NOT NULL
    )
  ) AS t;

  -- Upsert members
  INSERT INTO members (
    bioguide, govtrack, opensecrets, thomas, cspan, wikipedia, wikidata,
    official_full, first, middle, last, nickname, suffix,
    party, state, district, role, term_start, term_end, contact_form, website
  )
  SELECT
    bioguide, govtrack, opensecrets, thomas, cspan, wikipedia, wikidata,
    official_full, first, middle, last, nickname, suffix,
    party, state, district, role, term_start, term_end, contact_form, website
  FROM JSON_TABLE(p_json, '$.members[*]'
    COLUMNS (
      bioguide VARCHAR(16) PATH '$.id.bioguide' NOT NULL,
      govtrack BIGINT PATH '$.id.govtrack',
      opensecrets VARCHAR(32) PATH '$.id.opensecrets',
      thomas VARCHAR(16) PATH '$.id.thomas',
      cspan BIGINT PATH '$.id.cspan',
      wikipedia VARCHAR(255) PATH '$.id.wikipedia',
      wikidata VARCHAR(64) PATH '$.id.wikidata',

      official_full VARCHAR(255) PATH '$.name.official_full',
      first VARCHAR(100) PATH '$.name.first',
      middle VARCHAR(100) PATH '$.name.middle',
      last VARCHAR(100) PATH '$.name.last',
      nickname VARCHAR(100) PATH '$.name.nickname',
      suffix VARCHAR(32) PATH '$.name.suffix',

      party VARCHAR(32) PATH '$.party',
      state CHAR(2) PATH '$.state',
      district SMALLINT PATH '$.district',
      role VARCHAR(32) PATH '$.role',

      term_start DATE PATH '$.term.start',
      term_end DATE PATH '$.term.end',

      contact_form VARCHAR(255) PATH '$.contact.contact_form',
      website VARCHAR(255) PATH '$.contact.website'
    )
  ) AS m
  ON DUPLICATE KEY UPDATE
    govtrack      = VALUES(govtrack),
    opensecrets   = VALUES(opensecrets),
    thomas        = VALUES(thomas),
    cspan         = VALUES(cspan),
    wikipedia     = VALUES(wikipedia),
    wikidata      = VALUES(wikidata),
    official_full = VALUES(official_full),
    first         = VALUES(first),
    middle        = VALUES(middle),
    last          = VALUES(last),
    nickname      = VALUES(nickname),
    suffix        = VALUES(suffix),
    party         = VALUES(party),
    state         = VALUES(state),
    district      = VALUES(district),
    role          = VALUES(role),
    term_start    = VALUES(term_start),
    term_end      = VALUES(term_end),
    contact_form  = VALUES(contact_form),
    website       = VALUES(website);

  -- Upsert one capitol office per member
  INSERT INTO capitol_office (member_bioguide, office, address, phone, fax)
  SELECT
    bioguide, office, address, phone, fax
  FROM JSON_TABLE(p_json, '$.members[*]'
    COLUMNS (
      bioguide VARCHAR(16) PATH '$.id.bioguide' NOT NULL,
      office   VARCHAR(255) PATH '$.contact.capitol_office.office',
      address  VARCHAR(255) PATH '$.contact.capitol_office.address',
      phone    VARCHAR(32)  PATH '$.contact.capitol_office.phone',
      fax      VARCHAR(32)  PATH '$.contact.capitol_office.fax'
    )
  ) AS c
  ON DUPLICATE KEY UPDATE
    office  = VALUES(office),
    address = VALUES(address),
    phone   = VALUES(phone),
    fax     = VALUES(fax);

  -- Rebuild district offices only for members present in this payload
  DELETE dof
  FROM district_offices dof
  JOIN tmp_members tm ON tm.bioguide = dof.member_bioguide;

  INSERT INTO district_offices (
    member_bioguide, address, city, state, zip, phone, fax, latitude, longitude, suite
  )
  SELECT
    bioguide, address, city, state, zip, phone, fax, latitude, longitude, suite
  FROM JSON_TABLE(p_json, '$.members[*]'
    COLUMNS (
      bioguide VARCHAR(16) PATH '$.id.bioguide',
      NESTED PATH '$.contact.district_offices[*]' COLUMNS (
        address   VARCHAR(255) PATH '$.address',
        city      VARCHAR(100) PATH '$.city',
        state     CHAR(2)      PATH '$.state',
        zip       VARCHAR(20)  PATH '$.zip',
        phone     VARCHAR(32)  PATH '$.phone',
        fax       VARCHAR(32)  PATH '$.fax',
        latitude  DECIMAL(10,7) PATH '$.latitude',
        longitude DECIMAL(10,7) PATH '$.longitude',
        suite     VARCHAR(100) PATH '$.suite'
      )
    )
  ) AS d;

  -- Rebuild FEC IDs only for members present in this payload
  DELETE mfi
  FROM member_fec_ids mfi
  JOIN tmp_members tm ON tm.bioguide = mfi.member_bioguide;

  INSERT INTO member_fec_ids (member_bioguide, fec_id)
  SELECT bioguide, fec_id
  FROM JSON_TABLE(p_json, '$.members[*]'
    COLUMNS (
      bioguide VARCHAR(16) PATH '$.id.bioguide',
      NESTED PATH '$.id.fec[*]' COLUMNS (
        fec_id VARCHAR(32) PATH '$'
      )
    )
  ) AS f;

  -- Upsert social profiles
  INSERT INTO social_profiles (
    member_bioguide, twitter, twitter_id, facebook, youtube, youtube_id, instagram, mastodon, threads
  )
  SELECT
    bioguide, twitter, twitter_id, facebook, youtube, youtube_id, instagram, mastodon, threads
  FROM JSON_TABLE(p_json, '$.members[*]'
    COLUMNS (
      bioguide   VARCHAR(16) PATH '$.id.bioguide',
      twitter    VARCHAR(100) PATH '$.social.twitter',
      twitter_id BIGINT PATH '$.social.twitter_id',
      facebook   VARCHAR(150) PATH '$.social.facebook',
      youtube    VARCHAR(150) PATH '$.social.youtube',
      youtube_id VARCHAR(100) PATH '$.social.youtube_id',
      instagram  VARCHAR(150) PATH '$.social.instagram',
      mastodon   VARCHAR(255) PATH '$.social.mastodon',
      threads    VARCHAR(150) PATH '$.social.threads'
    )
  ) AS s
  ON DUPLICATE KEY UPDATE
    twitter    = VALUES(twitter),
    twitter_id = VALUES(twitter_id),
    facebook   = VALUES(facebook),
    youtube    = VALUES(youtube),
    youtube_id = VALUES(youtube_id),
    instagram  = VALUES(instagram),
    mastodon   = VALUES(mastodon),
    threads    = VALUES(threads);

  COMMIT;
END $$
DELIMITER ;

-- ------------------------------------------------------------
-- Convenience view (optional)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_members_overview AS
SELECT
  m.bioguide,
  m.official_full,
  m.first, m.middle, m.last, m.nickname, m.suffix,
  m.party, m.state, m.district, m.role,
  m.term_start, m.term_end,
  c.office AS capitol_office_name,
  c.address AS capitol_address,
  c.phone   AS capitol_phone,
  sp.twitter, sp.facebook, sp.instagram, sp.youtube
FROM members m
LEFT JOIN capitol_office c ON c.member_bioguide = m.bioguide
LEFT JOIN social_profiles sp ON sp.member_bioguide = m.bioguide.