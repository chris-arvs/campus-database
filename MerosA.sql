---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-------------------------------------   1  --------------------------------------------------------------------
create type room_t AS ENUM ('lecture_room','computer_room','lab_room','office');
CREATE TABLE Room(
	room_id integer not null,
	room_type room_t,
	capacity integer,
	primary key (room_id)
	);
--weekday can be extracted the WEEKDAY() function returns the weekday number for a given date.
--Monday = 0, Tuesday = 1,Wednesday = 2,Thursday = 3,Friday = 4,Saturday = 5,Sunday = 6.
--Note: 0 = Monday, 1 = Tuesday, 2 = Wednesday, 3 = Thursday, 4 = Friday, 5 = Saturday, 6 = Sunday.
create type activity_t AS ENUM ('lecture','tutorial','computer_lab','lab','office_hours');
CREATE TABLE LearningActivity(
	course_code varchar(20),
	serial_number integer,
	room_id integer,
	weekday date not null,
	start_time integer not null,
	end_time integer not null,
	activity_type activity_t,
	primary key(weekday,start_time,end_time),
	foreign key(course_code,serial_number) references "CourseRun" (course_code,serial_number) on delete cascade on update cascade,
	foreign key(room_id) references Room (room_id) on delete cascade on update cascade
	);
	
CREATE TABLE Person(
	amka integer,
	name char(30),
	father_name char(30),
	email char(30),
	Surname char(30),
	primary key(amka) 
	);

--firstly we copy all the existed records from tables "Student","Professor","LabStaff" into "Person" with command 
--insert into "Person"(Select amka,name,father_name,surname,email from "LabStaff"/"Student"/"Professor")
--and afterwords every amka exists in table "Person" so we can make the ISA:
ALTER TABLE "Student" ADD foreign key(amka) references "Person"(amka) ON DELETE CASCADE; 
ALTER TABLE "Professor" ADD foreign key(amka) references "Person"(amka) ON DELETE CASCADE;
ALTER TABLE "LabStaff" ADD foreign key(amka) references "Person"(amka) ON DELETE CASCADE;

create type role_type AS ENUM ('responsible','participant');
CREATE TABLE Participates(
	start_time integer,
	end_time integer,
	weekday date,
	amka integer,
	roles role_type,
	foreign key(weekday,start_time,end_time) references "LearningActivity" on delete cascade on update cascade,
	foreign key(amka) references "Person" on delete cascade on update cascade
	);
---------------------------------------------------------------------------------------------------------------
DROP TABLE "Diploma";
DROP TABLE "Graduation_rule";
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
------------------------------------     3.1    ---------------------------------------------------------------
create or replace function randomFatherName() returns table(fatherName char(30)) as
	$$
	begin 
	return query
	select n.name
	from "Name" n 
	where n.sex = 'M'
	order by random() limit 1;

	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
create or replace function randomRank() returns table(rank rank_type) as
	$$
	begin
	return query
	select p.rank
	from "Professor" p
	order by random() limit 1;

	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
create or replace function randomLab() returns table(lab_code integer) as
	$$
	begin
	return query
	select l.lab_code
	from "Lab" l
	order by random() limit 1;

	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
create or replace function randomLevel() returns table(level level_type) as
	$$
	begin
	return query
	select l.level
	from "LabStaff" l
	order by random() limit 1;

	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
create or replace function insertProfessor(numOfIns integer) returns void as
	$$
	declare
	 i integer;
	 amka integer;
	 email char(30);
	 ranN char(30);
	 ranF char(30);
	 ranS char(30);
	begin
	--return query
	amka:= (
		select count(*)
		from "Professor");

	amka:= amka + 20000;
	i:= 1;

    FOR i IN 1..numOfIns LOOP
    	amka:= amka + 1;
    	email:= concat('p',amka::text,'@isc.tuc.gr')::char(30);	
    	ranN:= (select randomName.name from random_names(1) as randomName);
		ranF:= randomFatherName();
		ranS:= (select adapt_surname(randomSurname.surname,randomName.sex) from random_surnames(1) as randomSurname,random_names(1) as randomName);
		insert into "Person" values (amka,ranN,ranF,ranS,email);
    	insert into "Professor" values (amka,ranN,ranF,ranS,email,randomLab(),randomRank());
	end LOOP;
	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
