create or replace procedure recover_student(t_stamp timestamp) as
    type id_array is varray(10000) of number;
    log_ids id_array;
    log_row logs_students%rowtype;
begin
    select id bulk collect into log_ids from logs_students where t > t_stamp order by t desc;
    for i in 1..log_ids.count loop
        select * into log_row from logs_students where id = log_ids(i);
        if log_row.operation = 'insert' then
            delete from students where id = log_row.student_id;
            dbms_output.put_line('delete from students where id =' || log_row.student_id);
        end if;
        if log_row.operation = 'update id' then
            update students set id = log_row.old_val where students.id = log_row.student_id;
            dbms_output.put_line('update students set id = ' || log_row.old_val || ' where students.id = ' || log_row.student_id );
        end if;
        if log_row.operation = 'update name' then
            update students set name = log_row.old_val where students.id = log_row.student_id;
            dbms_output.put_line('update students set name = ' || log_row.old_val || ' where students.id = ' || log_row.student_id );
        end if;
        if log_row.operation = 'update group_id' then
            update students set group_id = log_row.old_val where students.id = log_row.student_id;
            dbms_output.put_line('update students set group_id = ' || log_row.old_val || ' where students.id = ' || log_row.student_id );
        end if;
        if log_row.operation = 'delete' then
            insert into students values(log_row.student_id, log_row.old_val, log_row.new_val);
            dbms_output.put_line('insert into students values (' || log_row.student_id || log_row.old_val  ||  log_row.new_val || ')');
        end if;
    end loop;
    delete from logs_students where logs_students.t > t_stamp;
end;