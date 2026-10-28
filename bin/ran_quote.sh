#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        ran_quote TYPE [NUM] [DB] 
# Purpose:      ran_quote counts the number of quote types in the DB
# Returns:      The number of TYPE quotes in the DB
# Exit Codes:   Sets EX_OK exit code.
# Parameteres:  TYPE is the quote type to count, e.g. "Fortran"
#               NUM is the number of quotes to retrieve.
#               if NUM is not specified then the default value is 1.
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
NUM="${2:-1}"                         # The number of quotes to retrieve, default is 1.
DB="$3"                               # The database name passed as the fourth argument to the script.

if [[ -z "$DB" ]]; then
    DB="$DEFAULT_DB"                  # Use the default database path if no argument is provided.
    ols_err "$QID" "5001" "$EX_OK" "Using default database: $DB"
fi

cat > "$SQL" <</*                     # A throw back to my old OS/360 days.
.mode csv --quote off
.headers on
.separator " -- "

SELECT
    q.quote,
    cd.display_name AS creator_display
FROM quotes q
JOIN quote_type qt ON q.qid = qt.qid
JOIN quote_type_list qtl ON qt.qtid = qtl.qtid
JOIN creator_quote cq ON q.qid = cq.qid
JOIN creator_display cd ON cq.aid = cd.aid
WHERE qtl.qtype = '$TYPE'
ORDER BY RANDOM()
LIMIT $NUM;

.exit
/*

sqlite3 "$DB" < "$SQL" >"$HLD"        # Execute the SQL query and save the output to the HLD file.

tr -d '"' <"$HLD"

ols_end
