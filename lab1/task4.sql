create or replace function print_insert(i int) return varchar2 as
    val int;
begin
    select mytable.val into val from mytable where id = i;
    return 'insert into MyTable values('||i||', '||val||');';
end print_insert;