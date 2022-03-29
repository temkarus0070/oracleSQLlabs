--Претков Артем, 3 лаба

/*1. Выбрать с помощью иерархического запроса сотрудников 3-его уровня иерархии (т.е.
таких, у которых непосредственный начальник напрямую подчиняется руководителю
организации). Упорядочить по коду сотрудника.
 */
SELECT m.*
FROM (
         SELECT e.*, LEVEL as hLevel
         FROM EMPLOYEES e
         start with e.MANAGER_ID is null
         connect by prior e.EMPLOYEE_ID = e.MANAGER_ID
         order siblings by e.EMPLOYEE_ID
     ) m
where m.hLEVEL = 3
order by m.EMPLOYEE_ID;

/*2. Для каждого сотрудника выбрать всех его начальников по иерархии. Вывести поля: код
сотрудника, имя сотрудника (фамилия + имя через пробел), код начальника, имя
начальника (фамилия + имя через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. Если у какого-то сотрудника
есть несколько начальников, то для данного сотрудника в выборке должно быть
несколько строк с разными начальниками. Упорядочить по коду сотрудника, затем по
уровню начальника (первый – непосредственный начальник, последний – руководитель
организации).

 */
SELECT man.emp_id, man.emp_name, man.man, man.man_name, man.lvl - 2
FROM (
         SELECT connect_by_root e.EMPLOYEE_ID                                      as emp_id,
                connect_by_root e.LAST_NAME || ' ' || connect_by_root e.FIRST_NAME as emp_name,
                e.EMPLOYEE_ID                                                      as man,
                e.LAST_NAME || ' ' || e.FIRST_NAME                                 as man_name,
                LEVEL                                                              as lvl
         FROM EMPLOYEES e
         start with e.MANAGER_ID is not null
         connect by prior e.MANAGER_ID = e.EMPLOYEE_ID
     ) man
where man.emp_id <> man.man
order by emp_id, man.lvl - 2
;


/*3. Для каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. Вывести поля: код сотрудника, имя сотрудника (фамилия + имя через
пробел), общее кол-во подчиненных.
 */

select m.man_id,
       m.lastName || ' ' || m.firstName,
       count(m.emp_id)
from (
         SELECT connect_by_root e.EMPLOYEE_ID as man_id,
                connect_by_root e.FIRST_NAME  as firstName,
                connect_by_root e.LAST_NAME   as lastName,
                e.EMPLOYEE_ID                 as emp_id
         FROM EMPLOYEES e
         connect by prior e.EMPLOYEE_ID = e.MANAGER_ID
     ) m
where m.man_id <> m.emp_id
group by m.man_id,
         m.lastName,
         m.firstName
order by m.man_id;

-- help!!!!!!!!!!

перенумеровать строки темже аналитическим запросом, и начинать с записи 1,соединяем
критерий строк для отбора где номер совпадает с кол-вом строк

во внешнем rn и n , where rn=n

/*4. Для каждого заказчика выбрать в виде строки через запятую даты его заказов. Для
конкатенации дат заказов использовать sys_connect_by_path (иерархический запрос). Для
отбора «последних» строк использовать connect_by_isleaf.
 */
select c.CUSTOMER_ID,
       c.CUST_LAST_NAME || ' ' || c.CUST_FIRST_NAME,
       ord.orders_date
from CUSTOMERS c
         left join (
    SELECT connect_by_root o.CUSTOMER_ID                                 as cust_id,
           sys_connect_by_path(to_char(o.ORDER_DATE, 'dd.mm.yyyy'), ',') as orders_date,
           CONNECT_BY_ISLEAF                                             as leaf,
           length(sys_connect_by_path(to_char(o.ORDER_DATE, 'dd.mm.yyyy'), ','))
    FROM ORDERS o
    connect by prior o.CUSTOMER_ID = o.CUSTOMER_ID
           and prior o.ORDER_DATE < o.ORDER_DATE
    order by cust_id
) ord
                   on ord.cust_id = c.CUSTOMER_ID
where ord.leaf = 1
group by c.CUSTOMER_ID, c.CUST_LAST_NAME || ' ' || c.CUST_FIRST_NAME,
         ord.orders_date
having length(ord.orders_date) = max(length(ord.orders_date))
order by c.CUSTOMER_ID;


