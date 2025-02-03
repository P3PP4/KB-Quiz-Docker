USE userdb;

CREATE DATABASE IF NOT EXISTS userdb;



-- quizdb 생성 및 테이블 생성
CREATE DATABASE IF NOT EXISTS quizdb;

USE quizdb;
CREATE TABLE `Note` (
	`note_id`	int	auto_increment NOT NULL primary key,
	`user_id`	int	not NULL,
	`quiz_id`	int	not NULL,
	`count`		int	not NULL default 1
);

CREATE TABLE `Quiz` (
	`quiz_id`	int	auto_increment NOT NULL primary key,
	`content`	varchar(100)	not NULL,
	`ox`	boolean	not NULL,
	`commentary`	varchar(100)	not NULL
);

DROP TABLE IF EXISTS `user`;

CREATE TABLE `User` (
	`user_id`	int auto_increment NOT NULL primary key,
	`name`	varchar(20)	not NULL,
	`streak`	int	NULL,
	`latest`	date	NULL
);

DROP TABLE IF EXISTS `quiztoday`;

CREATE TABLE `QuizToday` (
	`today_id`	int	auto_increment NOT NULL primary key,
	`date`	date	not NULL,
	`quiz_id1`	int	not NULL,
	`quiz_id2`	int	not NULL,
	`quiz_id3`	int	not NULL,
	`participant`	int NULL default 0
);


-- Insert sample data
INSERT INTO `user` (`user_id`, `name`, `streak`, `latest`) VALUES 
(1, 'John Doe', 5, CURDATE()),
(2,'Emma Wilson', 3, CURDATE()),
(3, 'Michael Brown', 7, CURDATE()),
(4,'Sophia Davis', 2, CURDATE()),
(5,'William Taylor', 4, CURDATE());

INSERT INTO `quiz` (`quiz_id`,`content`, `ox`, `commentary`) VALUES 
(1,'Spring Boot is a Java-based framework for building microservices.', true, 'Spring Boot simplifies the development of microservices.'),
(2,'Docker containers share the same operating system kernel.', true, 'Docker containers are lightweight because they share the host OS kernel.'),
(3,'REST APIs require a database connection.', false, 'REST APIs can work without a database, they are independent of storage.'),
(4,'JPA is a programming language.', false, 'JPA is a specification for ORM in Java, not a programming language.'),
(5,'Kubernetes is used for container orchestration.', true, 'Kubernetes manages containerized applications at scale.');

INSERT INTO `quiztoday` (`date`, `quiz_id1`, `quiz_id2`, `quiz_id3`, `participant`) VALUES 
(CURDATE(), 1, 2, 3, 10);

INSERT INTO `note` (`user_id`, `quiz_id`, `count`) VALUES 
(1, 1, 2),
(1, 2, 1),
(2, 1, 3),
(3, 3, 1),
(4, 4, 2);