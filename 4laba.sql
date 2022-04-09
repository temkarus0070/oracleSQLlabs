--Претков Артем
/*
 1.	В анонимном PL/SQL блоке распечатать все пифагоровы числа, меньшие 25 (для печати использовать пакет dbms_output, процедуру put_line).
 */
declare
    i_var number;
    j_var number;
    k_var number;
BEGIN
    for i_var in 1..25
        loop
            for j_var in 1..25
                loop
                    for k_var in 1..25
                        loop
                            if i_var * i_var + j_var * j_var = k_var * k_var then
                                DBMS_OUTPUT.PUT_LINE(i_var || ' ' || j_var || ' ' || k_var);
                            end if;
                        end loop;
                end loop;
        end loop;
END;

/*
 2.	Переделать предыдущий пример, чтобы для определения, что 3 числа пифагоровы использовалась функция.
 */


declare
    i_var number;
    j_var number;
    k_var number;
    function is_piff_num(i_var number, j_var number, k_var number) return number
        is
    begin
        if i_var * i_var + j_var * j_var = k_var * k_var then
            return 1;
        else
            return 0;
        end if;
    end;
BEGIN
    for i_var in 1..25
        loop
            for j_var in 1..25
                loop
                    for k_var in 1..25
                        loop
                            if is_piff_num(i_var, j_var, k_var) = 1 then
                                DBMS_OUTPUT.PUT_LINE(i_var || ' ' || j_var || ' ' || k_var);
                            end if;
                        end loop;
                end loop;
        end loop;
END;


/*
 3.	Написать хранимую процедуру, которой передается ID сотрудника и которая увеличивает ему зарплату на 10%, если в 2000 году
 у сотрудника были продажи. Использовать выборку количества заказов за 2000 год в переменную. А затем, если переменная больше 0, выполнить update данных.
 */

create or replace procedure increase_salary(emp_id_var number)
    is
    v_orders_count NUMBER;
begin
    SELECT count(o.*)
    into v_orders_count
    FROM ORDERS o
    where o.SALES_REP_ID = emp_id_var;

    if v_orders_count > 0 then
        UPDATE EMPLOYEES set SALARY=SALARY*1.1
            WHERE EMPLOYEE_ID=emp_id_var;
    end if;
end;

/*
 4.	Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY по позициям каждого заказа. Для этого создать хранимую процедуру,
 в которой будет в цикле for проход по всем заказам, далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа и сравниваться с ORDER_TOTAL.
 Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
 */

 CREATE OR REPLACE PROCEDURE CHECK_CORRECTNESS_ORDERS
IS v_ord ORDERS%rowtype;
    v_sum number;
    v_name string(1000);
BEGIN
    FOR v_ord IN (SELECT * FROM ORDERS)
    loop
            SELECT sum(o.QUANTITY*o.UNIT_PRICE) into v_sum
                FROM ORDER_ITEMS O
                    WHERE O.ORDER_ID=v_ord.ORDER_ID;

            if v_ord.ORDER_TOTAL <> v_sum then
                SELECT   C.CUST_FIRST_NAME || ' ' || C.CUST_LAST_NAME  || ' ' ||e.FIRST_NAME || ' '||e.LAST_NAME into v_name
                    FROM EMPLOYEES e
                        JOIN CUSTOMERS c on c.CUSTOMER_ID=v_ord.CUSTOMER_ID
                        WHERE e.EMPLOYEE_ID=v_ord.SALES_REP_ID;
                DBMS_OUTPUT.PUT_LINE(v_ord.ORDER_ID || ' ' ||v_ord.ORDER_DATE || ' ' ||v_name);
            end if;
        end loop;
end;

/*
 5.	Переписать предыдущее задание с использованием явного курсора.
 */
  CREATE OR REPLACE PROCEDURE CHECK_CORRECTNESS_ORDERS
IS v_id number;
    v_name string(1000);
    v_ord_date ORDERS.order_date%type;
    cursor order_cursor is
        select o.ORDER_ID,
               o.ORDER_TOTAL,
               sum(OI.UNIT_PRICE*OI.QUANTITY) as oiSUM,
               o.CUSTOMER_ID,
               o.SALES_REP_ID,
               o.ORDER_DATE
            from ORDERS o
            inner join ORDER_ITEMS OI on o.ORDER_ID = OI.ORDER_ID
            group by o.ORDER_ID,o.ORDER_TOTAL,o.CUSTOMER_ID,o.SALES_REP_ID,o.ORDER_DATE;
