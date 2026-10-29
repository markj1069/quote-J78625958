#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        cnt_creators [DB] 
# Purpose:      cnt_creators - count the number of creators in the DB
# Returns:      The number of creators in the DB
# Exit Codes:   Sets EX_OK exit code.
# Parameteres:  DB is the quote database you want to check
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

SQL="$OLS_TMP_DIR/cnt_creators.sql"     # Temporary SQL file for checking creator(s).
HLD="$OLS_TMP_DIR/cnt_creators.txt"     # Temporary HLD file for checking creator(s)s.

DB="$1"                               # The database name passed as the argument to the script.

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "Using default database: $DB"
fi

cat > "$SQL" <</*                     # A throw back to my old OS/360 days.
.mode list
.headers off

SELECT COUNT(*)                                -- We want a count
FROM creators;                                 -- the creators

.exit
/*

sqlite3 "$DB" < "$SQL" > "$HLD"       # Execute the SQL query and save the output to the HLD file.

NUM=$(cat "$HLD")                     # Grab the count of creator(s) found.

if [[ "$NUM" -eq 0 ]]; then
    ols_err "$QID" "5006" "$EX_MISSINGFILE" "No creator(s) found."
    exit
else
    ols_err "$QID" "5007" "$EX_OK" "Found $NUM creator(s)."
fi

ols_end
