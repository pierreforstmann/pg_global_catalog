# pg_global_catalog
PostgreSQL extension to consolidate `pg_catalog` for each database in a single schema named `global_catalog`.

# Installation

`pg_global_catalog` creates a schema `local_catalog` in every database (except template0 and template1) and a schema `global_catalog` in the current database.

There is no `CREATE EXTENSION` statement to run: it's only needed to run `setup.sh`.

Following prerequisites must be met and are checked by `setup.sh`:

*  current Linux user must have password file `~./.pgpass.`
* passwordless superuser access by current Linux user 
* current Linux user must have an associated database with same name
* extension `postgres_fdw` must be installed in default database.

What `setup.sh` is doing: 
* in `local_catalog` schema, for most of `pg_catalog` views, a new view is created with an additional column named `dbid`
* in default database a foreign data wrapper (FDW) server is created for each database (except template0 and template1)
* in `global_catalog` schema a global view is created for each `pg_catalog` view as the union of all related `local_catalog` views.

# Usage

Most `pg_catalog` views are mapped to the same view in `global_catalog` schema and can by used to query catalog data at instance level.

For example, following query can be used to get number of objects referenced in `pg_class` by database at instance level:

```
select
datname, count(*)
from global_catalog.pg_class c
join pg_database d
on c.dbid = d.oid
group by datname
order by datname;
```

