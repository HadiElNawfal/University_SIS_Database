-- =========================
-- Idempotent Db Script
-- =========================

-- =========================
-- 1. DROP SECTION
-- =========================

-- Drop Trigger Functions
DROP FUNCTION IF EXISTS trg_check_enrollment_limits() CASCADE;

-- Drop Triggers
DROP TRIGGER IF EXISTS trg_enrollment_limits ON Enrollment;

-- Drop Views
DROP VIEW IF EXISTS student_course_counts;
DROP VIEW IF EXISTS course_enrollment_stats;

-- Drop Stored Procedures
DROP PROCEDURE IF EXISTS sp_promote_professor;
DROP PROCEDURE IF EXISTS sp_award_scholarship;
DROP PROCEDURE IF EXISTS sp_bulk_enroll_students;

-- Drop Indexes
DROP INDEX IF EXISTS idx_student_transcript;
DROP INDEX IF EXISTS idx_student_mentor;
DROP INDEX IF EXISTS idx_professor_supervisor;
DROP INDEX IF EXISTS idx_building_campus;
DROP INDEX IF EXISTS idx_faculty_building;
DROP INDEX IF EXISTS idx_department_faculty;
DROP INDEX IF EXISTS idx_course_department;
DROP INDEX IF EXISTS idx_prerequisite_prereq;
DROP INDEX IF EXISTS idx_prerequisite_course;
DROP INDEX IF EXISTS idx_enrollment_student;
DROP INDEX IF EXISTS idx_enrollment_course;
DROP INDEX IF EXISTS idx_teaches_professor;
DROP INDEX IF EXISTS idx_teaches_course;
DROP INDEX IF EXISTS idx_studentclub_student;
DROP INDEX IF EXISTS idx_studentclub_club;
DROP INDEX IF EXISTS idx_studentschol_student;
DROP INDEX IF EXISTS idx_studentschol_sch;
DROP INDEX IF EXISTS idx_studentinfo_student;
DROP INDEX IF EXISTS idx_personphone_person;
DROP INDEX IF EXISTS idx_professorphone_prof;
DROP INDEX IF EXISTS idx_departmentphone_dept;
DROP INDEX IF EXISTS idx_room_building;
DROP INDEX IF EXISTS idx_exam_course;
DROP INDEX IF EXISTS idx_person_last_name;
DROP INDEX IF EXISTS idx_student_major;
DROP INDEX IF EXISTS idx_enrollment_semester;
DROP INDEX IF EXISTS idx_course_name;
DROP INDEX IF EXISTS idx_scholarship_min_gpa;

-- Drop Tables (reverse dependency order)
DROP TABLE IF EXISTS StudentScholarship CASCADE;
DROP TABLE IF EXISTS Scholarship CASCADE;
DROP TABLE IF EXISTS StudentClub CASCADE;
DROP TABLE IF EXISTS Club CASCADE;
DROP TABLE IF EXISTS Teaches CASCADE;
DROP TABLE IF EXISTS Enrollment CASCADE;
DROP TABLE IF EXISTS Prerequisite CASCADE;
DROP TABLE IF EXISTS Exam CASCADE;
DROP TABLE IF EXISTS Course CASCADE;
DROP TABLE IF EXISTS DepartmentPhone CASCADE;
DROP TABLE IF EXISTS Department CASCADE;
DROP TABLE IF EXISTS Faculty CASCADE;
DROP TABLE IF EXISTS Room CASCADE;
DROP TABLE IF EXISTS Building CASCADE;
DROP TABLE IF EXISTS Campus CASCADE;
DROP TABLE IF EXISTS ProfessorPhone CASCADE;
DROP TABLE IF EXISTS Professor CASCADE;
DROP TABLE IF EXISTS StudentInfo CASCADE;
DROP TABLE IF EXISTS Student CASCADE;
DROP TABLE IF EXISTS Transcript CASCADE;
DROP TABLE IF EXISTS PersonPhone CASCADE;
DROP TABLE IF EXISTS Person CASCADE;

