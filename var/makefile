# Constants

SOURCE_PATH = /mnt/c/Users/Mark/Downloads
SOURCE_DIR="$SOURCE_PATH/Takeout"
SOURCE_TGZ=takeout-20260913T151415Z-1-001.tgz
SOURCE_PATH_TGZ=$(SOURCE_PATH)/$(SOURCE_TGZ)
BEGIN=2026-08-14
END=2026-09-14
HR_MED_CSV=takeout_hr_med.csv
RHR_MED_CSV=takeout_rhr_med.csv

MED_DB    := med.sqlite
MED_TODAY := $(shell date +%F)
MED_BAK_DB := ../arc/bak_$(MED_TODAY)_med.sqlite


# Document Directory Makefile

.PHONY: clean
.PHONY: db-bk
.PHONY: db-chk
.PHONY: smartbp_clean
.PHONY: takeout_hr
.PHONY: takeout_rhr



clean:
	@-rm -f core     2>/dev/null      # Remove code dumps.
	@-rm -f DEADJOE  2>/dev/null      # Remove jmacs files.
	@-rm -f *~       2>/dev/null      # Remove backup files.
	@-rm -f *.adoc   2>/dev/null      # Remove documentation files.
	@-rm -f *.bak    2>/dev/null      # Remove backup files.
	@-rm -f *.csv    2>/dev/null      # Remove CSV files.
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

db-bk:
	sqlite3 $(MED_DB)  "VACUUM INTO '$(MED_BAK_DB);'"

db-chk:
	sqlite3 $(MED_DB)  "PRAGMA integrity_check;"

takeout_hr takeout_hr_med.csv: $(SOURCE_PATH_TGZ)
	echo "TODO: Need to search for the takeout tar file..."
	../bin/takeout_hr2med.sh $(SOURCE_PATH) $(SOURCE_TGZ) $(BEGIN) $(END) $(HR_MED_CSV)

takeout_rhr takeout_rhr_med.csv: $(SOURCE_PATH_TGZ)
	echo "TODO: Need to search for the takeout tar file..."
	../bin/takeout_rhr2med.sh $(SOURCE_PATH) $(SOURCE_TGZ) $(BEGIN) $(END) $(RHR_MED_CSV)

smartbp_clean: SmartBP_processed.cat
	../bin/smartbp_clean.py

bp_report: tmpl-Blood-Pressure-Report-1.adoc tmpl-Blood-Pressure-Report-2.adoc ../bin/ex_bp.sh
	../bin/ex_bp.sh $(STARt) $(END)
 