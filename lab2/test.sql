insert into groups(name, c_val) values('group1', 0);
insert into groups(name, c_val) values('group1', 0);
insert into groups(name, c_val) values('group2', 0);

insert into students(name, group_id) values('name1', 1);
insert into students(name, group_id) values('name2', 2);
insert into students(id, name, group_id) values(2, 'name3', 1);
insert into students(id, name, group_id) values(3, 'name3', 1);
update students set name='omwi' where name='name1';

--delete from groups where id = 1;