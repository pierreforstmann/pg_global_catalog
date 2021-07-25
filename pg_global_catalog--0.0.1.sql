--
-- pg_global_catalog-0.0.1.sql
--
--
-- Copyright 2021 Fierre Forstmann
-- -------------------------------
--
--
-- must run as superuser in the database that will host the new schema global_catalog.
--
-- superuser must create ~/.pgpass to avoid password hard coding in this file.
--
--
\t on
select '\c ' || current_database();
\g setup1.sql
\t off
--
-- PROCEDURE pggc_create_fdws
--
create or replace procedure pggc_create_fdws()
language plpgsql
as $$
declare 
 l_r record;
begin
 for l_r in (select datname from pg_database)
 loop
 execute format ('DROP SERVER IF EXISTS %s CASCADE', l_r.datname);
 end loop;
 --
 execute format ('DROP SCHEMA IF EXISTS global_catalog');
 execute format ('CREATE SCHEMA global_catalog');

 for l_r in (select datname from pg_database where datname not in ('template0', 'template1'))
 loop
  raise notice 'CREATE SERVER %', l_r.datname;
  execute format ('CREATE SERVER %s FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host %s, port %s, dbname %s)', l_r.datname, quote_literal('localhost'), quote_literal('5432'), quote_literal(l_r.datname)
                 );
  raise notice 'CREATE USER MAPPING %', l_r.datname;
  execute format ('CREATE USER MAPPING FOR %s SERVER %s OPTIONS (user %s) ', current_user, l_r.datname, quote_literal(current_user)
                 );
  raise notice 'IMPORT %', l_r.datname;
  execute format ('IMPORT FOREIGN SCHEMA local_catalog FROM SERVER %s INTO global_catalog', l_r.datname);
 end loop;
end;
$$;
--
--
\t
select '\c ' || datname || chr(13) || ' \i pg_global_catalog-local--0.0.1.sql' from pg_database where datname not in ('template0', 'template1') ;
\g setup2.sql
\i setup2.sql
\t off
--
\i setup1.sql
call pggc_create_fdws();
--
