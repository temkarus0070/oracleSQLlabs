--Претков Артем, 2 лаба

/*1.Выбрать клиентов, у которых были заказы в июле 1999 года. Упорядочить по коду клиента. Использовать внутреннее соединение
(inner join) и distinct.
Ответ: 47 строк.
*/
SELECT distinct c.*
    FROM CUSTOMERS c
        inner join ORDERS O
            on c.CUSTOMER_ID = O.CUSTOMER_ID
    where o.ORDER_DATE>=date'1999-07-01' and o.ORDER_DATE<date'1999-08-01'
    order by c.CUSTOMER_ID;


/*2.Выбрать всех клиентов и сумму их заказов за 2000 год, упорядочив их по сумме заказов (клиенты, у которых вообще не было заказов
  за 2000 год, вывести в конце), затем по ID заказчика. Вывести поля: код заказчика, имя заказчика (фамилия + имя через пробел), сумма заказов за 2000 год.
  Использовать внешнее соединение (left join) таблицы заказчиков с подзапросом для выбора суммы товаров (по таблице заказов) по клиентам за 2000 год (подзапрос с группировкой).
Ответ: 319 строк.
 */
 SELECT c.CUSTOMER_ID,
        c.CUST_FIRST_NAME || ' ' || c.CUST_LAST_NAME,
        ord.sum
    FROM CUSTOMERS c
        left join (
            SELECT o.CUSTOMER_ID,sum(o.ORDER_TOTAL) as sum
                FROM ORDERS o
                WHERE o.ORDER_DATE>=date'2000-01-01' and o.ORDER_DATE<date'2001-01-01'
                GROUP BY o.CUSTOMER_ID
        )ord
            on ord.CUSTOMER_ID=c.CUSTOMER_ID
    order by ord.sum nulls last ;

/*3.Выбрать сотрудников, которые работают на первой своей должности (нет записей в истории). Использовать внешнее соединение
(какое конкретно?) с таблицей истории, а затем отбор записей из таблицы сотрудников таких, для которых не «подцепилось» строк
из таблицы истории. Упорядочить отобранных сотрудников по дате приема на работу (в обратном порядке, затем по коду сотрудника
(в обычном порядке).
Ответ: 100 строк.
 */
 SELECT e.*
    FROM EMPLOYEES e
        left join JOB_HISTORY JH
            on e.EMPLOYEE_ID = JH.EMPLOYEE_ID
    where JH.JOB_ID is null
    order by e.HIRE_DATE desc,
             e.EMPLOYEE_ID asc;

/*4.Выбрать все склады, упорядочив их по количеству номенклатуры товаров, представленных в них. Вывести поля: код склада,
  название склада, количество различных товаров на складе. Упорядочить по количеству номенклатуры товаров на складе (от большего количества
  к меньшему), затем по коду склада (в обычном порядке). Склады, для которых нет информации о товарах на складе, вывести в конце. Подзапросы не использовать.
Ответ: 9 строк.
 */
 SELECT w.WAREHOUSE_ID,
        w.WAREHOUSE_NAME,
        count(i.PRODUCT_ID) as count
    from WAREHOUSES w
        left join INVENTORIES I
            on w.WAREHOUSE_ID = I.WAREHOUSE_ID
    group by w.WAREHOUSE_ID,
             w.WAREHOUSE_NAME
    order by count desc nulls last ,
             w.WAREHOUSE_ID;

/*
5.Выбрать сотрудников, которые работают в США. Упорядочить по коду сотрудника.
Ответ: 68 строк.
 */
 SELECT e.*
    FROM EMPLOYEES e
        inner join DEPARTMENTS D
            on D.DEPARTMENT_ID = e.DEPARTMENT_ID
        inner join LOCATIONS l
            on D.LOCATION_ID = l.LOCATION_ID
        inner join COUNTRIES C2
            on C2.COUNTRY_ID = l.COUNTRY_ID
   where C2.COUNTRY_NAME='United States of America'
   order by e.EMPLOYEE_ID;

