-- Push local file to remote server: TERMINAL:
-- # example upload to remote server
-- scp [source file] [username]@[destination server]:.
-- # load from remote server
-- scp cool_stuff.txt sanjeev@example.com:.


-- Remote TERMINAL :
-- mysql --local-infile=1 -u root -p
-- mysql
-- 


-- mysql comands:
-- 
SHOW DATABASES;
CREATE mta;
USE mta;


-- Field Description

-- C/A,UNIT,SCP,STATION,LINENAME,DIVISION,DATE,TIME,DESC,ENTRIES,EXITS


-- C/A      = Control Area (A002)
-- UNIT     = Remote Unit for a station (R051)
-- SCP      = Subunit Channel Position represents an specific address for a device (02-00-00)
-- STATION  = Represents the station name the device is located at
-- LINENAME = Represents all train lines that can be boarded at this station
--            Normally lines are represented by one character.  LINENAME 456NQR repersents train server for 4, 5, 6, N, Q, and R trains.
-- DIVISION = Represents the Line originally the station belonged to BMT, IRT, or IND   
-- DATE     = Represents the date (MM-DD-YY)
-- TIME     = Represents the time (hh:mm:ss) for a scheduled audit event
-- DESc     = Represent the "REGULAR" scheduled audit event (Normally occurs every 4 hours)
--            1. Audits may occur more that 4 hours due to planning, or troubleshooting activities. 
--            2. Additionally, there may be a "RECOVR AUD" entry: This refers to a missed audit that was recovered. 
-- ENTRIES  = The comulative entry register value for a device
-- EXIST    = The cumulative exit register value for a device


CREATE TABLE test_mta_new(
	ca VARCHAR(255),
	unit VARCHAR(255),
	scp VARCHAR(255),
	station VARCHAR(255),
	linename VARCHAR(255),
	division VARCHAR(255),
	audit_date VARCHAR(255),
	audit_time TIME,
	description VARCHAR(255),
	entries INT,
	exits INT
);


-- LOAD file names into LIST; CONCAT list 
ls  *_15*txt  *_1412*txt *_1411*txt *_14102*txt *_141018.txt > new_format_list.txt
cat new_format_list.txt | xargs tail -n+2 > ALLNEW.txt

--  LOAD file DATA into TABLE: MySQL
LOAD DATA LOCAL INFILE "ALLNEW.txt"
    INTO TABLE mta_new FIELDS TERMINATED BY "," IGNORE 1 LINES;

UPDATE mta_new
SET audit_date = STR_TO_DATE(audit_date ,'%m/%d/%Y');

-- ADD column for day of week
ALTER TABLE mta_new
ADD COLUMN audit_day INT
AFTER audit_time;

-- ODBC standard: WEEKDAY

-- UPDATE mta_new
-- SET audit_day = WEEKDAY(STR_TO_DATE(audit_date ,'%m/%d/%Y') ) ;

-- UPDATE mta_new
-- SET audit_day = DAYOFWEEK(STR_TO_DATE(audit_date ,'%m/%d/%Y') ) ;

UPDATE mta_new
SET audit_day = WEEKDAY(audit_date) ;

-----------------------------------------

-- CAN DO SIMILAR THING FOR "WEEK OF YEAR"


-----------------------------------------

ALTER TABLE mta_new
ADD COLUMN audit_week INT
AFTER audit_day;

UPDATE mta_new
SET audit_week = WEEK(STR_TO_DATE(audit_date ,'%m/%d/%Y') ) ;

-----------------------------------------

-- BRUNCH - SUNDAY
--   11am - 4pm

-----------------------------------------
CREATE TABLE sun_brunch
SELECT * FROM mta_new
WHERE audit_day = 1 
AND audit_time >= '11:00:00' 
AND audit_time <= '16:00:00';

-- one station - one Sunday
SELECT * from sun_brunch WHERE unit = 'R001' AND audit_date = '2014-10-12';
SELECT * from sun_brunch WHERE unit = 'R092' AND audit_date = '2014-10-26';
--  OBSERVED PROBLEM: some days only have 1 AUDIT in "burnch time period"


-- SELECT ALL date / time combos for STATION:
SELECT * from sun_brunch WHERE unit = 'R001'
GROUP BY audit_date, audit_time;


