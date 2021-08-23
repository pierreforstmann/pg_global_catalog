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
\set ON_ERROR_STOP 1
set client_min_messages=ERROR;
--
-- PROCEDURE pggc_create_fdws
--
create or replace procedure pggc_create_fdws()
language plpgsql
as $$
declare 
 l_r record;
 l_port int;
 l_listen_addresses text;
begin
 for l_r in (select datname from pg_database where datname not in ('template0','template1'))
 loop
 execute format ('DROP SERVER IF EXISTS %s CASCADE', l_r.datname);
 end loop;
 --
 execute format ('DROP SCHEMA IF EXISTS global_catalog');
 execute format ('CREATE SCHEMA global_catalog');
 --
 show port into l_port;
 show listen_addresses into l_listen_addresses;
 --
 for l_r in (select datname from pg_database where datname not in ('template0', 'template1'))
 loop
  execute format ('CREATE SERVER %s FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host %s, port %s, dbname %s)', l_r.datname, quote_literal(split_part(l_listen_addresses,',',1)), quote_literal(l_port), quote_literal(l_r.datname)
                 );
  execute format ('CREATE USER MAPPING FOR %s SERVER %s OPTIONS (user %s) ', current_user, l_r.datname, quote_literal(current_user)
                 );
  execute format ('IMPORT FOREIGN SCHEMA local_catalog FROM SERVER %s INTO global_catalog', l_r.datname);
 end loop;
end;
$$;
--
--
--
call pggc_create_fdws();
--
-- PROCEDURE pggc_create_global_views
--
create or replace procedure pggc_create_global_views()
language plpgsql
as $$
declare
 l_r record;
 l_db record;
 l_stmt text;
 i int;
 l_max_db int;
begin
 l_max_db = 0;
 for l_db in (select datname from pg_database where datname not in ('template0','template1'))
 loop
  l_max_db = l_max_db + 1; 
 end loop; 
--
 for l_r in (select relname
             from pg_class
             join pg_namespace
             on pg_class.relnamespace  = pg_namespace.oid
             where pg_namespace.nspname = 'pg_catalog'
             and pg_class.relkind in ('r','t','v')
             and pg_class.relname not in ('pg_tablespace',
                                          'pg_shdepend',
                                          'pg_authid',
                                          'pg_database',
                                          'pg_shdescription',
                                          'pg_db_role_setting',
                                          'pg_sheclabel',
                                          'pg_replication_origin',
                                          'pg_subscription',
                                          -- pseudo array-type
                                          'pg_statistic',
                                          'pg_attribute',
                                          'pg_stats',
                                          --  column name "xmin" conflicts with a system column name
                                          'pg_replication_slots')
             )
  loop
   i = 0;
   l_stmt = '';
   for l_db in (select datname from pg_database where datname not in ('template0','template1'))
   loop
    l_stmt = l_stmt || format('select * from global_catalog.%s_%s', l_db.datname, l_r.relname);
    i =  i + 1;
    if ( i <> l_max_db)
    then
     l_stmt = l_stmt || ' union ';
    end if; 
    -- raise notice 'l_stmt=%', l_stmt;
   end loop; 
   execute format('create or replace view global_catalog.%s as %s', l_r.relname, l_stmt);
  end loop;
end;
$$;
--
call pggc_create_global_views();

