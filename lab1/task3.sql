create or replace function more_even return varchar2 as
  even int;
  odd int;
begin
  even := 0;
  odd := 0;
  select count(*) into odd from mytable where mod(val, 2) = 1;
  select count(*) into even from mytable where mod(val, 2) = 0;
  if even = odd then
    return 'EQUAL';
  elsif even > odd then
    return 'TRUE';
  else
    return 'FALSE';
  end if;    
end more_even;