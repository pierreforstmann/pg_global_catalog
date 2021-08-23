# pg_global_catalog Makefile
#
EXTENSION = pg_global_catalog
DATA = pg_global_catalog--0.0.1.sql pg_global_catalog-local--0.0.1.sql
#
test: 
	psql -e -f sql/test0.sql
#
ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir=contrib/pg_query_rewrite
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
#
