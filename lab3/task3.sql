create or replace procedure create_or_replace_object(dev_schema_name in varchar,
                                                     prod_schema_name in varchar,
                                                     object_type in varchar,
                                                     object_name in varchar) as
query_string varchar(200) := '';
begin
    IF object_type = 'PROCEDURE' or object_type = 'FUNCTION' THEN
        FOR src IN (SELECT line, text FROM all_source WHERE owner = dev_schema_name AND name = object_name) 
        LOOP
            IF src.line = 1 THEN
                query_string := 
                'CREATE OR REPLACE ' || replace(src.text, '    ' || lower(object_name), prod_schema_name || '.' || lower(object_name));
            ELSE
                query_string := query_string || src.text;
            END IF;
        END LOOP;
        dbms_output.put_line('Executing:');
        dbms_output.put_line(query_string);
        EXECUTE IMMEDIATE query_string;
    ELSIF object_type = 'TABLE' THEN
        query_string := 'CREATE TABLE ' ||  prod_schema_name || '.' || lower(object_name) || '(';
        FOR col IN (SELECT dev_table.column_name name, dev_table.data_type type, char_length FROM all_tab_columns dev_table
                    where dev_table.owner = dev_schema_name and dev_table.table_name = object_name) LOOP
        IF col.type = 'VARCHAR2' THEN
            query_string := query_string || lower(col.name) || ' ' || col.type || '('|| col.char_length || '), ';
        ELSE
            query_string := query_string || lower(col.name) || ' ' || col.type || ', ';
        END IF;
        END LOOP;
        query_string := SUBSTR(query_string, 1, length(query_string) - 2);
        query_string := query_string || ')';
        dbms_output.put_line('Executing:');
        dbms_output.put_line(query_string);
        EXECUTE IMMEDIATE query_string;
    END IF;
end;
/

create or replace procedure delete_object(prod_schema_name in varchar,
                                                     object_type in varchar,
                                                     object_name in varchar) as
query_string varchar(200);            
begin
    query_string := 'DROP ' || object_type || ' ' || prod_schema_name || '.' || object_name;
    dbms_output.put_line('Executing:');
    dbms_output.put_line(query_string);
    EXECUTE IMMEDIATE query_string;
end;
/

create or replace procedure add_cols_to_prod_table(dev_schema_name in varchar,
                                        prod_schema_name in varchar,
                                        tab_name in varchar) as
query_string varchar(200);
begin
    query_string := 'ALTER TABLE ' ||  prod_schema_name || '.' || lower(tab_name);
    for missing_col in (select distinct column_name, data_type
                        from all_tab_columns where owner = dev_schema_name
                        and table_name = tab_name  and (table_name, column_name) not in
                        (select table_name, column_name from all_tab_columns where owner = prod_schema_name)) loop
    query_string := query_string || ' ADD ' || missing_col.column_name || ' ' || missing_col.data_type;
    end loop;
    dbms_output.put_line('Executing:');
    dbms_output.put_line(query_string);
    EXECUTE IMMEDIATE query_string;

end;
/


create or replace procedure drop_cols_from_dev_table(dev_schema_name in varchar,
                                        prod_schema_name in varchar,
                                        tab_name in varchar) as
query_string varchar(200);
begin
    query_string := 'ALTER TABLE ' ||  prod_schema_name || '.' || lower(tab_name);
    for missing_col in (select distinct column_name
                        from all_tab_columns where owner = prod_schema_name
                        and table_name = tab_name  and (table_name, column_name) not in
                        (select table_name, column_name from all_tab_columns where owner = dev_schema_name)) loop
    query_string := query_string || ' DROP COLUMN ' || missing_col.column_name;
    end loop;
    dbms_output.put_line('Executing:');
    dbms_output.put_line(query_string);
    EXECUTE IMMEDIATE query_string;
end;
/


