# pg_global_catalog Makefile
#
 EXTENSION = pg_global_catalog
 DATA = pg_global_catalog--0.0.1.sql pg_global_catalog-local--0.0.1.sql
#
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
