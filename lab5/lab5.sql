drop table GROUPS;
CREATE TABLE GROUPS
(
    id    number,
    name  VARCHAR2(200),
    c_val NUMBER
);

drop table STUDENTS;
CREATE TABLE STUDENTS
(
    id       number,
    name     VARCHAR2(200),
    group_id NUMBER,
    datetime TIMESTAMP DEFAULT SYSTIMESTAMP
);

drop table TEST_TABLE;
CREATE TABLE TEST_TABLE
(
    id   number,
    val  number,
    name VARCHAR2(200)
);

drop table GROUPS_LOGS;
CREATE TABLE GROUPS_LOGS
(
    id          number,
    action      VARCHAR2(200),
    update_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    id_old      NUMBER,
    name_old    VARCHAR2(200),
    c_val_old   NUMBER,
    id_new      NUMBER,
    name_new    VARCHAR2(200),
    c_val_new   NUMBER
);
ALTER TABLE GROUPS_LOGS
    ADD (CONSTRAINT GROUPS_LOGS_pk PRIMARY KEY (id));
drop sequence GROUPS_LOGS_seq;
CREATE SEQUENCE GROUPS_LOGS_seq START WITH 1;
CREATE OR REPLACE TRIGGER GROUPS_LOGS_bir
    BEFORE INSERT
    ON GROUPS_LOGS
    FOR EACH ROW
BEGIN
    SELECT GROUPS_LOGS_seq.NEXTVAL
    INTO :new.id
    FROM dual;
END;
/

drop table students_logs;
CREATE TABLE STUDENTS_LOGS
(
    id           number,
    action       VARCHAR2(200),
    update_date  TIMESTAMP DEFAULT SYSTIMESTAMP,
    id_old       NUMBER,
    name_old     VARCHAR2(200),
    group_id_old NUMBER,
    datetime_old TIMESTAMP,
    id_new       NUMBER,
    name_new     VARCHAR2(200),
    group_id_new NUMBER,
    datetime_new TIMESTAMP
);
ALTER TABLE STUDENTS_LOGS
    ADD (CONSTRAINT STUDENTS_LOGS_pk PRIMARY KEY (id));
drop sequence STUDENTS_LOGS_seq;
CREATE SEQUENCE STUDENTS_LOGS_seq START WITH 1;
CREATE OR REPLACE TRIGGER STUDENTS_LOGS_bir
    BEFORE INSERT
    ON STUDENTS_LOGS
    FOR EACH ROW
BEGIN
    SELECT STUDENTS_LOGS_seq.NEXTVAL
    INTO :new.id
    FROM dual;
END;
/

drop table TEST_TABLE_LOGS;
CREATE TABLE TEST_TABLE_LOGS
(
    id          number,
    action      VARCHAR2(200),
    update_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    id_old      NUMBER,
    name_old    VARCHAR2(200),
    val_old     NUMBER,
    id_new      NUMBER,
    name_new    VARCHAR2(200),
    val_new     NUMBER
);
ALTER TABLE TEST_TABLE_LOGS
    ADD (CONSTRAINT TABLE22_LOGS_pk PRIMARY KEY (id));
drop sequence TEST_TABLE_LOGS_seq;
CREATE SEQUENCE TEST_TABLE_LOGS_seq START WITH 1;
CREATE OR REPLACE TRIGGER TEST_TABLE_LOGS_bir
    BEFORE INSERT
    ON TEST_TABLE_LOGS
    FOR EACH ROW
BEGIN
    SELECT TEST_TABLE_LOGS_seq.NEXTVAL
    INTO :new.id
    FROM dual;
END;
/