create or replace procedure compare_schemas(dev_schema_name in varchar, prod_schema_name in varchar) as
type char_array is varray(4) of varchar2(20);
obj_types char_array := char_array('PROCEDURE', 'FUNCTION', 'PACKAGE', 'TABLE');
tables_to_create char_array:= char_array();
different_count NUMBER := 0; 
BEGIN    
    FOR i IN 1 .. obj_types.count LOOP
        FOR common_object in (SELECT object_name as name FROM all_objects
                                       where owner = prod_schema_name and object_type = obj_types(i)
                                       INTERSECT
                                       SELECT object_name as name FROM all_objects
                                       where owner = dev_schema_name and object_type = obj_types(i)) LOOP
            
            IF obj_types(i) = 'TABLE' THEN
                SELECT COUNT(*) INTO different_count FROM
                            (SELECT dev_table.column_name, dev_table.data_type FROM all_tab_columns dev_table
                             where dev_table.owner = dev_schema_name and dev_table.table_name = common_object.name
                             EXCEPT
                             SELECT prod_table.column_name, prod_table.data_type FROM all_tab_columns prod_table
                             where prod_table.owner = prod_schema_name and prod_table.table_name = common_object.name);
                             IF different_count > 0 THEN
                                 dbms_output.put_line('Missing columns in ' || prod_schema_name || ' from table ' || common_object.name);
--                                 dbms_output.put_line('Some columns of ' || common_object.name || ' in ' || dev_schema_name || ' are missing from ' || prod_schema_name);
                                 add_cols_to_prod_table(dev_schema_name, prod_schema_name, common_object.name);
--                             ELSE
--                                dbms_output.put_line('Same columns in table ' || common_object.name);
--                                dbms_output.put_line(obj_types(i) ||' structure of ' || common_object.name || ' the same');
                             END IF;
                            
                SELECT COUNT(*) INTO different_count FROM
                            (SELECT prod_table.column_name, prod_table.data_type FROM all_tab_columns prod_table
                             where prod_table.owner = prod_schema_name and prod_table.table_name = common_object.name
                             EXCEPT
                             SELECT dev_table.column_name, dev_table.data_type FROM all_tab_columns dev_table
                             where dev_table.owner = dev_schema_name and dev_table.table_name = common_object.name);
                             
                             IF different_count > 0 THEN
                                 dbms_output.put_line('Missing columns in ' || dev_schema_name || ' from table ' || common_object.name);
--                                 dbms_output.put_line('Some columns of ' || common_object.name || ' in ' || prod_schema_name || ' are missing from ' || dev_schema_name);
                                 drop_cols_from_dev_table(dev_schema_name, prod_schema_name, common_object.name);
--                             ELSE
--                                dbms_output.put_line('Same columns in table' || common_object.name);
--                                dbms_output.put_line(obj_types(i) ||' structure of ' || common_object.name || ' the same');
                             END IF;
            ELSIF obj_types(i) = 'PROCEDURE' OR obj_types(i) = 'FUNCTION' THEN
                SELECT COUNT(*) INTO different_count FROM
                                     all_source src1
                                     JOIN all_source src2 ON src1.name = src2.name
                                     WHERE src1.name = common_object.name
                                            AND src1.line = src2.line
                                            AND src1.text != src2.text
                                            AND src1.owner = dev_schema_name
                                            AND src2.owner = prod_schema_name;
                
                    IF different_count > 0 THEN
                        dbms_output.put_line('Source code differs in ' || obj_types(i) || ' ' || common_object.name);
--                        dbms_output.put_line(obj_types(i) || ' structure of ' || common_object.name || ' is different in ' ||
--                        dev_schema_name || ' and ' || prod_schema_name);
                        create_or_replace_object(dev_schema_name, prod_schema_name, obj_types(i), common_object.name);
--                    ELSE
--                        dbms_output.put_line(obj_types(i) ||' structure of ' || common_object.name || ' the same');
                    END IF;
            END IF;
            
        END LOOP;

        FOR missing_object in (SELECT object_name as name FROM all_objects
                                   where owner = dev_schema_name and object_type = obj_types(i)
                                   MINUS
                                   SELECT object_name as name FROM all_objects
                                   where owner = prod_schema_name and object_type = obj_types(i))
        LOOP
            dbms_output.put_line('Missing ' || obj_types(i) || ' ' || missing_object.name || ' in '|| prod_schema_name);
--            dbms_output.put_line(obj_types(i) || ' ' || missing_object.name || ' from '|| dev_schema_name || ' is missing from ' || prod_schema_name);
            IF obj_types(i) = 'TABLE' THEN
                tables_to_create.extend();
                tables_to_create(tables_to_create.last) := missing_object.name;
            ELSE
                create_or_replace_object(dev_schema_name, prod_schema_name, obj_types(i), missing_object.name);
            END IF;
        END LOOP;
        
        FOR missing_object in (SELECT object_name as name FROM all_objects
                                   where owner = prod_schema_name and object_type = obj_types(i)
                                   MINUS
                                   SELECT object_name as name FROM all_objects
                                   where owner = dev_schema_name and object_type = obj_types(i))
        LOOP
            dbms_output.put_line('Missing ' || obj_types(i) || ' ' || missing_object.name || ' in '|| dev_schema_name);
