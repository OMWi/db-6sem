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

SELECT text FROM all_source WHERE owner = 'DEV' AND name = 'PROC';
SELECT text FROM all_source WHERE owner = 'DEV' AND name = 'TEST_PROC';
SELECT text FROM all_source WHERE owner = 'DEV' AND name = 'TEST_FUNC';
--SELECT text FROM all_source where name = 'GROUPS';
--drop TABLE PROD.books;

BEGIN
    compare_schemas('DEV', 'PROD');
END;