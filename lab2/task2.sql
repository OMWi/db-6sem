create or replace trigger verify_unique
before insert on students 
for each row
declare
    id_matches number;
begin
    select count(id) into id_matches from students where students.id = :new.id;
    if id_matches > 0 then
        raise_application_error(-20000, 'id already exists');
    end if;
end;
/

create or replace trigger verify_unique_groups
before insert on groups
for each row
declare
    id_matches number;
begin
    select count(id) into id_matches from groups where groups.id = :new.id;
    if id_matches > 0 then
        raise_application_error(-20000, 'id already exists');
    end if;
end; 
/

create or replace trigger auto_inc
before insert on students
for each row when(new.id is null)
declare
    new_id number;
begin
    select max(id) into new_id from students;
    if new_id is null then
        new_id := 0;
    end if;
    :new.id := new_id + 1;
end;
/

create or replace trigger auto_inc_groups
before insert on groups
for each row when(new.id is null)
declare
    new_id number;
begin
    select max(id) into new_id from groups;
    if new_id is null then
        new_id := 0;
    end if;
    :new.id := new_id + 1;
end;
/

create or replace trigger unique_group_name
before insert on groups
for each row
declare
    name_matches number;
begin
    select count(name) into name_matches from groups where groups.name = :new.name;
    if name_matches > 0 then
        raise_application_error(-20001, 'group name already exists');
    end if;
end;
/
    