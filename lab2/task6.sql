create or replace trigger update_cval
after
insert or
delete or
update of group_id
on students
for each row
begin
    case
    when inserting then
        update groups set c_val = c_val+1 where groups.id=:new.group_id;    
    when deleting then
        update groups set c_val = c_val-1 where groups.id=:old.group_id;    
    when updating('group_id') then
        update groups set c_val = c_val+1 where groups.id=:new.group_id;
        update groups set c_val = c_val-1 where groups.id=:old.group_id;
    end case;
end;