--
-- pg_global_catalog-local-0.0.1.sql
--
--
-- Copyright 2021 Fierre Forstmann
-- -------------------------------
--
-- PROCEDURE pggc_create_views
--
-- must be run in each source database
--
create or replace procedure pggc_create_views ()
language plpgsql
as $$
declare
 l_r record;
begin
 execute format ('drop schema if exists local_catalog cascade');
 execute format ('create schema local_catalog');
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
   execute format('create or replace view local_catalog.pggc_%s_%s as select (select oid from pg_database where datname=current_database()) as dbid, t.* from %s t', current_database(), l_r.relname, l_r.relname);
  end loop;
end;
$$;
--
call pggc_create_views();
--
