#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        cnt_quotes_type TYPE [DB] 
# Purpose:      cnt_quotes_type counts the number of quote types in the DB
# Returns:      The number of TYPE quotes in the DB
# Exit Codes:   Sets EX_OK exit code.
# Parameteres:  TYPE is the quote type to count, e.g. "Fortran"
#               DB is the quote database you want to check
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

SQL="$OLS_TMP_DIR/cnt_quotes.sql"     # Temporary SQL file for checking quotes.
HLD="$OLS_TMP_DIR/cnt_quotes.txt"     # Temporary HLD file for checking quotes.

TYPE="$1"                             # The quote type to count.
DB="$2"                               # The database name passed as the second argument to the script.

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "Using default database: $DB"
fi

cat > "$SQL" <</*                     # A throw back to my old OS/360 days.
.mode list
.headers off

SELECT COUNT(*)                                -- We want a count
FROM quotes q                                  -- Alias the quotes table as q.
JOIN quote_type qty ON q.qid = qty.qid
JOIN quote_type_list qt ON qty.qtid = qt.qtid
WHERE qt.qtype = '$TYPE';

.exit
/*

sqlite3 "$DB" < "$SQL" > "$HLD"       # Execute the SQL query and save the output to the HLD file.

NUM=$(cat "$HLD")                     # Grab the count of quotes found.

if [[ "$NUM" -eq 0 ]]; then
    ols_err "$QID" "5004" "$EX_MISSINGFILE" "No '$TYPE' quotes found."
    exit
else
    ols_err "$QID" "5005" "$EX_OK" "Found $NUM '$TYPE' quote(s)."
fi

ols_end