BEGIN

    for v_data in order_cursor
    loop

            if v_data.ORDER_TOTAL <> v_data.oiSUM then
                SELECT   C.CUST_FIRST_NAME || ' ' || C.CUST_LAST_NAME  || ' ' ||e.FIRST_NAME || ' '||e.LAST_NAME into v_name
                    FROM EMPLOYEES e
                        JOIN CUSTOMERS c on c.CUSTOMER_ID=v_data.CUSTOMER_ID
                        WHERE e.EMPLOYEE_ID=v_data.SALES_REP_ID;
                DBMS_OUTPUT.PUT_LINE(v_id || ' ' ||v_ord_date|| ' ' ||v_name);
            end if;
        end loop;
end;

/*
 6.	Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ на текущую дату из одной позиции
 каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров. Функция возвращает ID созданного клиента.
 */
create or replace  function create_client_and_new_order (v_name IN varchar, v_warehouse_id  IN number) RETURN NUMBER
is
    v_cust_id number;
    v_ord ORDERS%rowtype;
        v_pr_item PRODUCT_INFORMATION%rowtype;
begin

    INSERT INTO CUSTOMERS c (CUST_FIRST_NAME,CUST_LAST_NAME) VALUES (v_name,' ') RETURNING CUSTOMER_ID INTO v_cust_id;
    INSERT INTO ORDERS o (ORDER_DATE,CUSTOMER_ID) VALUES (SYSDATE,v_cust_id) RETURNING o.ORDER_ID,o.ORDER_DATE,o.CUSTOMER_ID,o.ORDER_STATUS,o.ORDER_MODE,o.ORDER_TOTAL,o.SALES_REP_ID,o.PROMOTION_ID into v_ord;
    FOR v_item in (SELECT * FROM INVENTORIES where WAREHOUSE_ID=v_warehouse_id)
    loop
        SELECT * INTO v_pr_item FROM PRODUCT_INFORMATION WHERE PRODUCT_ID=v_item.PRODUCT_ID;
        INSERT INTO ORDER_ITEMS (ORDER_ID,PRODUCT_ID,UNIT_PRICE,QUANTITY) VALUES (v_ord.ORDER_ID, v_item.PRODUCT_ID, v_pr_item.LIST_PRICE,1);
        end loop;
    RETURN  v_ord.ORDER_ID;
end;

  /*
   7.	Добавить в предыдущую функцию проверку на существование склада с переданным ID. Для этого выбрать склад в переменную типа «запись о складе» и
   перехватить исключение no_data_found, если оно возникнет. В обработчике исключения выйти из функции, вернув null.
   */

create or replace  function create_client_and_new_order1 (v_name IN varchar, v_warehouse_id  IN number) RETURN NUMBER
is
    v_warehouse_record WAREHOUSES%rowtype;
    v_cust_id number;
    v_ord ORDERS%rowtype;
        v_pr_item PRODUCT_INFORMATION%rowtype;
begin
    SELECT * INTO v_warehouse_record from WAREHOUSES where WAREHOUSE_ID=v_warehouse_id;

    INSERT INTO CUSTOMERS c (CUST_FIRST_NAME,CUST_LAST_NAME) VALUES (v_name,' ') RETURNING CUSTOMER_ID INTO v_cust_id;
    INSERT INTO ORDERS o (ORDER_DATE,CUSTOMER_ID) VALUES (SYSDATE,v_cust_id) RETURNING o.ORDER_ID,o.ORDER_DATE,o.CUSTOMER_ID,o.ORDER_STATUS,o.ORDER_MODE,o.ORDER_TOTAL,o.SALES_REP_ID,o.PROMOTION_ID into v_ord;
    FOR v_item in (SELECT * FROM INVENTORIES where WAREHOUSE_ID=v_warehouse_id)
    loop
        SELECT * INTO v_pr_item FROM PRODUCT_INFORMATION WHERE PRODUCT_ID=v_item.PRODUCT_ID;
        INSERT INTO ORDER_ITEMS (ORDER_ID,PRODUCT_ID,UNIT_PRICE,QUANTITY) VALUES (v_ord.ORDER_ID, v_item.PRODUCT_ID, v_pr_item.LIST_PRICE,1);
        end loop;
    RETURN  v_ord.ORDER_ID;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN NULL;
    end;


  /*  8.	Написанные процедуры и функции объединить в пакет FIRST_PACKAGE.

   */

   CREATE OR REPLACE PACKAGE  FIRST_PACKAGE AS

 procedure increase_salary(emp_id_var number);

