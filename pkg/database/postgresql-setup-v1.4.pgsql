-- PostgreSQL setup script for the search engine database.
-- Adjusted for better performance and best practices.

-- To run this setup script manually from a PostgreSQL UI
-- Define the following variables in psql replacing their values
-- with your own and then run the script.
--\set POSTGRES_DB 'SitesIndex'
--\set CROWLER_DB_USER 'your_username'
--\set CROWLER_DB_PASSWORD 'your_password'

--------------------------------------------------------------------------------
-- Database Tables setup

-- InformationSeeds table stores the seed information for the crawler
CREATE TABLE IF NOT EXISTS InformationSeed (
    information_seed_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    category_id BIGINT DEFAULT 0 NOT NULL,      -- The category of the information seed.
    usr_id BIGINT DEFAULT 0 NOT NULL,           -- The user that created the information seed
    information_seed VARCHAR(256) NOT NULL,     -- The size of an information seed is limited to 256
                                                -- characters due to the fact that it's used to dork
                                                -- search engines for sources that may be related to
                                                -- the information seed.
    config JSONB                                -- Stores JSON document with all details about
                                                -- the information seed configuration for the crawler
);

-- Sources table stores the URLs or the information's seed to be crawled
CREATE TABLE IF NOT EXISTS Sources (
    source_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP,
    usr_id BIGINT DEFAULT 0 NOT NULL,           -- The user that created the source.
    category_id BIGINT DEFAULT 0 NOT NULL,      -- The category of the source.
    url TEXT NOT NULL UNIQUE,                   -- The Source URL.
    status VARCHAR(50) DEFAULT 'new' NOT NULL,  -- All new sources are set to 'new' by default.
    engine VARCHAR(256) DEFAULT '' NOT NULL,    -- The engine crawling the source.
    last_crawled_at TIMESTAMP,                  -- The last time the source was crawled.
    last_error TEXT,                            -- Last error message that occurred during crawling.
    last_error_at TIMESTAMP,                    -- The date/time of the last error occurred.
    restricted INTEGER DEFAULT 2 NOT NULL,      -- 0 = fully restricted (just this URL)
                                                -- 1 = l3 domain restricted (everything within this
                                                --     URL l3 domain)
                                                -- 2 = l2 domain restricted
                                                -- 3 = l1 domain restricted
                                                -- 4 = no restrictions
    disabled BOOLEAN DEFAULT FALSE,             -- If the automatic re-crawling/re-scanning of the
                                                -- source is disabled.
    flags INTEGER DEFAULT 0 NOT NULL,           -- Bitwise flags for the source (used for various
                                                -- purposes, included but not limited to the Rules).
    config JSONB                                -- Stores JSON document with all details about
                                                -- the source configuration for the crawler.
);

-- Owners table stores the information about the owners of the sources
CREATE TABLE IF NOT EXISTS Owners (
    owner_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usr_id BIGINT NOT NULL,                     -- The user that created the owner
    details_hash VARCHAR(64) UNIQUE NOT NULL,   -- SHA256 hash of the details for fast comparison
                                                -- and uniqueness.
    details JSONB NOT NULL                      -- Stores JSON document with all details about
                                                -- the owner.
);

-- SearchIndex table stores the indexed information from the sources
CREATE TABLE IF NOT EXISTS SearchIndex (
    index_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    page_url TEXT NOT NULL UNIQUE,              -- Using TEXT for long URLs
    title VARCHAR(255),                         -- Page title might be NULL
    summary TEXT NOT NULL,                      -- Assuming summary is always required
    detected_type VARCHAR(8),                   -- (content type) denormalized for fast searches
    detected_lang VARCHAR(8)                    -- (URI language) denormalized for fast searches
);

-- Categories table stores the categories (and subcategories) for the sources
CREATE TABLE IF NOT EXISTS Categories (
    category_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    parent_id BIGINT,
    CONSTRAINT fk_parent
        FOREIGN KEY(parent_id)
        REFERENCES Categories(category_id)
        ON DELETE SET NULL
);

-- NetInfo table stores the network information retrieved from the sources
CREATE TABLE IF NOT EXISTS NetInfo (
    netinfo_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details_hash VARCHAR(64) UNIQUE NOT NULL,   -- SHA256 hash of the details for fast comparison
                                                -- and uniqueness.
    details JSONB NOT NULL
);

-- HTTPInfo table stores the HTTP header information retrieved from the sources
CREATE TABLE IF NOT EXISTS HTTPInfo (
    httpinfo_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details_hash VARCHAR(64) UNIQUE NOT NULL,   -- SHA256 hash of the details for fast comparison
                                                -- and uniqueness
    details JSONB NOT NULL
);