create or replace function insertLabStaff(numOfIns integer) returns void as
	$$
	declare
	 i integer;
	 amka integer;
	 email char(30);
	 ranN char(30);
	 ranF char(30);
	 ranS char(30);
	begin
	--return query
	amka:= (
	 	select count(*)
		from "LabStaff");

	amka:= amka + 30000;
	i:= 1;

	FOR i IN 1..numOfIns LOOP
   		amka:= amka + 1;
   		email:= concat('l',amka::text,'@isc.tuc.gr')::char(30);	
		ranN:= (select randomName.name from random_names(1) as randomName);
		ranF:= randomFatherName();
		ranS:= (select adapt_surname(randomSurname.surname,randomName.sex) from random_surnames(1) as randomSurname,random_names(1) as randomName);
		insert into "Person" values (amka,ranN,ranF,ranS,email);
   		insert into "LabStaff" values (amka,ranN,ranF,ranS,email,randomLab(),randomlevel());
   		
	end LOOP;
	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
create or replace function insertStudent(numOfIns integer,regDate date) returns void as
	$$
	declare
		i integer;
		amka integer;
		am integer := 0;
		am_num integer;
		email char(30);
		yearOfReg integer;
		DateOfReg date := current_date;
		ranN char(30);
	 	ranF char(30);
	    ranS char(30);
		
	begin

	amka := (
		select count(*)
		from "Student"
	);

	yearOfReg := extract (year from  date (current_date)); 

	am_num :=
		(
		select count(*)
		from "Student" s
		where (cast(s.am as integer)/1000000) = yearOfReg
		);

	i:= 1;
	FOR i IN 1..numOfIns LOOP
		am_num := am_num + 1;											   
		amka := amka + 1;
		email:= concat('s',amka::text,'@isc.tuc.gr')::char(30);									
		am := create_am(yearOfReg,am_num);
		ranN:= (select randomName.name from random_names(1) as randomName);
		ranF:= randomFatherName();
		ranS:= (select adapt_surname(randomSurname.surname,randomName.sex) from random_surnames(1) as randomSurname,random_names(1) as randomName);
		insert into "Person" values (amka,ranN,ranF,ranS,email);
		insert into "Student" values(amka,ranN,ranF,ranS,email,am,DateOfReg);
	end LOOP;
	end;
	$$
language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--------------------------   3.2    ---------------------------------------------------------------------------
create or replace function update_Register(sem integer) returns void as
	$$
	begin
	
	--with q1 as(
	--		select cr.course_code
	--		from "CourseRun" cr
	--		where cr.semesterrunsin = sem) 
			 

	
	update "Register" r
	set lab_grade = trunc(random() * 9 + 1)
	where 
	r.course_code in (
		select cr.course_code
		from "CourseRun" cr
		where cr.semesterrunsin = sem
	)
	and
	r.course_code in (
		select cr.course_code
		from "Course" cr
		where cr.lab_hours != 0
	)
	and
	(
	r.register_status in ('approved','pass','fail','proposed')
	);

------------------------------insert exam mark-------------------------
	update "Register" r
	set exam_grade = trunc(random() * 9 + 1)
	where 
	r.course_code in (
		select cr.course_code
		from "CourseRun" cr
		where cr.semesterrunsin = sem
	)
	and
	(
		r.register_status in ('approved','pass','fail','proposed')
	);

---------------------------------insert total mark---------------------------
	update "Register" r
	set final_grade = (
		case 
			when (exam_grade < 5 or lab_grade < 5) then 0
			else cr.exam_percentage*exam_grade + ( (1 - cr.exam_percentage) * lab_grade)
		end
	)
	from "CourseRun" cr
	where
	cr.course_code = r.course_code
	and
	r.course_code in (
		select cr.course_code
		from "CourseRun" cr
		where cr.semesterrunsin = sem
	)
	and
	(
		r.register_status in ('approved','pass','fail','proposed')
	);

---------------------------------update register status---------------------------

	update "Register" r
	set register_status = (
		case
			when final_grade >= 5 then cast('pass' as register_status_type)
			else cast ('fail' as register_status_type) 
		end
	)
	where
	r.course_code in (
		select cr.course_code
		from "CourseRun" cr
		where cr.semesterrunsin = sem
	)
	and
	(
		r.register_status in ('approved','pass','fail','proposed')
	);

	end;
	$$
language 'plpgsql';
----------------------------------------------------------4.1--------------------------------------------------------

create or replace function BigRoomProfs() returns table(Tamka integer,Tname char(30),Tsurname char(30)) as 
	$$