-- =========================
-- 2. RECREATION SECTION
-- =========================

-- 2a) CREATE TABLES

-- 1. PERSON
CREATE TABLE Person (
  person_id      SERIAL           NOT NULL,
  person_ssn     VARCHAR(11)      NOT NULL DEFAULT 'XXX-XX-XXXX',
  first_name     VARCHAR(50)      NOT NULL,
  middle_name    VARCHAR(50),
  last_name      VARCHAR(50)      NOT NULL,
  date_of_birth  DATE             NOT NULL,
  CONSTRAINT PK_Person PRIMARY KEY (person_id),
  CONSTRAINT UQ_Person_SSN UNIQUE (person_ssn),
  CONSTRAINT CHK_Person_dob_past CHECK (date_of_birth <= CURRENT_DATE)
);

-- 2. PERSONPHONE
CREATE TABLE PersonPhone (
  person_id  INT   NOT NULL,
  phone_num  VARCHAR(24) NOT NULL DEFAULT '000-000-000',
  CONSTRAINT PK_PersonPhone PRIMARY KEY (person_id, phone_num),
  CONSTRAINT FK_PersonPhone_Person FOREIGN KEY (person_id) REFERENCES Person(person_id) ON DELETE CASCADE
);

-- 3. TRANSCRIPT
CREATE TABLE Transcript (
  transcript_id   SERIAL  NOT NULL,
  creation_date   DATE    NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT PK_Transcript PRIMARY KEY (transcript_id)
);

-- 4. STUDENT
CREATE TABLE Student (
  student_id     INT      NOT NULL,
  transcript_id  INT      NOT NULL,
  major          VARCHAR(50) NOT NULL DEFAULT 'Undeclared',
  mentor_id      INT,
  CONSTRAINT PK_Student PRIMARY KEY (student_id),
  CONSTRAINT FK_Student_Person FOREIGN KEY (student_id) REFERENCES Person(person_id) ON DELETE CASCADE,
  CONSTRAINT FK_Student_Transcript FOREIGN KEY (transcript_id) REFERENCES Transcript(transcript_id) ON DELETE CASCADE,
  CONSTRAINT FK_Student_Mentor FOREIGN KEY (mentor_id) REFERENCES Student(student_id) ON DELETE SET NULL
);

-- 5. STUDENTINFO
CREATE TABLE StudentInfo (
  student_id    INT      NOT NULL,
  student_info  VARCHAR(100) NOT NULL DEFAULT 'No Information',
  CONSTRAINT PK_StudentInfo PRIMARY KEY (student_id, student_info),
  CONSTRAINT FK_StudentInfo_Student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE
);

-- 6. PROFESSOR
CREATE TABLE Professor (
  professor_id   INT      NOT NULL,
  professor_rank VARCHAR(50) NOT NULL DEFAULT 'Undeclared',
  hire_date      DATE     NOT NULL DEFAULT CURRENT_DATE,
  supervisor_id  INT,
  CONSTRAINT PK_Professor PRIMARY KEY (professor_id),
  CONSTRAINT FK_Professor_Person FOREIGN KEY (professor_id) REFERENCES Person(person_id) ON DELETE CASCADE,
  CONSTRAINT FK_Professor_Supervisor FOREIGN KEY (supervisor_id) REFERENCES Professor(professor_id) ON DELETE SET NULL,
  CONSTRAINT CHK_Professor_hire_date_past CHECK (hire_date <= CURRENT_DATE)
);

-- 7. PROFESSORPHONE
CREATE TABLE ProfessorPhone (
  professor_id INT    NOT NULL,
  phone_num    VARCHAR(24) NOT NULL DEFAULT '000-000-000',
  CONSTRAINT PK_ProfessorPhone PRIMARY KEY (professor_id, phone_num),
  CONSTRAINT FK_ProfessorPhone_Professor FOREIGN KEY (professor_id) REFERENCES Professor(professor_id) ON DELETE CASCADE
);