/*6.Выбрать все товары и их описание на русском языке. Вывести поля: код товара, название товара, цена товара в каталоге (LIST_PRICE),
  описание товара на русском языке. Если описания товара на русском языке нет, в поле описания вывести «Нет описания», воспользовавшись функцией nvl
  или выражением case (в учебной базе данных для всех товаров есть описания на русском языке, однако запрос должен быть написан в предположении,
  что описания на русском языке может и не быть; для проверки запроса можно указать код несуществующего языка и проверить,
  появилось ли в поле описания соответствующий комментарий). Упорядочить по коду категории товара, затем по коду товара.
Ответ: 288 строк.
 */
 SELECT p.PRODUCT_ID,
        p.PRODUCT_NAME,
        p.LIST_PRICE,
        nvl(pd.TRANSLATED_NAME,'Нет описания')
    from PRODUCT_INFORMATION p
        left join PRODUCT_DESCRIPTIONS PD
            on p.PRODUCT_ID = PD.PRODUCT_ID and pd.LANGUAGE_ID='RU'
    order by p.CATEGORY_ID,
             p.PRODUCT_ID;



/*7.Выбрать товары, которые никогда не продавались. Вывести поля: код товара, название товара, цена товара в каталоге (LIST_PRICE),
  название товара на русском языке (запрос должен быть написан в предположении, что описания товара на русском языке может и не быть).
  Упорядочить по цене товара в обратном порядке (товары, для которых не указана цена, вывести в конце), затем по коду товара.
Ответ: 103 строки.
   */
SELECT p.PRODUCT_ID,
        p.PRODUCT_NAME,
        p.LIST_PRICE,
        nvl(pd.TRANSLATED_NAME,'Нет описания')
    FROM PRODUCT_INFORMATION p
        left join ORDER_ITEMS OI
            on p.PRODUCT_ID = OI.PRODUCT_ID
        left join PRODUCT_DESCRIPTIONS PD
            on p.PRODUCT_ID = PD.PRODUCT_ID and pd.LANGUAGE_ID='RU'
    where oi.ORDER_ID is null
    order by p.LIST_PRICE desc nulls last ,
             p.PRODUCT_ID;


/*

8.Выбрать клиентов, у которых есть заказы на сумму больше, чем в 2 раза превышающую среднюю цену заказа. Вывести поля: код клиента,
название клиента (фамилия + имя через пробел), количество таких заказов, максимальная сумма заказа. Упорядочить по количеству таких заказов
в обратном порядке, затем по коду клиента.
Ответ: 13 строк.

--средняя в магазине
*/

 SELECT c.CUSTOMER_ID,
        c.CUST_LAST_NAME || ' ' || c.CUST_FIRST_NAME,
        count(o.ORDER_ID),
        max(o.ORDER_TOTAL)
    FROM CUSTOMERS c
    inner join ORDERS O on c.CUSTOMER_ID = O.CUSTOMER_ID
    where o.ORDER_TOTAL>2*(
        SELECT AVG(o1.ORDER_TOTAL)
            FROM ORDERS o1
                        )
    group by c.CUSTOMER_ID,
             c.CUST_FIRST_NAME,
             c.CUST_LAST_NAME
    order by count(o.ORDER_ID) desc ,
             c.CUSTOMER_ID
;

/*
9.Упорядочить клиентов по сумме заказов за 2000 год. Вывести поля: код клиента, имя клиента (фамилия + имя через пробел), сумма заказов за 2000 год.
Упорядочить данные по сумме заказов за 2000 год в обратном порядке, затем по коду клиента. Клиенты, у которых не было заказов в 2000, вывести в конце.
Ответ: 319 строк.

 */
 SELECT c.CUSTOMER_ID,
        c.CUST_FIRST_NAME || ' ' || c.CUST_LAST_NAME,
        sum(o.ORDER_TOTAL) as sum
    FROM CUSTOMERS c
        left join ORDERS O
            on c.CUSTOMER_ID = O.CUSTOMER_ID
                              and (o.ORDER_DATE>=date'2000-01-01' and o.ORDER_DATE<date'2001-01-01')
    group by c.CUSTOMER_ID, c.CUST_FIRST_NAME, c.CUST_LAST_NAME
    order by sum desc nulls last ,
             c.CUSTOMER_ID;


