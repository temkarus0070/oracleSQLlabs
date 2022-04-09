--Претков Артем ,5 лаба

/*
 Создать схему БД для фиксации успеваемости студентов.

Есть таблицы:
	Специальности (просто справочник);
Учебный план (специальность, семестр, предмет, вид отчетности);
Студенты (фио, специальность, год поступления);
Оценки (студент, дата, оценка – предусмотреть неявку).
(Понятно, что указаны не все необходимые поля, а только список того, что должно быть обязательно).

В таблицах должны быть предусмотрены все ограничения целостности.

Создать триггеры для автоинкрементности первичных ключей.

Заполнить таблицы тестовыми данными.

Написать запрос, выводящий список должников на текущий момент времени (сколько семестров проучился студент вычислять из года поступления и текущей даты – написать для этого функцию). Должны выводиться поля: код студента, ФИО студента, курс, код предмета, название предмета, семестр, оценка (2 – если сдавал экзамен, нулл – если не сдавал).

Сделать из этого запроса представление.

Выбрать из представления студентов с 4-мя и более хвостами (на отчисление).

 */


DROP TABLE SPECIALIZATIONS;
 CREATE TABLE SPECIALIZATIONS(
    NAME VARCHAR2(1000) PRIMARY KEY
 );

DROP TABLE STUDY_PLANS;
CREATE TABLE STUDY_PLANS(
    SPECIALIZATION_NAME VARCHAR2(1000),
    SEMESTER INTEGER,
    SUBJECT_NAME VARCHAR2(1000),
    REPORT_FORM VARCHAR2(200) NOT NULL ,
    CONSTRAINT SPECIALIZATION_STUDY_PLANS_FK FOREIGN KEY (SPECIALIZATION_NAME) REFERENCES SPECIALIZATIONS (NAME),
    CONSTRAINT STUDY_PLANS_PK PRIMARY KEY (SPECIALIZATION_NAME,SEMESTER,SUBJECT_NAME)

);

DROP TABLE STUDENTS;
CREATE TABLE STUDENTS(
    ID INTEGER PRIMARY KEY,
    FULL_NAME VARCHAR2(2000) NOT NULL,
    SPECIALIZATION_NAME VARCHAR2(1000) NOT NULL ,
    APPLIED_AT_UNIERSITY_YEAR NUMBER NOT NULL ,
    CONSTRAINT SPECIALIZATION_STUDENTS_FK FOREIGN KEY (SPECIALIZATION_NAME) REFERENCES SPECIALIZATIONS (NAME)
);

DROP TABLE MARKS;
CREATE TABLE MARKS(
    STUDENT_ID INTEGER ,
    MARK_DATE TIMESTAMP,
    MARK INTEGER,
    SUBJECT_NAME VARCHAR2(1000),
      SPECIALIZATION_NAME VARCHAR2(1000),
    SEMESTER INTEGER,
    CONSTRAINT MARK_PK PRIMARY KEY (STUDENT_ID,MARK_DATE,SUBJECT_NAME),
    CONSTRAINT SUBJECT_NAME_IN_STUDY_PLANS_FK FOREIGN KEY (SUBJECT_NAME,SPECIALIZATION_NAME,SEMESTER) REFERENCES STUDY_PLANS(SUBJECT_NAME,SPECIALIZATION_NAME,SEMESTER),
    CONSTRAINT STUDENT_MARKS_FK FOREIGN KEY (STUDENT_ID) REFERENCES STUDENTS (ID)
);

DROP SEQUENCE STUDENT_IDS;
CREATE SEQUENCE STUDENT_IDS INCREMENT BY 1;


CREATE OR REPLACE TRIGGER STUDENT_ID_INSERT_TRIGGER
    BEFORE INSERT
    ON STUDENTS
FOR EACH ROW
    DECLARE
    BEGIN
        :new.id := STUDENT_IDS.nextval;
    end;


INSERT INTO SPECIALIZATIONS VALUES ('Applied informatics');

INSERT INTO STUDY_PLANS VALUES ('Applied informatics',1,'Web programming','EXAM');
INSERT INTO STUDY_PLANS VALUES ('Applied informatics',1,'1C programming','EXAM');
INSERT INTO STUDY_PLANS VALUES ('Applied informatics',1,'Math','EXAM');
INSERT INTO STUDY_PLANS VALUES ('Applied informatics',1,'Applied informatics','EXAM');

