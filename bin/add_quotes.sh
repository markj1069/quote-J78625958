#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        add_quotes <data.ods> [DB]
# Purpose:      add_quotes - adds quotes to the database from LibreOffice spreadsheet
# Returns:      Sets EX_OK exit code.
# Parameteres:  <data.ods> is the LibreOffice spreadsheet containing the quotes to add
#               [DB] is the quote database you want to update
#               If DB is not specified then the default database will be used.
# Throws:       None
# Comments:     None
# See Also:     Olaus Bash Shell Library
# Source:       
#
#===================================================================================================

# shellcheck source=/home/mjj/.local/lib/b_ols.lib
source "$OLSLIB"                      # Use the Olaus Bash Shell Library.

DEFAULT_DB="/mnt/d/db/quotes.sqlite"  # Default database path.

readonly QID="QID"                    # The identifier use d in Olaus error messages.
SCRIPT_NAME="${0##*/}"                # Get the name of the current script includes the extension if any.
ols_err "$QID" "0000" "$EX_OK" "$SCRIPT_NAME: Begin"

SQL="$OLS_TMP_DIR/chk_quotes.sql"                  # Temporary SQL file for checking quotes.

ODS="$1"                              # The LibreOffice spreadsheet containing the quotes to add.
DB="$2"                               # The database name passed as the second argument to the script.

if [[ -z "$ODS" ]]; then              # filename Argument Required
    ODS="raw_quote.ods"               # Use the default data file if no argument is provided.
    ols_err "$QID" "5038" "$EX_OK" "$SCRIPT_NAME: Using default data file: $ODS."
else
    ols_err "$QID" "5039" "$EX_OK" "$SCRIPT_NAME: Using specified data file: $ODS."
fi
declare FILENAME="$ODS"

FILEBASE=$(basename "$FILENAME" .ods)  # Pull out the base name of the file without the extension.

# Now we know what the names of the CVS files LibreOffice will create.
RAW="${FILEBASE}-raw_data.csv"           # Extracted but unused used to set the number of
QUO="${FILEBASE}-quotes_new.csv"         # Temporary file for storing new quotes.
CQU="${FILEBASE}-creator_quote_new.csv"  # Temporary file for storing new creator-quote relationships.
RQU="${FILEBASE}-ref_quote_new.csv"      # Temporary file for storing new Zotero-quote entries.
QTY="${FILEBASE}-quote_type_new.csv"     # Temporary file for storing new quote types.

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "$SCRIPT_NAME: Using default database: $DB"
else
    ols_err "$QID" "5012" "$EX_OK" "$SCRIPT_NAME: Using specified database: $DB"
fi

# ============ Convert the LibreOffice spreadsheet to CSV files ============

soffice --headless --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,false,true,false,false,false,-1 "$ODS" >/dev/null; EX_CODE=$?

if [[ "$EX_CODE" -ne 0 ]]; then
    ols_err "$QID" "5013" "$EX_CODE" "LibreOffice conversion failed with exit code $EX_CODE."
    exit
fi

# ============ Remove empty records from CSV files ============

sed '/^[[:space:]]*,[[:space:]]*$/d' "$RAW" > raw_data.csv           # Remove empty records from the raw data CSV file (There should be none.)
sed '/^[[:space:]]*,[[:space:]]*$/d' "$QUO" > quotes_new.csv         # Remove empty records from the quotes CSV file.
sed '/^[[:space:]]*,[[:space:]]*$/d' "$CQU" > creator_quote_new.csv  # Remove empty records from the creator-quote CSV file.
sed '/^[[:space:]]*,[[:space:]]*$/d' "$RQU" > ref_quote_new.csv      # Remove empty records from the reference-quote CSV file.
sed '/^[[:space:]]*,[[:space:]]*$/d' "$QTY" > quote_type_new.csv     # Remove empty records from the quote-type CSV file.
 
# ============ Verify the number of quotes in the raw data ============

# Use csvstat to count the number of unique quotes in the raw data because the quote may have multiple lines.
NQUOTES=$(csvstat --columns 1 --count "raw_data.csv");  # csvstat --count already excludes the header.
ols_err "$QID" "5013" "$EX_OK" "$SCRIPT_NAME: Number of quotes in raw data: $NQUOTES"

if [[ $NQUOTES -eq 0 ]]; then
    ols_err "$QID" "5015" "$EX_FATAL" "$SCRIPT_NAME: No quotes found in the raw data."
    exit
fi
 
NQUO=$(csvstat --columns 1 --count "quotes_new.csv");  # csvstat --count already excludes the header.
if [[ $NQUO -ne $NQUOTES ]]; then
    ols_err "$QID" "5016" "$EX_FATAL" "$SCRIPT_NAME: Number of quotes in QUO ($NQUO) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