begin
return query
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------      4.1      ---------Professors at Big Rooms ------------------------------------

Select amka as Tamka ,name as Tname ,surname as Tsurname
from "Professor" Prf
Where Prf.amka in (select Ptc.amka
				   from "Participates" Ptc inner join "LearningActivity" Lrn
				   on Lrn.weekday = Ptc.weekday AND Lrn.start_time = Ptc.start_time AND Lrn.end_time = Ptc.end_time
				   Where Lrn.room_id in (Select room_id
									   from "Room" Rm
									   where Rm.capacity>30)


);

end
	$$

language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
------------------------------------  4.2  --------------------------------------------------------------------

 create or replace function PreSemInfo() returns table(Tamka integer,Tname char(30),Tsurname char(30),Tweekday date,Tstime integer,Tetime integer) as 
$$
begin
return query
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------4.2----------- Present Semister Info -----------------------------------------------

Select Pr.amka as Tamka, Pr.name as Tname, Pr.surname as Tsurname , Lrn.weekday as Tweekday , Lrn.start_time as Tstime , Lrn.end_time as Tetime
		from "Professor" Pr 
		inner join "CourseRun" Cr ON Pr.amka = Cr.amka_prof1  
		inner join "LearningActivity" Lrn ON Cr.course_code = Lrn.course_code --AND Cr.serial_number = Cr.serial_number
		where Lrn.activity_type = 'office_hours'
		AND	semesterrunsin in (	select semester_id
								from "Semester"
								where semester_status = 'present')

;			   

end
$$

language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
----------------------------------------------------   4.3     ------------------------------------------------

create or replace function SemGradInfo(sem_id integer , grade_type char(20)) returns table(Tgrade numeric) as 
	$$
begin
return query
---------------------------4.3----------- Semester Grades  Info ----------------------------------------------

Select MAX(grade_type) as Tgrade
From "Register" Rg
Where Rg.course_code in (Select CR.course_code
			From "CourseRun" CR
	               	where semesterrunsin = sem_id)
Order by MAX(grade_type);
end;
$$

language 'plpgsql';
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--------------------------------------------------      4.4      ----------------------------------------------


create or replace function CompStud() returns table(Tam char(10),Tentry date) as 
$$
begin
return query
---------------------------4.4----------- Computer Present  Students ----------------------------------------------

Select St.am as Tam, St.entry_date as Tentry
From "Student" St
Where St.amka in (Select Ptc.amka
                  From "Participates" Ptc inner join "LearningActivity"Lrn
                  on Ptc.weekday=Lrn.weekday AND Ptc.start_time=Lrn.start_time AND Ptc.end_time=Lrn.end_time
                   Where Lrn.room_id in (Select room_id
				                     	  From "Room" Rm
					                      Where Rm.room_type = 'computer_room')
                  );

end;
$$

language 'plpgsql';



-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-----------------               4.5          ----------------------------------------------------------------
create or replace function AfternoonLearningActivities() returns table(course varchar(20),AfternoonActivity text) as
	$$
	begin
	return query 

	select *
	from
	(select distinct l.course_code as course, (case when(l.start_time >= 16 and l.end_time <= 18 ) then 'YES' else 'NO' end) as "AfternoonActivity"
	from "LearningActivity" l inner join "Course" cr on l.course_code = cr.course_code
	where cr.obligatory = true)
	as query1
	where "AfternoonActivity" = 'YES'

	union--all LearingActivities those between 16:00 - 20:00 and not

	select *
	from

	(select distinct l.course_code as course, (case when(l.start_time >= 16 and l.end_time <= 18 ) then 'YES' else 'NO' end) as "AfternoonActivity"
	from "LearningActivity" l inner join "Course" cr on l.course_code = cr.course_code
	where cr.obligatory = true)
	as query2
	where "AfternoonActivity" = 'NO'

	and
	query2.course not in (
	select distinct query3.course
	from
	(select distinct l.course_code as course, (case when(l.start_time >= 16 and l.end_time <= 18) then 'YES' else 'NO' end) as "AfternoonActivity"
	from "LearningActivity" l inner join "Course" cr on l.course_code = cr.course_code
	where cr.obligatory = true)
	as query3
	where "AfternoonActivity" = 'YES'
	);

	end;
	$$
language 'plpgsql';
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------     4.6      --------------------------------------------------------

