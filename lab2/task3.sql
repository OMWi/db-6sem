create or replace trigger foreign_key_del
after delete on groups
for each row
begin
    delete from students where students.group_id = :old.id;
end;