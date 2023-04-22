drop database if exists lesson1;
create database lesson1;
SET search_path TO lesson1;
create schema demo;
SET search_path TO demo;

---

drop table if exists demo.test cascade;
create table demo.test (
    id      bigserial primary key,
    time	timestamp
);

select * from demo.test;

---

drop function if exists demo.test_partition_creation();
create or replace function demo.test_partition_creation( date, date )
    returns void as $$
declare
    create_query text;
    index_query text;
begin
    for create_query, index_query in select
        'create table test_'
        || to_char( d, 'YYYY_MM' )
        || ' ( check( time >= date '''
        || to_char( d, 'YYYY-MM-DD' )
        || ''' and time < date '''
        || to_char( d + interval '1 month', 'YYYY-MM-DD' )
        || ''' ) ) inherits ( test );',
        'create index test_'
        || to_char( d, 'YYYY_MM' )
        || '_time on test_'
        || to_char( d, 'YYYY_MM' )
        || ' ( time );'
        from generate_series( $1, $2, '1 month' ) as d
        loop
            execute create_query;
            execute index_query;
        end loop;
end;
$$
language plpgsql;

---

select demo.test_partition_creation( '2020-01-01', '2024-01-01' );

---

drop function if exists test_partition_function();
create or replace function test_partition_function()
    returns trigger as $$
begin
    execute 'insert into test_'
    || to_char( NEW.time, 'YYYY_MM' )
    || ' values ( $1, $2 )' using NEW.id, NEW.time ;
    return null;
end;
$$
language plpgsql;

---

drop trigger if exists test_partition_trigger;
create trigger test_partition_trigger
    before insert
    on test
    for each row
execute procedure test_partition_function();

---

insert into test (id, time)
select
    generate_series,
    now() - '3 years'::interval * random()
from
    generate_series(1, 10000);

---

select * from test order by id asc limit 1000;
select count(*) from test;

select * from test_2021_06;
drop table test_2021_06;