/*5. Выполнить задание № 4 c помощью обычного запроса с группировкой и функцией
listagg.
 */
SELECT c.CUSTOMER_ID, LISTAGG(to_char(o.ORDER_DATE, 'dd-mm-yyyy'), ',')
FROM CUSTOMERS c
         inner join ORDERS O
                    on c.CUSTOMER_ID = O.CUSTOMER_ID
group by c.CUSTOMER_ID;

/*6. Выполнить задание № 2 с помощью рекурсивного запроса.
  /*2. Для каждого сотрудника выбрать всех его начальников по иерархии. Вывести поля: код
сотрудника, имя сотрудника (фамилия + имя через пробел), код начальника, имя
начальника (фамилия + имя через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. Если у какого-то сотрудника
есть несколько начальников, то для данного сотрудника в выборке должно быть
несколько строк с разными начальниками. Упорядочить по коду сотрудника, затем по
уровню начальника (первый – непосредственный начальник, последний – руководитель
организации).

 */
WITH rec_2(emp_id, emp_name, man_id, man_name, prev_manager, count) as (
    SELECT emp.EMPLOYEE_ID,
           emp.LAST_NAME || ' ' || emp.FIRST_NAME,
           emp.MANAGER_ID,
           man1.LAST_NAME || ' ' || man1.FIRST_NAME,
           man1.MANAGER_ID,
           0
    from EMPLOYEES emp
             inner join EMPLOYEES man1
                        on man1.EMPLOYEE_ID = emp.MANAGER_ID
    union all
    SELECT emp_id,
           emp_name,
           man2.EMPLOYEE_ID,
           man2.LAST_NAME || ' ' || man2.FIRST_NAME,
           man2.MANAGER_ID,
           count + 1
    FROM rec_2
             join EMPLOYEES man2
                  on man2.EMPLOYEE_ID = prev_manager
)

SELECT rec_2.emp_id,
       rec_2.emp_name,
       rec_2.man_id,
       rec_2.man_name,
       rec_2.count
FROM rec_2
order by rec_2.emp_id,
         rec_2.prev_manager desc nulls last;

/*7. Выполнить задание № 3 с помощью рекурсивного запроса.
/*3. Для каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. Вывести поля: код сотрудника, имя сотрудника (фамилия + имя через
пробел), общее кол-во подчиненных.
 */

with rec_3(emp_id, emp_name, sl_id, last_man) as (
    SELECT emp.EMPLOYEE_ID,
           emp.LAST_NAME || ' ' || emp.FIRST_NAME,
           sl.EMPLOYEE_ID,
           sl.EMPLOYEE_ID
    FROM EMPLOYEES emp
             inner join EMPLOYEES sl
                        on sl.MANAGER_ID = emp.EMPLOYEE_ID
    union all
    SELECT emp_id,
           emp_name,
           sl1.EMPLOYEE_ID,
           sl1.EMPLOYEE_ID
    FROM rec_3
             join EMPLOYEES sl1 on sl1.MANAGER_ID = last_man
)
select emp_id,
       emp_name,
       count(sl_id)
from rec_3
group by emp_id, emp_name
order by count(sl_id) desc;




/*8. Каждому менеджеру по продажам сопоставить последний его заказ. Менеджером по
продажам считаем сотрудников, код должности которых: «SA_MAN» и «SA_REP». Для
выборки последних заказов по менеджерам использовать подзапрос с применением
аналитических функций (например в подзапросе выбирать дату следующего заказа
менеджера, а во внешнем запросе «оставить» только те строки, у которых следующего
заказа нет). Вывести поля: код менеджера, имя менеджера (фамилия + имя через
пробел), код клиента, имя клиента (фамилия + имя через пробел), дата заказа, сумма
заказа, количество различных позиций в заказе. Упорядочить данные по дате заказа в
обратном порядке, затем по сумме заказа в обратном порядке, затем по коду сотрудника.
Тех менеджеров, у которых нет заказов, вывести в конце.

 */