--  MIN & MAX entries / EXITS for 1 turnstile
SELECT ca, unit, scp, station, linename, audit_date, entries, exits,
min(audit_time) as start_time, max(audit_time) as end_time ,
min(entries) as entry_start_cnt, max(entries) as entry_end_cnt,
max(entries) - min(entries) as entry_period_cnt
FROM sun_brunch 
WHERE unit = 'R001' # for testing 
AND scp ='01-00-00' # for testing 
GROUP BY unit, ca, scp, audit_date
ORDER BY unit, ca, scp, audit_date, audit_time
LIMIT 50;

-----------------------------------------

-- 						   CUMULATIVE
-- BRUNCH - SUNDAY       ENTRIES / EXITS
--   11am - 4pm			  BY TURNSTILE

-----------------------------------------
CREATE TABLE sun_cnts_by_turnstile
SELECT ca, unit, scp, station, linename, audit_date, 
min(audit_time) as start_time, max(audit_time) as end_time ,
min(entries) as entry_start_cnt, max(entries) as entry_end_cnt,
max(entries) - min(entries) as entry_period_cnt,
min(exits) as exit_start_cnt, max(exits) as exit_end_cnt,
max(exits) - min(exits) as exit_period_cnt
FROM sun_brunch 
GROUP BY unit, ca, scp, audit_date
ORDER BY unit, ca, scp, audit_date, audit_time;

-----------------------------------------

-- 						   CUMULATIVE
-- BRUNCH - SUNDAY       ENTRIES / EXITS
--   11am - 4pm			  BY TURNSTILE

-----------------------------------------



WHERE unit = 'R001'   # for testing 
AND ( scp ='01-00-00' OR scp = '01-00-01' )  # for testing 


AND MIN(audit_time)

-- ALL UNIT VALUES!!! 463 stations
CREATE TABLE station_list
SELECT DISTINCT(unit) from sun_brunch;

--  ALL SUNDAY DATES: 
CREATE TABLE sun_date_list
SELECT DISTINCT(audit_date) from sun_brunch;

-- AUDIT DATES & TIMES for 1 station
SELECT ca, unit, scp, audit_date, audit_time, entries, exits from sun_brunch 
WHERE unit = 'R001'
AND scp = '00-00-01'
GROUP BY unit, ca, scp, audit_date, audit_time ;





SELECT unit, audit_date, audit_time, entries, exits from sun_brunch 
WHERE unit = 'R001'
GROUP BY audit_date, audit_time;


SELECT sun_brunch.unit,
sun_date_list.audit_date, 
MIN(sun_brunch.audit_time) AS start_time, 
MAX(sun_brunch.audit_time) AS end_time,
MIN(sun_brunch.entries) AS start_cnt,
MAX(sun_brunch.entries) AS end_cnt
FROM sun_brunch JOIN sun_date_list
ON (sun_date_list.audit_date = sun_brunch.audit_date)
GROUP BY sun_brunch.audit_date, sun_brunch.audit_time
ORDER BY sun_brunch.unit
LIMIT 50;



SELECT sun_brunch.unit,
sun_date_list.audit_date, 
MIN(sun_brunch.entries) AS start_cnt,
MAX(sun_brunch.entries) AS end_cnt
FROM sun_brunch JOIN sun_date_list
ON (sun_date_list.audit_date = sun_brunch.audit_date)
GROUP BY sun_brunch.audit_date, sun_brunch.audit_time
ORDER BY sun_brunch.unit, sun_brunch.audit_date
LIMIT 50;






HAVING DISTINCT(audit_date);
HAVING COUNT(DISTINCT(audit_date)) > 1;

group by EmailAddress, CustomerName

-----------------------------------------

-- for TESTING!!!!

-----------------------------------------

-- Also calculate the total salary for these teams -- their salary budget.

INSERT OVERWRITE DIRECTORY '/user/jess/baseballdata/total_team_salary.txt'
SELECT Teams.name, Salaries.yearID, AVG(Salaries.salary) FROM Salaries JOIN Teams
ON (Salaries.teamID = Teams.teamID)
WHERE Salaries.yearID IN (2000, 2005, 2010)
AND Teams.name IN ('New York Yankees' ,'New York Mets' , 'Chicago Cubs' ,'Chicago White Sox' ) 
GROUP BY Teams.name, Salaries.yearID;

