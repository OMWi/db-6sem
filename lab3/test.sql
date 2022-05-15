--create procedure dev.test_proc as 
--begin
--    dbms_output.put_line('Hello world!');
--end;
--/
--create function dev.test_func return number as
--begin
--    return 0;
--end;
--/


BEGIN
    compare_schemas('DEV', 'PROD');
END;