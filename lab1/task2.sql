declare
  rand_int number;
begin
  for i in 1..10000 loop
    rand_int := round(dbms_random.value(1, 10));
    insert into MyTable values (i, rand_int);
  end loop;
end;