create or replace function LabNoLab() returns table(crs_code char(20),crs_title char(30)) as 
$$
begin
return query
---------------------------4.6----------- Lab without Lab --------------------------------------------
Select Crs.course_code as crs_code , Crs.course_title as crs_title
From "Course" Crs inner join "LearningActivity" Lrn
ON Crs.course_code = Lrn.course_code 
Where Crs.obligatory 
AND Crs.lab_hours > 0
AND Lrn.room_id not in (Select room_id
					  From "Room" Rm
					 Where Rm.room_type = 'lab_room')
;
end;
$$

language 'plpgsql';
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------    4.7   --------------------------------------------------------------------------------------
create or replace function LabStaffLoad() returns table(Tamka integer,Tname char(30),Tsurname char(30), total bigint) as 
	$$
begin

	return query

	select Lbst.amka as Tamka , Lbst.name as Tname, Lbst.surname as Tsurname,sum(cr.lab_hours) as total 
	from "Supports" sup 
	inner join "Course" cr on sup.course_code = cr.course_code
	right outer join "LabStaff" Lbst on sup.amka = Lbst.amka
	where sup.serial_number in (
		select serial_number
		from "CourseRun"
		where semesterrunsin in (
			select semester_id
			from "Semester"
			where semester_status = 'present'
		)
	)
	group by Lbst.amka
	order by Lbst.amka;

	end;
	$$

language 'plpgsql';
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------        4.8       ------------------------------------------------------------

create or replace function MaxCrsRoom() returns table(rm_id integer,dif_crs bigint)as
$$
begin
return query
---------------------------4.8----------- Max Courses Room --------------------------------------------------
SELECT room_id as rm_id , Count(distinct course_code) as dif_crs
from "LearningActivity"
group by room_id 
having Count(course_code) = (select MAX(diaforetika)  
   from (select Count(course_code)  diaforetika 
    from "LearningActivity"
    group by room_id) tab) 
	
;
end;
$$

language 'plpgsql';
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------     5.1   ---------------------------------------------------------------------
create or replace function PersonUpdate() returns trigger as $$
begin

IF(tg_op = 'insert' or tg_op = 'updage')
THEN 
        --------------------------------------Participation not at the same time check----------------------
 	 	IF   (select amka
	     	  from "Participates"
			  where amka <> new.amka
			  ) ---Different guy 
		THEN 
		      return NEW;
	    ELSEIF   (select amka
	     	     from "Participates"
			     where amka = new.amka
			     And weekday <> new.weekday
				 ) ---Same guy , different day
		THEN 
		      return NEW;
	    ELSEIF   (select amka
	     	     from "Participates"
			     where amka = new.amka
			     And weekday = new.weekday
				 ---Same guy , same day day
				 And(
					 ((start_time>new.start_time)AND(start_time>new.end_time))--- New participation earlier
					 OR(end_time<new.start_time))  -- New participation later
				 )
		THEN 
		     return NEW;
		ELSE
		     return OLD;
		END IF;
			
		-----------------------------------------------------------------------------------	
	    --------------------Find total student lab hours-----------------------------------
		Select Ptc.amka as Pamka, (Sum(Ptc.end_time - Ptc.start_time)) as LabHours 
		From "Participates" Ptc inner join "LearningActivity" Lrn
		on Ptc.weekday = Lrn.weekday AND Ptc.start_time = Lrn.start_time AND Ptc.end_time = Lrn.end_time
		Where (Lrn.activity_type ='computer_lab' OR Lrn.activity_type='lab' )
		Group by Ptc.amka;
        --------------------------- Find total course lab hours----------------------------
		Select distinct Rg.amka as Ramka, Sum(Crs.lab_hours) as HoursLimit
		From "Register" Rg inner join "Course" Crs
		ON Crs.course_code = Rg.course_code
		Group by Rg.amka
		Order by Rg.amka;
        ---------------------------------------------Final Check-----------------------------
		IF LabHours < HoursLimit THEN
		return NEW;
		ELSE 
		return OLD;
		END IF;
		     	
	
END IF;
	end;
	
	$$
language 'plpgsql';

----------------------------------Execute-----------------------------------------------------

