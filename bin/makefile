# Constants


MED_DB    := med.sqlite
MED_TODAY := $(shell date +%F)
MED_BAK_DB := bak/bak_$(MED_TODAY)_med.sqlite


# Document Directory Makefile

.PHONY: clean
.PHONY: chk-quotes




clean:
	@-rm -f core     2>/dev/null      # Remove code dumps.
	@-rm -f DEADJOE  2>/dev/null      # Remove jmacs files.
	@-rm -f *~       2>/dev/null      # Remove backup files.
	@-rm -f *.adoc   2>/dev/null      # Remove documentation files.
	@-rm -f *.bak    2>/dev/null      # Remove backup files.
	@-rm -f *.hold   2>/dev/null      # Remove temporary files.
	@-rm -f hold.*   2>/dev/null      # Remove temporary files.
	@-rm -f *.html   2>/dev/null      # Remove derived HTML files.
	@-rm -f *.pdf    2>/dev/null      # Remove derived PDF files.
	@-rm -f *.sed    2>/dev/null      # Remove sed commands.
	@-rm -f *.sql    2>/dev/null      # Remove sqlite3 commands.
	@-rm -f *.tar    2>/dev/null      # Remove tar archives.
	@-rm -f *.tgz    2>/dev/null      # Remove tar archives.
	@-rm -f *.tmp    2>/dev/null      # Remove temporary files.
	@-rm -f tmp.*    2>/dev/null      # Remove temporary files.
	@-rm -f *.1      2>/dev/null      # Remove derived man pages.
	@-rm -f *.2      2>/dev/null      # Remove derived man pages.
	@-rm -f *.3      2>/dev/null      # Remove derived man pages.
	@-rm -f *.4      2>/dev/null      # Remove derived man pages.
	@-rm -f *.5      2>/dev/null      # Remove derived man pages.
	@-rm -f *.6      2>/dev/null      # Remove derived man pages.
	@-rm -f *.7      2>/dev/null      # Remove derived man pages.
	@-rm -f *.8      2>/dev/null      # Remove derived man pages.
	@-rm -f *.9      2>/dev/null      # Remove derived man pages.

db-bak:
	sqlite3 $(MED_DB)  "VACUUM INTO '$(MED_BAK_DB)';"
	sqlite3 $(MED_BAK_DB)  "PRAGMA quick_check;"
	sqlite3 $(MED_BAK_DB)  "PRAGMA integrity_check;"
	sqlite3 $(MED_BAK_DB)  "PRAGMA foreign_key_check;"

db-chk:
	sqlite3 $(MED_DB)  "PRAGMA quick_check;"
	sqlite3 $(MED_DB)  "PRAGMA integrity_check;"
	sqlite3 $(MED_DB)  "PRAGMA foreign_key_check;"

chk-quotes:
	./chk_quotes.sh
	