SELECT
    distinct emp.EMPLOYEE_ID,
       emp.LAST_NAME || ' ' || emp.FIRST_NAME,
       O.CUSTOMER_ID,
       C2.CUST_LAST_NAME || C2.CUST_FIRST_NAME,
       O.ORDER_DATE,
       O.ORDER_TOTAL,
       COUNT(OI.PRODUCT_ID) over ( partition by OI.ORDER_ID)


    FROM EMPLOYEES emp
         left join(
                select  o.ORDER_ID
                        ,o.SALES_REP_ID,
                        o.ORDER_DATE,
                        lead(o.ORDER_DATE) over (partition by o.SALES_REP_ID order by o.ORDER_DATE) as last_date,
                        o.CUSTOMER_ID,
                       o.ORDER_TOTAL
                from ORDERS o
        ) O
                   on emp.EMPLOYEE_ID = O.SALES_REP_ID and O.last_date is null
         left join CUSTOMERS C2 on O.CUSTOMER_ID = C2.CUSTOMER_ID
         left join ORDER_ITEMS OI on OI.ORDER_ID=O.ORDER_ID

    where JOB_ID in ('SA_MAN', 'SA_REP')
    order by o.ORDER_DATE desc nulls last ,
             o.ORDER_TOTAL desc ,
             emp.EMPLOYEE_ID
             ;





/*9. Для каждого месяца текущего года найти первые и последние рабочие и выходные дни с
учетом праздников и переносов выходных дней (на 2016 год эту информацию можно
посмотреть, например, на странице http://www.interfax.ru/russia/469373). Для
формирования списка всех дней текущего года использовать иерархический запрос,
оформленный в виде подзапроса в секции with. Праздничные дни и переносы выходных
также задать в виде подзапроса в секции with (с помощью union all перечислить все
даты, в которых рабочие/выходные дни не совпадают с обычной логикой определения
выходного дня как субботы и воскресения). Запрос должен корректно работать, если
добавить изменить какие угодно выходные/рабочие дни в данном подзапросе. Вывести
поля: месяц в виде первого числа месяца, первый выходной день месяца, последний
выходной день, первый праздничный день, последний праздничный день.

 */

with days(currentDate, offday, holiday) as (
    SELECT to_date('31.12.2020', 'dd.mm.yyyy') + level as currentDate,
           decode(to_char((to_date('31.12.2020', 'dd.mm.yyyy', 'NLS_DATE_LANGUAGE = ENGLISH') + level), 'D'),
                  1, 1,
                  7, 1,
                    null
               ) as offday,
           null as holiday
    FROM DUAL
    connect by level <= 365

    union all
    select date'2021-01-01', null, 1
    from dual

  minus
    select date'2021-01-02', 1, null
    from dual
  minus
    select date'2021-01-03', 1, null
    from dual

  union all
    select date'2021-01-02', null, 1
    from dual
  union all
    select date'2021-01-03', null, 1
    from dual

  union all
    select date'2021-01-04', null, 1
    from dual

  union all
    select date'2021-01-05', null, 1
    from dual

  union all
    select date'2021-01-06', null, 1
    from dual


  union all
    select date'2021-01-07', null, 1
    from dual

  union all
    select date'2021-01-08', null, 1
    from dual

minus
    select date'2021-02-20', 1, null
    from dual

union all
    select date'2021-02-22', 1, null
    from dual

    union all
    select date'2021-02-23', null, 1
    from dual

    union all
    select date'2021-03-08', null, 1
    from dual

    minus
    select date'2021-05-01', 1, null
    from dual

    union all
    select date'2021-05-01', null, 1
    from dual

union all
    select date'2021-05-03', 1, null
    from dual

    minus
    select date'2021-05-09', 1, null
    from dual

    union all
    select date'2021-05-09', null, 1
    from dual

union all
    select date'2021-05-10', 1, null
    from dual

minus
    select date'2021-06-12', 1, null
    from dual

union all
    select date'2021-06-12', null, 1
    from dual

union all
    select date'2021-06-14', 1, null
    from dual

minus
 select date'2021-10-30', 1, null
    from dual

minus
 select date'2021-10-31', 1, null
    from dual


union all
    select date'2021-11-04', null, 1
    from dual

minus
 select date'2021-11-06', 1, null
    from dual

minus
 select date'2021-11-07', 1, null
    from dual

union all
    select date'2021-12-31', 1, null
    from dual
)



