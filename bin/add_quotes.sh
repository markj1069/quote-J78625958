#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        add_quotes data.ods [DB]
# Purpose:      add_quotes - adds quotes to the database from LibreOffice spreadsheet
# Returns:      Sets EX_OK exit code.
# Parameteres:  data.ods is the LibreOffice spreadsheet containing the quotes to add
#               DB is the quote database you want to update
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

SQL="$OLS_TMP_DIR/chk_quotes.sql"                  # Temporary SQL file for checking quotes.

ODS="$1"                              # The LibreOffice spreadsheet containing the quotes to add.
DB="$2"                               # The database name passed as the second argument to the script.

if [[ -z "$1" ]]; then                # filename Argument Required
    ols_err "$QID" "5011" "$EX_USAGE" "add_quotes: Argument #1 is missing, data.ods."
    exit
else
    declare FILENAME="$1"
fi

FILEBASE=$(basename "$FILENAME" .ods)  # Pull out the base name of the file without the extension.

echo "FILEBASE: $FILEBASE"

# Now we know what the names of the CVS files LibreOffice will create.
RAW="${FILEBASE}-raw_data.csv"           # Extracted but unused used to set the number of
QUO="${FILEBASE}-quotes_new.csv"         # Temporary file for storing new quotes.
CQU="${FILEBASE}-creator_quote_new.csv"  # Temporary file for storing new creator-quote relationships.
RQU="${FILEBASE}-ref_quote_new.csv"      # Temporary file for storing new Zotero-quote entries.
QTY="${FILEBASE}-quote_type_new.csv"     # Temporary file for storing new quote types.

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "Using default database: $DB"
else
    ols_err "$QID" "5012" "$EX_OK" "Using specified database: $DB"
fi

# ============ Convert the LibreOffice spreadsheet to CSV files ============

soffice --headless --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,false,true,false,false,false,-1 "$ODS" >/dev/null; EX_CODE=$?

if [[ "$EX_CODE" -ne 0 ]]; then
    ols_err "$QID" "5013" "$EX_CODE" "LibreOffice conversion failed with exit code $EX_CODE."
    exit
fi

# ============ Verify the number of quotes in the raw data ============

NQUOTES=$(wc -l < "$RAW"); NQUOTES=$((NQUOTES - 1))  # Subtract the header line from the count.
ols_err "$QID" "5013" "$EX_OK" "Number of quotes in raw data: $NQUOTES"

if [[ $NQUOTES -eq 0 ]]; then
    ols_err "$QID" "5015" "$EX_FATAL" "No quotes found in the raw data."
    exit
fi

NQUO=$(wc -l < "$QUO"); NQUO=$((NQUO - 1))  # Subtract the header line from the count.
if [[ $NQUO -ne $NQUOTES ]]; then
    ols_err "$QID" "5016" "$EX_FATAL" "Number of quotes in QUO ($NQUO) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

NCQU=$(wc -l < "$CQU"); NCQU=$((NCQU - 1))  # Subtract the header line from the count.
if [[ $NCQU -ne $NQUOTES ]]; then
    ols_err "$QID" "5017" "$EX_FATAL" "Number of creator-quote relationships in CQU ($NCQU) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

NRQU=$(wc -l < "$RQU"); NRQU=$((NRQU - 1))  # Subtract the header line from the count.
if [[ $NRQU -ne $NQUOTES ]]; then
    ols_err "$QID" "5018" "$EX_FATAL" "Number of reference-quote relationships in RQU ($NRQU) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

NQTY=$(wc -l < "$QTY"); NQTY=$((NQTY - 1))  # Subtract the header line from the count.
if [[ $NQTY -ne $NQUOTES ]]; then
    ols_err "$QID" "5019" "$EX_FATAL" "Number of quote types in QTY ($NQTY) does not match the number of quotes in the raw data ($NQUOTES)."
    exit
fi

# ============ We now have all the temporary files created and verified. ============

# Count the initial number of quotes and reference-quote relationships in the database.

NQBEGIN=$(sqlite3 "$DB" "SELECT COUNT(*) FROM quotes;")    # Count the initial number of quotes in the database.
NRBEGIN=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ref_quote;")  # Count the initial number of reference-quote relationships in the database.

ols_err "$QID" "5013" "$EX_OK" "Initial number of quotes in the database: $NQBEGIN"
ols_err "$QID" "5024" "$EX_OK" "Initial number of reference-quote relationships in the database: $NRBEGIN"

# ============ Import the raw data into the database. ============

sqlite3 "$DB" << /*                   # Import the raw data into the into the database.
.mode csv
.bail on

.import --skip 1 "$QUO" quotes
.import --skip 1 "$CQU" creator_quote
.import --skip 1 "$RQU" ref_quote
.import --skip 1 "$QTY" quote_type

.exit
/*
EX_CODE=$?

if [[ $EX_CODE -ne 0 ]]; then
    ols_err "$QID" "5022" "$EX_FATAL" "Import failed. Exit code: $EX_CODE"
    exit 
fi

NQEND=$(sqlite3 "$DB" "SELECT COUNT(*) FROM quotes;")    # Count the number of quotes in the database after insertion.
NREND=$(sqlite3 "$DB" "SELECT COUNT(*) FROM ref_quote;")  # Count the number of reference-quote relationships in the database after insertion.

NSHOULD=$(($NQUO + $NQBEGIN))

if [[ "$NQEND" -ne "$NSHOULD" ]]; then
    ols_err "$QID" "5020" "$EX_FATAL" "Number of quotes in the database after insertion ($NQEND) does not match the expected number ($NSHOULD)."
    exit
else
    ols_err "$QID" "5021" "$EX_OK" "Number of quotes in the database after insertion ($NQEND) matches the expected number ($NSHOULD)."
fi 

NSHOULD=$(($NRQU + $NRBEGIN))

if [[ "$NREND" -ne "$NSHOULD" ]]; then
    ols_err "$QID" "5024" "$EX_FATAL" "Number of reference-quote relationships in the database after insertion ($NREND) does not match the expected number ($NSHOULD)."
    exit
else
    ols_err "$QID" "5025" "$EX_OK" "Number of reference-quote relationships in the database after insertion ($NREND) matches the expected number ($NSHOULD)."
fi

# Delete temporary files.

rm -f "$RAW"
rm -f "$QUO"
rm -f "$CQU"
rm -f "$RQU"
rm -f "$QTY"

ols_end