--            dbms_output.put_line(obj_types(i) || ' ' || missing_object.name || ' from '|| prod_schema_name ||' is missing from ' || dev_schema_name);
            delete_object(prod_schema_name, obj_types(i), missing_object.name);
        END LOOP;
    END LOOP;
    delete from foreign_table_links;
    dbms_output.put_line('Table creation order:');
--    dbms_output.put_line('Order of table creation in ' || prod_schema_name|| ': ');
    
    FOR i in 1 .. tables_to_create.count LOOP    
        INSERT INTO foreign_table_links (child_table_name, parent_table_name)
            SELECT DISTINCT all_cons.table_name, parent_cons.table_name
            FROM all_cons_columns all_cons
            
                JOIN all_constraints cons
                    ON all_cons.owner = cons.owner and all_cons.constraint_name = cons.constraint_name
                JOIN all_constraints parent_cons
                    ON cons.r_owner = parent_cons.owner and cons.r_constraint_name = parent_cons.constraint_name
                    
            WHERE cons.constraint_type = 'R'
            AND all_cons.table_name = tables_to_create(i) AND all_cons.owner = dev_schema_name;
            
            IF SQL%rowcount = 0 THEN
                create_or_replace_object(dev_schema_name, prod_schema_name, 'TABLE', tables_to_create(i));
            END IF;
    END LOOP;
    
    FOR current_foreign_key IN (
        SELECT
            child_table_name,
            parent_table_name,
            CONNECT_BY_ISCYCLE
        FROM
            foreign_table_links
        CONNECT BY NOCYCLE
            PRIOR parent_table_name = child_table_name
        ORDER BY
            level
    ) LOOP
        IF current_foreign_key.connect_by_iscycle = 0 THEN
            create_or_replace_object(dev_schema_name, prod_schema_name, 'TABLE', current_foreign_key.child_table_name);
        ELSE
            dbms_output.put_line('Found cycle in ' || current_foreign_key.child_table_name);
        END IF;
    END LOOP;
END;
/


--
--select distinct column_name, data_type
--                            from all_tab_columns where owner = 'DEV'
--                            and table_name = ''  and (table_name, column_name) not in
--                            (select table_name, column_name from all_tab_columns where owner = prod_schema_name)
                            
--    query_string := 'CREATE OR REPLACE TABLE ' ||  'PROD' || '.' || 'books' || '(';
--        FOR col IN (select dev_name, type, con_name, con_col_name, r_owner, r_constraint_name from 
--                    (SELECT dev_table.column_name dev_name, dev_table.data_type type FROM all_tab_columns dev_table
--                    where dev_table.owner = 'DEV' and dev_table.table_name = 'BOOKS') col1
--                    JOIN
--                    (SELECT cons.constraint_name con_name, all_cons.column_name con_col_name, cons.r_owner r_owner, cons.r_constraint_name r_constraint_name
--                    FROM all_cons_columns all_cons
--                    JOIN all_constraints cons
--                        ON all_cons.owner = cons.owner and all_cons.constraint_name = cons.constraint_name
--                    WHERE all_cons.table_name = 'BOOKS' AND all_cons.owner = 'DEV'
--                ) col2 on col1.dev_name = col2.con_col_name )  LOOP
--        query_string := query_string || lower(col.dev_name) || ' ' || col.type || ', ';
--        if col.con_name is not null then
--            query_string := query_string || col.con_name || ' ' || col.r_owner || ' ' || col.con_name || ' ' || col.r_constraint_name;
--        end if;
--        END LOOP;
--        query_string := SUBSTR(query_string, 1, length(query_string) - 2);
--        query_string := query_string || ');';
--        dbms_output.put_line(query_string);
--        EXECUTE IMMEDIATE query_string;
--        EXECUTE IMMEDIATE 'CREATE TABLE PROD.books(id NUMBER, name VARCHAR2(20), student_id NUMBER, price NUMBER)';