-- 8. CAMPUS
CREATE TABLE Campus (
  campus_id       SERIAL     NOT NULL,
  campus_name     VARCHAR(100) NOT NULL,
  campus_location VARCHAR(100) NOT NULL,
  CONSTRAINT PK_Campus PRIMARY KEY (campus_id)
);

-- 9. BUILDING
CREATE TABLE Building (
  building_id       SERIAL     NOT NULL,
  building_name     VARCHAR(100) NOT NULL,
  building_location VARCHAR(100),
  campus_id         INT         NOT NULL,
  CONSTRAINT PK_Building PRIMARY KEY (building_id),
  CONSTRAINT FK_Building_Campus FOREIGN KEY (campus_id) REFERENCES Campus(campus_id) ON DELETE CASCADE
);

-- 10. ROOM
CREATE TABLE Room (
  building_id INT     NOT NULL,
  room_number VARCHAR(10) NOT NULL,
  nb_seats    INT     NOT NULL DEFAULT 30,
  CONSTRAINT PK_Room PRIMARY KEY (building_id, room_number),
  CONSTRAINT FK_Room_Building FOREIGN KEY (building_id) REFERENCES Building(building_id) ON DELETE CASCADE,
  CONSTRAINT CHK_Room_seats_positive CHECK (nb_seats > 0)
);

-- 11. FACULTY
CREATE TABLE Faculty (
  faculty_id   SERIAL      NOT NULL,
  faculty_name VARCHAR(100) NOT NULL,
  building_id  INT          NOT NULL,
  CONSTRAINT PK_Faculty PRIMARY KEY (faculty_id),
  CONSTRAINT FK_Faculty_Building FOREIGN KEY (building_id) REFERENCES Building(building_id) ON DELETE CASCADE
);

-- 12. DEPARTMENT
CREATE TABLE Department (
  dept_id    SERIAL      NOT NULL,
  dept_name  VARCHAR(100) NOT NULL,
  faculty_id INT          NOT NULL,
  CONSTRAINT PK_Department PRIMARY KEY (dept_id),
  CONSTRAINT FK_Department_Faculty FOREIGN KEY (faculty_id) REFERENCES Faculty(faculty_id) ON DELETE CASCADE
);

-- 13. DEPARTMENTPHONE
CREATE TABLE DepartmentPhone (
  dept_id   INT    NOT NULL,
  phone_num VARCHAR(24) NOT NULL DEFAULT '000-000-000',
  CONSTRAINT PK_DepartmentPhone PRIMARY KEY (dept_id, phone_num),
  CONSTRAINT FK_DepartmentPhone_Department FOREIGN KEY (dept_id) REFERENCES Department(dept_id) ON DELETE CASCADE
);

-- 14. COURSE
CREATE TABLE Course (
  course_id    SERIAL      NOT NULL,
  course_name  VARCHAR(100) NOT NULL,
  credit_hours INT          NOT NULL,
  dept_id      INT          NOT NULL,
  CONSTRAINT PK_Course PRIMARY KEY (course_id),
  CONSTRAINT FK_Course_Department FOREIGN KEY (dept_id) REFERENCES Department(dept_id) ON DELETE CASCADE,
  CONSTRAINT CHK_Course_credit_positive CHECK (credit_hours > 0)
);

-- 15. EXAM
CREATE TABLE Exam (
  course_id    INT           NOT NULL,
  exam_number  VARCHAR(10)   NOT NULL,
  exam_date    DATE          NOT NULL,
  exam_location VARCHAR(50),
  exam_weight  DECIMAL(5,2)  NOT NULL,
  CONSTRAINT PK_Exam PRIMARY KEY (course_id, exam_number),
  CONSTRAINT FK_Exam_Course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE,
  CONSTRAINT CHK_Exam_weight_range CHECK (exam_weight >= 0 AND exam_weight <= 100)
);

