--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)

-- Started on 2024-11-26 18:37:55 IST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16478)
-- Name: course; Type: TABLE; Schema: public; Owner: soumik
--

CREATE TABLE public.course (
    course_id character varying(8) NOT NULL,
    title character varying(50),
    dept_name character varying(20),
    credits numeric(2,0),
    year numeric(4,0),
    CONSTRAINT course_credits_check CHECK ((credits > (0)::numeric))
);


ALTER TABLE public.course OWNER TO soumik;

--
-- TOC entry 3447 (class 0 OID 16478)
-- Dependencies: 219
-- Data for Name: course; Type: TABLE DATA; Schema: public; Owner: soumik
--

INSERT INTO public.course VALUES ('787', 'C  Programming', 'Mech. Eng.', 4, 2052);
INSERT INTO public.course VALUES ('238', 'The Music of Donovan', 'Mech. Eng.', 3, 2003);
INSERT INTO public.course VALUES ('608', 'Electron Microscopy', 'Mech. Eng.', 3, 2002);
INSERT INTO public.course VALUES ('539', 'International Finance', 'Comp. Sci.', 3, 2001);
INSERT INTO public.course VALUES ('278', 'Greek Tragedy', 'Statistics', 4, 2053);
INSERT INTO public.course VALUES ('972', 'Greek Tragedy', 'Psychology', 4, 2001);
INSERT INTO public.course VALUES ('391', 'Virology', 'Biology', 3, 2055);
INSERT INTO public.course VALUES ('814', 'Compiler Design', 'Elec. Eng.', 3, 2002);
INSERT INTO public.course VALUES ('272', 'Geology', 'Mech. Eng.', 3, 2051);
INSERT INTO public.course VALUES ('612', 'Mobile Computing', 'Physics', 3, 2050);
INSERT INTO public.course VALUES ('237', 'Surfing', 'Cybernetics', 3, 2054);
INSERT INTO public.course VALUES ('313', 'International Trade', 'Marketing', 3, 2053);
INSERT INTO public.course VALUES ('887', 'Latin', 'Mech. Eng.', 3, 2051);
INSERT INTO public.course VALUES ('328', 'Composition and Literature', 'Cybernetics', 3, 2053);
INSERT INTO public.course VALUES ('984', 'Music of the 50s', 'History', 3, 2003);
INSERT INTO public.course VALUES ('241', 'Biostatistics', 'Geology', 3, 2051);
INSERT INTO public.course VALUES ('338', 'Graph Theory', 'Psychology', 3, 2003);
INSERT INTO public.course VALUES ('400', 'Visual BASIC', 'Psychology', 4, 2052);
INSERT INTO public.course VALUES ('760', 'How to Groom your Cat', 'Accounting', 3, 2050);
INSERT INTO public.course VALUES ('629', 'Finite Element Analysis', 'Cybernetics', 3, 2050);
INSERT INTO public.course VALUES ('762', 'The Monkeys', 'History', 4, 2001);
INSERT INTO public.course VALUES ('242', 'Rock and Roll', 'Marketing', 3, 2054);
INSERT INTO public.course VALUES ('482', 'FOCAL Programming', 'Psychology', 4, 2055);
INSERT INTO public.course VALUES ('581', 'Calculus', 'Pol. Sci.', 4, 2003);
INSERT INTO public.course VALUES ('843', 'Environmental Law', 'Math', 4, 2003);
INSERT INTO public.course VALUES ('679', 'The Beatles', 'Math', 3, 2051);
INSERT INTO public.course VALUES ('704', 'Marine Mammals', 'Geology', 4, 2055);
INSERT INTO public.course VALUES ('774', 'Game Programming', 'Cybernetics', 4, 2050);
INSERT INTO public.course VALUES ('591', 'Shakespeare', 'Pol. Sci.', 4, 2050);
INSERT INTO public.course VALUES ('319', 'World History', 'Finance', 4, 2003);
INSERT INTO public.course VALUES ('960', 'Tort Law', 'Civil Eng.', 3, 2054);
INSERT INTO public.course VALUES ('274', 'Corporate Law', 'Comp. Sci.', 4, 2054);
INSERT INTO public.course VALUES ('426', 'Video Gaming', 'Finance', 3, 2050);
INSERT INTO public.course VALUES ('852', 'World History', 'Athletics', 4, 2051);
INSERT INTO public.course VALUES ('408', 'Bankruptcy', 'Accounting', 3, 2003);
INSERT INTO public.course VALUES ('808', 'Organic Chemistry', 'English', 4, 2053);
INSERT INTO public.course VALUES ('902', 'Existentialism', 'Finance', 3, 2052);
INSERT INTO public.course VALUES ('730', 'Quantum Mechanics', 'Elec. Eng.', 4, 2001);
INSERT INTO public.course VALUES ('362', 'Embedded Systems', 'Finance', 4, 2050);
INSERT INTO public.course VALUES ('341', 'Quantum Mechanics', 'Cybernetics', 3, 2053);
INSERT INTO public.course VALUES ('582', 'Marine Mammals', 'Cybernetics', 3, 2001);
INSERT INTO public.course VALUES ('867', 'The IBM 360 Architecture', 'History', 3, 2054);
INSERT INTO public.course VALUES ('169', 'Marine Mammals', 'Elec. Eng.', 3, 2053);
INSERT INTO public.course VALUES ('680', 'Electricity and Magnetism', 'Civil Eng.', 3, 2052);
INSERT INTO public.course VALUES ('227', 'Elastic Structures', 'Languages', 4, 2051);
INSERT INTO public.course VALUES ('991', 'Transaction Processing', 'Psychology', 3, 2051);
INSERT INTO public.course VALUES ('366', 'Computational Biology', 'English', 3, 2053);
INSERT INTO public.course VALUES ('376', 'Cost Accounting', 'Physics', 4, 2053);
INSERT INTO public.course VALUES ('489', 'Journalism', 'Astronomy', 4, 2053);
INSERT INTO public.course VALUES ('663', 'Geology', 'Psychology', 3, 2051);
INSERT INTO public.course VALUES ('461', 'Physical Chemistry', 'Math', 3, 2053);
INSERT INTO public.course VALUES ('105', 'Image Processing', 'Astronomy', 3, 2050);
INSERT INTO public.course VALUES ('407', 'Industrial Organization', 'Languages', 4, 2053);
INSERT INTO public.course VALUES ('254', 'Security', 'Cybernetics', 3, 2050);
INSERT INTO public.course VALUES ('998', 'Immunology', 'Civil Eng.', 4, 2003);
INSERT INTO public.course VALUES ('457', 'Systems Software', 'History', 3, 2002);
INSERT INTO public.course VALUES ('401', 'Sanitary Engineering', 'Athletics', 4, 2052);
INSERT INTO public.course VALUES ('127', 'Thermodynamics', 'Geology', 3, 2053);
INSERT INTO public.course VALUES ('399', 'RPG Programming', 'Pol. Sci.', 4, 2002);
INSERT INTO public.course VALUES ('949', 'Japanese', 'Comp. Sci.', 3, 2053);
INSERT INTO public.course VALUES ('496', 'Aquatic Chemistry', 'Cybernetics', 3, 2053);
INSERT INTO public.course VALUES ('334', 'International Trade', 'Athletics', 3, 2050);
INSERT INTO public.course VALUES ('544', 'Differential Geometry', 'Statistics', 3, 2051);
INSERT INTO public.course VALUES ('451', 'Database System Concepts', 'Pol. Sci.', 4, 2050);
INSERT INTO public.course VALUES ('190', 'Romantic Literature', 'Civil Eng.', 3, 2052);
INSERT INTO public.course VALUES ('630', 'Religion', 'English', 3, 2001);
INSERT INTO public.course VALUES ('761', 'Existentialism', 'Athletics', 3, 2053);
INSERT INTO public.course VALUES ('804', 'Introduction to Burglary', 'Cybernetics', 4, 2055);
INSERT INTO public.course VALUES ('781', 'Compiler Design', 'Finance', 4, 2002);
INSERT INTO public.course VALUES ('805', 'Composition and Literature', 'Statistics', 4, 2002);
INSERT INTO public.course VALUES ('318', 'Geology', 'Cybernetics', 3, 2052);
INSERT INTO public.course VALUES ('353', 'Operating Systems', 'Psychology', 3, 2050);
INSERT INTO public.course VALUES ('394', 'C  Programming', 'Athletics', 3, 2001);
INSERT INTO public.course VALUES ('137', 'Manufacturing', 'Finance', 3, 2050);
INSERT INTO public.course VALUES ('192', 'Drama', 'Languages', 4, 2001);
INSERT INTO public.course VALUES ('681', 'Medieval Civilization or Lack Thereof', 'English', 3, 2051);
INSERT INTO public.course VALUES ('377', 'Differential Geometry', 'Astronomy', 4, 2054);
INSERT INTO public.course VALUES ('959', 'Bacteriology', 'Physics', 4, 2053);
INSERT INTO public.course VALUES ('235', 'International Trade', 'Math', 3, 2052);
INSERT INTO public.course VALUES ('421', 'Aquatic Chemistry', 'Athletics', 4, 2054);
INSERT INTO public.course VALUES ('647', 'Service-Oriented Architectures', 'Comp. Sci.', 4, 2051);
INSERT INTO public.course VALUES ('598', 'Number Theory', 'Accounting', 4, 2001);
INSERT INTO public.course VALUES ('858', 'Sailing', 'Math', 4, 2002);
INSERT INTO public.course VALUES ('487', 'Physical Chemistry', 'History', 3, 2002);
INSERT INTO public.course VALUES ('133', 'Antidisestablishmentarianism in Modern America', 'Biology', 4, 2055);
INSERT INTO public.course VALUES ('267', 'Hydraulics', 'Physics', 4, 2052);
INSERT INTO public.course VALUES ('200', 'The Music of the Ramones', 'Accounting', 4, 2053);
INSERT INTO public.course VALUES ('664', 'Elastic Structures', 'English', 3, 2055);
INSERT INTO public.course VALUES ('599', 'Mechanics', 'Finance', 4, 2002);
INSERT INTO public.course VALUES ('900', 'Water Pollution', 'Psychology', 3, 2050);
INSERT INTO public.course VALUES ('431', 'Security', 'Cybernetics', 3, 2052);
INSERT INTO public.course VALUES ('580', 'Financial Accounting', 'Cybernetics', 4, 2053);
INSERT INTO public.course VALUES ('658', 'Astronomy', 'Biology', 4, 2003);
INSERT INTO public.course VALUES ('628', 'The Beatles', 'Pol. Sci.', 3, 2001);
INSERT INTO public.course VALUES ('418', 'Systems Programming', 'Cybernetics', 4, 2054);
INSERT INTO public.course VALUES ('100', 'Game Programming', 'Biology', 4, 2053);
INSERT INTO public.course VALUES ('156', 'Logic', 'Accounting', 4, 2055);
INSERT INTO public.course VALUES ('634', 'The Music of Wagner', 'Math', 4, 2054);
INSERT INTO public.course VALUES ('561', 'Animal Behavior', 'History', 4, 2053);
INSERT INTO public.course VALUES ('249', 'Statistics', 'Civil Eng.', 3, 2055);
INSERT INTO public.course VALUES ('860', 'Wavelets', 'Statistics', 3, 2001);
INSERT INTO public.course VALUES ('505', 'Database Management', 'Civil Eng.', 4, 2054);
INSERT INTO public.course VALUES ('460', 'Software Engineering', 'Pol. Sci.', 4, 2053);
INSERT INTO public.course VALUES ('938', 'Astrobiology', 'Biology', 4, 2002);
INSERT INTO public.course VALUES ('130', 'Statistics', 'Finance', 3, 2050);
INSERT INTO public.course VALUES ('458', 'Quantum Mechanics', 'Accounting', 3, 2054);
INSERT INTO public.course VALUES ('173', 'Thermodynamics', 'Finance', 4, 2050);
INSERT INTO public.course VALUES ('873', 'Water Pollution', 'English', 3, 2050);
INSERT INTO public.course VALUES ('225', 'Signal Processing', 'Psychology', 4, 2003);
INSERT INTO public.course VALUES ('606', 'Digital Signal Processing', 'Statistics', 4, 2003);
INSERT INTO public.course VALUES ('911', 'Digital Signal Processing', 'Physics', 4, 2002);
INSERT INTO public.course VALUES ('375', 'Geology', 'Civil Eng.', 3, 2052);
INSERT INTO public.course VALUES ('276', 'Programming Languages', 'Finance', 4, 2052);
INSERT INTO public.course VALUES ('218', 'International Trade', 'Statistics', 3, 2053);
INSERT INTO public.course VALUES ('427', 'Biochemistry', 'Cybernetics', 3, 2052);
INSERT INTO public.course VALUES ('384', 'Sociology', 'Pol. Sci.', 3, 2055);
INSERT INTO public.course VALUES ('632', 'English Composition', 'Cybernetics', 4, 2053);
INSERT INTO public.course VALUES ('822', 'Game Theory', 'Pol. Sci.', 3, 2055);
INSERT INTO public.course VALUES ('766', 'Biochemistry', 'History', 4, 2050);
INSERT INTO public.course VALUES ('999', 'Advanced Calculus', 'Math', 4, 2055);
INSERT INTO public.course VALUES ('882', 'Cosmology', 'Biology', 3, 2052);
INSERT INTO public.course VALUES ('631', 'Theoretical Mathematics', 'Statistics', 4, 2052);
INSERT INTO public.course VALUES ('124', 'Game Programming', 'Finance', 4, 2050);
INSERT INTO public.course VALUES ('649', 'Artificial Intelligence', 'Cybernetics', 3, 2002);
INSERT INTO public.course VALUES ('187', 'Intellectual Property', 'Accounting', 3, 2052);
INSERT INTO public.course VALUES ('546', 'Psychology', 'Biology', 4, 2001);
INSERT INTO public.course VALUES ('832', 'Communications', 'Finance', 3, 2055);
INSERT INTO public.course VALUES ('896', 'Operating Systems', 'Finance', 4, 2002);
INSERT INTO public.course VALUES ('689', 'Systems Programming', 'Cybernetics', 3, 2050);
INSERT INTO public.course VALUES ('983', 'Terrorism', 'Pol. Sci.', 4, 2003);
INSERT INTO public.course VALUES ('589', 'Systems Software', 'Cybernetics', 4, 2052);
INSERT INTO public.course VALUES ('610', 'Modern Literature', 'Statistics', 3, 2055);
INSERT INTO public.course VALUES ('509', 'Music of the 50s', 'Cybernetics', 4, 2051);
INSERT INTO public.course VALUES ('423', 'Cybernetics', 'Cybernetics', 4, 2002);
INSERT INTO public.course VALUES ('924', 'Accounting', 'Math', 3, 2002);
INSERT INTO public.course VALUES ('725', 'World Literature', 'History', 3, 2051);
INSERT INTO public.course VALUES ('691', 'The Music of the Beatles', 'Accounting', 4, 2003);
INSERT INTO public.course VALUES ('462', 'Sociology', 'English', 3, 2055);
INSERT INTO public.course VALUES ('479', 'Game Theory', 'History', 3, 2052);
INSERT INTO public.course VALUES ('944', 'Quantum Mechanics', 'Physics', 4, 2052);
INSERT INTO public.course VALUES ('372', 'Political Science', 'Statistics', 4, 2054);
INSERT INTO public.course VALUES ('876', 'Physical Geography', 'Geology', 4, 2051);
INSERT INTO public.course VALUES ('517', 'Sociology', 'Statistics', 4, 2053);
INSERT INTO public.course VALUES ('180', 'Environmental Chemistry', 'Physics', 4, 2053);
INSERT INTO public.course VALUES ('827', 'Animal Physiology', 'Athletics', 4, 2050);
INSERT INTO public.course VALUES ('298', 'Game Programming', 'Cybernetics', 4, 2055);
INSERT INTO public.course VALUES ('564', 'Control Systems', 'Cybernetics', 4, 2055);
INSERT INTO public.course VALUES ('131', 'Algebra', 'Finance', 4, 2002);
INSERT INTO public.course VALUES ('894', 'Thermodynamics', 'Pol. Sci.', 3, 2053);
INSERT INTO public.course VALUES ('962', 'Communication', 'Athletics', 4, 2054);
INSERT INTO public.course VALUES ('611', 'Developmental Psychology', 'Biology', 3, 2050);
INSERT INTO public.course VALUES ('360', 'Artificial Intelligence', 'Cybernetics', 4, 2002);
INSERT INTO public.course VALUES ('792', 'Environmental Science', 'Finance', 4, 2052);
INSERT INTO public.course VALUES ('743', 'Calculus', 'Statistics', 3, 2052);
INSERT INTO public.course VALUES ('912', 'Psychology', 'Pol. Sci.', 4, 2051);
INSERT INTO public.course VALUES ('678', 'Environmental Studies', 'History', 4, 2054);
INSERT INTO public.course VALUES ('764', 'Hydrology', 'Statistics', 3, 2002);
INSERT INTO public.course VALUES ('321', 'Calculus', 'Cybernetics', 3, 2051);
INSERT INTO public.course VALUES ('206', 'Quantum Computing', 'Biology', 4, 2050);
INSERT INTO public.course VALUES ('639', 'Computer Science', 'Cybernetics', 3, 2055);
INSERT INTO public.course VALUES ('103', 'Quantum Mechanics', 'Finance', 4, 2054);
INSERT INTO public.course VALUES ('347', 'Digital Communications', 'Accounting', 3, 2003);
INSERT INTO public.course VALUES ('112', 'Financial Analysis', 'Finance', 3, 2052);
INSERT INTO public.course VALUES ('337', 'Calculus', 'Pol. Sci.', 3, 2051);
INSERT INTO public.course VALUES ('285', 'Game Programming', 'Psychology', 4, 2055);
INSERT INTO public.course VALUES ('436', 'Biochemistry', 'Athletics', 4, 2054);
INSERT INTO public.course VALUES ('826', 'Game Theory', 'Statistics', 4, 2051);
INSERT INTO public.course VALUES ('905', 'Environmental Engineering', 'Physics', 3, 2052);
INSERT INTO public.course VALUES ('842', 'Advanced Mathematics', 'Statistics', 3, 2050);
INSERT INTO public.course VALUES ('772', 'Artificial Intelligence', 'Cybernetics', 3, 2054);
INSERT INTO public.course VALUES ('654', 'Environmental Ethics', 'Philosophy', 4, 2001);
INSERT INTO public.course VALUES ('223', 'Digital Marketing', 'Business', 3, 2001);
INSERT INTO public.course VALUES ('716', 'Web Development', 'Computer Science', 4, 2055);
INSERT INTO public.course VALUES ('908', 'Microbiology', 'Biology', 3, 2051);
INSERT INTO public.course VALUES ('467', 'Political Theory', 'Political Science', 4, 2002);
INSERT INTO public.course VALUES ('315', 'Social Psychology', 'Psychology', 3, 2051);
INSERT INTO public.course VALUES ('213', 'Machine Learning', 'Computer Science', 4, 2003);
INSERT INTO public.course VALUES ('527', 'Robotics', 'Engineering', 4, 2002);
INSERT INTO public.course VALUES ('430', 'Neuroscience', 'Biology', 3, 2052);
INSERT INTO public.course VALUES ('790', 'Cognitive Science', 'Psychology', 4, 2001);


--
-- TOC entry 3303 (class 2606 OID 16483)
-- Name: course course_pkey; Type: CONSTRAINT; Schema: public; Owner: soumik
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_pkey PRIMARY KEY (course_id);


-- Completed on 2024-11-26 18:37:55 IST

--
-- PostgreSQL database dump complete
--

