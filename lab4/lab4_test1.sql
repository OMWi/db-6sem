--insert into groups values(2, 'group 2', 0);
insert into groups values(3, 'average group 2', 0);
insert into groups values(4, 'verage group 2', 0);

declare
    xml_rec xml_record:= xml_record();
    cur SYS_REFCURSOR;
    group_id number;
    group_name varchar(1000);
    group_cval number;
begin
    cur := xml_package.process_xml_select(
    '<Command>
        <QueryType>
            SELECT
        </QueryType>
        <OutputColumns>
            <Column>groups.id</Column>
            <Column>groups.name</Column>
            <Column>groups.c_val</Column>
        </OutputColumns>
        <Tables>
            <Table>groups</Table>
        </Tables>
        <Where>
            <Conditions>
                <Condition>
                    <Body>groups.name like ''%a%''</Body>
                </Condition>
            </Conditions>
        </Where>
    </Command>');
    loop
        fetch cur into group_id, group_name, group_cval;
        exit when cur%notfound;        
        dbms_output.put_line('Id: ' || group_id|| ' Name: ' || group_name|| ' Cval: ' || group_cval);
    end loop;
end;
