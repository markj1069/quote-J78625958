-- Schema for managing creators, quotes, quote types, and Zotero references.

CREATE TABLE [creators](
  [aid] TEXT(24) PRIMARY KEY,        -- CUID2 Unique identifier for the creator.
  [family] VARCHAR,                  -- Family name of the creator.
  [given] VARCHAR,                   -- Given name of the creator.
  [middle] VARCHAR,                  -- Middle name of the creator.
  [nick] VARCHAR,                    -- Nickname of the creator.
  [prefix] VARCHAR,                  -- Prefix of the creator (e.g., "Dr.").
  [postfix] VARCHAR,                 -- Postfix of the creator (e.g., "PhD").
  [twitter] VARCHAR);                -- Twitter handle of the creator.

CREATE TABLE quotes (                -- Table storing quotes with their unique identifiers.
    qid     TEXT(24) PRIMARY KEY,    -- CUID2 Unique identifier for the quote.
    quote   VARCHAR  NOT NULL        -- The text of the quote.
);

CREATE TABLE [creator_quote](
  [qid] TEXT(24) NOT NULL REFERENCES [quotes]([qid]),    -- CUID2 Unique identifier for the quote.
  [aid] TEXT(24) NOT NULL REFERENCES [creators]([aid]),  -- CUID2 Unique identifier for the creator.
  PRIMARY KEY([aid], [qid]));

CREATE TABLE "quote_type_list" (     -- Table storing quote types with their unique identifiers.  
    qtid    TEXT(24) PRIMARY KEY,    -- CUID2 Unique identifier for the quote type.
    qtype   VARCHAR  NOT NULL        -- The name of the quote type, e.g., "Fortran".
);

CREATE TABLE quote_type (                                   -- Associate quotes with their types.
  qid  TEXT(24) NOT NULL REFERENCES quotes(qid),            -- CUID2 Unique identifier for the quote.
  qtid TEXT(24) NOT NULL REFERENCES quote_type_list(qtid),  -- CUID2 Unique identifier for the quote type.
  PRIMARY KEY (qid, qtid)                                   -- Composite primary key ensuring each quote-type combination is unique.
);

CREATE TABLE zotero_refs (           -- References to Zotero items.
    rid     TEXT(24) PRIMARY KEY,    -- CUID2 Unique identifier for the reference.
    zkey    VARCHAR  NOT NULL        -- Zotero citation key for the reference.
);

CREATE TABLE [ref_quote](
  [qid] TEXT(24) NOT NULL REFERENCES [quotes]([qid]),       -- CUID2 Unique identifier for the quote.
  [rid] TEXT(24) NOT NULL REFERENCES [zotero_refs]([rid]),  -- CUID2 Unique identifier for the reference.
  PRIMARY KEY([rid], [qid]));                               -- Composite primary key ensuring each reference-quote combination is unique.

CREATE VIEW creator_display AS       -- View for displaying creator information with a computed display name.
SELECT
    c.aid,
    c.family,

    c.given,
    c.middle,
    c.nick,
    c.prefix,
    c.postfix,
    c.twitter,
    COALESCE(
        NULLIF(TRIM(COALESCE(c.given, '') || ' ' || COALESCE(c.family, '')), ''),
        NULLIF(TRIM(c.nick), ''),
        NULLIF(TRIM(c.twitter), ''),
        'Anonymous'
    ) AS display_name
FROM creators c;
