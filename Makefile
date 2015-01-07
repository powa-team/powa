MODULES = powa
EXTENSION = powa
DATA = powa--2.0.sql
DOCS = README.md

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
