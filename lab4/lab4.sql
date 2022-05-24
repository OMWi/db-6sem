drop type xml_record;

create type xml_record is table of VARCHAR2(1000);
/

create or replace package xml_package as
    function extract_xml_value(xml_string in varchar, xpath_string in varchar) return xml_record;
    
    function extract_inner_xml(xml_string in varchar, xpath_string in varchar) return xml_record;
    
    function get_first_value(current_record in xml_record) return varchar;
    
    function get_select_string(xml_string in varchar) return varchar;
    
    function get_where_string(xml_string in varchar) return varchar;
    
    function get_insert_string(xml_string in varchar) return varchar;
    
    function get_update_string(xml_string in varchar) return varchar;
    
    function get_delete_string ( xml_string in varchar) return varchar;
    
    function get_drop_string(xml_string in varchar) return varchar;
    
    function get_create_string(xml_string in varchar) return varchar;
    
    function process_xml_select(xml_string in varchar) return SYS_REFCURSOR;
    
    function generate_auto_increment (table_name in varchar, pk_name in varchar) return varchar;
    
    procedure process_xml_dml(xml_string in varchar);
    
end xml_package;
/

create or replace package body xml_package as

    function extract_xml_value(xml_string in varchar, xpath_string in varchar) 
    return xml_record is
        xml_rec xml_record:= xml_record();
        current_rec varchar(1000) := '';
        current_index number:= 1;
    BEGIN
        select extractvalue(xmltype(xml_string), xpath_string || '['|| current_index || ']') into current_rec from dual;
        
        while current_rec is not null
        loop
            xml_rec.extend();
            xml_rec(current_index) := trim(current_rec);
            current_index := current_index + 1;
            select extractvalue(xmltype(xml_string), xpath_string || '['|| current_index || ']') into current_rec from dual;
            
        end loop;
        
        return xml_rec;
    end;
    
    function extract_inner_xml(xml_string in varchar, xpath_string in varchar) 
    return xml_record is
        xml_rec xml_record:= xml_record();
        current_rec varchar(1000) := '';
        current_index number:= 1;
    BEGIN
        SELECT
            extract(xmltype(xml_string), xpath_string|| '['|| current_index || ']').getstringval()
        INTO current_rec
        FROM
            dual;

        WHILE current_rec IS NOT NULL LOOP
            xml_rec.extend();
            xml_rec(current_index) := trim(current_rec);
            current_index := current_index + 1;
            SELECT
                extract(xmltype(xml_string), xpath_string
                                             || '['
                                             || current_index
                                             || ']').getstringval()
            INTO current_rec
            FROM
                dual;

        END LOOP;
        
        return xml_rec;
    end;
    
    function get_first_value(current_record in xml_record) return varchar is
    res varchar(1000);
    begin
        if current_record.count > 0 then
            res := current_record(1);
        end if;
        
        return res;
    end;
    
    
    function process_xml_select(xml_string in varchar) return SYS_REFCURSOR is
        cur SYS_REFCURSOR;
        command_string varchar(1000);
    begin
        command_string := get_select_string(xml_string);
        dbms_output.put_line(command_string);
        open cur for command_string;
        return cur;
    end;
    
    procedure process_xml_dml(xml_string in varchar) is
        command_type varchar(1000);
        command_string varchar(1000);
    begin
        command_type := get_first_value(extract_xml_value(xml_string,'Command/Type'));
        if command_type = 'INSERT' then
            command_string := get_insert_string(xml_string);
        elsif command_type = 'UPDATE' then
            command_string := get_update_string(xml_string);
        elsif command_type = 'DELETE' then
            command_string := get_delete_string(xml_string);
        elsif command_type = 'DROP' then
            command_string := get_drop_string(xml_string);
        elsif command_type = 'CREATE' then
            command_string := get_create_string(xml_string);
        else
            raise_application_error(-20002, 'Command type is undefined.');
        end if;
            dbms_output.put_line(command_string);
            execute immediate command_string;
    end;
    
    function get_select_string(xml_string in varchar) return varchar is
        tables_list    xml_record := xml_record();
        columns_list   xml_record := xml_record();
        filters        xml_record := xml_record();
        join_type      VARCHAR2(1000);
        join_condition VARCHAR2(1000);
        select_query   VARCHAR2(1000) := 'SELECT';
    begin
        tables_list := extract_xml_value(xml_string, 'Command/Tables/Table');
        columns_list := extract_xml_value(xml_string, 'Command/OutputColumns/Column');
        select_query := select_query || ' ' || columns_list(1);
        
        FOR col_index IN 2..columns_list.count LOOP
            select_query := select_query || ', ' || columns_list(col_index);
        END LOOP;
        
        select_query := select_query || ' FROM ' || tables_list(1);
        
        FOR i IN 2..tables_list.count LOOP
            SELECT extractvalue(xmltype(xml_string), 'Command/Joins/Join'
                                                  || '['
                                                  ||(i - 1)
                                                  || ']/Type')
            INTO join_type
            FROM dual;

            SELECT extractvalue(xmltype(xml_string), 'Command/Joins/Join'
                                                  || '['
                                                  ||(i - 1)
                                                  || ']/Condition')
            INTO join_condition
            FROM dual;

            select_query := select_query
                            || ' '
                            || join_type
                            || ' '
                            || tables_list(i)
                            || ' ON '
                            || join_condition;

        END LOOP;
        
        select_query := select_query || get_where_string(xml_string);
        return select_query;
    end;
    
    function get_where_string(xml_string in varchar) return varchar as
        where_conditions xml_record := xml_record();
        where_string varchar(1000) := ' WHERE';
        condition_body varchar(1000);
        inner_command varchar(1000);
        condition_operator varchar(1000);
        current_record varchar(1000);
        current_index number:= 0;
        temp_record xml_record := xml_record();
    begin
        where_conditions := extract_inner_xml(xml_string, 'Command/Where/Conditions/Condition');
        
        if where_conditions.count > 0 then
            where_string := ' WHERE';
        else
            where_string := '';
        end if;

        for i in 1..where_conditions.count loop
            condition_body := get_first_value(extract_xml_value(where_conditions(i), 'Condition/Body'));
            inner_command := get_first_value(extract_inner_xml(where_conditions(i),'Condition/Command'));
            condition_operator := get_first_value(extract_xml_value(where_conditions(i), 'Condition/Operator'));
                
            IF inner_command IS NOT NULL THEN
                inner_command := get_select_string(inner_command);
                inner_command := '(' || inner_command || ')';
            END IF;

            where_string := where_string
                            || ' '
                            || trim(condition_body)
                            || ' '
                            || inner_command
                            || trim(condition_operator);
        end loop;
        
        return where_string;
    end;
    
    function get_insert_string(xml_string in varchar) return varchar is
        values_to_insert VARCHAR2(1000);
        inner_select VARCHAR(1000);
        values_list xml_record := xml_record();
        columns_list xml_record := xml_record();
        insert_query VARCHAR2(1000);
        table_name VARCHAR(200);
        columns_string VARCHAR2(200);
    begin
        values_to_insert := get_first_value(extract_inner_xml(xml_string, 'Command/Values'));
        table_name := get_first_value(extract_xml_value(xml_string, 'Command/Table'));
        
        columns_list := extract_xml_value(xml_string, 'Command/Columns/Column');
        columns_string := '(' || columns_list(1);
        
        FOR i IN 2..columns_list.count LOOP
            columns_string := columns_string
                           || ', '
                           || columns_list(i);
        END LOOP;

        columns_string := columns_string || ')';
        
        insert_query := 'INSERT INTO '
                        || table_name
                        || columns_string;
        
        IF values_to_insert IS NOT NULL THEN
            values_list := extract_xml_value(values_to_insert, 'Values/Value');
            insert_query := insert_query
                            || ' VALUES( '
                            || values_list(1);

            FOR i IN 2..values_list.count LOOP
                insert_query := insert_query
                                || ', '
                                || values_list(i);
            END LOOP;
            
            insert_query := insert_query || ')';
        else
            inner_select := get_first_value(extract_inner_xml(xml_string, 'Command/Command'));

            insert_query := insert_query
                            || ' '
                            || get_select_string(inner_select);
        end if;
        
        return insert_query;
    end;
    
    function get_update_string(xml_string in varchar) return varchar is
        set_commands xml_record := xml_record();
        update_query VARCHAR2(1000) := 'UPDATE ';
        table_name VARCHAR(200);
    begin
        table_name := get_first_value(extract_xml_value(xml_string, 'Command/Table'));
       
        set_commands := extract_xml_value(xml_string, 'Command/SetCommands/Set');
        update_query := update_query
                        || table_name
                        || ' SET '
                        || set_commands(1);
        
        FOR i IN 2..set_commands.count LOOP
            update_query := update_query
                            || ', '
                            || set_commands(i);
        END LOOP;
        
        update_query := update_query || get_where_string(xml_string);
        return update_query;
    end;
    
    function get_delete_string (xml_string in varchar) return varchar as
        delete_query varchar(1000) := 'DELETE FROM ';
        table_name   varchar(100);
    begin
        table_name := get_first_value(extract_xml_value(xml_string, 'Command/Table'));

        delete_query := delete_query
                        || table_name
                        || ' '
                        || get_where_string(xml_string);

        return delete_query;
    end;
    
    function get_drop_string(xml_string in varchar) return varchar as
        drop_query varchar2(1000) := 'DROP TABLE ';
        table_name varchar2(100);
    begin
        table_name := get_first_value(extract_xml_value(xml_string, 'Command/Table'));

        drop_query := drop_query
                      || table_name;
        return drop_query;
    end;
    
    function get_create_string(xml_string in varchar) return varchar as
        col_name              varchar(100);
        col_type              varchar(100);
        parent_table          varchar(100);
        constraint_value      varchar(100);
        temporal_record       xml_record := xml_record();
        temporal_string       varchar(100);
        create_query          varchar(1000) := 'begin execute immediate ''CREATE TABLE';
        primary_constraint    varchar(1000);
        auto_increment        varchar(1000);
        table_columns         xml_record := xml_record();
        table_name            varchar(100);
        col_constraints       xml_record := xml_record();
        table_constraints     xml_record := xml_record();
    begin
        table_name := get_first_value(extract_xml_value(xml_string, 'Command/Table'));

        create_query := create_query
                        || ' '
                        || table_name
                        || '(';
                        
        table_columns := extract_inner_xml(xml_string, 'Command/Columns/Column');
        FOR i IN 1..table_columns.count LOOP
            constraint_value := '';
            col_name := get_first_value(extract_xml_value(table_columns(i), 'Column/Name'));
            col_type := get_first_value(extract_xml_value(table_columns(i), 'Column/Type'));

            col_constraints := extract_xml_value(table_columns(i), 'Column/Constraints/Constraint');
            FOR i IN 1..col_constraints.count LOOP
                constraint_value := constraint_value
                                    || ' '
                                    || col_constraints(i);
            END LOOP;

            create_query := create_query
                            || ' '
                            || col_name
                            || ' '
                            || col_type
                            || ' '
                            || constraint_value;

            IF i != table_columns.count THEN
                create_query := create_query || ', ';
            END IF;

        END LOOP;
        
        primary_constraint := get_first_value(extract_xml_value(xml_string, 'Command/TableConstraints/PrimaryKey/Columns/Column'));
        
        IF primary_constraint IS NOT NULL THEN

            create_query := create_query
                            || ', CONSTRAINT '
                            || table_name
                            || '_pk '
                            || 'PRIMARY KEY ('
                            || primary_constraint
                            || ')';
            auto_increment := generate_auto_increment(table_name, primary_constraint);
        else
            auto_increment := generate_auto_increment(table_name, 'ID');
            create_query := create_query || ', ID NUMBER PRIMARY KEY';
        end if;
        
        table_constraints := extract_inner_xml(xml_string, 'Command/TableConstraints/ForeignKey');
        
        FOR i IN 1..table_constraints.count LOOP
            parent_table := extract_xml_value(table_constraints(i), 'ForeignKey/Parent')(1);

            temporal_record := extract_xml_value(table_constraints(i), 'ForeignKey/ChildColumns/Column');
            temporal_string := temporal_record(1);
            FOR i IN 2..temporal_record.count LOOP
                temporal_string := temporal_string
                                   || ', '
                                   || temporal_record(i);
            END LOOP;

            create_query := create_query
                            || ', CONSTRAINT '
                            || table_name
                            || '_'
                            || parent_table
                            || '_fk '
                            || 'Foreign Key'
                            || '('
                            || temporal_string
                            || ') ';

            temporal_record := extract_xml_value(table_constraints(i), 'ForeignKey/ParentColumns/Column');
            temporal_string := temporal_record(1);
            FOR i IN 2..temporal_record.count LOOP
                temporal_string := temporal_string
                                   || ', '
                                   || temporal_record(i);
            END LOOP;

            create_query := create_query
                            || 'REFERENCES '
                            || parent_table
                            || '('
                            || temporal_string
                            || ')';

        END LOOP;
        
        create_query := create_query
                        || ')'';'
                        || chr(10)
                        || auto_increment
                        || 'end;';
        
        return create_query;
    end;
    
    function generate_auto_increment (table_name in varchar, pk_name in varchar) return varchar as
        generated_script varchar(1000);
    begin
        generated_script := 'execute immediate ''CREATE SEQUENCE '
                            || table_name
                            || '_pk_seq'''
                            || ';'
                            || chr(10);
        generated_script := generated_script
                            || 'execute immediate ''CREATE OR REPLACE TRIGGER '
                            || table_name
                            || '_trigger '
                            || chr(10)
                            || ' BEFORE INSERT ON '
                            || table_name
                            || ' FOR EACH ROW '
                            || chr(10)
                            || 'BEGIN '
                            || chr(10)
                            || ' IF inserting THEN '
                            || chr(10)
                            || ' IF :NEW.'|| pk_name ||' IS NULL THEN '
                            || chr(10)
                            || ' SELECT '
                            || table_name
                            || '_pk_seq'
                            || '.nextval INTO :NEW.'|| pk_name ||' FROM dual; '
                            || chr(10)
                            || ' END IF; '
                            || chr(10)
                            || ' END IF; '
                            || chr(10)
                            || 'END;'';';
    
        return generated_script;
    end;
    
end xml_package;
/
