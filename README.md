# pg_global_catalog
PostgreSQL extension to consolidate pg_catalog for each database in a single schema named `global_catalog`.

# Installation

`pg_global_catalog` creates a schema `local_catalog` in every database (except template0 and template1) and a schema `global_catalog` in the current database.

There is no `CREATE EXTENSION` statement to run: it's only needed to run `setup.sh`.

Following prerequisites must be met and are checked by `setup.sh`

*  current Linux user must have password file `~./.pgpass.`
* passwordless superuser access by current Linux user 
* current Linux user must have an associated database with same name
* extension `postgres_fdw` must be installed in default database.

What `setup.sh` is doing: 
* in `local_catalog, for most of `pg_catalog` view, a new view is created with an additional column named `dbid`
* a foreign data wrapper (FDW) server is created for each database 
* a global view is created for each `pg_catalog` view as the union of all `local_catalog` views.


# Usage