-- 16. PREREQUISITE
CREATE TABLE Prerequisite (
  course_id      INT NOT NULL,
  prereq_course  INT NOT NULL,
  CONSTRAINT PK_Prerequisite PRIMARY KEY (course_id, prereq_course),
  CONSTRAINT FK_Prerequisite_Course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE,
  CONSTRAINT FK_Prerequisite_Prereq FOREIGN KEY (prereq_course) REFERENCES Course(course_id) ON DELETE CASCADE
);

-- 17. ENROLLMENT
CREATE TABLE Enrollment (
  student_id      INT     NOT NULL,
  course_id       INT     NOT NULL,
  semester        VARCHAR(10) NOT NULL,
  enrollment_date DATE    NOT NULL DEFAULT CURRENT_DATE,
  final_grade     DECIMAL(4,2),
  CONSTRAINT PK_Enrollment PRIMARY KEY (student_id, course_id),
  CONSTRAINT FK_Enrollment_Student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE,
  CONSTRAINT FK_Enrollment_Course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE,
  CONSTRAINT CHK_Enrollment_date_past CHECK (enrollment_date <= CURRENT_DATE),
  CONSTRAINT CHK_Enrollment_grade_range CHECK (final_grade IS NULL OR (final_grade >= 0 AND final_grade <= 4))
);

-- 18. TEACHES
CREATE TABLE Teaches (
  professor_id   INT     NOT NULL,
  course_id      INT     NOT NULL,
  course_timing  VARCHAR(50)  NOT NULL,
  course_location VARCHAR(100) NOT NULL,
  CONSTRAINT PK_Teaches PRIMARY KEY (professor_id, course_id),
  CONSTRAINT FK_Teaches_Professor FOREIGN KEY (professor_id) REFERENCES Professor(professor_id) ON DELETE CASCADE,
  CONSTRAINT FK_Teaches_Course FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE
);

-- 19. CLUB
CREATE TABLE Club (
  club_id   SERIAL      NOT NULL,
  club_name VARCHAR(100) NOT NULL,
  CONSTRAINT PK_Club PRIMARY KEY (club_id)
);

-- 20. STUDENTCLUB
CREATE TABLE StudentClub (
  student_id  INT          NOT NULL,
  club_id     INT          NOT NULL,
  position    VARCHAR(50),
  date_joined DATE DEFAULT CURRENT_DATE,
  CONSTRAINT PK_StudentClub PRIMARY KEY (student_id, club_id),
  CONSTRAINT FK_StudentClub_Student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE,
  CONSTRAINT FK_StudentClub_Club FOREIGN KEY (club_id) REFERENCES Club(club_id) ON DELETE CASCADE
);

-- 21. SCHOLARSHIP
CREATE TABLE Scholarship (
  scholarship_id   SERIAL       NOT NULL,
  scholarship_name VARCHAR(100) NOT NULL,
  min_gpa          DECIMAL(3,2) DEFAULT 0.00,
  CONSTRAINT PK_Scholarship PRIMARY KEY (scholarship_id),
  CONSTRAINT CHK_Scholarship_min_gpa_range CHECK (min_gpa >= 0 AND min_gpa <= 4)
);

-- 22. STUDENTSCHOLARSHIP
CREATE TABLE StudentScholarship (
  student_id     INT           NOT NULL,
  scholarship_id INT           NOT NULL,
  amount_received_percentage DECIMAL(5,2),
  date_received  DATE          NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT PK_StudentScholarship PRIMARY KEY (student_id, scholarship_id),
  CONSTRAINT FK_StudentScholarship_Student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE,
  CONSTRAINT FK_StudentScholarship_Scholarship FOREIGN KEY (scholarship_id) REFERENCES Scholarship(scholarship_id) ON DELETE CASCADE,
  CONSTRAINT CHK_StudSchol_amount_pct CHECK (amount_received_percentage >= 0 AND amount_received_percentage <= 100)
);