/*10.Переписать предыдущий запрос так, чтобы не выводить клиентов, у которых вообще не было заказов.
Ответ: 16 строк.

 */
  SELECT c.CUSTOMER_ID,
        c.CUST_FIRST_NAME || ' ' || c.CUST_LAST_NAME,
        sum(o.ORDER_TOTAL) as sum
    FROM CUSTOMERS c
        inner join ORDERS O
            on c.CUSTOMER_ID = O.CUSTOMER_ID
                              and (o.ORDER_DATE>=date'2000-01-01' and o.ORDER_DATE<date'2001-01-01')
    group by c.CUSTOMER_ID, c.CUST_FIRST_NAME, c.CUST_LAST_NAME
    order by sum desc nulls last ,
             c.CUSTOMER_ID;

--ВОПРОС ПО КОЛ-ВУ ПОЗИЦИЙ!!

/*11.Каждому менеджеру по продажам сопоставить последний его заказ. Менеджера по продажам считаем сотрудников,
  код должности которых: «SA_MAN» и «SA_REP». Вывести поля: код менеджера, имя менеджера (фамилия + имя через пробел),
  код клиента, имя клиента (фамилия + имя через пробел), дата заказа, сумма заказа, количество различных позиций в заказе.
  Упорядочить данные по дате заказа в обратном порядке, затем по сумме заказа в обратном порядке, затем по коду сотрудника.
  Тех менеджеров, у которых нет заказов, вывести в конце.
Ответ: 35 строк.
 */
 SELECT e.EMPLOYEE_ID,
        e.LAST_NAME || ' ' || e.FIRST_NAME,
        ord.CUSTOMER_ID,
        cust.CUST_LAST_NAME || ' ' || cust.CUST_FIRST_NAME,
        ord.lastDate,
        ord.ORDER_TOTAL,
        count(oi.PRODUCT_ID)
    FROM EMPLOYEES e
        left join (
            SELECT o.ORDER_ID,O.SALES_REP_ID,o.CUSTOMER_ID,lastOrd.lastDate,o.ORDER_TOTAL
                FROM ORDERS o
                    inner join (SELECT distinct o.SALES_REP_ID,max(o.ORDER_DATE) as lastDate
                                FROM ORDERS o
                                GROUP BY o.SALES_REP_ID)lastOrd
                        on lastOrd.SALES_REP_ID=o.SALES_REP_ID and lastOrd.lastDate=o.ORDER_DATE
            )ord
            on e.EMPLOYEE_ID=ord.SALES_REP_ID
        left join ORDER_ITEMS oi
            on oi.ORDER_ID=ord.ORDER_ID
        left join CUSTOMERS cust
            on cust.CUSTOMER_ID=ord.CUSTOMER_ID
    WHERE e.JOB_ID in ('SA_REP','SA_MAN')
    GROUP BY e.EMPLOYEE_ID,
        e.LAST_NAME,
        e.FIRST_NAME,
        ord.CUSTOMER_ID,
        cust.CUST_LAST_NAME ,
        cust.CUST_FIRST_NAME,
        ord.lastDate,
        ord.ORDER_TOTAL
    ORDER BY ord.lastDate DESC NULLS LAST ,
             ord.ORDER_TOTAL DESC ,
             e.EMPLOYEE_ID;

/*
12.Проверить, были ли заказы, в которых товары поставлялись со скидкой. Считаем, что скидка была, если сумма заказа меньше суммы стоимости
всех позиций в заказе, если цены товаров смотреть в каталоге (прайсе). Если такие заказы были, то вывести максимальный процент скидки среди всех таких заказов,
округленный до 2 знаков после запятой.
Ответ: 1 строка (1 число).
 */


SELECT max(100-(ord.orderPrice/ord.itemPrice*100))
    FROM (
        SELECT PI.PRODUCT_ID,SUM(o.UNIT_PRICE)as orderPrice,SUM(pi.LIST_PRICE) as itemPrice
            FROM ORDER_ITEMS o
                inner join PRODUCT_INFORMATION PI
                    on PI.PRODUCT_ID = o.PRODUCT_ID
            group by PI.PRODUCT_ID
        )ord
    where ord.itemPrice<>0;

