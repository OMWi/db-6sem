create or replace trigger logger_students
after
insert or
update of id, name, group_id or
delete
on students
for each row
begin
    case
    when inserting then
        insert into logs_students(student_id, operation, old_val, new_val) 
        values(:new.id, 'insert', :new.name, :new.group_id);
    when updating('id') then
        insert into logs_students(student_id, operation, old_val, new_val)
        values(:new.id, 'update id', :old.id, :new.id);    
    when updating('name') then
        insert into logs_students(student_id, operation, old_val, new_val)
        values(:new.id, 'update name', :old.name, :new.name);
    when updating('group_id') then
        insert into logs_students(student_id, operation, old_val, new_val)
        values(:new.id, 'update group_id', :old.group_id, :new.group_id);
    when deleting then
        insert into logs_students(student_id, operation, old_val, new_val)
        values(:old.id, 'delete', :old.name, :old.group_id);
    end case;
end;
