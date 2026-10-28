#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        chk_quotes [DB]
# Purpose:      chk_quotes finds quotes with out a creator.
# Returns:      Sets EX_OK exit code.
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

SQL="$OLS_TMP_DIR/chk_quotes.sql"     # Temporary SQL file for checking quotes.
HLD="$OLS_TMP_DIR/chk_quotes.txt"     # Temporary HLD file for checking quotes.


DB="$1"                               # The database name passed as the first argument to the script.

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "Using default database: $DB"
fi

cat > "$SQL" <</*                     # A throw back to my old OS/360 days.
.mode list
.headers off

SELECT COUNT(*)                      -- Select the count of quotes that do not have a corresponding entry in the creator_quote table.
FROM quotes q                        -- Alias the quotes table as q.
WHERE NOT EXISTS (                   -- Filter out quotes that have a corresponding entry in the creator_quote table.
    SELECT 1                         -- Select a constant value to check for the existence of a matching row.
    FROM creator_quote cq            -- Alias the creator_quote table as cq.
    WHERE cq.qid = q.qid             -- Match the quote ID from the creator_quote table with the quote ID from the quotes table.
);

.exit
/*

sqlite3 "$DB" < "$SQL" > "$HLD"       # Execute the SQL query and save the output to the HLD file.

NUM=$(cat "$HLD")                     # Grab the count of quotes found.

if [[ "$NUM" -eq 0 ]]; then
    ols_err "$QID" "5003" "$EX_OK" "No quotes found without a corresponding entry in the creator_quote table."
    exit
else
    ols_err "$QID" "5003" "$EX_OK" "Found $NUM quotes without a corresponding entry in the creator_quote table."
fi

cat > "$SQL" <</*                     # A throw back to my old OS/360 days.
.mode table
.headers on

SELECT *                             -- Select the count of quotes that do not have a corresponding entry in the creator_quote table.
FROM quotes q                        -- Alias the quotes table as q.
WHERE NOT EXISTS (                   -- Filter out quotes that have a corresponding entry in the creator_quote table.
    SELECT 1                         -- Select a constant value to check for the existence of a matching row.
    FROM creator_quote cq            -- Alias the creator_quote table as cq.
    WHERE cq.qid = q.qid             -- Match the quote ID from the creator_quote table with the quote ID from the quotes table.
);

.exit
/*

sqlite3 "$DB" < "$SQL"                # Execute the SQL query and save the output STDOUT.

ols_end