-- 1) Persons (serial person_id: 1–25)
INSERT INTO Person (person_ssn, first_name, middle_name, last_name, date_of_birth) VALUES
  ('111-11-1111','Alice', NULL,     'Smith',     '1990-04-15'),
  ('222-22-2222','Bob',   'J.',     'Brown',     '1988-07-23'),
  ('333-33-3333','Carol', NULL,     'Davis',     '1992-12-02'),
  ('444-44-4444','David', NULL,     'Evans',     '1991-03-10'),
  ('555-55-5555','Eva',   NULL,     'Frank',     '1993-09-30'),
  ('666-66-6666','Frank', NULL,     'Green',     '1987-05-25'),
  ('777-77-7777','Grace', NULL,     'Hall',      '1994-11-12'),
  ('888-88-8888','Henry', NULL,     'Irwin',     '1989-02-20'),
  ('999-99-9999','Irene', NULL,     'Johnson',   '1995-06-18'),
  ('101-01-0101','Jack',  NULL,     'King',      '1990-12-01'),
  ('121-21-2121','Karen', NULL,     'Lee',       '1992-01-09'),
  ('131-31-3131','Leo',   NULL,     'Martinez',  '1991-08-23'),
  ('141-41-4141','Maya',  NULL,     'Nelson',    '1993-04-04'),
  ('151-51-5151','Nathan',NULL,     'OBrien',    '1988-10-14'),
  ('161-61-6161','Olivia',NULL,     'Perez',     '1994-07-07'),
  ('171-71-7171','Paul',  NULL,     'Quinn',     '1989-09-09'),
  ('181-81-8181','Quinn', NULL,     'Roberts',   '1990-02-02'),
  ('191-91-9191','Rachel',NULL,     'Scott',     '1992-05-05'),
  ('202-02-0202','Steve', NULL,     'Turner',    '1987-12-12'),
  ('212-12-1212','Tina',  NULL,     'Underwood', '1991-03-03'),
  ('313-13-1313','Uma',   NULL,     'Vargas',    '1975-05-20'),
  ('414-14-1414','Victor',NULL,     'White',     '1972-02-12'),
  ('515-15-1515','Wendy', NULL,     'Xu',        '1980-07-07'),
  ('616-16-1616','Xavier',NULL,     'Young',     '1978-11-11'),
  ('717-17-1717','Zoe',   NULL,     'Zhang',     '1982-03-03');

-- 2) PersonPhone
INSERT INTO PersonPhone (person_id, phone_num) VALUES
  (1,'555-0001'), (2,'555-0002'), (3,'555-0003');

-- 3) Transcripts (IDs 1–20)
INSERT INTO Transcript DEFAULT VALUES;  -- repeat 20 times
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;
INSERT INTO Transcript DEFAULT VALUES;

-- 4) Students (IDs 1–20 → person 1–20, transcripts 1–20)
INSERT INTO Student (student_id, transcript_id, major, mentor_id) VALUES
  (1,1,'Computer Science',   NULL),
  (2,2,'Mathematics',        1),
  (3,3,'Physics',            1),
  (4,4,'Engineering',        2),
  (5,5,'Biology',            3),
  (6,6,'Chemistry',          4),
  (7,7,'History',            5),
  (8,8,'Art',                6),
  (9,9,'Music',              7),
  (10,10,'Economics',        8),
  (11,11,'Philosophy',       9),
  (12,12,'Psychology',       10),
  (13,13,'Sociology',        11),
  (14,14,'Literature',       12),
  (15,15,'Geology',          13),
  (16,16,'Astronomy',        14),
  (17,17,'Comp Eng',         15),
  (18,18,'Elec Eng',         16),
  (19,19,'Mech Eng',         17),
  (20,20,'Civil Eng',        18);

