#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        add_creators [creator.ods] [DB]
# Purpose:      add_creators adds creators to the database.
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

DEFAULT_DB="/mnt/d/db/quotes.sqlite"  # Default database path.

readonly QID="QID"                    # The identifier use d in Olaus error messages.
SCRIPT_NAME="${0##*/}"                # Get the name of the current script includes the extension if any.

ols_err "$QID" "0000" "$EX_OK" "$SCRIPT_NAME: Begin"

SQL="$OLS_TMP_DIR/chk_quotes.sql"     # Temporary SQL file for checking quotes.
HLD="$OLS_TMP_DIR/chk_quotes.txt"     # Temporary HLD file for checking quotes.


ODS="$1"                              # The LibreOffice spreadsheet containing the creators to add.
DB="$2"                               # The database name passed as the second argument to the script.

if [[ -z "$ODS" ]]; then              # filename Argument Required
    ODS="raw_creators.ods"            # Use the default data file if no argument is provided.
    ols_err "$QID" "5038" "$EX_OK" "$SCRIPT_NAME: Using default data file: $ODS."
else
    ols_err "$QID" "5039" "$EX_OK" "$SCRIPT_NAME: Using specified data file: $ODS."
fi



if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "Using default database: $DB"
else
    ols_err "$QID" "5002" "$EX_OK" "Using specified database: $DB"
fi

declare FILENAME="$ODS"

NAME="${FILENAME##*/}"                # Drop the directory path, leaving only the file name.
FILEBASE="${NAME%.*}"                 # Drop the file extension, leaving only the base name.

# Now we know what the names of the CVS files LibreOffice will create.
CRE="${FILEBASE}-creators_new.csv"    # Extracted but unused used to set the number of

ONUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM creators;")
ols_err "$QID" "5007" "$EX_OK" "Initial number of creators in the database: $ONUM"

# ============ Convert the LibreOffice spreadsheet to CSV files ============

soffice --headless --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,false,true,false,false,false,-1 "$ODS" >/dev/null; EX_CODE=$?

if [[ "$EX_CODE" -ne 0 ]]; then
    ols_err "$QID" "5013" "$EX_CODE" "LibreOffice conversion failed with exit code $EX_CODE."
    exit
fi

NNUM=$(csvstat --columns 1 --count "$CRE" )

cat > "$SQL" <</*                     # A throw back to my old OS/360 days.
.mode csv
.headers off
.import --skip 1 "$CRE" creators

SELECT COUNT(*)                      -- Select the count of creators that do not have a corresponding entry in the creator_quote table.
FROM creators;

.exit
/*

sqlite3 "$DB" < "$SQL" > "$HLD"       # Execute the SQL query and save the output to the HLD file.

ENUM=$(($NNUM - $ONUM))               # Expect to have added NNUM creators to the database.
ols_err "$QID" "5010" "$EX_OK" "Expected number of creators to be added: $ENUM"

NUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM creators;")                     # Grab the count of quotes found.
ols_err "$QID" "5011" "$EX_OK" "Actual number of creators in the database after insertion: $NUM"

if [[ "$NUM" -ne $ENUM ]]; then
    ols_err "$QID" "5008" "$EX_FATAL" "Mismatch between expected and actual number of creators in the database."
fi

rm "$CRE" "$SQL" "$HLD"               # Clean up temporary files.

ols_err "$QID" "9999" "$EX_OK" "$SCRIPT_NAME: End"

ols_end
