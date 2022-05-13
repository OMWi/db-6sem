create or replace procedure insert_value(new_id number, val number) as
begin
    insert into mytable values(new_id, val);
end insert_value;
/

create or replace procedure delete_value(new_id number) as 
begin
    delete from mytable where id=new_id;
end delete_value;
/

create or replace procedure update_value(new_id number, new_val number) as
begin
    update mytable set val = new_val where id=new_id;
end update_value;
/