/*
13.Выбрать товары, которые есть только на одном складе. Вывести поля: код товара, название товара,
цена товара по каталогу (LIST_PRICE), код и название склада, на котором есть данный товар, страна,
в которой находится данный склад. Упорядочить данные по названию стране, затем по коду склада, затем по названию товара.
Ответ: 12 строк.
 */

SELECT      distinct p.PRODUCT_ID,
            p.PRODUCT_NAME,
            p.LIST_PRICE,
            W2.WAREHOUSE_ID,
            W2.WAREHOUSE_NAME,
            L.COUNTRY_ID
    FROM
         (
          select i.PRODUCT_ID,count(w.WAREHOUSE_ID)
          from INVENTORIES I
                   inner join WAREHOUSES W on W.WAREHOUSE_ID = I.WAREHOUSE_ID
          group by i.PRODUCT_ID
          having count(w.WAREHOUSE_ID) = 1
         )PS
    inner join PRODUCT_INFORMATION p
            on p.PRODUCT_ID=PS.PRODUCT_ID
    INNER JOIN INVENTORIES I2
            on p.PRODUCT_ID = I2.PRODUCT_ID
    INNER JOIN WAREHOUSES W2
            on W2.WAREHOUSE_ID = I2.WAREHOUSE_ID
    INNER JOIN LOCATIONS L
            on L.LOCATION_ID = W2.LOCATION_ID
    ORDER BY L.COUNTRY_ID,
            W2.WAREHOUSE_ID,
            p.PRODUCT_NAME;

/*14.Для всех стран вывести количество клиентов, которые находятся в данной стране. Вывести поля: код страны, название страны, количество клиентов.
  Для стран, в которых нет клиентов, в качестве количества клиентов вывести 0. Упорядочить по количеству клиентов в обратном порядке, затем по названию страны.
Ответ: 25 строк.
 */
 SELECT c.COUNTRY_ID,
        c.COUNTRY_NAME,
        nvl(count(cust.CUSTOMER_ID),0) as count
    FROM COUNTRIES c
        left join CUSTOMERS cust
            on cust.CUST_ADDRESS_COUNTRY_ID=c.COUNTRY_ID
    group by c.COUNTRY_ID, c.COUNTRY_NAME
    order by count desc ,
             c.COUNTRY_NAME;

/*15.Для каждого клиента выбрать минимальный интервал (количество дней) между его заказами.
  Интервал между заказами считать как разницу в днях между датами 2-х заказов без учета времени заказа.
  Вывести поля: код клиента, имя клиента (фамилия + имя через пробел), даты заказов с минимальным интервалом (время не отбрасывать),
  интервал в днях между этими заказами. Если у клиента заказов нет или заказ один за всю историю, то таких клиентов не выводить.
  Упорядочить по коду клиента.
Ответ: 18 строк.
 */

 SELECT c.CUSTOMER_ID,
        c.CUST_LAST_NAME || ' ' || c.CUST_FIRST_NAME,
        min.firstDate,
        min.secondDate,
        extract(day  from min.secondDate-min.firstDate) as dayInterval
    FROM CUSTOMERS c
       inner join
        (
            SELECT o1.CUSTOMER_ID,
                    o1.ORDER_DATE as firstDate,
                    o2.ORDER_DATE as secondDate,
                    o2.ORDER_DATE - o1.ORDER_DATE
                FROM ORDERS o1
                      join ORDERS o2
                           on o1.CUSTOMER_ID = o2.CUSTOMER_ID and o2.ORDER_DATE > o1.ORDER_DATE and not exists
                               (
                                  SELECT *
                                        FROM ORDERS o3
                                            inner join ORDERS o4
                                                on o3.CUSTOMER_ID=o4.CUSTOMER_ID and o3.CUSTOMER_ID=o2.CUSTOMER_ID
                                                       and o3.ORDER_DATE<>o4.ORDER_DATE
                                                       and o4.ORDER_DATE>o3.ORDER_DATE
                                        where o4.ORDER_DATE-o3.ORDER_DATE<o2.ORDER_DATE-o1.ORDER_DATE
                               )



        ) min
            on min.CUSTOMER_ID=c.CUSTOMER_ID
    order by c.CUSTOMER_ID;