-----------------------------------------

-- for TESTING!!!!

-----------------------------------------
--  LOAD file DATA into TABLE: MySQL
LOAD DATA LOCAL INFILE "turnstile_141018.txt"
    INTO TABLE test_mta_new FIELDS TERMINATED BY "," IGNORE 1 LINES;



UPDATE test_mta_new
SET audit_date = SELECT STR_TO_DATE(audit_date ,'%m/%d/%y') FROM test_mta_new ;

SELECT

-- Records: 3995401  Deleted: 0  Skipped: 0  Warnings: 402


---------------------------------------------------------
-- DISTINCT STATIONS!!!! 

-- mysql> SELECT COUNT(DISTINCT unit) FROM mta_new;
-- +----------------------+
-- | COUNT(DISTINCT unit) |
-- +----------------------+
-- |                  463 |
-- +----------------------+


SELECT * FROM mta_new
	GROUP BY unit
	LIMIT 500;

cursor = db.cursor()

cursor.execute("SELECT * FROM french_men_2013")
for i in cursor.fetchall():
    print i

cursor.close()
db.close()



INSERT IGNORE 
    INTO all_hospitals
SELECT *
    FROM va_tidy;

-- Field Description

-- C/A,UNIT,SCP,
-- DATE1,TIME1,DESC1,ENTRIES1,EXITS1,
-- DATE2,TIME2,DESC2,ENTRIES2,EXITS2,
-- DATE3,TIME3,DESC3,ENTRIES3,EXITS3,
-- DATE4,TIME4,DESC4,ENTRIES4,EXITS4,
-- DATE5,TIME5,DESC5,ENTRIES5,EXITS5,
-- DATE6,TIME6,DESC6,ENTRIES6,EXITS6,
-- DATE7,TIME7,DESC7,ENTRIES7,EXITS7,
-- DATE8,TIME8,DESC8,ENTRIES8,EXITS8


-- C/A = Control Area (A002)
-- UNIT = Remote Unit for a station (R051)
-- SCP = Subunit Channel Position represents an specific address for a device (02-00-00)
-- DATEn = Represents the date (MM-DD-YY)
-- TIMEn = Represents the time (hh:mm:ss) for a scheduled audit event
-- DEScn = Represent the "REGULAR" scheduled audit event (occurs every 4 hours)
-- ENTRIESn = The comulative entry register value for a device
-- EXISTn = The cumulative exit register value for a device

CREATE TABLE mta_old(
	ca VARCHAR(255),
	unit VARCHAR(255),
	scp VARCHAR(255),
	audit_date1 VARCHAR(255),
	audit_time1 TIME,
	description1 VARCHAR(255),
	entries1 INT,
	exits1 INT,
	audit_date2 VARCHAR(255),
	audit_time2 TIME,
	description2 VARCHAR(255),
	entries2 INT,
	exits2 INT,
	audit_date3 VARCHAR(255),
	audit_time3 TIME,
	description3 VARCHAR(255),
	entries3 INT,
	exits3 INT,
	audit_date3 VARCHAR(255),
	audit_time3 TIME,
	description3 VARCHAR(255),
	entries3 INT,
	exits3 INT,
	audit_date4 VARCHAR(255),
	audit_time4 TIME,
	description4 VARCHAR(255),
	entries4 INT,
	exits4 INT,
	audit_date5 VARCHAR(255),
	audit_time5 TIME,
	description5 VARCHAR(255),
	entries5 INT,
	exits5 INT,
	audit_date6 VARCHAR(255),
	audit_time6 TIME,
	description6 VARCHAR(255),
	entries6 INT,
	exits6 INT,
	audit_date7 VARCHAR(255),
	audit_time7 TIME,
	description7 VARCHAR(255),
	entries7 INT,
	exits7 INT,
	audit_date8 VARCHAR(255),
	audit_time8 TIME,
	description8 VARCHAR(255),
	entries8 INT,
	exits8 INT,
	PRIMARY KEY (ca, unit, scp)
);