-- 5) StudentInfo
INSERT INTO StudentInfo (student_id, student_info) VALUES
  (1,'GPA:3.50'), (2,'GPA:3.75'), (3,'GPA:3.20'), (4,'GPA:3.80'),
  (5,'GPA:3.10'), (6,'GPA:3.40'), (7,'GPA:3.60'), (8,'GPA:3.30'),
  (9,'GPA:3.90'), (10,'GPA:3.45'), (11,'GPA:3.55'), (12,'GPA:3.25'),
  (13,'GPA:3.15'), (14,'GPA:3.85'), (15,'GPA:3.95'), (16,'GPA:3.05'),
  (17,'GPA:3.65'), (18,'GPA:3.70'), (19,'GPA:3.35'), (20,'GPA:3.00');

-- 6) Professors (IDs 21–25 → persons 21–25)
INSERT INTO Professor (professor_id, professor_rank, hire_date, supervisor_id) VALUES
  (21,'Assistant', '2015-08-01', NULL),
  (22,'Associate', '2010-06-15', 21),
  (23,'Full',      '2005-09-01', 22),
  (24,'Assistant', '2018-01-20', 21),
  (25,'Associate', '2012-11-30', 23);

-- 7) ProfessorPhone
INSERT INTO ProfessorPhone (professor_id, phone_num) VALUES
  (21,'555-1001'), (22,'555-1002'), (23,'555-1003'),
  (24,'555-1004'), (25,'555-1005');

-- 8) Campuses
INSERT INTO Campus (campus_name, campus_location) VALUES
  ('Main Campus',     'City A'),
  ('Downtown Campus', 'City B'),
  ('West Campus',     'City C');

-- 9) Buildings
INSERT INTO Building (building_name, building_location, campus_id) VALUES
  ('Science Hall',     'North end',  1),
  ('Library',          'Center',     1),
  ('Engineering Bldg','East side',  2),
  ('Arts Building',    'West side',  2),
  ('Business Center',  'Downtown',   3);

-- 10) Rooms
INSERT INTO Room (building_id, room_number, nb_seats) VALUES
  (1,'101',30),(1,'102',25),
  (2,'201',40),(2,'202',35),
  (3,'301',50),(3,'302',45),
  (4,'401',20),(4,'402',15),
  (5,'501',60),(5,'502',55);

-- 11) Faculties
INSERT INTO Faculty (faculty_name, building_id) VALUES
  ('Science',     1),
  ('Engineering', 3),
  ('Arts',        4);

-- 12) Departments
INSERT INTO Department (dept_name, faculty_id) VALUES
  ('Computer Science',        2),
  ('Mechanical Engineering',  2),
  ('Biology',                 1),
  ('History',                 3),
  ('Business',                3);

-- 13) DepartmentPhone
INSERT INTO DepartmentPhone (dept_id, phone_num) VALUES
  (1,'555-2001'), (2,'555-2002'),
  (3,'555-2003'), (4,'555-2004'),
  (5,'555-2005');

-- 14) Courses
INSERT INTO Course (course_name, credit_hours, dept_id) VALUES
  ('Data Structures',   3, 1),
  ('Algorithms',        3, 1),
  ('Thermodynamics',    4, 2),
  ('Fluid Mechanics',   3, 2),
  ('Genetics',          3, 3),
  ('Microbiology',      3, 3),
  ('World History',     3, 4),
  ('European History',  3, 4),
  ('Marketing 101',     3, 5),
  ('Finance',           3, 5);

-- 15) Exams (2 each for courses 1–3)
INSERT INTO Exam (course_id, exam_number, exam_date, exam_location, exam_weight) VALUES
  (1,'Exam1','2024-05-01','Room 101',50),
  (1,'Exam2','2024-06-01','Room 102',50),
  (2,'Exam1','2024-05-02','Room 103',60),
  (2,'Exam2','2024-06-02','Room 104',40),
  (3,'Exam1','2024-05-03','Room 105',55),
  (3,'Exam2','2024-06-03','Room 106',45);

