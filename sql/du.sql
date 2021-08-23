select
    d.datname as "database",
    n.nspname as "schema",
    c.relname as "relation name",
    case
        when c.relkind='i' then 'index'
        when c.relkind='t' then 'toast'
        when c.relkind='r' then 'table'
    end as "relation type",
    pg_size_pretty(pg_total_relation_size(c.oid)) as total_size
from
    global_catalog.pg_class c
    join pg_database d on d.oid = c.dbid
    join global_catalog.pg_namespace n on (n.oid = c.relnamespace and n.dbid = c.dbid)
where c.relkind in ('r','i','t')
order by
    pg_total_relation_size(c.oid) desc nulls last,
    d.datname,
    n.nspname,
    c.relname;

