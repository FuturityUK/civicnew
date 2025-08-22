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