/*
 4.	Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY по позициям каждого заказа. Для этого создать хранимую процедуру,
 в которой будет в цикле for проход по всем заказам, далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа и сравниваться с ORDER_TOTAL.
 Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
 */

  PROCEDURE CHECK_CORRECTNESS_ORDERS;

/*
 5.	Переписать предыдущее задание с использованием явного курсора.
 */
   PROCEDURE CHECK_CORRECTNESS_ORDERS1;

/*
 6.	Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ на текущую дату из одной позиции
 каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров. Функция возвращает ID созданного клиента.
 */
  function create_client_and_new_order (v_name IN varchar, v_warehouse_id  IN number) RETURN NUMBER;

  /*
   7.	Добавить в предыдущую функцию проверку на существование склада с переданным ID. Для этого выбрать склад в переменную типа «запись о складе» и
   перехватить исключение no_data_found, если оно возникнет. В обработчике исключения выйти из функции, вернув null.
   */

  function create_client_and_new_order1 (v_name IN varchar, v_warehouse_id  IN number) RETURN NUMBER;

       END FIRST_PACKAGE;





        CREATE OR REPLACE PACKAGE BODY  FIRST_PACKAGE AS

 procedure increase_salary(emp_id_var number)
    is
    v_orders_count NUMBER;
begin
    SELECT count(*)
    into v_orders_count
    FROM ORDERS o
    where o.SALES_REP_ID = emp_id_var;

    if v_orders_count > 0 then
        UPDATE EMPLOYEES set SALARY=SALARY*1.1
            WHERE EMPLOYEE_ID=emp_id_var;
    end if;
end increase_salary;

/*
 4.	Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY по позициям каждого заказа. Для этого создать хранимую процедуру,
 в которой будет в цикле for проход по всем заказам, далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа и сравниваться с ORDER_TOTAL.
 Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
 */

  PROCEDURE CHECK_CORRECTNESS_ORDERS
IS v_ord ORDERS%rowtype;
    v_sum number;
    v_name string(1000);
BEGIN
    FOR v_ord IN (SELECT * FROM ORDERS)
    loop
            SELECT sum(o.QUANTITY*o.UNIT_PRICE) into v_sum
                FROM ORDER_ITEMS O
                    WHERE O.ORDER_ID=v_ord.ORDER_ID;

            if v_ord.ORDER_TOTAL <> v_sum then
                SELECT   C.CUST_FIRST_NAME || ' ' || C.CUST_LAST_NAME  || ' ' ||e.FIRST_NAME || ' '||e.LAST_NAME into v_name
                    FROM EMPLOYEES e
                        JOIN CUSTOMERS c on c.CUSTOMER_ID=v_ord.CUSTOMER_ID
                        WHERE e.EMPLOYEE_ID=v_ord.SALES_REP_ID;
                DBMS_OUTPUT.PUT_LINE(v_ord.ORDER_ID || ' ' ||v_ord.ORDER_DATE || ' ' ||v_name);
            end if;
        end loop;
end CHECK_CORRECTNESS_ORDERS;

/*
 5.	Переписать предыдущее задание с использованием явного курсора.
 */
   PROCEDURE CHECK_CORRECTNESS_ORDERS1
IS v_id number;
    v_name string(1000);
    v_ord_date ORDERS.order_date%type;
    cursor order_cursor is
        select o.ORDER_ID,
               o.ORDER_TOTAL,
               sum(OI.UNIT_PRICE*OI.QUANTITY) as oiSUM,
               o.CUSTOMER_ID,
               o.SALES_REP_ID,
               o.ORDER_DATE
            from ORDERS o
            inner join ORDER_ITEMS OI on o.ORDER_ID = OI.ORDER_ID
            group by o.ORDER_ID,o.ORDER_TOTAL,o.CUSTOMER_ID,o.SALES_REP_ID,o.ORDER_DATE;
BEGIN

    for v_data in order_cursor
    loop

            if v_data.ORDER_TOTAL <> v_data.oiSUM then
                SELECT   C.CUST_FIRST_NAME || ' ' || C.CUST_LAST_NAME  || ' ' ||e.FIRST_NAME || ' '||e.LAST_NAME into v_name
                    FROM EMPLOYEES e
                        JOIN CUSTOMERS c on c.CUSTOMER_ID=v_data.CUSTOMER_ID
                        WHERE e.EMPLOYEE_ID=v_data.SALES_REP_ID;
                DBMS_OUTPUT.PUT_LINE(v_id || ' ' ||v_ord_date|| ' ' ||v_name);
            end if;
        end loop;