SELECT distinct TRUNC(d.currentDate,'MONTH'),
                offdays.minDate as "первый выходной день месяца",
                offdays.maxDate as "последний выходной",
                holidays.minDate as "первый праздничный",
                holidays.maxDate as "последний праздничный день"

    FROM days d
        left join (
            SELECT trunc(d1.currentDate,'mm') as curDate,
                   min(d1.currentDate) as minDate,
                   max(d1.currentDate) as maxDate
                FROM days d1
                where d1.offday is not null
                group by trunc(d1.currentDate,'mm')

            ) offdays
                on  TRUNC(d.currentDate,'MONTH')=offdays.curDate
        left join (
                SELECT trunc(d2.currentDate,'mm') as curDate,
                   min(d2.currentDate) as minDate,
                   max(d2.currentDate) as maxDate
                FROM days d2
                where d2.holiday is not null
                group by trunc(d2.currentDate,'mm')

            ) holidays
                  on  TRUNC(d.currentDate,'MONTH')=holidays.curDate
    order by TRUNC(d.currentDate,'MONTH')
;




 /*   2
    Задачи на манипулирование данными.(После выполнения запросов транзакции
    завершать необязательно
   , чтобы исходные данные не поменялись).
    10.3-м самых эффективным по сумме заказов за 1999 год менеджерам по продажам
    увеличить зарплату еще на 20%.

  */

    UPDATE EMPLOYEES emp1
        SET emp1.SALARY = emp1.SALARY + (emp1.SALARY*0.2)
        WHERE emp1.EMPLOYEE_ID IN (

            SELECT emp.EMPLOYEE_ID
                FROM (
                         SELECT emp.EMPLOYEE_ID,
                                ROW_NUMBER() over
                                    (ORDER BY SUM(o.ORDER_TOTAL) DESC ) as rowN,
                                SUM(o.ORDER_TOTAL)
                         FROM EMPLOYEES emp
                                  inner join ORDERS o
                                             on emp.EMPLOYEE_ID = O.SALES_REP_ID and
                                                (o.ORDER_DATE >= date'1999-01-01' and o.ORDER_DATE < date'2000-01-01')

                         WHERE EMP.JOB_ID = 'SA_MAN'
                         GROUP BY emp.EMPLOYEE_ID
                         ORDER BY SUM(o.ORDER_TOTAL) DESC
                     ) emp
                where emp.rowN<=3
        );



/*    11.Завести нового клиента ‘Старый клиент’ с менеджером, который является
руководителем организации. Остальные поля клиента – по умолчанию.

 */

INSERT INTO
    CUSTOMERS(CUST_FIRST_NAME,
              CUST_LAST_NAME,
              ACCOUNT_MGR_ID)
    VALUES ('Старый',
                'Клиент',
               (SELECT
                max(emp.EMPLOYEE_ID)
            FROM EMPLOYEES emp
            WHERE emp.JOB_ID='AD_PRES'
            ));


/*12. Для клиента, созданного в предыдущем запросе, (найти можно по максимальному id
клиента), продублировать заказы всех клиентов за 1990 год. (Здесь будет 2 запроса, для
дублирования заказов и для дублирования позиций заказа).

 */

 INSERT INTO ORDERS(CUSTOMER_ID,ORDER_DATE,ORDER_TOTAL,ORDER_MODE,ORDER_STATUS,SALES_REP_ID,PROMOTION_ID)
 (SELECT (SELECT MAX(c.CUSTOMER_ID) FROM  CUSTOMERS c),
              o.ORDER_DATE,
              o.ORDER_TOTAL,
              o.ORDER_MODE,
              o.ORDER_STATUS,
              o.SALES_REP_ID,
              o.PROMOTION_ID
              from
         ORDERS o
         where o.ORDER_DATE>=date'1990-01-01' and o.ORDER_DATE<date'1991-01-01');


--help!!!!!!!!!!!!!!!



 INSERT  INTO ORDER_ITEMS(ORDER_ID, LINE_ITEM_ID, PRODUCT_ID, UNIT_PRICE, QUANTITY)
     (SELECT newOrd.ORDER_ID,
             oi.LINE_ITEM_ID,
             oi.PRODUCT_ID,
             oi.UNIT_PRICE,
             oi.QUANTITY
      FROM ORDER_ITEMS oi
               inner join ORDERS o1
                          on oi.ORDER_ID = o1.ORDER_ID and
                             (o1.ORDER_DATE >= date'1990-01-01' and o1.ORDER_DATE < date'1991-01-01')
                              and (o1.CUSTOMER_ID <> (
                                  SELECT MAX(c.CUSTOMER_ID)
                                  FROM CUSTOMERS c
                              ))
               inner join ORDERS newOrd
                          on newOrd.ORDER_DATE = o1.ORDER_DATE and newOrd.ORDER_ID <> o1.ORDER_ID
     );


