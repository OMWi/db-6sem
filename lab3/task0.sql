--DROP TABLESPACE lab3_prod INCLUDING CONTENTS AND DATAFILES;
--DROP USER prod CASCADE;

--create tablespace lab3_prod 
--DATAFILE 'lab3_prod.dat' SIZE 10M 
--REUSE AUTOEXTEND ON NEXT 10M MAXSIZE 300M;

alter session set "_oracle_script"=TRUE;

create user prod 
IDENTIFIED BY prod
DEFAULT TABLESPACE lab3_prod
QUOTA 300M on lab3_prod;
grant create session to prod;
grant create any table to prod;
grant create any trigger to prod;
grant create any procedure to prod;
grant create any sequence to prod;
grant create any view to prod;

--create table prod.students(
--    id NUMBER NOT NULL,
--    name VARCHAR(100) NOT NULL,
--    CONSTRAINT students_pk PRIMARY KEY(id)
--);

--DROP TABLESPACE lab3_dev INCLUDING CONTENTS AND DATAFILES;
--DROP USER dev CASCADE;

--create tablespace lab3_dev 
--DATAFILE 'lab3_dev.dat' SIZE 10M 
--REUSE AUTOEXTEND ON NEXT 10M MAXSIZE 300M;

create user dev
IDENTIFIED BY dev
DEFAULT TABLESPACE lab3_dev
QUOTA 300M on lab3_dev;
grant create session to dev;
grant create any table to dev;
grant create any trigger to dev;
grant create any procedure to dev;
grant create any sequence to dev;
grant create any view to dev;

--drop table dev.students;
--ALTER table dev.students add age NUMBER;
--ALTER table prod.students add surname varchar(100);    
--create table dev.students(
--    id NUMBER NOT NULL,
--    name VARCHAR(20) NOT NULL,
--    CONSTRAINT students_pk PRIMARY KEY(id)
--);

--drop table prod.books;

--CREATE TABLE dev.books(
--    id NUMBER NOT NULL,
--    name VARCHAR(20) NOT NULL,
--    student_id NUMBER,
--    price NUMBER NOT NULL,
--    CONSTRAINT book_pk PRIMARY KEY(id)
--);
--
--create table prod.tab(
--    id NUMBER NOT NULL
--);
--
--drop table prod.proc;
--create or replace procedure dev.proc as
--    begin
--    dbms_output.put_line('Hello world!');
--end;

