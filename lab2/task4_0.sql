create table logs_students(
    id number generated by default as identity,
    t timestamp default systimestamp,
    student_id number,
    operation varchar2(100),
    old_val varchar2(100),
    new_val varchar2(100),
    primary key(id)
);
    