/*13. Для каждого клиента удалить самый первый заказ. Должно быть 2 запроса: первый – для
удаления позиций в заказах, второй – на удаление собственно заказов).

 */

     DELETE ORDER_ITEMS oi
         WHERE oi.ORDER_ID in(
             SELECT
                    min(o1.ORDER_ID)
                FROM ORDERS o1
                GROUP BY o1.CUSTOMER_ID
                   );

    DELETE ORDERS o
         WHERE o.ORDER_ID in(
             SELECT
                    min(o1.ORDER_ID)
                FROM ORDERS o1
                GROUP BY o1.CUSTOMER_ID
                   );


/*14. Для товаров, по которым не было ни одного заказа, уменьшить цену в 2 раза (округлив
до целых) и изменить название, приписав префикс ‘Супер Цена! ’.

 */

 UPDATE PRODUCT_INFORMATION pi
    SET
        pi.LIST_PRICE=pi.LIST_PRICE/2 ,
                      pi.MIN_PRICE=pi.MIN_PRICE/2,
        pi.PRODUCT_NAME='Супер Цена! ' || pi.PRODUCT_NAME
    WHERE NOT EXISTS(
        SELECT *
            FROM ORDER_ITEMS oi
            where oi.PRODUCT_ID=pi.PRODUCT_ID
        );



/*15. Импортировать в базу данных из прайс-листа фирмы «Рет» (http://www.voronezh.ret.ru/?
&pn=down) информацию о всех реализуемых планшетах. Подсказка: воспользоваться
excel для конструирования
insert -запросов (или select -запросов, что даже удобнее).
    3

 */

