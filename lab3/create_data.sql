create table dev.students(
    id NUMBER,
    name VARCHAR2(100),
    group_id NUMBER,
    CONSTRAINT students_pk PRIMARY KEY(id)
);

create table dev.groups(
    id NUMBER,
    name VARCHAR2(100),
    CONSTRAINT groups_pk PRIMARY KEY(id)
);

--create or replace procedure dev.proc as
--begin
--    dbms_output.put_line('Hello world!');
--end;
--/

create procedure dev.test_proc as 
begin
    dbms_output.put_line('Hello world!');
end;
/
create function dev.test_func return number as
begin
    return 0;
end;
/

create table prod.students(
    id NUMBER,
    name VARCHAR2(100),
    CONSTRAINT students_pk PRIMARY KEY(id)
);

create table prod.teachers(
    id NUMBER,
    name VARCHAR2(100),
    subject VARCHAR2(100)
);