create trigger PersonUpdate 
Before insert or update
on "Person"
For each row
execute procedure PersonUpdate();
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------     5.2   ---------------------------------------------------------------------
create or replace function ActivityUpdate() returns trigger as $$
		declare
		fweekday int;
	begin
	--returns the weekday number for a given date.
	--Monday = 1, Tuesday = 2,Wednesday = 3,Thursday = 4,Friday = 5,Saturday = 6,Sunday = 0.

 	if(tg_op = 'insert' or tg_op = 'updage') then
		fweekday := extract(day from date(new.date));
 		if exists(select room_id from "Room" where room_id = new.room_id) then
 			---new room is not used for any activity yet
 			if not exists(select room_id from "LearningActivity" where room_id = new.room_id) then
 				if(new.start_time < 8 or new.start_time >= 20 or fweekday = 6 or fweekday = 0 or new.end_time < 8 or new.end_time > 20) then
					raise notice 'Invalid date or start time or end time';
					return old;
				else
					return new;
				end if;
 			end if;
 			-----new room is used the same day for another activity but different time
		 	if exists(select room_id from "LearningActivity" where room_id = new.room_id and weekday = new.weekday and ((start_time > new.start_time) AND (start_time > new.end_time) OR (end_time < new.start_time))) then
				if(new.start_time < 8 or new.start_time >= 20 or fweekday = 6 or fweekday = 0 or new.end_time < 8 or new.end_time > 20) then
					raise notice 'Invalid date or start time or end time';
					return old;
				else
					return new;
				end if;
			------new room is used for another activity but different day
			elsif exists(select room_id from "LearningActivity" where room_id = new.room_id and weekday <> new.weekday) then
				if(new.start_time < 8 or new.start_time >= 20 or fweekday = 6 or fweekday = 0 or new.end_time < 8 or new.end_time > 20) then
					raise notice 'Invalid date or start time or end time';
					return old;
				else
					return new;
				end if;
			else
				raise notice 'Invalid input';
				return old;
			end if;
		else
			raise notice 'There is not room with this id';
			return old;
		end if;
	end if;
	end;
	
	$$
language 'plpgsql';

create trigger ActivityUpdate before insert or update on "LearningActivity"
for each row execute procedure ActivityUpdate()

---------------------------------------------------------------------------------------------------

CREATE VIEW view6_1 AS

Select Count(Std.name),Rg.serial_number , Rg.course_code
From "Student" Std
Inner Join "Register" Rg ON Std.amka=Rg.amka
Where Rg.register_status = 'pass'
AND Rg.lab_grade >= 8
Group by Rg.course_code, Rg.serial_number

--------------------------------------------------------------------------------------


Select Std.name , Std.surname , Rg.serial_number , Rg.course_code
From "Student" Std
Inner Join "Register" Rg ON Std.amka=Rg.amka
Where Rg.register_status = 'pass'
AND Rg.lab_grade >= 8
Order by Rg.course_code, Rg.serial_number

CREATE VIEW view6_2 AS

Select Rm.room_id, Lrn.weekday , Lrn.start_time , Lrn.end_time , Prf.name , Prf.surname , Lrn.course_code
From "Room" Rm
Inner Join "LearningActivity" Lrn ON Rm.room_id = Lrn.room_id
Inner Join "Participates" Ptc ON Ptc.weekday = Lrn.weekday AND Ptc.start_time = Lrn.start_time AND Ptc.end_time = Lrn.end_time
Left Outer Join "Professor" Prf ON Ptc.amka = Prf.amka
---------------------------------------------------------------------------------------------

create or replace function merosA_4_9() returns table(Trid integer,Tday double precision, Tst integer , Tet integer) as 
$$
begin
return query
---------------------------------------------------4.9--------------------------------------------
SELECT  room_id as Trid ,EXTRACT(DOW FROM weekday) as Tday, Min(start_time) as Tst, Max(end_time) as Tet
from "LearningActivity" 
group by room_id, weekday
Having (Max(end_time)-Min(start_time))=Sum(end_time-start_time)
Order by room_id;
end;
$$

language 'plpgsql';

create or replace function merosA_4_10(min_c integer,max_c integer) returns table(Tamka integer) as 
$$
begin
return query
---------------------------------------------------4.10--------------------------------------------
Select distinct Ptc.amka as Tamka
From "Participates" Ptc
Inner join "LearningActivity" Lrn ON ((Lrn.weekday=Ptc.weekday) AND (Lrn.start_time=Ptc.start_time) AND (Lrn.end_time = Ptc.end_time))
Inner join "Room" Rm ON Lrn.room_id=Rm.room_id
Where Rm.capacity > min_c 
AND Rm.capacity < max_c
AND Ptc.amka > 19999
AND Ptc.amka <30000;
end;
$$

language 'plpgsql';