end CHECK_CORRECTNESS_ORDERS1;

/*
 6.	Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ на текущую дату из одной позиции
 каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров. Функция возвращает ID созданного клиента.
 */
  function create_client_and_new_order (v_name IN varchar, v_warehouse_id  IN number) RETURN NUMBER
is
    v_cust_id number;
    v_ord ORDERS%rowtype;
        v_pr_item PRODUCT_INFORMATION%rowtype;
begin

    INSERT INTO CUSTOMERS c (CUST_FIRST_NAME,CUST_LAST_NAME) VALUES (v_name,' ') RETURNING CUSTOMER_ID INTO v_cust_id;
    INSERT INTO ORDERS o (ORDER_DATE,CUSTOMER_ID) VALUES (SYSDATE,v_cust_id) RETURNING o.ORDER_ID,o.ORDER_DATE,o.CUSTOMER_ID,o.ORDER_STATUS,o.ORDER_MODE,o.ORDER_TOTAL,o.SALES_REP_ID,o.PROMOTION_ID into v_ord;
    FOR v_item in (SELECT * FROM INVENTORIES where WAREHOUSE_ID=v_warehouse_id)
    loop
        SELECT * INTO v_pr_item FROM PRODUCT_INFORMATION WHERE PRODUCT_ID=v_item.PRODUCT_ID;
        INSERT INTO ORDER_ITEMS (ORDER_ID,PRODUCT_ID,UNIT_PRICE,QUANTITY) VALUES (v_ord.ORDER_ID, v_item.PRODUCT_ID, v_pr_item.LIST_PRICE,1);
        end loop;
    RETURN  v_ord.ORDER_ID;
end create_client_and_new_order;

  /*
   7.	Добавить в предыдущую функцию проверку на существование склада с переданным ID. Для этого выбрать склад в переменную типа «запись о складе» и
   перехватить исключение no_data_found, если оно возникнет. В обработчике исключения выйти из функции, вернув null.
   */

  function create_client_and_new_order1 (v_name IN varchar, v_warehouse_id  IN number) RETURN NUMBER
is
    v_warehouse_record WAREHOUSES%rowtype;
    v_cust_id number;
    v_ord ORDERS%rowtype;
        v_pr_item PRODUCT_INFORMATION%rowtype;
begin
    SELECT * INTO v_warehouse_record from WAREHOUSES where WAREHOUSE_ID=v_warehouse_id;

    INSERT INTO CUSTOMERS c (CUST_FIRST_NAME,CUST_LAST_NAME) VALUES (v_name,' ') RETURNING CUSTOMER_ID INTO v_cust_id;
    INSERT INTO ORDERS o (ORDER_DATE,CUSTOMER_ID) VALUES (SYSDATE,v_cust_id) RETURNING o.ORDER_ID,o.ORDER_DATE,o.CUSTOMER_ID,o.ORDER_STATUS,o.ORDER_MODE,o.ORDER_TOTAL,o.SALES_REP_ID,o.PROMOTION_ID into v_ord;
    FOR v_item in (SELECT * FROM INVENTORIES where WAREHOUSE_ID=v_warehouse_id)
    loop
        SELECT * INTO v_pr_item FROM PRODUCT_INFORMATION WHERE PRODUCT_ID=v_item.PRODUCT_ID;
        INSERT INTO ORDER_ITEMS (ORDER_ID,PRODUCT_ID,UNIT_PRICE,QUANTITY) VALUES (v_ord.ORDER_ID, v_item.PRODUCT_ID, v_pr_item.LIST_PRICE,1);
        end loop;
    RETURN  v_ord.ORDER_ID;
    EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN NULL;
    end create_client_and_new_order1;

       END FIRST_PACKAGE;


/*
 9.	Написать функцию, которая возвратит таблицу (table of record), содержащую информацию о частоте встречаемости отдельных символов во всех названиях (и описаниях)
 товара на заданном языке (передается код языка, а также параметр, указывающий, учитывать ли описания товаров).
 Возвращаемая таблица состоит из 2-х полей: символ, частота встречаемости в виде частного от кол-ва данного символа к количеству всех символов в названиях (и описаниях) товара.
 */

