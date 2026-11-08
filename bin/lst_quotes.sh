#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        lst_quotes <type> [DB] 
# Purpose:      lst_quotes - list the quotes in the DB
# Returns:      The list of quotes in the DB
# Exit Codes:   Sets EX_OK exit code.
# Parameteres:  [type] is the type of quotes to list, e.g., "Fortran," or "Gundilda"
#               If type is not specified then all quotes will be listed.
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

SQL="$OLS_TMP_DIR/cnt_creators.sql"   # Temporary SQL file for checking creator(s).
HLD="$OLS_TMP_DIR/cnt_creators.txt"   # Temporary HLD file for checking creator(s)s.

TYPE="$1"                             # The type of quotes to list, passed as the argument to the script.
DB="$2"                               # The database name passed as the second argument to the script.

if [[ -z "$TYPE" ]]; then
    TYPE="all"                        # If no type is specified, list all quotes.
    ols_err "$QID" "5001" "$EX_OK" "Using default type: $TYPE"
fi

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

sqlite3 "$DB" > "$HLD" <</*      # Execute the SQL query and save the output to the HLD file.
.mode table
SELECT
  q.qid,
  q.quote,
  cd.display_name AS creator,
  COALESCE(GROUP_CONCAT(z.zkey, '; '), '') AS zotero_refs
FROM quotes q
JOIN quote_type qt           ON q.qid = qt.qid
JOIN quote_type_list qtl     ON qt.qtid = qtl.qtid
LEFT JOIN creator_quote cq   ON q.qid = cq.qid
LEFT JOIN creator_display cd ON cq.aid = cd.aid
LEFT JOIN ref_quote rq       ON q.qid = rq.qid
LEFT JOIN zotero_refs z      ON rq.rid = z.rid
WHERE qtl.qtype = '$TYPE'
GROUP BY q.qid, q.quote
ORDER BY cd.display_name, q.qid;

/*

NUM=$(wc -l < "$HLD")                     # Grab the count of creator(s) found.

if [[ "$NUM" -eq 0 ]]; then
    ols_err "$QID" "5006" "$EX_MISSINGFILE" "No $TYPE quotes found."
    exit
else
    ols_err "$QID" "5007" "$EX_OK" "Found $NUM $TYPE quotes."
    cat "$HLD"                        # Display the found quotes.
fi

ols_end