--drop trigger GROUPS_TRIGGER;
create or replace TRIGGER GROUPS_TRIGGER
    AFTER INSERT OR DELETE OR UPDATE
    ON GROUPS
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO GROUPS_LOGS (action, id_new, name_new, c_val_new)
        VALUES ('INSERT', :NEW.id, :NEW.name, :NEW.c_val);
    ELSIF DELETING THEN
        INSERT INTO GROUPS_LOGS (action, id_old, name_old, c_val_old)
        VALUES ('DELETE', :OLD.id, :OLD.name, :OLD.c_val);
    ELSIF UPDATING THEN
        INSERT INTO GROUPS_LOGS (action, id_old, name_old, c_val_old, id_new, name_new, c_val_new)
        VALUES ('UPDATE', :OLD.id, :OLD.name, :OLD.c_val, :NEW.id, :NEW.name, :NEW.c_val);
    END IF;
END;
/

--drop trigger STUDENTS_TRIGGER;
create or replace TRIGGER STUDENTS_TRIGGER
    AFTER INSERT OR DELETE OR UPDATE
    ON STUDENTS
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO STUDENTS_LOGS (action, id_new, name_new, group_id_new, datetime_new)
        VALUES ('INSERT', :NEW.id, :NEW.name, :NEW.group_id, :NEW.datetime);
    ELSIF DELETING THEN
        INSERT INTO STUDENTS_LOGS (action, id_new, name_new, group_id_old, datetime_old)
        VALUES ('DELETE', :OLD.id, :OLD.name, :OLD.group_id, :OLD.datetime);
    ELSIF UPDATING THEN
        INSERT INTO STUDENTS_LOGS (action, id_old, name_old, group_id_old, id_new, name_new, group_id_new, datetime_old,
                                   datetime_new)
        VALUES ('UPDATE', :OLD.id, :OLD.name, :OLD.group_id, :NEW.id, :NEW.name, :NEW.group_id, :OLD.datetime,
                :NEW.datetime);
    END IF;
END;
/

--drop trigger TEST_TABLE_TRIGGER;
create or replace TRIGGER TEST_TABLE_TRIGGER
    AFTER INSERT OR DELETE OR UPDATE
    ON TEST_TABLE
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO TEST_TABLE_LOGS (action, id_new, val_new, name_new)
        VALUES ('INSERT', :NEW.id, :NEW.val, :NEW.name);
    ELSIF DELETING THEN
        INSERT INTO TEST_TABLE_LOGS (action, id_old, val_old, name_old)
        VALUES ('DELETE', :OLD.id, :OLD.val, :OLD.name);
    ELSIF UPDATING THEN
        INSERT INTO TEST_TABLE_LOGS (action, id_old, val_old, name_old, id_new, val_new, name_new)
        VALUES ('UPDATE', :OLD.id, :OLD.val, :OLD.name, :NEW.id, :NEW.val, :NEW.name);
    END IF;
END;
/

create or replace package lab5_package as
    procedure recovery(time_stamp in timestamp);
    procedure recovery(time_delta in number);
end;
/