declare TYPE words_table is table of number index by string(20);
FUNCTION CHARS_STATS(v_lang_code in varchar2, v_is_descriptions_need in number) return words_table
    is
    v_table    words_table;
    v_sentence varchar2(32000);
    v_count    number;
    v_char     varchar2(20);
begin
    v_count := 0;
    v_table := words_table();

    for v_row in (select * from PRODUCT_DESCRIPTIONS pd where pd.LANGUAGE_ID = v_lang_code)
        loop
            if v_is_descriptions_need = 1 then
                v_sentence := v_row.TRANSLATED_DESCRIPTION || v_row.TRANSLATED_NAME;
            else
                v_sentence := v_row.TRANSLATED_NAME;
            end if;
            for v_char_num in 1..LENGTH(v_row.TRANSLATED_NAME || v_row.TRANSLATED_DESCRIPTION)
                LOOP
                    v_char := substr(v_sentence, v_char_num);
                    if regexp_like(v_char, '[^\W\d_]') then
                        v_count := v_count + 1;
                        if v_table.EXISTS(v_char) then
                            v_table(v_char) := v_table(v_char) + 1;
                        else
                            v_table(v_char) := 1;
                        end if;
                    end if;
                end loop;

        end loop;
        for v_rec in v_table.FIRST..v_table.LAST
    loop
            v_table(v_rec) := v_table(v_rec)/v_count;
            end loop;
    return v_table;
    end;
    begin
end;


/*
 10.	Написать функцию, которой передается sys_refcursor и
 которая по данному курсору формирует HTML-таблицу, содержащую информацию из курсора. Тип возвращаемого значения – clob.
 */

CREATE OR REPLACE FUNCTION print_html_table(v_cursor in out sys_refcursor) return clob
    is
    v_table      clob;
    l_curid      number;
    v_cols_count integer;
    v_desc_tab   DBMS_sql.DESC_TAB;
    l_text       VARCHAR2(32767) ;
    l_varchar2   VARCHAR2(32767) ;
    l_number     NUMBER;
    l_date       DATE;
    v_row        number;
begin

    v_table := '<table>';
    l_curid := DBMS_SQL.TO_CURSOR_NUMBER(v_cursor);
    DBMS_SQL.DESCRIBE_COLUMNS(l_curid, v_cols_count, v_desc_tab);
    v_table := v_table || '<th>';
    for pos in 1..v_cols_count
        loop
            v_table := v_table || '<td>' || v_desc_tab(pos).COL_NAME || '</td>';
            CASE v_desc_tab(pos).col_type
                WHEN 1 THEN DBMS_SQL.DEFINE_COLUMN(l_curid, pos, l_varchar2, 2000);
                WHEN 2 THEN DBMS_SQL.DEFINE_COLUMN(l_curid, pos, l_number);
                WHEN 12 THEN DBMS_SQL.DEFINE_COLUMN(l_curid, pos, l_date);
                ELSE DBMS_SQL.DEFINE_COLUMN(l_curid, pos, l_varchar2, 2000);
                END CASE;
        end loop;
    v_table := v_table || '</th>';

    v_table := v_table || '<tr>';
    loop
        v_row := DBMS_SQL.FETCH_ROWS(l_curid);
        EXIT WHEN v_row = 0;
        for pos in 1..v_cols_count
            loop
                l_text := '';
                CASE v_desc_tab(pos).col_type
                    WHEN 1 THEN DBMS_SQL.COLUMN_VALUE(l_curid, pos, l_varchar2);
                                l_text := LTRIM(l_text || ',"' || l_varchar2 || '"', ',');
                    WHEN 2 THEN DBMS_SQL.COLUMN_VALUE(l_curid, pos, l_number);
                                l_text := LTRIM(l_text || ',' || l_number, ',');
                    WHEN 12 THEN DBMS_SQL.COLUMN_VALUE(l_curid, pos, l_date);
                                 l_text := LTRIM(l_text || ',' || TO_CHAR(l_date, 'DD/MM/YYYY HH24:MI:SS'), ',');
                    ELSE l_text := LTRIM(l_text || ',"' || l_varchar2 || '"', ',');
                    END CASE;
                v_table := v_table || '<td>' || l_text || '</td>';
            end loop;
        v_table := v_table || '</tr>';
    end loop;


    return v_table;
end;



declare
    v_cur SYS_REFCURSOR;
BEGIN
    OPEN v_cur FOR SELECT * FROM EMPLOYEES;
    DBMS_OUTPUT.PUT_LINE(PRINT_HTML_TABLE(v_cur));

end;