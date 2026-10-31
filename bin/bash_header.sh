#! /usr/bin/env bash

#===================================================================================================
#
# Usage:        <command> <arguments>
# Purpose:      <command> - one-line description of what the command does
# Returns:      Sets EX_OK exit code
# Parameteres:  DB is the quote database you want to check.
#               If DB is not specified then the default database will be used.
# Throws:       None
# Comments:     None
# See Also:     Olaus Bash Shell Library    
# Source:       bash
#
#===================================================================================================

# shellcheck source=/home/mjj/.local/lib/b_ols.lib
source "$OLSLIB"                      # Use the Olaus Bash Shell Library.

readonly QID="XXX"                    # Replace XXX with your 3-letter identifier.
