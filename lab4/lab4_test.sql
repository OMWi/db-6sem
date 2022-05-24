
SELECT * FROM groups;
SELECT * FROM students;
SELECT * FROM new_table;
SELECT * FROM new_table2;
    
declare
    xml_rec xml_record:= xml_record();
    cur SYS_REFCURSOR;
    student_id number;
    student_name varchar(1000);
    group_name varchar(1000);
begin
    cur := xml_package.process_xml_select(
    '<Command>
    <QueryType>
        SELECT
    </QueryType>
    <OutputColumns>
        <Column>students.id</Column>
        <Column>students.name</Column>
        <Column>groups.name</Column>
    </OutputColumns>
    <Tables>
        <Table>students</Table>
        <Table>groups</Table>
    </Tables>
    <Joins>
        <Join>
            <Type>LEFT JOIN</Type>
            <Condition>groups.id = students.group_id</Condition>
        </Join>
    </Joins>
    <Where>
        <Conditions>
            <Condition>
                <Body>groups.name = ''group1''</Body>
            </Condition>
        </Conditions>
    </Where>
</Command>');
    loop
        fetch cur into student_id, student_name, group_name;
        exit when cur%notfound;
        
        dbms_output.put_line('Id: ' || student_id|| ' Name: ' || student_name|| ' Group name: ' || group_name);
    end loop;
end;
/

declare
    xml_rec xml_record:= xml_record();
    cur SYS_REFCURSOR;
    student_id number;
    student_name varchar(1000);
    group_name varchar(1000);
begin
    cur := xml_package.process_xml_select(
    '<Command>
    <QueryType>
        SELECT
    </QueryType>
    <OutputColumns>
        <Column>students.id</Column>
        <Column>students.name</Column>
        <Column>groups.name</Column>
    </OutputColumns>
    <Tables>
        <Table>students</Table>
        <Table>groups</Table>
    </Tables>
    <Joins>
        <Join>
            <Type>LEFT JOIN</Type>
            <Condition>groups.id = students.group_id</Condition>
        </Join>
    </Joins>
    <Where>
        <Conditions>
            <Condition>
                <Body>groups.name IN</Body>
                <Command>
                    <QueryType>SELECT</QueryType>
                    <OutputColumns>
                        <Column>name</Column>
                    </OutputColumns>
                    <Tables>
                        <Table>groups</Table>
                    </Tables>
                    <Where>
                        <Conditions>
                            <Condition>
                                <Body>c_val > 0</Body>
                            </Condition>
                        </Conditions>
                    </Where>
                </Command>
            </Condition>
        </Conditions>
    </Where>
</Command>');
    loop
        fetch cur into student_id, student_name, group_name;
        exit when cur%NOTFOUND;
        
        dbms_output.put_line('Id: ' || student_id|| ' Name: ' || student_name|| ' Group name: ' || group_name);
    end loop;
end;
/

begin
    xml_package.process_xml_dml(
    '<Command>
        <Type>INSERT</Type>
        <Columns>
            <Column>students.name</Column>
            <Column>students.group_id</Column>
        </Columns>
        <Table>students</Table>
        <Values>
            <Value>''Artem''</Value>
            <Value>1</Value>
        </Values>
    </Command>');
end;
/

create table Persons
(
    id NUMBER,
    name VARCHAR (50) not null,
    group_id NUMBER NOT NULL
);
/

insert into persons(id, name, group_id) values(1, 'Joe', 1);
select * from students;
select * from persons;
begin
    xml_package.process_xml_dml(
    '<Command>
        <Type>INSERT</Type>
        <Columns>
            <Column>students.id</Column>
            <Column>students.name</Column>
            <Column>students.group_id</Column>
        </Columns>
        <Table>students</Table>
        <Command>
            <QueryType>SELECT</QueryType>
                <OutputColumns>
                    <Column>id</Column>
                    <Column>name</Column>
                    <Column>group_id</Column>
                </OutputColumns>
                <Tables>
                    <Table>persons</Table>
                </Tables>
                <Where>
                    <Conditions>
                        <Condition>
                            <Body>persons.name = ''Joe''</Body>
                        </Condition>
                    </Conditions>
                </Where>
        </Command>
    </Command>');
end;
/

begin
    xml_package.process_xml_dml(
    '<Command>
        <Type>UPDATE</Type>
        <Table>groups</Table>
        <SetCommands>
            <Set>name = ''Full group''</Set>
        </SetCommands>
        <Where>
            <Conditions>
                <Condition>
                    <Body>name IN</Body>
                    <Command>
                        <QueryType>SELECT</QueryType>
                        <OutputColumns>
                            <Column>name</Column>
                        </OutputColumns>
                        <Tables>
                            <Table>groups</Table>
                        </Tables>
                        <Where>
                            <Conditions>
                                <Condition>
                                    <Body>c_val >= 2</Body>
                                </Condition>
                            </Conditions>
                        </Where>
                    </Command>
                </Condition>
            </Conditions>
        </Where>
    </Command>');
    
end;
/

begin
    xml_package.process_xml_dml(
    '<Command>
        <Type>DELETE</Type>
        <Table>students</Table>
        <Where>
            <Conditions>
                <Condition>
                    <Body>students.name = ''Joe''</Body>
                </Condition>
            </Conditions>
        </Where>
    </Command>');
end;
/

select * from new_table;

BEGIN
    xml_package.process_xml_dml(
    '<Command>
        <Type>CREATE</Type>
        <Table>new_table</Table>
        <Columns>
            <Column>
                <Name>id</Name>
                <Type>NUMBER</Type>
                <Constraints>
                    <Constraint>NOT NULL</Constraint>
                </Constraints>
            </Column>
            <Column>
                <Name>name</Name>
                <Type>VARCHAR(100)</Type>
                <Constraints>
                    <Constraint>NOT NULL</Constraint>
                </Constraints>
            </Column>
        </Columns>
        <TableConstraints>
            <PrimaryKey>
                <Columns>
                    <Column>id</Column>
                </Columns>
            </PrimaryKey>
        </TableConstraints>
    </Command>');
end;
/

BEGIN
    xml_package.process_xml_dml(
'<Command>
    <Type>CREATE</Type>
    <Table>new_table_2</Table>
    <Columns>
        <Column>
            <Name>id</Name>
            <Type>NUMBER</Type>
            <Constraints>
                <Constraint>NOT NULL</Constraint>
            </Constraints>
        </Column>
        <Column>
            <Name>name</Name>
            <Type>VARCHAR(100)</Type>
            <Constraints>
                <Constraint>NOT NULL</Constraint>
            </Constraints>
        </Column>
        <Column>
            <Name>fk_id</Name>
            <Type>NUMBER</Type>
        </Column>
    </Columns>
    <TableConstraints>
        <PrimaryKey>
            <Columns>
                <Column>id</Column>
            </Columns>
        </PrimaryKey>
        <ForeignKey>
            <ChildColumns>
                <Column>fk_id</Column>
            </ChildColumns>
            <Parent>new_table</Parent>
            <ParentColumns>
                <Column>id</Column>
            </ParentColumns>
        </ForeignKey>
    </TableConstraints>
</Command>');
end;
/

begin
    xml_package.process_xml_dml(
    '<Command>
        <Type>DROP</Type>
        <Table>persons</Table>
    </Command>');
end;
/


--drop table new_table_2;
--drop table new_table;
--drop SEQUENCE new_table_pk_seq;
--drop SEQUENCE new_table_2_pk_seq;
--
--insert into new_table(name) values('Name');
--insert into new_table_2(name, fk_id) values('Name2', 2);
--select * from new_table;
--select * from new_table_2;
--
--CREATE TABLE new_table( col_1 NUMBER  NOT NULL, ID NUMBER PRIMARY KEY);
--
--CREATE SEQUENCE new_table_pk_seq;
--
--CREATE OR REPLACE TRIGGER new_table_trigger 
-- BEFORE INSERT ON new_table FOR EACH ROW 
--BEGIN 
-- IF inserting THEN 
-- IF :NEW.ID IS NULL THEN 
-- SELECT new_table_pk_seq.nextval INTO :NEW.ID FROM dual; 
-- END IF; 
-- END IF; 
--END;
--/