create or replace package body lab5_package as
    PROCEDURE recovery(time_stamp in TIMESTAMP) IS
        log_student students_logs%ROWTYPE DEFAULT NULL;
        log_group   groups_logs%ROWTYPE DEFAULT NULL;
        log_mytable TEST_TABLE_LOGS%ROWTYPE DEFAULT NULL;
    BEGIN
        delete from TEST_TABLE;
        for log_mytable in (SELECT * FROM TEST_TABLE_LOGS WHERE TEST_TABLE_LOGS.update_date <= time_stamp ORDER BY update_date)
            loop
                IF log_mytable.action = 'INSERT' THEN
                    INSERT INTO TEST_TABLE(ID, VAL, NAME)
                    VALUES (log_mytable.id_new, log_mytable.val_new, log_mytable.name_new);

                ELSIF log_mytable.action = 'UPDATE' THEN
                    UPDATE TEST_TABLE
                    SET id   = log_mytable.id_new,
                        name = log_mytable.name_new,
                        val  = log_mytable.val_new
                    WHERE id = log_mytable.id_old
                      AND name = log_mytable.name_old
                      AND val = log_mytable.val_old;

                ELSIF log_mytable.action = 'DELETE' THEN
                    DELETE FROM TEST_TABLE WHERE ID = log_mytable.id_old;
                END IF;
            end loop;


        delete from students;
        for log_student in (SELECT * FROM STUDENTS_LOGS WHERE update_date <= time_stamp ORDER BY update_date)
            loop
                IF log_student.action = 'INSERT' THEN
                    INSERT INTO students(id, name, group_id, datetime)
                    VALUES (log_student.id_new,
                            log_student.name_new,
                            log_student.group_id_new,
                            log_student.datetime_new);

                ELSIF log_student.action = 'UPDATE' THEN
                    UPDATE students
                    SET id       = log_student.id_new,
                        name     = log_student.name_new,
                        group_id = log_student.group_id_new,
                        datetime = log_student.datetime_new
                    WHERE id = log_student.id_old;

                ELSIF log_student.action = 'DELETE' THEN
                    DELETE FROM STUDENTS where id = log_student.id_new;
                END IF;

            end loop;

        delete from GROUPS;
        for log_group in (SELECT * FROM GROUPS_LOGS WHERE GROUPS_LOGS.update_date <= time_stamp ORDER BY update_date)
            loop
                IF log_group.action = 'INSERT' THEN
                    INSERT INTO GROUPS(ID, NAME, C_VAL)
                    VALUES (log_group.id_new, log_group.name_new, log_group.c_val_new);

                ELSIF log_group.action = 'UPDATE' THEN
                    UPDATE groups
                    SET id     = log_group.id_new,
                        name   = log_group.name_new,
                        c_val = log_group.c_val_new
                    WHERE id = log_group.id_old;

                ELSIF log_group.action = 'DELETE' THEN
                    DELETE FROM GROUPS WHERE ID = log_group.id_old;
                END IF;

            end loop;

    END;

    PROCEDURE recovery(time_delta in NUMBER)
        IS
        time_stamp TIMESTAMP;
    BEGIN
        time_stamp := SYSTIMESTAMP - INTERVAL '1' SECOND * time_delta;
        DBMS_OUTPUT.PUT_LINE('recovering to ' || time_stamp);
        recovery(time_stamp);
    END;
END;
/

create or replace procedure get_html(required_date in timestamp) IS
    log_html_report varchar(3000);
begin
    log_html_report := '<html><head>
    <style>
        table, th, td {
            border: 1px solid black;
        }
    </style>
    </head><body>
    <table>
    <h2>students:</h1>
    <tr align="center">
    <th align="center">Action</th>
    <th align="center">Date</th>
    </tr>';
    for l_rec in (select * from students_logs where update_date > required_date)
        loop
            log_html_report := log_html_report || '<tr> <td>' || l_rec.action || '</td> <td>' || l_rec.update_date || '</td> </tr>';
        end loop;
    log_html_report := log_html_report || '</table></body></html>';
    DBMS_OUTPUT.PUT_LINE(log_html_report);


    log_html_report := '<html><head>
    </head><body>
    <table>
    <h2>groups:</h1>
    <tr align="center">
    <th align="center">Action</th>
    <th align="center">Date</th>
    </tr>';
    for l_rec in (select * from groups_logs where update_date > required_date)
        loop
            log_html_report := log_html_report || '<tr> <td>' || l_rec.action || '</td> <td>' || l_rec.update_date || '</td> </tr>';
        end loop;
    log_html_report := log_html_report || '</table></body></html>';
    DBMS_OUTPUT.PUT_LINE(log_html_report);

    log_html_report := '<html><head>
    </head><body>
    <table>
    <h2>test_table</h1>
    <tr align="center">
    <th align="center">Action</th>
    <th align="center">Date</th>
    </tr>';
    for l_rec in (select * from TEST_TABLE_LOGS where update_date > required_date)
        loop
            log_html_report := log_html_report || '<tr> <td>' || l_rec.action || '</td> <td>' || l_rec.update_date || '</td> </tr>';
        end loop;
    log_html_report := log_html_report || '</table></body></html>';

    DBMS_OUTPUT.PUT_LINE(log_html_report);
end;
/