-- 16) Prerequisites
INSERT INTO Prerequisite (course_id, prereq_course) VALUES
  (2,1),   -- Algorithms ← Data Structures
  (4,3);   -- Fluid Mechanics ← Thermodynamics

-- 17) Enrollments (one per student 1–6; you can add more to reach 4–6 each)
INSERT INTO Enrollment (student_id, course_id, semester, enrollment_date, final_grade) VALUES
  (1,1,'Spring2024','2024-01-10',NULL),
  (2,2,'Spring2024','2024-01-11',NULL),
  (3,3,'Spring2024','2024-01-12',NULL),
  (4,4,'Spring2024','2024-01-13',NULL),
  (5,5,'Spring2024','2024-01-14',NULL),
  (6,6,'Spring2024','2024-01-15',NULL);

-- 18) Teaches
INSERT INTO Teaches (professor_id, course_id, course_timing, course_location) VALUES
  (21,1,'MWF 9–10','Room 101'),
  (22,2,'TTh 10–11','Room 102'),
  (23,3,'MWF 11–12','Room 103'),
  (24,4,'TTh 1–2','Room 104'),
  (25,5,'MWF 2–3','Room 105');

-- 19) Clubs
INSERT INTO Club (club_name) VALUES
  ('Robotics'),
  ('Debate'),
  ('Chess');

-- 20) StudentClub
INSERT INTO StudentClub (student_id, club_id, position, date_joined) VALUES
  (1,1,'President','2024-01-15'),
  (2,1,NULL,'2024-02-01'),
  (3,2,'Secretary','2024-02-10'),
  (4,2,NULL,'2024-03-05'),
  (5,3,'Member','2024-01-20'),
  (6,3,NULL,'2024-02-15');

-- 21) Scholarships
INSERT INTO Scholarship (scholarship_name, min_gpa) VALUES
  ('Academic Excellence',3.50),
  ('Athletic Merit',     2.50),
  ('Need-Based',         NULL);

-- 22) StudentScholarship
INSERT INTO StudentScholarship (student_id, scholarship_id, amount_received_percentage, date_received) VALUES
  (1,1,100,'2024-02-01'),
  (2,1, 50,'2024-03-01'),
  (3,2,100,'2024-02-15'),
  (4,3, 75,'2024-04-01');

-- 2b) FOREIGN KEY INDEXES
CREATE INDEX idx_student_transcript   ON Student(transcript_id);
CREATE INDEX idx_student_mentor       ON Student(mentor_id);
CREATE INDEX idx_professor_supervisor ON Professor(supervisor_id);
CREATE INDEX idx_building_campus      ON Building(campus_id);
CREATE INDEX idx_faculty_building     ON Faculty(building_id);
CREATE INDEX idx_department_faculty   ON Department(faculty_id);
CREATE INDEX idx_course_department    ON Course(dept_id);
CREATE INDEX idx_prerequisite_prereq  ON Prerequisite(prereq_course);
CREATE INDEX idx_prerequisite_course  ON Prerequisite(course_id);
CREATE INDEX idx_enrollment_student   ON Enrollment(student_id);
CREATE INDEX idx_enrollment_course    ON Enrollment(course_id);
CREATE INDEX idx_teaches_professor    ON Teaches(professor_id);
CREATE INDEX idx_teaches_course       ON Teaches(course_id);
CREATE INDEX idx_studentclub_student  ON StudentClub(student_id);
CREATE INDEX idx_studentclub_club     ON StudentClub(club_id);
CREATE INDEX idx_studentschol_student ON StudentScholarship(student_id);
CREATE INDEX idx_studentschol_sch     ON StudentScholarship(scholarship_id);
CREATE INDEX idx_studentinfo_student  ON StudentInfo(student_id);
CREATE INDEX idx_personphone_person   ON PersonPhone(person_id);
CREATE INDEX idx_professorphone_prof  ON ProfessorPhone(professor_id);
CREATE INDEX idx_departmentphone_dept  ON DepartmentPhone(dept_id);
CREATE INDEX idx_room_building         ON Room(building_id);
CREATE INDEX idx_exam_course           ON Exam(course_id);

