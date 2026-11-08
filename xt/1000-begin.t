#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        1000-begin
# Purpose:      1000_begin - create a test quote database.
# Returns:      Sets EX_OK exit code.
# Parameteres:  [creator.ods] is the LibreOffice spreadsheet containing the creators to add
#               If creator.ods is not specified then the default file will be used.
#               [DB] is the quote database you want to check
#               If DB is not specified then the default database will be used.
# Throws:       None
# Comments:     None
# See Also:     Olaus Bash Shell Library
# Source:       bash
#
#===================================================================================================

# shellcheck source=/home/mjj/.local/lib/b_ols.lib
source "$OLSLIB"                      # Use the Olaus Bash Shell Library.

source ols_err.sh                     # Use the updated ols_err until the library is updated.

QID="QID"                             # Use the Olaus Bash Shell Library identifier.
SCRIPT_NAME="${0##*/}"                # Get the name of the current script includes the extension if any.

ols_err "$QID" "0000" "$EX_OK" "$SCRIPT_NAME: Begin"

DB="var/tst_quote.sqlite"             # This is the quote test database.
rm -f "$DB"                           # Start with a clean quote test database.

# Initialize the quote test database tables.
sqlite3 "$DB" <</*
CREATE TABLE [creators](
  [aid] TEXT(24) PRIMARY KEY, 
  [family] VARCHAR, 
  [given] VARCHAR, 
  [middle] VARCHAR, 
  [nick] VARCHAR, 
  [prefix] VARCHAR, 
  [postfix] VARCHAR, 
  [twitter] VARCHAR);

CREATE TABLE quotes (                -- Table storing quotes with their unique identifiers.
    qid     TEXT(24) PRIMARY KEY,    -- CUID2 Unique identifier for the quote.
    quote   VARCHAR  NOT NULL        -- The text of the quote.
);

CREATE TABLE [creator_quote](
  [qid] TEXT(24) NOT NULL REFERENCES [quotes]([qid]), 
  [aid] TEXT(24) NOT NULL REFERENCES [creators]([aid]), 
  PRIMARY KEY([aid], [qid]));

CREATE TABLE "quote_type_list" (     -- Table storing quote types with their unique identifiers.  
    qtid    TEXT(24) PRIMARY KEY,    -- CUID2 Unique identifier for the quote type.
    qtype   VARCHAR  NOT NULL        -- The name of the quote type, e.g., "Fortran".
);

CREATE TABLE quote_type (                               -- Associate quotes with their types.
  qid  TEXT(24) NOT NULL REFERENCES quotes(qid),        -- CUID2 Unique identifier for the quote.
  qtid TEXT(24) NOT NULL REFERENCES quote_type_list(qtid),  -- CUID2 Unique identifier for the quote type.
  PRIMARY KEY (qid, qtid)                               -- Composite primary key ensuring each quote-type combination is unique.
);

CREATE TABLE zotero_refs (           -- References to Zotero items.
    rid     TEXT(24) PRIMARY KEY,    -- CUID2 Unique identifier for the reference.
    zkey    VARCHAR  NOT NULL        -- Zotero citation key for the reference.
);

CREATE TABLE [ref_quote](
  [qid] TEXT(24) NOT NULL REFERENCES [quotes]([qid]), 
  [rid] TEXT(24) NOT NULL REFERENCES [zotero_refs]([rid]), 
  PRIMARY KEY([rid], [qid]));

CREATE VIEW creator_display AS
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

/*

# These spreadsheets contain the initial data for the quote test database.
CRE="var/first_creators.ods"
ZOT="var/first_zotero.ods"
TYP="var/first_quote_type_list.ods"
QUO="var/first_quotes.ods"

# Begin the test plan for the quote test database.
test_plan 3


../bin/add_creators "$CRE" "$DB"
NUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM creators;")
is "$NUM" "14" "check_creators_count" "Expected 14 creators, got $NUM"

../bin/add_zotero "$ZOT" "$DB"
NUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM zotero_refs;")
is "$NUM" "2" "check_zotero_count" "Expected 2 zotero refs, got $NUM"

#../bin/add_quote_type_list "$TYP" "$DB"
#NUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM quote_type_list;")
#is "$NUM" "14" "check_quote_type_list_count" "Expected 14 quote types, got $NUM"

../bin/add_quotes "$QUO" "$DB"
NUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM quotes;")
is "$NUM" "10" "check_quotes_count" "Expected 14 quotes, got $NUM"

ols_err "$QID" "9999" "$EX_OK" "$SCRIPT_NAME: End"
ols_end
