drop procedure proc;
drop procedure prod.proc;
drop procedure prod.test_proc;
drop function prod.test_func;
create table prod.teachers(
    id NUMBER,
    name VARCHAR2(100),
    subject VARCHAR2(100)
);
alter table prod.students drop column group_id;
drop table prod.groups;