-- 2c) PERFORMANCE INDEXES
CREATE INDEX idx_person_last_name      ON Person(last_name);
CREATE INDEX idx_student_major         ON Student(major);
CREATE INDEX idx_enrollment_semester   ON Enrollment(semester);
CREATE INDEX idx_course_name           ON Course(course_name);
CREATE INDEX idx_scholarship_min_gpa    ON Scholarship(min_gpa);

-- 2d) VIEWS
CREATE OR REPLACE VIEW student_course_counts AS
SELECT s.student_id, p.first_name || ' ' || p.last_name AS student_name, COUNT(e.course_id) AS course_count
FROM Student s
JOIN Person p ON s.student_id = p.person_id
LEFT JOIN Enrollment e ON e.student_id = s.student_id
GROUP BY s.student_id, p.first_name, p.last_name;

CREATE OR REPLACE VIEW course_enrollment_stats AS
SELECT c.course_id, c.course_name, COUNT(e.student_id) AS enrolled_students
FROM Course c
LEFT JOIN Enrollment e ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_name;

-- 2e) STORED PROCEDURES
CREATE OR REPLACE PROCEDURE sp_promote_professor(IN p_professor_id INT, IN p_new_rank VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE Professor SET professor_rank = p_new_rank WHERE professor_id = p_professor_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Professor % not found', p_professor_id; END IF;
END;$$;

CREATE OR REPLACE PROCEDURE sp_award_scholarship(IN p_student_id INT, IN p_scholarship_id INT, IN p_amount_pct NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
  LOOP
    UPDATE StudentScholarship SET amount_received_percentage = LEAST(100,p_amount_pct), date_received = CURRENT_DATE
      WHERE student_id=p_student_id AND scholarship_id=p_scholarship_id;
    IF FOUND THEN RETURN; END IF;
    BEGIN
      INSERT INTO StudentScholarship(student_id,scholarship_id,amount_received_percentage,date_received)
      VALUES(p_student_id,p_scholarship_id,LEAST(100,p_amount_pct),CURRENT_DATE);
      RETURN;
    EXCEPTION WHEN unique_violation THEN CONTINUE;
    END;
  END LOOP;
END;$$;

CREATE OR REPLACE PROCEDURE sp_bulk_enroll_students(IN p_course_id INT, IN p_student_ids INT[])
LANGUAGE plpgsql AS $$
DECLARE sid INT;
BEGIN
  FOREACH sid IN ARRAY p_student_ids LOOP
    PERFORM 1 FROM Enrollment WHERE course_id=p_course_id AND student_id=sid;
    IF NOT FOUND THEN
      INSERT INTO Enrollment(student_id,course_id,semester,enrollment_date)
      VALUES(sid,p_course_id,'Fall2025',CURRENT_DATE);
    END IF;
  END LOOP;
END;$$;

-- 2f) TRIGGER FUNCTION & TRIGGER
CREATE OR REPLACE FUNCTION trg_check_enrollment_limits() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE stu_count INT; crs_count INT;
BEGIN
  SELECT COUNT(*) INTO stu_count FROM Enrollment WHERE student_id = NEW.student_id;
  IF stu_count >= 6 THEN RAISE EXCEPTION 'Student % already has % enrollments',NEW.student_id,stu_count; END IF;
  SELECT COUNT(*) INTO crs_count FROM Enrollment WHERE course_id = NEW.course_id;
  IF crs_count >= 40 THEN RAISE EXCEPTION 'Course % full (% students)',NEW.course_id,crs_count; END IF;
  RETURN NEW;
END;$$;

CREATE TRIGGER trg_enrollment_limits
  BEFORE INSERT ON Enrollment
  FOR EACH ROW
  EXECUTE FUNCTION trg_check_enrollment_limits();