INSERT  ALL
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Archos 70c Xenon',' 1024*600, ARM 1.3ГГц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 2/0.3Мпикс,  Android 5.1, 190*110*10мм 242г, серебристый',3665.000000,3665.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Huawei MediaPad T3 7.0 53010adp',' 1024*600, Spreadtrum 1.3ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/2Мпикс, Android 7, 187.6*103.7*8.6мм 275г, серый',6990.000000,6990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Iconbit NetTAB Sky 3G Duo',' 1024*600, ARM 1.2ГГц, 4GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, MiniHDMI, 2 камеры 5/0.3Мпикс, Android 4.0, 195*124*11мм 315г, черный',2700.000000,2700.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Iconbit NetTAB Sky II mk2',' 800*480, ARM 1.2ГГц, 4GB, WiFi, SD-micro, камера 0.3Мпикс, Android 4.1, 191*114*11мм 310г, белый',2100.000000,2100.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Lenovo Tab 3 TB3-710I Essential ZA0S0023RU',' 1024*600, MTK 1.3ГГц, 8GB, BT, WiFi, 3G, GPS, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 113*190*10мм 300г, черный',5590.000000,5590.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Lenovo Tab 3 TB3-730X ZA130004RU',' 1024*600,  MTK 1ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 6, 101*191*98мм 260г, белый',7690.000000,7690.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Lenovo Tab 4 TB-7304i Essential ZA310031RU',' 1024*600, MTK 1.3ГГц, 16GB, BT, WiFi, 3G, GPS, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 102*194.8*8.8мм 254г, черный',6990.000000,6990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad  Wize 3787',' 1280*800, intel 1.1ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 190*115*9.5мм 270г, серый',4300.000000,4300.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad  Wize 3787',' 1280*800, intel 1.1ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 190*115*9.5мм 270г, черный',4300.000000,4300.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad Color Wize 3797',' 1280*800, intel 1.2ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 190*115*9.5мм 270г, серый',4290.000000,4290.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad Grace PMT3157',' 1280*720, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 186*115*9.5мм 280г черный',5590.000000,5590.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad Grace PMT3157',' 1280*720, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 186*115*9.5мм 280г черный',4240.000000,4240.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad PMT3677',' 800*480, ARM 1ГГц, 4GB, WiFi, SD-micro, камера 0.3Мпикс, Android 4.2, 192*116*11мм 300г, черный',2100.000000,2100.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad WIZE 3757',' 1280*800, intel 1.2ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 186*115*9.5мм 280г черный',5250.000000,5250.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad Wize 3407',' 1024*600, intel 1.3ГГц, 8GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 188*108*10.5мм 310г, черный',5390.000000,5390.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Prestigio MultiPad Wize PMT3427',' 1024*600, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 186*115*9.5мм 280г серый',4190.000000,4190.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Samsung Galaxy Tab 4 SM-T231NYKASER',' 1280*800, Samsung 1.2ГГц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 3/1.3Мпикс, Android 4.2, 107*186*9мм 281г, 10ч, черный',8800.000000,8800.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Samsung Galaxy Tab 4 SM-T231NZWASER',' 1280*800, Samsung 1.2ГГц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 3/1.3Мпикс, Android 4.2, 107*186*9мм 281г, 10ч, белый',8800.000000,8800.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Samsung Galaxy Tab A SM-T285NZKASER',' 1280*800, Samsung 1.3ГГц, 8GB, 4G/3G, GPS, BT, WiFi, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 109*187*8.7мм 285г, 10ч, черный',9990.000000,9990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Tesla Element 7.0',' 1024*600, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, камера 0.3Мпикс, Android 4.4, 188*108*10.5мм 311г, черный',3190.000000,3190.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7" Topstar TS-AD75 TE',' 1024*600, ARM 1ГГц, 8GB, 3G, GSM, BT, WiFi, SD-micro, SDHC-micro, miniHDMI, камера 0.3 Мпикс, Android 4.0, 193*123*10мм 350г, черный',2700.000000,2700.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7.9" Apple iPad mini 3 MGGQ2RU/A',' 2048*1536, A7 1.3ГГц, 64GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 135*200*8мм 331г, 10ч, серый',25990.000000,25990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7.9" Apple iPad mini 3 MGGT2RU/A',' 2048*1536, A7 1.3ГГц, 64GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 135*200*8мм 331г, 10ч, серебристый',25990.000000,25990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7.9" Apple iPad mini 3 MGJ32RU/A',' 2048*1536, A7 1.3ГГц, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 341г, 10ч, серебристый',28990.000000,28990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7.9" Apple iPad mini 3 MGP32RU/A',' 2048*1536, A7 1.3ГГц, 128GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 331г, 10ч, серый',28990.000000,28990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 7.9" Apple iPad mini 3 MGYU2RU/A',' 2048*1536, A7 1.3ГГц, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 134.7*200*7.5мм 341г, 10ч, золотистый',29990.000000,29990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" ASUS VivoTab Note 8 M80TA',' 1280*800, Intel 1.86ГГц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/1.26Мпикс, W8.1, 134*221*11мм 380г, черный',9490.000000,9490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Acer Iconia Tab 8 A1-840FHD-17RT',' 1920*1080, Intel 1.8ГГц, 16GB, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2Мпикс, Android 4.4, серебристый',10200.000000,10200.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Archos 80 G9',' 1024*768, ARM 1ГГц, 8GB, GPS, BT, WiFi, SD-micro, miniHDMI, камера, Android 3.2, 226*155*12мм 465г, 10ч, темно-серый',2290.000000,2290.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Huawei MediaPad T3 8.0 53018493',' 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 211*124.65*7.95мм, 350гр, серый',10990.000000,10990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Lenovo Tab 4 TB-8504X ZA2D0036RU',' 1280*800, Qualcomm 1.4ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 7, 211*124*8мм 310г, черный',11990.000000,11990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Lenovo Tab 4 TB-8504X ZA2D0059RU',' 1280*800, Qualcomm 1.4ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 7, 211*124*8мм 310г, белый',11990.000000,11990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Grace PMT3118',' 1280*800, MTK 1.1ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 206*123*10мм, 343гр, черный',4590.000000,4590.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Grace PMT5588',' 1920*1200, MTK 1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 8.1, 213*125*8мм, 357гр, черный',9990.000000,9990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Muze PMT3708',' 1280*800, MTK 1.3ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 206*122.8*10мм, 360гр, черный',4990.000000,4990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Muze PMT3708',' 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 206*122.8*10мм, 360гр, черный',5490.000000,5490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Muze PMT3718',' 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 206*122.8*10мм, 360гр, черный',5490.000000,5490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3108 + CNE-CSPB26W',' 1280*800, intel 1.2ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 207*123*8.8мм, 356гр, черный',5890.000000,5890.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3208',' 1280*800, intel 1.1ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 208.2*126.2*10мм, 613гр, черный',5390.000000,5390.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3418',' 1280*800, MTK 1.1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 6, 206*122.8*10мм, 360гр, черный',6490.000000,6490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3508',' 1280*800, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 206*122.8*10мм, 360гр, серый',6200.000000,6200.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3508',' 1280*800, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 5.1, 206*122.8*10мм, 360гр, черный',6200.000000,6200.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3518',' 1280*800, MTK 1.1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 6, 206*122.8*10мм, 360гр, черный',6390.000000,6390.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Prestigio MultiPad Wize PMT3618',' 1280*800, MTK 1.1ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 8.1, 206*122.8*9.9мм, 363гр, черный',6490.000000,6490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" RoverPad Magic HD8G',' 1280*800, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 6, 208*123.5*11мм 420г, черный',4990.000000,4990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 8" Tesla Impulse 8.0 3G',' 1280*800, ARM 1.3ГГц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 4.4, 208*123.5*11мм 420г, черный',3700.000000,3700.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.6" Huawei MediaPad T3 10 53018522',' 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 229.8*159.8*7.95мм, 460гр, серый',11990.000000,11990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.6" Huawei MediaPad T3 10 53018545',' 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 229.8*159.8*7.95мм, 460гр, золотистый',11990.000000,11990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.6" Prestigio MultiPad Wize 3096',' 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 8, 261*155*9.8мм, 554гр, черный',6490.000000,6490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Air 2 Demo 3A141RU',' 2048*1536, A8X 1.5ГГц, 16GB, BT, WiFi, 2 камеры 8/1.2Мпикс, золотистый',22500.000000,22500.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Air MD791',' 2048*1536, A7 1.4ГГц, 16GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 480г, 10ч, серый',33990.000000,33990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Air ME898',' 2048*1536, A7 1.4ГГц, 128GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 469г, 10ч, серый',32000.000000,32000.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Air ME906',' 2048*1536, A7 1.4ГГц, 128GB, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 469г, 10ч, серебристый',32000.000000,32000.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Air ME987',' 2048*1536, A7 1.4ГГц, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 478г, 10ч, серый',34990.000000,34990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Air ME988',' 2048*1536, A7 1.4ГГц, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2Мпикс, 170*240*8мм 480г, 10ч, серебристый',34990.000000,34990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES (' 9.7" Apple iPad Pro MM172RU/A',' 2048*1536, A9X 2.26ГГц, 32GB, BT, WiFi, 2 камеры 12/5Мпикс, 169.5*240*6.1мм437г, 10ч, розовое золото',43490.000000,43490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" ASUS Eee Pad Transformer Prime TF201',' 1280*800, ARM 1.4ГГц, 32GB, GPS, BT, WiFi, Android 4.0, док-станция, клавиатура, 263*181*8мм 586г, 12ч, золотистый',7990.000000,7990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" ASUS Transformer Book T100HA-FU002T',' 1280*800, Intel 1.44ГГц, 32GB,  BT, WiFi, SDHC-micro, microHDMI, 2 камеры 5/2Мпикс, W10, док-станция, клавиатура, 263*171*11мм 550гр, серый',17500.000000,17500.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" ASUS Transformer Pad TF103CG-1A056A',' 1280*800, intel 1.6ГГц, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3Мпикс, Android 4.4, 257.3*178.4*9.9мм 550г черный',7400.000000,7400.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" ASUS Transformer Pad TF103CG-1A059A',' 1280*800, intel 1.33ГГц, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3Мпикс, клавиатура, Android 4.4, 257.3*178.4*9.9мм 550г черный',14989.000000,14989.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" ASUS ZenPad 10 Z300M-6A056A',' 1280*800, MTK 1.3ГГц, 8GB, BT,  WiFi, SD/SD-micro, 2/5Мпикс, Android 6, 251.6*172*7.9мм 490г, черный',9990.000000,9990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Acer Iconia Tab A200',' 1280*800, ARM 1ГГц, 32GB, GPS, BT, WiFi, SD-micro, камера 2Мпикс, Android 4.0, 260*175*70мм 720г, красный',5590.000000,5590.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Archos 101b Copper',' 1024*600, ARM 1.3ГГц, 8GB, 3G, BT, WiFi, SD-micro, 2 камеры 2/0.3Мпикс,  Android 4.4, 262*166*10мм 577г, серый',6300.000000,6300.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Archos 101c Copper',' 1024*600, ARM 1.3ГГц, 16GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 2/0.3Мпикс,  Android 5.1, 259*150*9.8мм 450г, синий',6250.000000,6250.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Dell XPS 10 Tablet 6225-8264',' 1366*768, Qualcomm 1.5ГГц, 64GB, BT, WiFi, SD-micro, miniHDMI, 2 камеры 5/2 Мпикс, W8RT, док-станция, клавиатура, 275*177*9мм 635г, 10.5ч, черный',8200.000000,8200.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Huawei MediaPad T5 10 LTE 53010DLM',' 1920*1200, Kirin 2.36ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 8, 243*164*7.8мм, 460гр, черный',15990.000000,15990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Irbis TW21',' 1280*800, Intel 1.8ГГц, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, microHDMI, 2 камеры 2/2Мпикс, W8.1, клавиатура, черный',5790.000000,5790.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Irbis TW31',' 1280*800, Intel 1.8ГГц, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2Мпикс,  W10, клавиатура, 170*278*10мм 600г, черный',10400.000000,10400.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Lenovo Tab 4 TB-X304L ZA2K0056RU',' 1280*800, Qualcomm 1.4ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2Мпикс, Android 7, 247*170*8.4мм 505г, черный',13100.000000,13100.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Lenovo Tab 4 TB-X304L ZA2K0082RU',' 1280*800, Qualcomm 1.4ГГц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2Мпикс, Android 7, 247*170*8.4мм 505г, белый',12990.000000,12990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Pegatron Chagall 90NL-083S100',' 1280*800, ARM 1.5ГГц, 16GB, BT, WiFi, SD-micro,  2 камеры 8/2 Мпикс, Android 4.0, 260*7*180мм 540г, 8ч, черный',4100.000000,4100.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio MultiPad Grace PMT3101',' 1280*800, MTK 1.3ГГц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 243*171*10мм, 545гр, черный',7990.000000,7990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio MultiPad Wize PMT3131',' 1280*800, MTK 1.13ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 261*155*9.8мм, 554гр, черный',6490.000000,6490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio MultiPad Wize PMT3131',' 1280*800, MTK 1.13ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 261*155*9.8мм, 554гр, черный',5490.000000,5490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio MultiPad Wize PMT3151',' 1280*800, MTK 1.13ГГц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 6, 261*155*9.8мм, 554гр, черный',6490.000000,6490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio MultiPad Wize PMT3161',' 1280*800, MTK 1.3ГГц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3Мпикс, Android 7, 243*171*10мм, 545гр, черный',6490.000000,6490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio Visconte 4U XIPMP1011TDBK',' 1280*800, Intel 1.8ГГц, 16GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2Мпикс, W10, клавиатура, 256*173.6*10.5мм 580г, черный',7490.000000,7490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Prestigio Visconte A WCPMP1014TEDG',' 1280*800, Intel 1.83ГГц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2Мпикс, W10, клавиатура, 259.3*173.5*10.1мм 575г, серый',8490.000000,8490.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" RoverPad Magic HD10G',' 1280*800, ARM 1.2ГГц, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 7, 242.3*171.2*9.5мм 560г, черный',5990.000000,5990.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('10.1" Tesla Impulse 10.1 3G',' 1280*800, ARM 1.2ГГц, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3Мпикс, Android 5.1, 242.3*171.2*9.5мм 560г, черный',5590.000000,5590.000000)
 INTO PRODUCT_INFORMATION(PRODUCT_NAME,PRODUCT_DESCRIPTION,MIN_PRICE,LIST_PRICE) VALUES ('11.6" Prestigio Visconte S UEPMP1020CESR',' 1920*1080, Intel 1.84ГГц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2Мпикс, W10, клавиатура, 260*186*9.75мм 684г, серый',12490.000000,12490.000000)
SELECT * from dual;