#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        add_zotero <zotero.ods> [DB]
# Purpose:      add_zotero - adds zotero citations to the database from LibreOffice spreadsheet
# Returns:      Sets EX_OK exit code.
# Parameteres:  <zotero.ods> is the LibreOffice spreadsheet containing the zotero citations to add.
#               If <zotero.ods> is not specified then the default file will be used.
#               The worksheet in <zotero.ods> MUST be named "zotero_new".
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
SCRIPT_NAME="${0##*/}"                # Get the name of the current script includes the extension if any.

ols_err "$QID" "0000" "$EX_OK" "$SCRIPT_NAME: Begin"

SQL="$OLS_TMP_DIR/sql.sql"            # Temporary SQL file for importing zotero citations.

ODS="$1"                              # The LibreOffice spreadsheet containing the zotero citations to add.
DB="$2"                               # The database name passed as the second argument to the script.

if [[ -z "$ODS" ]]; then              # filename Argument Required
    ODS="raw_zotero.ods"              # Use the default data file if no argument is provided.
    ols_err "$QID" "5038" "$EX_OK" "$SCRIPT_NAME: Using default data file: $ODS."
else
    ols_err "$QID" "5039" "$EX_OK" "$SCRIPT_NAME: Using specified data file: $ODS."
fi

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "$SCRIPT_NAME: Using default database: $DB"
else
    ols_err "$QID" "5012" "$EX_OK" "$SCRIPT_NAME: Using specified database: $DB"
fi

declare FILENAME="$ODS"

NAME="${FILENAME##*/}"                # Drop the directory path, leaving only the file name.
FILEBASE="${NAME%.*}"                 # Drop the file extension, leaving only the base name.

# Now we know what the names of the CVS files LibreOffice will create.
ZOT="${FILEBASE}-zotero_ref_new.csv"  # CSV file containing the new zotero citations.

ONUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM zotero_refs;")
ols_err "$QID" "5034" "$EX_OK" "Initial number of zotero citations in the database: $ONUM"

# ============ Convert the LibreOffice spreadsheet to CSV files ============

soffice --headless --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,false,true,false,false,false,-1 "$ODS" >/dev/null; EX_CODE=$?

if [[ "$EX_CODE" -ne 0 ]]; then
    ols_err "$QID" "5013" "$EX_CODE" "LibreOffice conversion failed with exit code $EX_CODE."
    exit
fi

# ============ Verify the number of zotero citations in the raw data ============

NNUM=$(csvstat --columns 1 --count "$ZOT" )

if [[ $NNUM -eq 0 ]]; then
    ols_err "$QID" "5032" "$EX_FATAL" "No zotero citations found in the raw data."
    exit
else
    ols_err "$QID" "5033" "$EX_OK" "Number of zotero citations in raw data: $NNUM"
fi

# ============ We now have the temporary CSV file created and verified. ============

# Count the initial number of zotero citations in the database.

# ============ Import the raw data into the database. ============

sqlite3 "$DB" << /*                   # Import the raw data into the into the database.
.mode csv
.bail on

.import --skip 1 "$ZOT" zotero_refs

.exit
/*
EX_CODE=$?

if [[ $EX_CODE -ne 0 ]]; then
    ols_err "$QID" "5035" "$EX_FATAL" "Import failed. Exit code: $EX_CODE"
    exit 
fi

ENUM=$(($NNUM - $ONUM))               # Expect to have added NNUM creators to the database.
ols_err "$QID" "5010" "$EX_OK" "Expected number of creators to be added: $ENUM"

NUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM zotero_refs;")  # Grab the count of zotero citations found.
ols_err "$QID" "5011" "$EX_OK" "Actual number of zotero citations in the database after insertion: $NUM"

if [[ "$NUM" -ne $ENUM ]]; then
    ols_err "$QID" "5008" "$EX_FATAL" "Mismatch between expected and actual number of zotero citations in the database."
fi  


rm -f "$ZOT"

ols_err "$QID" "9999" "$EX_OK" "$SCRIPT_NAME: End"
ols_end