-- Screenshots table stores the screenshots details of the indexed pages
CREATE TABLE IF NOT EXISTS Screenshots (
    screenshot_id BIGSERIAL PRIMARY KEY,
    index_id BIGINT REFERENCES SearchIndex(index_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    type VARCHAR(10) NOT NULL DEFAULT 'desktop',
    screenshot_link TEXT NOT NULL,
    height INTEGER NOT NULL DEFAULT 0,
    width INTEGER NOT NULL DEFAULT 0,
    byte_size INTEGER NOT NULL DEFAULT 0,
    thumbnail_height INTEGER NOT NULL DEFAULT 0,
    thumbnail_width INTEGER NOT NULL DEFAULT 0,
    thumbnail_link TEXT NOT NULL DEFAULT '',
    format VARCHAR(10) NOT NULL DEFAULT 'png',
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE
);

-- WebObjects table stores all types of web objects found in the indexed pages
-- This includes scripts, styles, images, iframes, HTML etc.
CREATE TABLE IF NOT EXISTS WebObjects (
    object_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    object_link TEXT NOT NULL DEFAULT 'db',     -- The link to where the object is stored if not
                                                -- in the DB.
    object_type VARCHAR(255) NOT NULL DEFAULT 'text/html', -- The type of the object, for fast searches
    object_hash VARCHAR(64) UNIQUE NOT NULL,    -- SHA256 hash of the object for fast comparison
                                                -- and uniqueness.
    object_content TEXT,                        -- The actual content of the object, nullable if
                                                -- stored externally.
    object_html TEXT,                           -- The HTML content of the object, nullable if
                                                -- stored externally.
    details JSONB NOT NULL                      -- Stores JSON document with all details about
                                                -- the object.
);

-- MetaTags table stores the meta tags from the SearchIndex
CREATE TABLE IF NOT EXISTS MetaTags (
    metatag_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    UNIQUE(name, content)                       -- Ensure that each name-content pair is unique
);

-- Keywords table stores all the found keywords during an indexing
CREATE TABLE IF NOT EXISTS Keywords (
    keyword_id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    keyword VARCHAR(256) NOT NULL UNIQUE
);

-- Events table stores the events generated by the system
CREATE TABLE IF NOT EXISTS Events (
    event_sha256 CHAR(64) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_id BIGINT REFERENCES Sources(source_id) ON DELETE CASCADE,
    event_type VARCHAR(255) NOT NULL,
    event_severity VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    details JSONB NOT NULL
);

----------------------------------------
-- Relationship tables

-- SourceInformationSeedIndex table stores the relationship between sources and their information seeds
CREATE TABLE IF NOT EXISTS SourceInformationSeedIndex (
    source_information_seed_id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES Sources(source_id) ON DELETE CASCADE,
    information_seed_id BIGINT NOT NULL REFERENCES InformationSeed(information_seed_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (source_id, information_seed_id)
);

-- SourceOwnerIndex table stores the relationship between sources and their owners
CREATE TABLE IF NOT EXISTS SourceOwnerIndex (
    source_owner_id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL,
    owner_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_source
        FOREIGN KEY(source_id)
        REFERENCES Sources(source_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_owner
        FOREIGN KEY(owner_id)
        REFERENCES Owners(owner_id)
        ON DELETE CASCADE,
    UNIQUE(source_id, owner_id),                -- Ensures unique combinations of source_id and
                                                -- owner_id
    FOREIGN KEY (source_id) REFERENCES Sources(source_id) ON DELETE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES Owners(owner_id) ON DELETE CASCADE
);

-- SourceSearchIndex table stores the relationship between sources and the indexed pages
CREATE TABLE IF NOT EXISTS SourceSearchIndex (
    ss_index_id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL,
    index_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_source
        FOREIGN KEY(source_id)
        REFERENCES Sources(source_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_search_index
        FOREIGN KEY(index_id)
        REFERENCES SearchIndex(index_id)
        ON DELETE CASCADE,
    UNIQUE(source_id, index_id),                -- Ensures unique combinations of source_id
                                                -- and index_id
    FOREIGN KEY (source_id) REFERENCES Sources(source_id) ON DELETE CASCADE,
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE
);

-- SourceCategoryIndex table stores the relationship between sources and their categories
CREATE TABLE IF NOT EXISTS SourceCategoryIndex (
    source_category_id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_source
        FOREIGN KEY(source_id)
        REFERENCES Sources(source_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_category
        FOREIGN KEY(category_id)
        REFERENCES Categories(category_id)
        ON DELETE CASCADE,
    UNIQUE(source_id, category_id)
);

-- WebObjectsIndex table stores the relationship between indexed pages and the objects found in them
CREATE TABLE IF NOT EXISTS WebObjectsIndex (
    page_object_id BIGSERIAL PRIMARY KEY,
    index_id BIGINT NOT NULL REFERENCES SearchIndex(index_id),
    object_id BIGINT NOT NULL REFERENCES WebObjects(object_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(index_id, object_id),                -- Ensures that the same object is not linked
                                                -- multiple times to the same page.
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE,
    FOREIGN KEY (object_id) REFERENCES WebObjects(object_id) ON DELETE CASCADE
);

-- Relationship table between SearchIndex and MetaTags
CREATE TABLE IF NOT EXISTS MetaTagsIndex (
    sim_id BIGSERIAL PRIMARY KEY,
    index_id BIGINT NOT NULL REFERENCES SearchIndex(index_id),
    metatag_id BIGINT NOT NULL REFERENCES MetaTags(metatag_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(index_id, metatag_id),               -- Prevents duplicate associations
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE,
    FOREIGN KEY (metatag_id) REFERENCES MetaTags(metatag_id) ON DELETE CASCADE
);

-- KeywordIndex table stores the relationship between keywords and the indexed pages
CREATE TABLE IF NOT EXISTS KeywordIndex (
    keyword_index_id BIGSERIAL PRIMARY KEY,
    keyword_id BIGINT REFERENCES Keywords(keyword_id),
    index_id BIGINT REFERENCES SearchIndex(index_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    occurrences INTEGER,
    UNIQUE(keyword_id, index_id),               -- Ensures unique combinations of keyword_id
                                                -- and index_id
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE,
    FOREIGN KEY (keyword_id) REFERENCES Keywords(keyword_id) ON DELETE CASCADE
);

-- NetInfoIndex table stores the relationship between network information and the indexed pages
CREATE TABLE IF NOT EXISTS NetInfoIndex (
    netinfo_index_id BIGSERIAL PRIMARY KEY,
    netinfo_id BIGINT REFERENCES NetInfo(netinfo_id),
    index_id BIGINT REFERENCES SearchIndex(index_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(netinfo_id, index_id),               -- Ensures unique combinations of netinfo_id
                                                -- and index_id
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE,
    FOREIGN KEY (netinfo_id) REFERENCES NetInfo(netinfo_id) ON DELETE CASCADE
);

-- HTTPInfoIndex table stores the relationship between HTTP information and the indexed pages
CREATE TABLE IF NOT EXISTS HTTPInfoIndex (
    httpinfo_index_id BIGSERIAL PRIMARY KEY,
    httpinfo_id BIGINT REFERENCES HTTPInfo(httpinfo_id),
    index_id BIGINT REFERENCES SearchIndex(index_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(httpinfo_id, index_id),              -- Ensures unique combinations of httpinfo_id
                                                -- and index_id
    FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE,
    FOREIGN KEY (httpinfo_id) REFERENCES HTTPInfo(httpinfo_id) ON DELETE CASCADE
);

--------------------------------------------------------------------------------
-- Indexes and triggers setup

-- Indexes for the InformationSeed table ---------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_informationseed_category_id') THEN
        CREATE INDEX idx_informationseed_category_id ON InformationSeed(category_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_informationseed_usr_id') THEN
        CREATE INDEX idx_informationseed_usr_id ON InformationSeed(usr_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_informationseed_information_seed') THEN
        CREATE INDEX idx_informationseed_information_seed ON InformationSeed(information_seed);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_informationseed_created_at') THEN
        CREATE INDEX idx_informationseed_created_at ON InformationSeed(created_at);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_informationseed_last_updated_at') THEN
        CREATE INDEX idx_informationseed_last_updated_at ON InformationSeed(last_updated_at);
    END IF;
END
$$;


-- Indexes for the Sources table -----------------------------------------------

-- Creates an index for the Sources url column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_url') THEN
        CREATE INDEX idx_sources_url ON Sources(url text_pattern_ops);
    END IF;
END
$$;

-- Creates an index for the Sources category_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_category_id') THEN
        CREATE INDEX idx_sources_category_id ON Sources(category_id);
    END IF;
END
$$;

-- Creates an index for the Sources usr_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_usr_id') THEN
        CREATE INDEX idx_sources_usr_id ON Sources(usr_id);
    END IF;
END
$$;

-- Creates an index for the Sources status column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_status') THEN
        CREATE INDEX idx_sources_status ON Sources(status);
    END IF;
END
$$;

-- Creates an index for the Sources engine column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_engine') THEN
        CREATE INDEX idx_sources_engine ON Sources(engine);
    END IF;
END
$$;

-- Creates an index for the Sources last_crawled_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_last_crawled_at') THEN
        CREATE INDEX idx_sources_last_crawled_at ON Sources(last_crawled_at);
    END IF;
END
$$;

-- Creates an index for the Sources last_error_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_last_error_at') THEN
        CREATE INDEX idx_sources_last_error_at ON Sources(last_error_at);
    END IF;
END
$$;

-- Creates a gin index for the Source config column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sources_config') THEN
        CREATE INDEX idx_sources_config ON Sources USING gin(config jsonb_path_ops);
    END IF;
END
$$;


-- Indexes for the Owners table ------------------------------------------------

-- Creates an index for the Owners usr_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_owners_usr_id') THEN
        CREATE INDEX idx_owners_usr_id ON Owners(usr_id);
    END IF;
END
$$;

-- Creates an index for the Owners details_hash column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_owners_details_hash') THEN
        CREATE INDEX idx_owners_details_hash ON Owners(details_hash);
    END IF;
END
$$;

-- Creates an index for the Owners details column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_owners_details') THEN
        CREATE INDEX idx_owners_details ON Owners USING gin(details jsonb_path_ops);
    END IF;
END
$$;

-- Creates an index for the Owners last_updated_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_owners_last_updated_at') THEN
        CREATE INDEX idx_owners_last_updated_at ON Owners(last_updated_at);
    END IF;
END
$$;

-- Creates an index for the Owners created_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_owners_created_at') THEN
        CREATE INDEX idx_owners_created_at ON Owners(created_at);
    END IF;
END
$$;


-- Indexes for the SearchIndex table -------------------------------------------

-- Creates an index for the SearchIndex page_url column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_searchindex_page_url') THEN
        CREATE INDEX idx_searchindex_page_url ON SearchIndex(page_url);
    END IF;
END
$$;

-- Creates an index for the SearchIndex title column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_searchindex_title') THEN
        CREATE INDEX idx_searchindex_title ON SearchIndex(title);
    END IF;
END
$$;

-- Creates an index for the SearchIndex summary column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_searchindex_summary') THEN
        CREATE INDEX idx_searchindex_summary ON SearchIndex(summary);
    END IF;
END
$$;

-- Creates an index for the SearchIndex detected_type column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_searchindex_detected_type') THEN
        CREATE INDEX idx_searchindex_detected_type ON SearchIndex(detected_type);
    END IF;
END
$$;

-- Creates an index for the SearchIndex detected_lang column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_searchindex_detected_lang') THEN
        CREATE INDEX idx_searchindex_detected_lang ON SearchIndex(detected_lang);
    END IF;
END
$$;


-- Indexes for the Categories table --------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_categories_parent_id') THEN
        CREATE INDEX idx_categories_parent_id ON Categories(parent_id);
    END IF;
END
$$;


-- Indexes for the NetInfo table -----------------------------------------------

-- Creates an index for the NetInfo details_hash column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_netinfo_details_hash') THEN
        CREATE INDEX idx_netinfo_details_hash ON NetInfo(details_hash);
    END IF;
END
$$;

-- Creates an index for the NetInfo last_updated_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_netinfo_last_updated_at') THEN
        CREATE INDEX idx_netinfo_last_updated_at ON NetInfo(last_updated_at);
    END IF;
END
$$;

-- Creates an index for the NetInfo created_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_netinfo_created_at') THEN
        CREATE INDEX idx_netinfo_created_at ON NetInfo(created_at);
    END IF;
END
$$;

-- Creates an index for the details column in the NetInfo table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_json_netinfo_details') THEN
        CREATE INDEX idx_json_netinfo_details ON NetInfo USING gin (details jsonb_path_ops);
    END IF;
END
$$;


-- Indexes for the Screenshots table -------------------------------------------

-- Creates an index for the Screenshots index_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_screenshots_index_id') THEN
        CREATE INDEX idx_screenshots_index_id ON Screenshots(index_id);
    END IF;
END
$$;

-- Creates an index for the Screenshots screenshot_link column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_screenshots_screenshot_link') THEN
        CREATE INDEX idx_screenshots_screenshot_link ON Screenshots(screenshot_link);
    END IF;
END
$$;

-- Creates an index for the Screenshots last_updated_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_screenshots_last_updated_at') THEN
        CREATE INDEX idx_screenshots_last_updated_at ON Screenshots(last_updated_at);
    END IF;
END
$$;

-- Creates an index for the Screenshots created_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_screenshots_created_at') THEN
        CREATE INDEX idx_screenshots_created_at ON Screenshots(created_at);
    END IF;
END
$$;


-- Indexes for the WebObjects table --------------------------------------------

-- Creates an index for the WebObjects object_link column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjects_object_link') THEN
        CREATE INDEX idx_webobjects_object_link ON WebObjects(object_link text_pattern_ops);
    END IF;
END
$$;

-- Creates an index for the WebObjects object_type column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjects_object_type') THEN
        CREATE INDEX idx_webobjects_object_type ON WebObjects(object_type);
    END IF;
END
$$;

-- Creates an index for the WebObjects object_hash column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjects_object_hash') THEN
        CREATE INDEX idx_webobjects_object_hash ON WebObjects(object_hash);
    END IF;
END
$$;

-- Creates an index for the WebObjects object_content column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjects_object_content') THEN
        CREATE INDEX idx_webobjects_object_content ON WebObjects(left(object_content, 1024) text_pattern_ops) WHERE object_content IS NOT NULL AND object_link = 'db';
    END IF;
END
$$;

-- Creates an index for the WebObjects created_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjects_created_at') THEN
        CREATE INDEX idx_webobjects_created_at ON WebObjects(created_at);
    END IF;
END
$$;

-- Creates an index for the WebObjects last_updated_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjects_last_updated_at') THEN
        CREATE INDEX idx_webobjects_last_updated_at ON WebObjects(last_updated_at);
    END IF;
END
$$;

-- Creates an index for the details column in the WebObjects table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_json_webobjects_details') THEN
        CREATE INDEX idx_json_webobjects_details ON WebObjects USING gin (details jsonb_path_ops);
    END IF;
END
$$;


-- Indexes for WebObjectsIndex Table -------------------------------------------

-- Creates an index for the WebObjectsIndex table on the object_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjectsindex_object_id') THEN
        CREATE INDEX idx_webobjectsindex_object_id ON WebObjectsIndex (object_id);
    END IF;
END
$$;

-- Creates an index for the WebObjectsIndex table on the index_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_webobjectsindex_index_id') THEN
        CREATE INDEX idx_webobjectsindex_index_id ON WebObjectsIndex (index_id);
    END IF;
END
$$;


-- Indexes for the Keywords table ----------------------------------------------

-- Creates an index for the Keywords table on the keyword column (for lower-cased searches)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_keywords_keyword_lower') THEN
        CREATE INDEX idx_keywords_keyword_lower ON Keywords (LOWER(keyword));
    END IF;
END
$$;


-- Indexes for the KeywordIndex table ------------------------------------------

-- Creates an index for the KeywordIndex table on the keyword_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_keywordindex_keyword_id') THEN
        CREATE INDEX idx_keywordindex_keyword_id ON KeywordIndex (keyword_id);
    END IF;
END
$$;

-- Creates an index for the KeywordIndex table on the index_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_keywordindex_index_id') THEN
        CREATE INDEX idx_keywordindex_index_id ON KeywordIndex (index_id);
    END IF;
END
$$;

-- Creates an index for the KeywordIndex table on the occurrences column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_keywordindex_occurrences') THEN
        CREATE INDEX idx_keywordindex_occurrences ON KeywordIndex(occurrences);
    END IF;
END
$$;


-- Indexes for the HTTPInfo table ----------------------------------------------

-- Creates an index for the HTTPInfo details_hash column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_httpinfo_details_hash') THEN
        CREATE INDEX idx_httpinfo_details_hash ON HTTPInfo(details_hash);
    END IF;
END
$$;

-- Creates an index for the HTTPInfo details column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_json_httpinfo_details') THEN
        CREATE INDEX idx_json_httpinfo_details ON HTTPInfo USING gin (details jsonb_path_ops);
    END IF;
END
$$;

-- Creates an index for the HTTPInfo last_updated_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_httpinfo_last_updated_at') THEN
        CREATE INDEX idx_httpinfo_last_updated_at ON HTTPInfo(last_updated_at);
    END IF;
END
$$;

-- Creates an index for the HTTPInfo created_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_httpinfo_created_at') THEN
        CREATE INDEX idx_httpinfo_created_at ON HTTPInfo(created_at);
    END IF;
END
$$;


-- Indexes for the Events table ------------------------------------------------

-- Creates an index for the Events source_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_source_id') THEN
        CREATE INDEX idx_events_source_id ON Events(source_id);
    END IF;
END
$$;

-- Creates an index for the Events event_type column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_event_type') THEN
        CREATE INDEX idx_events_event_type ON Events(event_type);
    END IF;
END
$$;

-- Creates an index for the Events event_severity column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_event_severity') THEN
        CREATE INDEX idx_events_event_severity ON Events(event_severity);
    END IF;
END
$$;

-- Creates an index for the Events event_timestamp column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_event_timestamp') THEN
        CREATE INDEX idx_events_event_timestamp ON Events(event_timestamp);
    END IF;
END
$$;

-- Creates an index for the Events details column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_details') THEN
        CREATE INDEX idx_events_details ON Events USING gin(details jsonb_path_ops);
    END IF;
END
$$;

-- Creates an index for the Events last_updated_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_last_updated_at') THEN
        CREATE INDEX idx_events_last_updated_at ON Events(last_updated_at);
    END IF;
END
$$;

-- Creates an index for the Events created_at column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_events_created_at') THEN
        CREATE INDEX idx_events_created_at ON Events(created_at);
    END IF;
END
$$;


-- Indexes for the SourceInformationSeedIndex table ----------------------------

-- Creates an index for SourceInformationSeedIndex source_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sourceinformationseedindex_source_id') THEN
        CREATE INDEX idx_sourceinformationseedindex_source_id ON SourceInformationSeedIndex(source_id);
    END IF;
END
$$;

-- Creates an index for SourceInformationSeedIndex information_seed_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sourceinformationseedindex_information_seed_id') THEN
        CREATE INDEX idx_sourceinformationseedindex_information_seed_id ON SourceInformationSeedIndex(information_seed_id);
    END IF;
END
$$;


-- Indexes for the SourceOwnerIndex table ---------------------------------------

-- Creates an index for SourceOwnerIndex source_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sourceownerindex_source_id') THEN
        CREATE INDEX idx_sourceownerindex_source_id ON SourceOwnerIndex(source_id);
    END IF;
END
$$;

-- Creates an index for SourceOwnerIndex owner_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_sourceownerindex_owner_id') THEN
        CREATE INDEX idx_sourceownerindex_owner_id ON SourceOwnerIndex(owner_id);
    END IF;
END
$$;


-- Indexes for the SourceSearchIndex table ---------------------------------------

-- Creates an index for the SourceSearchIndex source_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_ssi_source_id') THEN
        CREATE INDEX idx_ssi_source_id ON SourceSearchIndex(source_id);
    END IF;
END
$$;

-- Creates an index for the SourceSearchIndex index_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_ssi_index_id') THEN
        CREATE INDEX idx_ssi_index_id ON SourceSearchIndex(index_id);
    END IF;
END
$$;


-- Indexes for WebObjectsIndex table -----------------------------------------

-- Creates an index for the WebObjectsIndex index_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_woi_index_id') THEN
        CREATE INDEX idx_woi_index_id ON WebObjectsIndex(index_id);
    END IF;
END
$$;

-- Creates an index for the WebObjectsIndex object_id column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_woi_object_id') THEN
        CREATE INDEX idx_woi_object_id ON WebObjectsIndex(object_id);
    END IF;
END
$$;

--------------------------------------------------------------------------------
-- Full Text Search setup

-- SearchIndex Full Text Search (FTS)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'searchindex'
        AND column_name = 'tsv'
    ) THEN
        ALTER TABLE SearchIndex ADD COLUMN tsv tsvector;
    END IF;
END
$$;

-- Update the tsvector column
UPDATE SearchIndex SET tsv = to_tsvector('english', coalesce(page_url, '') || ' ' || coalesce(title, '') || ' ' || coalesce(summary, ''));

-- Create a trigger to update the tsvector column
CREATE OR REPLACE FUNCTION searchindex_tsv_trigger() RETURNS trigger AS $$
BEGIN
    NEW.tsv := to_tsvector('english', coalesce(NEW.page_url, '') || ' ' || coalesce(NEW.title, '') || ' ' || coalesce(NEW.summary, ''));
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Creates an index for the SearchIndex tsv column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_searchindex_tsv') THEN
        CREATE INDEX idx_searchindex_tsv ON SearchIndex USING gin(tsv);
    END IF;
END
$$;

-- WebObjects Full Text Search (FTS)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name  = 'webobjects'
        AND   column_name = 'object_content_fts'
    ) THEN
        ALTER TABLE WebObjects ADD COLUMN object_content_fts tsvector;
    END IF;
END
$$;

-- Create a trigger to update the tsvector column for WebObjects
CREATE OR REPLACE FUNCTION webobjects_content_trigger() RETURNS trigger AS $$
BEGIN
  NEW.object_content_fts := to_tsvector('english', coalesce(NEW.object_content, ''));
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_webobjects_content') THEN
        CREATE TRIGGER trg_webobjects_content BEFORE INSERT OR UPDATE
        ON WebObjects FOR EACH ROW EXECUTE FUNCTION webobjects_content_trigger();
    END IF;
END
$$;

--------------------------------------------------------------------------------
-- Functions and Triggers setup

-- Creates a function to update the last_updated_at column
CREATE OR REPLACE FUNCTION update_last_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creates a trigger to update the last_updated_at column on Sources table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_sources_last_updated_before_update') THEN
		CREATE TRIGGER trg_update_sources_last_updated_before_update
		BEFORE UPDATE ON Sources
		FOR EACH ROW
		EXECUTE FUNCTION update_last_updated_at_column();
	END IF;
END
$$;

-- Create a trigger to update the last_updated_at column for InformationSeed table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_information_seed_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_information_seed_last_updated_before_update
        BEFORE UPDATE ON InformationSeed
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Create a trigger to update the last_updated_at column for SourceInformationSeedIndex table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_sourceinformationseedidx_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_sourceinformationseedidx_last_updated_before_update
        BEFORE UPDATE ON SourceInformationSeedIndex
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on SearchIndex table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_searchindex_last_updated_before_update') THEN
		CREATE TRIGGER trg_update_searchindex_last_updated_before_update
		BEFORE UPDATE ON SearchIndex
		FOR EACH ROW
		EXECUTE FUNCTION update_last_updated_at_column();
	END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on Owners table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_owners_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_owners_last_updated_before_update
        BEFORE UPDATE ON Owners
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on NetInfo table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_netinfo_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_netinfo_last_updated_before_update
        BEFORE UPDATE ON NetInfo
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on HTTPInfo table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_httpinfo_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_httpinfo_last_updated_before_update
        BEFORE UPDATE ON HTTPInfo
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on WebObjects table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_webobjects_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_webobjects_last_updated_before_update
        BEFORE UPDATE ON WebObjects
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on MetaTags table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_metatags_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_metatags_last_updated_before_update
        BEFORE UPDATE ON MetaTags
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on Keywords table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_keywords_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_keywords_last_updated_before_update
        BEFORE UPDATE ON Keywords
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on SourceOwnerIndex table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_sourceowner_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_sourceowner_last_updated_before_update
        BEFORE UPDATE ON SourceOwnerIndex
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on SourceSearchIndex table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_ssi_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_ssi_last_updated_before_update
        BEFORE UPDATE ON SourceSearchIndex
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Creates a trigger to update the last_updated_at column on KeywordIndex table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_update_keywordindex_last_updated_before_update') THEN
        CREATE TRIGGER trg_update_keywordindex_last_updated_before_update
        BEFORE UPDATE ON KeywordIndex
        FOR EACH ROW
        EXECUTE FUNCTION update_last_updated_at_column();
    END IF;
END
$$;

-- Function to handle orphaned records in the HTTPInfo and NetInfo tables
CREATE OR REPLACE FUNCTION cleanup_orphaned_httpinfo()
RETURNS void AS $$
BEGIN
    DELETE FROM HTTPInfo
    WHERE NOT EXISTS (
        SELECT 1 FROM HTTPInfoIndex
        WHERE HTTPInfo.httpinfo_id = HTTPInfoIndex.httpinfo_id
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_orphaned_netinfo()
RETURNS void AS $$
BEGIN
    DELETE FROM NetInfo
    WHERE NOT EXISTS (
        SELECT 1 FROM NetInfoIndex
        WHERE NetInfo.netinfo_id = NetInfoIndex.netinfo_id
    );
END;
$$ LANGUAGE plpgsql;

-- Function to handle the deletion of shared entities when no longer linked to any Source.
CREATE OR REPLACE FUNCTION handle_shared_entity_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'metatagsindex' THEN
        IF (SELECT COUNT(*) FROM MetaTagsIndex WHERE metatag_id = OLD.metatag_id) = 0 THEN
            DELETE FROM MetaTags WHERE metatag_id = OLD.metatag_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'webobjectsindex' THEN
        IF (SELECT COUNT(*) FROM WebObjectsIndex WHERE object_id = OLD.object_id) = 0 THEN
            DELETE FROM WebObjects WHERE object_id = OLD.object_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'keywordindex' THEN
        IF (SELECT COUNT(*) FROM KeywordIndex WHERE keyword_id = OLD.keyword_id) = 0 THEN
            DELETE FROM Keywords WHERE keyword_id = OLD.keyword_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'netinfoindex' THEN
        IF (SELECT COUNT(*) FROM NetInfoIndex WHERE netinfo_id = OLD.netinfo_id) = 0 THEN
            DELETE FROM NetInfo WHERE netinfo_id = OLD.netinfo_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'httpinfoindex' THEN
        IF (SELECT COUNT(*) FROM HTTPInfoIndex WHERE httpinfo_id = OLD.httpinfo_id) = 0 THEN
            DELETE FROM HTTPInfo WHERE httpinfo_id = OLD.httpinfo_id;
        END IF;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers to handle the deletion of shared entities.

-- Creates a trigger to handle the deletion of shared entities when no longer linked to any Source.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_after_delete_metatagsindex') THEN
        CREATE TRIGGER trg_after_delete_metatagsindex
        AFTER DELETE ON MetaTagsIndex
        FOR EACH ROW
        EXECUTE FUNCTION handle_shared_entity_deletion();
    END IF;
END
$$;

-- Creates a trigger to handle the deletion of shared entities when no longer linked to any Source.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_after_delete_webobjectsindex') THEN
        CREATE TRIGGER trg_after_delete_webobjectsindex
        AFTER DELETE ON WebObjectsIndex
        FOR EACH ROW
        EXECUTE FUNCTION handle_shared_entity_deletion();
    END IF;
END
$$;

-- Creates a trigger to handle the deletion of shared entities when no longer linked to any Source.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_after_delete_keywordindex') THEN
        CREATE TRIGGER trg_after_delete_keywordindex
        AFTER DELETE ON KeywordIndex
        FOR EACH ROW
        EXECUTE FUNCTION handle_shared_entity_deletion();
    END IF;
END
$$;

-- Creates a trigger to handle the deletion of shared entities when no longer linked to any Source.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_after_delete_netinfoindex') THEN
        CREATE TRIGGER trg_after_delete_netinfoindex
        AFTER DELETE ON NetInfoIndex
        FOR EACH ROW
        EXECUTE FUNCTION handle_shared_entity_deletion();
    END IF;
END
$$;

-- Creates a trigger to handle the deletion of shared entities when no longer linked to any Source.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_after_delete_httpinfoindex') THEN
        CREATE TRIGGER trg_after_delete_httpinfoindex
        AFTER DELETE ON HTTPInfoIndex
        FOR EACH ROW
        EXECUTE FUNCTION handle_shared_entity_deletion();
    END IF;
END
$$;

-- Function to handle the deletion of SearchIndex entries when no longer linked to any Source.
CREATE OR REPLACE FUNCTION handle_searchindex_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if there are no more links in SourceSearchIndex for the index_id of the deleted row
    IF (SELECT COUNT(*) FROM SourceSearchIndex WHERE index_id = OLD.index_id) = 0 THEN
        -- If no more links exist, delete the SearchIndex entry
        DELETE FROM SearchIndex WHERE index_id = OLD.index_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Creates a trigger to handle the deletion of SearchIndex entries when no longer linked to any Source.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_after_delete_source_searchindex') THEN
        CREATE TRIGGER trg_after_delete_source_searchindex
        AFTER DELETE ON SourceSearchIndex
        FOR EACH ROW EXECUTE FUNCTION handle_searchindex_deletion();
    END IF;
END
$$;

-- Ensure that the ON CASCADE DELETE is defined correctly:
ALTER TABLE Screenshots DROP CONSTRAINT IF EXISTS screenshots_index_id_fkey;
ALTER TABLE Screenshots ADD CONSTRAINT screenshots_index_id_fkey FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE;
ALTER TABLE webobjectsindex DROP CONSTRAINT IF EXISTS webobjectsindex_index_id_fkey;
ALTER TABLE webobjectsindex ADD CONSTRAINT webobjectsindex_index_id_fkey FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE;
ALTER TABLE metatagsindex DROP CONSTRAINT IF EXISTS metatagsindex_index_id_fkey;
ALTER TABLE metatagsindex ADD CONSTRAINT metatagsindex_index_id_fkey FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE;
ALTER TABLE keywordindex DROP CONSTRAINT IF EXISTS keywordindex_index_id_fkey;
ALTER TABLE keywordindex ADD CONSTRAINT keywordindex_index_id_fkey FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE;
ALTER TABLE netinfoindex DROP CONSTRAINT IF EXISTS netinfoindex_index_id_fkey;
ALTER TABLE netinfoindex ADD CONSTRAINT netinfoindex_index_id_fkey FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE;
ALTER TABLE httpinfoindex DROP CONSTRAINT IF EXISTS httpinfoindex_index_id_fkey;
ALTER TABLE httpinfoindex ADD CONSTRAINT httpinfoindex_index_id_fkey FOREIGN KEY (index_id) REFERENCES SearchIndex(index_id) ON DELETE CASCADE;

-- Creates a function to fetch and update the sources as an atomic operation
-- this is required to be able to deploy multiple crawlers without the risk of
-- fetching the same source multiple times
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_sources') THEN
        DROP FUNCTION update_sources(INTEGER, VARCHAR);
    END IF;
END
$$;
CREATE OR REPLACE FUNCTION update_sources(limit_val INTEGER, engineID VARCHAR)
RETURNS TABLE(source_id BIGINT, url TEXT, restricted INT, flags INT, config JSONB, last_updated_at TIMESTAMP) AS
$$
BEGIN
    RETURN QUERY
    WITH SelectedSources AS (
        SELECT s.source_id
        FROM Sources AS s
        WHERE s.disabled = FALSE
          AND (
               (s.last_updated_at IS NULL OR s.last_updated_at < NOW() - INTERVAL '3 days')
            OR (s.status = 'error' AND s.last_updated_at < NOW() - INTERVAL '15 minutes')
            OR (s.status = 'completed' AND s.last_updated_at < NOW() - INTERVAL '1 week')
            OR s.status = 'pending' OR s.status = 'new' OR s.status IS NULL
          )
        FOR UPDATE
        LIMIT limit_val
    )
    UPDATE Sources
        SET status = 'processing',
            engine = engineID
    WHERE Sources.source_id IN (SELECT SelectedSources.source_id FROM SelectedSources)
    RETURNING Sources.source_id, Sources.url, Sources.restricted, Sources.flags, Sources.config, Sources.last_updated_at;
END;
$$
LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Special function for data correlation

CREATE OR REPLACE FUNCTION find_correlated_sources_by_domain(domain TEXT)
RETURNS TABLE (
    source_id BIGINT,
    url TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH PartnerSourcesFromNetInfo AS (
        SELECT DISTINCT ssi.source_id
        FROM NetInfo ni
        JOIN NetInfoIndex nii ON ni.netinfo_id = nii.netinfo_id
        JOIN SourceSearchIndex ssi ON nii.index_id = ssi.index_id
        WHERE ni.details::text LIKE '%' || domain || '%'
    ),
    PartnerSourcesFromHTTPInfo AS (
        SELECT DISTINCT ssi.source_id
        FROM HTTPInfo hi
        JOIN HTTPInfoIndex hii ON hi.httpinfo_id = hii.httpinfo_id
        JOIN SourceSearchIndex ssi ON hii.index_id = ssi.index_id
        WHERE hi.details::text LIKE '%' || domain || '%'
    ),
    PartnerSourcesFromWebObjects AS (
        SELECT DISTINCT ssi.source_id
        FROM WebObjects wo
        JOIN WebObjectsIndex woi ON wo.object_id = woi.object_id
        JOIN SourceSearchIndex ssi ON woi.index_id = ssi.index_id
        WHERE wo.details::text LIKE '%' || domain || '%'
    ),
    AllPartnerSources AS (
        SELECT psni.source_id FROM PartnerSourcesFromNetInfo psni
        UNION
        SELECT pshi.source_id FROM PartnerSourcesFromHTTPInfo pshi
        UNION
        SELECT pswo.source_id FROM PartnerSourcesFromWebObjects pswo
    )

    SELECT DISTINCT s.source_id, s.url
    FROM Sources s
    JOIN AllPartnerSources aps ON s.source_id = aps.source_id;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- User and permissions setup

-- Helper functions:

CREATE OR REPLACE FUNCTION grant_sequence_permissions(schema_name text, target_user text)
RETURNS void AS
$$
DECLARE
    sequence_record record;
BEGIN
    FOR sequence_record IN SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = schema_name
    LOOP
        EXECUTE format('GRANT USAGE, SELECT, UPDATE ON SEQUENCE %I.%I TO %I', schema_name, sequence_record.sequence_name, target_user);
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- Creates a new user
CREATE USER :CROWLER_DB_USER WITH ENCRYPTED PASSWORD :'CROWLER_DB_PASSWORD';

-- Grants permissions to the user on the :"POSTGRES_DB" database
GRANT CONNECT ON DATABASE :"POSTGRES_DB" TO :CROWLER_DB_USER;
GRANT USAGE ON SCHEMA public TO :CROWLER_DB_USER;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO :CROWLER_DB_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO :CROWLER_DB_USER;
ALTER ROLE :CROWLER_DB_USER SET search_path TO public;
ALTER TABLE searchindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE keywordindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE sourceownerindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE sourceinformationseedindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE informationseed OWNER TO :CROWLER_DB_USER;
ALTER TABLE sourcesearchindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE webobjectsindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE metatagsindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE netinfoindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE httpinfoindex OWNER TO :CROWLER_DB_USER;
ALTER TABLE netinfo OWNER TO :CROWLER_DB_USER;
ALTER TABLE httpinfo OWNER TO :CROWLER_DB_USER;
ALTER TABLE webobjects OWNER TO :CROWLER_DB_USER;
ALTER TABLE metatags OWNER TO :CROWLER_DB_USER;
ALTER TABLE sources OWNER TO :CROWLER_DB_USER;
ALTER TABLE owners OWNER TO :CROWLER_DB_USER;
ALTER TABLE screenshots OWNER TO :CROWLER_DB_USER;
ALTER TABLE keywords OWNER TO :CROWLER_DB_USER;
ALTER TABLE events OWNER TO :CROWLER_DB_USER;
ALTER TABLE categories OWNER TO :CROWLER_DB_USER;

-- Grants permissions to the user on the :"POSTGRES_DB" database
SELECT grant_sequence_permissions('public', :'CROWLER_DB_USER');