NCQU=$(csvstat --columns 1 --count "creator_quote_new.csv");  # csvstat --count already excludes the header.
if [[ $NCQU -ne $NQUOTES ]]; then
    ols_err "$QID" "5017" "$EX_FATAL" "$SCRIPT_NAME: Number of creator-quote relationships in CQU ($NCQU) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

NRQU=$(csvstat --columns 1 --count "ref_quote_new.csv");  # csvstat --count already excludes the header.
if [[ $NRQU -ne $NQUOTES ]]; then
    ols_err "$QID" "5018" "$EX_FATAL" "$SCRIPT_NAME: Number of reference-quote relationships in RQU ($NRQU) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

NQTY=$(csvstat --columns 1 --count "quote_type_new.csv");  # csvstat --count already excludes the header.
if [[ $NQTY -ne $NQUOTES ]]; then
    ols_err "$QID" "5019" "$EX_FATAL" "$SCRIPT_NAME: Number of quote types in QTY ($NQTY) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

# ============ We now have all the temporary files created and verified. ============

# ============ Fail if any new qid already exists in the database ============

EXISTING=$(sqlite3 "$DB" <<EOF
CREATE TEMP TABLE new_qids (qid TEXT PRIMARY KEY, quote VARCHAR);
.mode csv
.import --skip 1 "quotes_new.csv" new_qids
SELECT qid FROM new_qids
WHERE qid IN (SELECT qid FROM quotes);
EOF
)

if [[ -n "$EXISTING" ]]; then
    ols_err "$QID" "5030" "$EX_FATAL" "$SCRIPT_NAME: These qids already exist in the database (import aborted):"
    while IFS= read -r q; do
        [[ -n "$q" ]] && echo "Duplicate qid: $q"
    done <<< "$EXISTING"
    exit
fi

# Count the initial number of quotes and reference-quote relationships in the database.

NQBEGIN=$(sqlite3 "$DB" "SELECT COUNT(*) FROM quotes;")    # Count the initial number of quotes in the database.
NRBEGIN=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ref_quote;")  # Count the initial number of reference-quote relationships in the database.

ols_err "$QID" "5013" "$EX_OK" "$SCRIPT_NAME: Initial number of quotes in the database: $NQBEGIN"
ols_err "$QID" "5024" "$EX_OK" "$SCRIPT_NAME: Initial number of reference-quote relationships in the database: $NRBEGIN"

# ============ Import the raw data into the database. ============

sqlite3 "$DB" << /*                   # Import the raw data into the into the database.
.mode csv
.bail on

.import --skip 1 "quotes_new.csv" quotes
.import --skip 1 "creator_quote_new.csv" creator_quote
.import --skip 1 "ref_quote_new.csv" ref_quote
.import --skip 1 "quote_type_new.csv" quote_type

.exit
/*
EX_CODE=$?

if [[ $EX_CODE -ne 0 ]]; then
    ols_err "$QID" "5022" "$EX_FATAL" "Import failed. Exit code: $EX_CODE"
    exit 
fi

NQEND=$(sqlite3 "$DB" "SELECT COUNT(*) FROM quotes;")    # Count the number of quotes in the database after insertion.
NREND=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ref_quote;")  # Count the number of reference-quote relationships in the database after insertion.

NSHOULD=$(($NQUOTES + $NQBEGIN))

if [[ "$NQEND" -ne "$NSHOULD" ]]; then
    ols_err "$QID" "5020" "$EX_FATAL" "$SCRIPT_NAME: Number of quotes in the database after insertion ($NQEND) does not match the expected number ($NSHOULD)."
    exit
else
    ols_err "$QID" "5021" "$EX_OK" "$SCRIPT_NAME: Number of quotes in the database after insertion ($NQEND) matches the expected number ($NSHOULD)."
fi 

NSHOULD=$(($NRQUOTES + $NRBEGIN))

if [[ "$NREND" -ne "$NSHOULD" ]]; then
    ols_err "$QID" "5024" "$EX_FATAL" "$SCRIPT_NAME: Number of reference-quote relationships in the database after insertion ($NREND) does not match the expected number ($NSHOULD)."
    exit
else
    ols_err "$QID" "5025" "$EX_OK" "$SCRIPT_NAME: Number of reference-quote relationships in the database after insertion ($NREND) matches the expected number ($NSHOULD)."
fi

# Delete temporary files.

rm -f "$RAW" raw_data.csv
rm -f "$QUO" quotes_new.csv
rm -f "$CQU" creator_quote_new.csv
rm -f "$RQU" ref_quote_new.csv
rm -f "$QTY" quote_type_new.csv

ols_err "$QID" "9999" "$EX_OK" "$SCRIPT_NAME: End"

ols_end
