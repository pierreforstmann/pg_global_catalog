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
\set ON_ERROR_STOP 1
set client_min_messages=ERROR;
--
create or replace procedure pggc_create_views ()
language plpgsql
as $$
declare
 l_r record;
 l_version int;
begin
 select split_part(split_part(version(), ' ', 2), '.', 1)::int into l_version;
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
-- oid hidden column up to PG 11
    if (
         l_version >= 12 or 
        (l_r.relname = 'pg_foreign_table' or l_r.relname = 'pg_shadow' or l_r.relname = 'pg_roles' or
         l_r.relname = 'pg_settings' or l_r.relname = 'pg_file_settings' or l_r.relname = 'pg_hba_file_rules' or
         l_r.relname = 'pg_config' or l_r.relname = 'pg_replication_origin_status' or 
         l_r.relname = 'pg_statio_all_indexes' or l_r.relname = 'pg_largeobject' or
         l_r.relname = 'pg_inherits' or l_r.relname = 'pg_index' or l_r.relname = 'pg_aggregate' or
         l_r.relname = 'pg_depend' or l_r.relname = 'pg_description' or l_r.relname = 'pg_pltemplate' or
         l_r.relname = 'pg_auth_members' or l_r.relname = 'pg_ts_config' or l_r.relname = 'pg_ts_config_map'  or
         l_r.relname = 'pg_init_privs' or l_r.relname = 'pg_seclabel' or l_r.relname = 'pg_shseclabel' or
         l_r.relname = 'pg_partitioned_table' or l_r.relname = 'pg_range' or l_r.relname = 'pg_sequence' or
         l_r.relname = 'pg_subscription' or l_r.relname = 'pg_subscription_rel' or l_r.relname = 'pg_matviews' or
         l_r.relname = 'pg_group' or l_r.relname = 'pg_user' or l_r.relname = 'pg_policies' or
         l_r.relname = 'pg_rules' or l_r.relname = 'pg_views' or l_r.relname = 'pg_tables' or
         l_r.relname = 'pg_indexes' or l_r.relname = 'pg_sequences' or
         l_r.relname = 'pg_publication_tables' or l_r.relname = 'pg_locks' or l_r.relname = 'pg_cursors' or
         l_r.relname = 'pg_available_extensions' or l_r.relname  = 'pg_available_extension_versions' or
         l_r.relname = 'pg_prepared_xacts' or l_r.relname = 'pg_prepared_statements' or
         l_r.relname = 'pg_seclabels' or l_r.relname = 'pg_statio_sys_indexes' or 
         l_r.relname = 'pg_timezone_abbrevs' or l_r.relname = 'pg_timezone_names' or
         l_r.relname = 'pg_stat_all_tables' or l_r.relname = 'pg_stat_xact_all_tables' or
         l_r.relname = 'pg_stat_sys_tables' or l_r.relname = 'pg_stat_xact_sys_tables' or
         l_r.relname = 'pg_stat_user_tables' or l_r.relname = 'pg_stat_xact_user_tables' or
         l_r.relname = 'pg_statio_all_tables' or l_r.relname = 'pg_statio_sys_tables' or
         l_r.relname = 'pg_statio_user_tables' or l_r.relname = 'pg_stat_all_indexes' or
         l_r.relname = 'pg_stat_sys_indexes' or l_r.relname = 'pg_stat_user_indexes' or
         l_r.relname = 'pg_statio_user_indexes' or l_r.relname = 'pg_statio_all_sequences' or
         l_r.relname = 'pg_statio_sys_sequences' or l_r.relname = 'pg_statio_user_sequences' or
         l_r.relname = 'pg_stat_activity' or l_r.relname = 'pg_stat_replication' or
         l_r.relname = 'pg_stat_wal_receiver' or l_r.relname = 'pg_stat_subscription' or
         l_r.relname = 'pg_stat_ssl' or l_r.relname = 'pg_stat_database' or
         l_r.relname = 'pg_stat_database_conflicts' or l_r.relname = 'pg_stat_user_functions' or 
         l_r.relname = 'pg_stat_xact_user_functions' or l_r.relname = 'pg_stat_archiver' or
         l_r.relname = 'pg_stat_bgwriter' or l_r.relname = 'pg_stat_progress_vacuum' or
         l_r.relname = 'pg_user_mappings'
        )
       )
    then 
      execute format('create or replace view local_catalog.%s_%s as select (select oid from pg_database where datname=current_database()) as dbid, t.* from %s t', current_database(), l_r.relname, l_r.relname);
    else
      execute format('create or replace view local_catalog.%s_%s as select (select oid from pg_database where datname=current_database()) as dbid, oid, t.* from %s t', current_database(), l_r.relname, l_r.relname);
    end if;
  end loop;
end;
$$;
--
call pggc_create_views();
--