INSERT INTO STUDENTS(FULL_NAME, SPECIALIZATION_NAME, APPLIED_AT_UNIERSITY_YEAR) VALUES ('Vasya Pupkin Vasilyevich','Applied informatics',2021);
INSERT INTO STUDENTS(FULL_NAME, SPECIALIZATION_NAME, APPLIED_AT_UNIERSITY_YEAR) VALUES ('Vasya Ivanov Vasilyevich','Applied informatics',2021);
INSERT INTO STUDENTS(FULL_NAME, SPECIALIZATION_NAME, APPLIED_AT_UNIERSITY_YEAR) VALUES ('Elizabeth iVANOVA Vasilyevna','Applied informatics',2021);

INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Pupkin Vasilyevich'),DATE'2022-01-15',NULL,'Web programming','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Pupkin Vasilyevich'),DATE'2022-01-19',2,'1C programming','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Pupkin Vasilyevich'),DATE'2022-01-19',2,'Math','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Pupkin Vasilyevich'),DATE'2022-01-19',2,'Applied informatics','Applied informatics',1);

INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Elizabeth iVANOVA Vasilyevna'),DATE'2022-01-15',4,'Web programming','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Elizabeth iVANOVA Vasilyevna'),DATE'2022-01-19',5,'1C programming','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Elizabeth iVANOVA Vasilyevna'),DATE'2022-01-19',3,'Math','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Elizabeth iVANOVA Vasilyevna'),DATE'2022-01-19',5,'Applied informatics','Applied informatics',1);

INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Ivanov Vasilyevich'),DATE'2022-01-15',2,'Web programming','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Ivanov Vasilyevich'),DATE'2022-01-19',2,'1C programming','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Ivanov Vasilyevich'),DATE'2022-01-19',2,'Math','Applied informatics',1);
INSERT INTO MARKS VALUES ((SELECT ID from STUDENTS where FULL_NAME='Vasya Ivanov Vasilyevich'),DATE'2022-01-19',2,'Applied informatics','Applied informatics',1);


create or replace function get_semester_of_student_study(v_student_id in integer) return integer
is
    v_stud STUDENTS%rowtype;
        v_sems integer;
        begin
    select * INTO v_stud
        from STUDENTS s
    where s.ID=v_student_id;

    v_sems := (extract(year  from sysdate)-v_stud.APPLIED_AT_UNIERSITY_YEAR)*2-1;
    if extract(month  from sysdate)>=8 and v_sems>0 then
        v_sems := v_sems +1;
        end if;
    return v_sems;
end;


    SELECT s.ID,
           s.FULL_NAME,
           CEIL(GET_SEMESTER_OF_STUDENT_STUDY(s.ID)/2)as course,
           m.SUBJECT_NAME,
           m.MARK
        FROM MARKS m
        inner join STUDENTS S
            on S.ID = m.STUDENT_ID
        WHERE m.MARK is null  or m.MARK<3 and not exists(
            SELECT * FROM
                MARKS m1
                where m1.STUDENT_ID=M.STUDENT_ID AND m1.SUBJECT_NAME=m.SUBJECT_NAME AND  m1.SEMESTER=m.SEMESTER
                  and m1.MARK_DATE<> m.MARK_DATE and m.MARK is not null  and m.MARK>2
            );

    CREATE OR REPLACE VIEW BAD_STUDENTS_MARKS as
        SELECT s.ID,
           s.FULL_NAME,
           CEIL(GET_SEMESTER_OF_STUDENT_STUDY(s.ID)/2) as course,
           m.SUBJECT_NAME,
           m.MARK
        FROM MARKS m
        inner join STUDENTS S
            on S.ID = m.STUDENT_ID
        WHERE m.MARK is null  or m.MARK<3 and not exists(
            SELECT * FROM
                MARKS m1
                where m1.STUDENT_ID=M.STUDENT_ID AND m1.SUBJECT_NAME=m.SUBJECT_NAME AND  m1.SEMESTER=m.SEMESTER
                  and m1.MARK_DATE<> m.MARK_DATE and m.MARK is not null  and m.MARK>2
            );

    select bm.ID,
           bm.FULL_NAME,
           count(*)
        from BAD_STUDENTS_MARKS bm
        group by bm.ID,bm.FULL_NAME
        having count(bm.MARK)>=4;