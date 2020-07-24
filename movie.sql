-- phpMyAdmin SQL Dump
-- version 4.8.5
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jul 24, 2020 at 02:21 PM
-- Server version: 5.7.26
-- PHP Version: 7.2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `movie`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `deletennecessary`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deletennecessary` ()  NO SQL
DELETE FROM seatbooked WHERE buserId IS NULL$$

DROP PROCEDURE IF EXISTS `deleteSlot`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteSlot` ()  NO SQL
DELETE FROM forslot$$

DROP PROCEDURE IF EXISTS `moviecusor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `moviecusor` (OUT `name` VARCHAR(500))  NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE mname varchar(100) DEFAULT "";
    DECLARE tp varchar(500) DEFAULT "";

    DECLARE curmovie
        CURSOR FOR 
            SELECT movieName FROM movie;
 
    -- declare NOT FOUND handler
    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
    OPEN curmovie;
 
    getm: LOOP
        FETCH curmovie INTO mname;
        IF finished = 1 THEN 
            LEAVE getm;
        END IF;
        SET tp = CONCAT(mname,';',tp);
    END LOOP getm;
    SET name=tp;
    CLOSE curmovie;
 
END$$

DROP PROCEDURE IF EXISTS `movieid`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `movieid` (IN `mid` INT, OUT `n` VARCHAR(30))  NO SQL
SELECT movieName into n FROM movie where movieId=mid$$

DROP PROCEDURE IF EXISTS `moviepara`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `moviepara` (INOUT `name` VARCHAR(100))  NO SQL
BEGIN
    SELECT 
        title, 
        isbn, 
        CONCAT(first_name,' ',last_name) AS author
    FROM books
    INNER JOIN book_author 
        ON book_author.book_id =  books.id
    INNER JOIN authors
        ON book_author.author_id = authors.id
    ORDER BY title;
END$$

DROP PROCEDURE IF EXISTS `movieWeekly`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `movieWeekly` ()  NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE movieId INTEGER DEFAULT 0;
    DECLARE mid INTEGER DEFAULT 0;
    DECLARE number INTEGER DEFAULT 0;
    DECLARE moviename varchar(200) DEFAULT "";
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";
    DECLARE dat DATE ;
 declare cur1 cursor for  SELECT moviearchive.movieId,moviearchive.movieName FROM moviearchive where moviearchive.movieStatus='Released' ORDER BY moviearchive.movieName;
 
declare cur2 cursor for SELECT movieweekly.mwNoUser,movieweekly.date FROM movieweekly WHERE movieweekly.mwMovieId=mid;

    -- declare NOT FOUND handler   
    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
    OPEN cur1;
    getm: LOOP
        FETCH cur1 INTO movieId,movieName;
        IF finished = 1 THEN 
            LEAVE getm;
        END IF;  
        SET tp = CONCAT(tp,movieName,'=');
        SET mid=movieId;
        
        OPEN cur2;
        getn: LOOP      
        FETCH cur2 INTO number,dat;
        IF finished = 1 THEN 
            SET finished =0;
            LEAVE getn;
        END IF; 
         SET tp = CONCAT(tp,number,',',dat,';');
        END LOOP getn;
        CLOSE cur2;
        SET tp = CONCAT(tp,'+');
    END LOOP getm;
    CLOSE cur1;
    SET name=tp;
    SELECT name;
END$$

DROP PROCEDURE IF EXISTS `noUserMovie`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `noUserMovie` ()  NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE movieId INTEGER DEFAULT 0;
    DECLARE mname INTEGER DEFAULT 0;
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE mid INTEGER DEFAULT 0;
    DECLARE moviename varchar(200) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";
declare cur cursor for SELECT bmovieID,count(bseatId) FROM seatbooked WHERE seatbooked.paymentStatus=1 GROUP BY bmovieId ORDER BY bmovieId DESC;

declare cur2 cursor for SELECT movie.movieName FROM movie WHERE movie.movieId=mid;
    -- declare NOT FOUND handler
    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
        
        DELETE FROM movieweekly WHERE date=CURRENT_DATE();
    OPEN cur;
    getm: LOOP
        FETCH cur INTO movieId,mname;
        IF finished = 1 THEN 
            LEAVE getm;
        END IF; 
        
        SET mid=movieId;
        OPEN cur2;
        FETCH cur2 into movieName;
        CLOSE cur2;
        
        INSERT INTO movieweekly VALUES(movieId,mname,CURRENT_DATE());
        SET tp = CONCAT(movieName,'=',mname,';',tp);
    END LOOP getm;
    SET name=tp;
    CLOSE cur;
    SELECT name;
END$$

DROP PROCEDURE IF EXISTS `showTicket`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `showTicket` (IN `mid` INT, IN `tid` INT, IN `sid` INT, IN `uName` VARCHAR(200))  NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE uid INTEGER DEFAULT 0;
    DECLARE mname INTEGER DEFAULT 0;
    DECLARE total INTEGER DEFAULT 0;
    DECLARE comboName varchar (200) DEFAULT ""; 
    DECLARE type varchar (50) DEFAULT ""; 
    DECLARE comboPrice INTEGER DEFAULT  0;
    DECLARE ucbComboQuantity INTEGER DEFAULT 0;
    DECLARE ucbTotalPrice INTEGER DEFAULT 0;
    DECLARE movieName varchar(200) DEFAULT "";
    DECLARE theaterName varchar(200) DEFAULT "";
    DECLARE location varchar(100) DEFAULT "";
    DECLARE slot varchar(20) DEFAULT "";
    DECLARE seatId varchar(2) DEFAULT "";
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";


declare cur1 cursor for SELECT movie.movieName from movie where movie.movieId=mid;

declare cur2 cursor for SELECT theater.theaterName, theater.location from theater where theater.theaterId=tid;

DECLARE cur3 cursor for SELECT screen.screenType FROM screen where screen.screenId=sid and screen.screenTheaterId=tid;


DECLARE cur4 cursor for SELECT userId from user where userName=uName;

DECLARE cur5 cursor for SELECT DISTINCT bslot FROM seatbooked,seat WHERE seatbooked.bseatId=seat.seatId and seatbooked.bmovieId=mid and seatbooked.btheaterId=tid and seatbooked.bscreenId=sid and seatbooked.paymentStatus=0 and seatbooked.buserId=uid order by bseatId desc;

DECLARE cur6 cursor for SELECT bseatId FROM seatbooked,seat WHERE seatbooked.bseatId=seat.seatId and seatbooked.bmovieId=mid and seatbooked.btheaterId=tid and seatbooked.bscreenId=sid and seatbooked.paymentStatus=0 and seatbooked.buserId=uid order by bseatId desc;
 

DECLARE cur7 cursor for SELECT combo.comboName,combo.comboPrice,usercombobridge.ucbComboQuantity,usercombobridge.ucbTotalPrice FROM combo,usercombobridge WHERE usercombobridge.paymentStatus=0 and combo.comboId=usercombobridge.ucbComboId and  combo.comboTheaterId=usercombobridge.ucbTheaterId and usercombobridge.ucbUserId=uid and usercombobridge.ucbTheaterId=tid;

DECLARE cur8 cursor for SELECT totalPricePay(uid,tid); 

    -- declare NOT FOUND handler
    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;        
OPEN cur1;
FETCH cur1 into movieName;
CLOSE cur1;
SET tp = CONCAT(tp,movieName,'+');

OPEN cur2;
FETCH cur2 into theaterName,location;
CLOSE cur2;
SET tp = CONCAT(tp,theaterName,'+',location,'+');

OPEN cur3;
FETCH cur3 into type;
CLOSE cur3;
SET tp = CONCAT(tp,type,'+');

OPEN cur4;
FETCH cur4 into uid;
CLOSE cur4;

OPEN cur5;
FETCH cur5 into slot;
CLOSE cur5;
SET tp = CONCAT(tp,slot,'+');

OPEN cur8;
FETCH cur8 into total;
CLOSE cur8;
SET tp = CONCAT(tp,total,'+');

OPEN cur6;
  getm: LOOP
        FETCH cur6 INTO seatId;
        IF finished = 1 THEN 
        	SET finished=0;
            LEAVE getm;
        END IF; 
        SET tp = CONCAT(tp,seatId,',');
    END LOOP getm;
CLOSE cur6;
SET tp = CONCAT(tp,'+');

OPEN cur7;
  getm: LOOP
        FETCH cur7 INTO comboName,comboPrice,ucbComboQuantity,ucbTotalPrice; 
        IF finished = 1 THEN 
        	SET finished=0;
            LEAVE getm;
        END IF; 
        SET tp = CONCAT(tp,comboName,',',comboPrice,',',ucbComboQuantity,',',ucbTotalPrice,';');
    END LOOP getm;
CLOSE cur7;

SET name=tp;
SELECT name;
    
END$$

DROP PROCEDURE IF EXISTS `tableUpdate`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `tableUpdate` (IN `aId` INT, IN `price` INT, IN `uid` INT, IN `mid` INT, IN `tid` INT, IN `sid` INT)  NO SQL
BEGIN
 
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE cid INTEGER DEFAULT 0;
    DECLARE qua INTEGER DEFAULT 0;
  
    
declare cur1 cursor for SELECT usercombobridge.ucbComboId,usercombobridge.ucbComboQuantity from usercombobridge WHERE usercombobridge.ucbUserId=uid and usercombobridge.ucbTheaterId=tid and usercombobridge.paymentStatus=0;



    -- declare NOT FOUND handler
    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
  UPDATE useraccount set useraccount.accountBalance=useraccount.accountBalance-price,useraccount.updateDate=CURRENT_DATE() where useraccount.accountId=aId; 
    OPEN cur1;
    getm: LOOP
        FETCH cur1 INTO cid,qua;
        
        IF finished = 1 THEN 
            LEAVE getm;
        END IF; 
 
      UPDATE combo set combo.comboQuantity=combo.comboQuantity-qua where combo.comboId=cid and combo.comboTheaterId=tid;
      UPDATE usercombobridge SET usercombobridge.paymentStatus=1 WHERE usercombobridge.ucbUserId=uid and usercombobridge.ucbComboId=cid and usercombobridge.ucbTheaterId=tid;
      
    END LOOP getm;
   
    CLOSE cur1;


  INSERT INTO usermovie(usermovie.umUserId,usermovie.umMovieId) VALUES(uid,mid);
UPDATE seatbooked SET seatbooked.paymentStatus=1 WHERE buserId =uid and seatbooked.paymentStatus=0 and seatbooked.bmovieId=mid and seatbooked.btheaterId=tid and seatbooked.bscreenId=sid;


END$$

DROP PROCEDURE IF EXISTS `userSuggestion`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `userSuggestion` ()  NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE movieId INTEGER DEFAULT 0;
    DECLARE num INTEGER DEFAULT 0;
    DECLARE mname INTEGER DEFAULT 0;
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE mid INTEGER DEFAULT 0;
    DECLARE moviename varchar(200) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";
declare cur1 cursor for SELECT DISTINCT timmingofmovie.slotMovieId from timmingofmovie;

declare cur2 cursor for SELECT movie.movieName FROM movie WHERE movie.movieId=mid and movie.movieStatus='Released';

DECLARE cur3 CURSOR for SELECT SUM(movieweekly.mwNoUser) FROM movieweekly WHERE mwMovieId=mid group BY movieweekly.mwMovieId;

    -- declare NOT FOUND handler
    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
    OPEN cur1;
    getm: LOOP
        FETCH cur1 INTO movieId;
        IF finished = 1 THEN 
            LEAVE getm;
        END IF; 
        
        SET mid=movieId;
 
        OPEN cur2;
        FETCH cur2 into movieName;
        SET tp = CONCAT(tp,movieName,':');
        CLOSE cur2;
        
		OPEN cur3;
        FETCH cur3 into num;
        SET tp = CONCAT(tp,num,'+');
        CLOSE cur3;
        
    END LOOP getm;
    SET name=tp;
    CLOSE cur1;
    SELECT name;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `dailyTheaterVisiter`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `dailyTheaterVisiter` () RETURNS VARCHAR(5000) CHARSET latin1 NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE slot INTEGER DEFAULT 0;
    DECLARE slotname varchar(20) DEFAULT "";
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";
    
declare cur1 cursor for SELECT bslot,count(bseatId) FROM seatbooked WHERE seatbooked.paymentStatus=1 and seatbooked.btheaterId=1 GROUP BY seatbooked.bslot ORDER BY bslot;

declare cur2 cursor for SELECT bslot,count(bseatId) FROM seatbooked WHERE seatbooked.paymentStatus=1 and seatbooked.btheaterId=2 GROUP BY seatbooked.bslot ORDER BY bslot;
    -- declare NOT FOUND handler

    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
  DELETE FROM slotweekly WHERE slotweekly.swdate=CURRENT_DATE();
    OPEN cur1;
    getm: LOOP
        FETCH cur1 INTO slotname,slot;
        IF finished = 1 THEN 
           SET finished=0;
            LEAVE getm;
        END IF; 
        INSERT INTO slotweekly VALUES(slotname,1,slot,CURRENT_DATE());
        SET tp = CONCAT(tp,slotname,',',slot,';');
    END LOOP getm;
    CLOSE cur1;
    SET tp= CONCAT(tp,'+');
    OPEN cur2;
    getm: LOOP
        FETCH cur2 INTO slotname,slot;
        IF finished = 1 THEN 
            LEAVE getm;
        END IF; 
     INSERT INTO slotweekly VALUES(slotname,2,slot,CURRENT_DATE());
        SET tp = CONCAT(tp,slotname,',',slot,';');
    END LOOP getm;
    CLOSE cur2;
    SET name=tp;
    RETURN name;
END$$

DROP FUNCTION IF EXISTS `funIntro`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `funIntro` (`s` INT) RETURNS INT(11) NO SQL
BEGIN

   DECLARE income INT;

   SET income = 0;

   label1: WHILE income <= 3000 DO
     SET income = income +s;
   END WHILE label1;
   
   RETURN income;

END$$

DROP FUNCTION IF EXISTS `historyTheaterVisiter`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `historyTheaterVisiter` () RETURNS VARCHAR(5000) CHARSET latin1 NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE slot INTEGER DEFAULT 0;
    DECLARE slotname varchar(20) DEFAULT "";
    DECLARE d1 date;
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";
    
declare cur1 cursor for SELECT DISTINCT slotweekly.swdate FROM slotweekly WHERE slotweekly.swTheaterId=1 ORDER BY slotweekly.swdate;

declare cur2 cursor for SELECT slotweekly.swSlot,slotweekly.swNoUser FROM slotweekly WHERE slotweekly.swTheaterId=1 and slotweekly.swdate=d1;

declare cur3 cursor for SELECT DISTINCT slotweekly.swdate FROM slotweekly WHERE slotweekly.swTheaterId=2 ORDER BY slotweekly.swdate;

declare cur4 cursor for SELECT slotweekly.swSlot,slotweekly.swNoUser FROM slotweekly WHERE slotweekly.swTheaterId=2 and slotweekly.swdate=d1;


    -- declare NOT FOUND handler

    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
    SET tp = CONCAT(tp,'');
    OPEN cur1;
    getm: LOOP
        FETCH cur1 INTO d1;
        IF finished = 1 THEN 
           SET finished=0;
            LEAVE getm;
        END IF;   
        SET tp = CONCAT(tp,d1,'/');
        OPEN cur2;
        getn: LOOP
           FETCH cur2 INTO slotname,slot;
           IF finished = 1 THEN 
           SET finished=0;
            LEAVE getn;
           END IF;
            SET tp = CONCAT(tp,slotname,'#',slot,','); 
    END LOOP getn;
    CLOSE cur2; 
    SET tp = CONCAT(tp,';');
    END LOOP getm;
    CLOSE cur1;
    SET tp= CONCAT(tp,'+');
     OPEN cur3;
    getm: LOOP
        FETCH cur3 INTO d1;
        IF finished = 1 THEN 
           SET finished=0;
            LEAVE getm;
        END IF;   
        SET tp = CONCAT(tp,d1,'/');
        OPEN cur4;
        getn: LOOP
           FETCH cur4 INTO slotname,slot;
           IF finished = 1 THEN 
           SET finished=0;
            LEAVE getn;
           END IF;
            SET tp = CONCAT(tp,slotname,'#',slot,','); 
    END LOOP getn;
    CLOSE cur4; 
    SET tp = CONCAT(tp,';');
    END LOOP getm;
    CLOSE cur3;
    SET name=tp;
    RETURN name;
END$$

DROP FUNCTION IF EXISTS `movieRate`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `movieRate` (`uid` INT) RETURNS VARCHAR(5000) CHARSET latin1 NO SQL
BEGIN
        DECLARE done INT DEFAULT 0;
        declare mid int DEFAULT 0;
        declare mrate float DEFAULT 0;
        declare mname varchar(200);
        declare tp varchar(5000) DEFAULT "";

        declare cur1 cursor for SELECT movie.movieId ,movie.movieName,movieRating FROM movie,usermovie WHERE  umUserId=uid and movie.movieId=umMovieId and umRating IS null;

            
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
       
DELETE FROM usercombobridge where paymentStatus=0;
UPDATE seatbooked SET buserId=uid WHERE buserId IS NULL;
      SET tp='no';
    open cur1;
        read_loop: loop
            fetch cur1 into mid,mname,mrate;
            IF done=1 THEN
            set done=0;
                LEAVE read_loop;
            END IF;
          set tp=CONCAT(mid,',',mname,',',mrate) ;   
        END loop;
    close cur1;
    return tp;
end$$

DROP FUNCTION IF EXISTS `theaterSale`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `theaterSale` () RETURNS VARCHAR(5000) CHARSET latin1 NO SQL
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE tsum INTEGER DEFAULT 0;
    DECLARE csum INTEGER DEFAULT 0;
    DECLARE tid INTEGER DEFAULT 0;
    DECLARE thid INTEGER DEFAULT 0;
    DECLARE tp varchar(5000) DEFAULT "";
    DECLARE name varchar(5000) DEFAULT "";
    
declare cur1 cursor for SELECT sum(ucbTotalPrice) FROM usercombobridge WHERE usercombobridge.ucbTheaterId=thid GROUP BY ucbTheaterId ORDER BY ucbTheaterId;

declare cur2 cursor for SELECT theatertotal.ttheaterId,sum(theatertotal.total) FROM theatertotal GROUP BY theatertotal.ttheaterId;

    -- declare NOT FOUND handler

    DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;
    OPEN cur2;
    getm: LOOP
        FETCH cur2 INTO tid,tsum;
        IF finished = 1 THEN 
           SET finished=0;
            LEAVE getm;
        END IF; 
        SET tp = CONCAT(tp,tsum,',');
        SET thid=tid;
        OPEN cur1;
        getn: LOOP
        FETCH cur1 INTO csum; 
          IF finished = 1 THEN 
           SET finished=0;
            LEAVE getn;
        END IF; 
        SET tp = CONCAT(tp,csum);
        END loop;
        CLOSE cur1;
        SET tp = CONCAT(tp,'+');
    END LOOP getm;
    CLOSE cur2;
    SET name=tp;
    RETURN name;
END$$

DROP FUNCTION IF EXISTS `totalPricePay`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `totalPricePay` (`userId` INT, `theaterid` INT) RETURNS INT(11) NO SQL
BEGIN
        DECLARE done INT DEFAULT 0;
        declare i_myfield int;
        declare i_myfield1 varchar(10);
        declare i_myfield2 int;
        declare tid int;
        declare iter int;
        declare cur1 cursor for SELECT ucbTheaterId, ucbTotalPrice from usercombobridge WHERE ucbUserId=userId and usercombobridge.paymentStatus=0;
        declare cur2 cursor for SELECT seatbooked.bseatId, seat.seatEprice FROM seat,seatbooked WHERE seat.seatId=seatbooked.bseatId AND buserId=userId and seatbooked.paymentStatus=0;
            
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
        set iter = 0;
    open cur2;
        read_loop: loop
            fetch cur2 into i_myfield1,i_myfield2;
            IF done=1 THEN
            set done=0;
                LEAVE read_loop;
            END IF;
            IF (i_myfield1='G1' OR i_myfield1='G2' OR i_myfield1='G3') THEN
            SET iter = iter + 100+i_myfield2;
            END IF;
             IF (i_myfield1='S1' OR i_myfield1='S2' OR i_myfield1='S3') THEN
            SET iter = iter + 100+i_myfield2;
            END IF;
            IF (i_myfield1='P1' OR i_myfield1='P2' OR i_myfield1='P3') THEN
            SET iter = iter + 100+i_myfield2;
            END IF;    
        END loop;
        
    close cur2;
    open cur1;
        read_loop: loop
            fetch cur1 into tid,i_myfield;
            IF done=1 THEN
                LEAVE read_loop;
            END IF;

            SET iter = iter + i_myfield;
        END loop;
        
    close cur1;
    INSERT INTO theatertotal VALUES(theaterid,iter);

    return iter;
end$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

DROP TABLE IF EXISTS `admin`;
CREATE TABLE IF NOT EXISTS `admin` (
  `username` varchar(30) NOT NULL,
  `password` varchar(8) NOT NULL,
  PRIMARY KEY (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`username`, `password`) VALUES
('dipika', 'abcabc');

-- --------------------------------------------------------

--
-- Table structure for table `combo`
--

DROP TABLE IF EXISTS `combo`;
CREATE TABLE IF NOT EXISTS `combo` (
  `comboId` int(11) NOT NULL,
  `comboTheaterId` int(11) NOT NULL,
  `comboName` varchar(30) NOT NULL,
  `comboPrice` int(11) NOT NULL,
  `comboQuantity` int(11) NOT NULL,
  `comboDiscription` varchar(150) NOT NULL,
  PRIMARY KEY (`comboId`,`comboTheaterId`),
  KEY `comboTheaterId` (`comboTheaterId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `combo`
--

INSERT INTO `combo` (`comboId`, `comboTheaterId`, `comboName`, `comboPrice`, `comboQuantity`, `comboDiscription`) VALUES
(1, 2, 'cheese combo', 100, 26, 'one cheese popcorn (small) and one coke (250ml)\r\n\r\n'),
(2, 1, 'peri-peri combo', 100, 41, 'one peri-peri popcorn (small) and one coke (250ml)'),
(2, 2, 'samosa combo', 100, 23, 'two samosa and one sprite (250ml)'),
(3, 1, 'large cheese combo', 150, 64, 'two cheese popcorn (tub) and two cokes'),
(3, 2, 'large peri-peri combo', 150, 60, 'two peri-peri popcorn (tub) and two cokes'),
(4, 1, 'burger combo', 200, 59, 'one veg. burger and one coke');

--
-- Triggers `combo`
--
DROP TRIGGER IF EXISTS `checkPrimaryConstraintCombo`;
DELIMITER $$
CREATE TRIGGER `checkPrimaryConstraintCombo` BEFORE INSERT ON `combo` FOR EACH ROW BEGIN
           if (EXISTS( SELECT * from combo where combo.comboId=new.comboId and combo.comboTheaterId=new.comboTheaterId)) THEN
       		 signal sqlstate '49000' set message_text ='Already combo exists having same comboId and theaterId';
             END IF;       
        
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `combochild`;
DELIMITER $$
CREATE TRIGGER `combochild` BEFORE DELETE ON `combo` FOR EACH ROW DELETE FROM usercombobridge WHERE usercombobridge.ucbComboId=old.comboId and usercombobridge.ucbTheaterId=old.comboTheaterId
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `forslot`
--

DROP TABLE IF EXISTS `forslot`;
CREATE TABLE IF NOT EXISTS `forslot` (
  `fsmovieId` int(11) NOT NULL,
  `fstheaterId` int(11) NOT NULL,
  `fsscreenId` int(11) NOT NULL,
  `fsslot` varchar(30) NOT NULL,
  KEY `fsmovieId` (`fsmovieId`),
  KEY `fsscreenId` (`fsscreenId`,`fstheaterId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `forslot`
--

INSERT INTO `forslot` (`fsmovieId`, `fstheaterId`, `fsscreenId`, `fsslot`) VALUES
(28, 1, 2, '\'time3\'');

-- --------------------------------------------------------

--
-- Table structure for table `movie`
--

DROP TABLE IF EXISTS `movie`;
CREATE TABLE IF NOT EXISTS `movie` (
  `movieId` int(11) NOT NULL AUTO_INCREMENT,
  `movieName` varchar(40) NOT NULL,
  `movieDiscription` mediumtext NOT NULL,
  `movieDirector` varchar(30) NOT NULL,
  `movieProducer` varchar(30) NOT NULL,
  `movieGenre` varchar(20) NOT NULL,
  `movieCertificate` varchar(10) NOT NULL,
  `movieDuration` time NOT NULL,
  `movieRating` float NOT NULL,
  `movieReleaseDate` date NOT NULL,
  `movieLanguage` varchar(20) NOT NULL,
  `movieStatus` varchar(20) NOT NULL,
  `moviePosture` blob,
  PRIMARY KEY (`movieId`),
  UNIQUE KEY `movieName` (`movieName`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `movie`
--

INSERT INTO `movie` (`movieId`, `movieName`, `movieDiscription`, `movieDirector`, `movieProducer`, `movieGenre`, `movieCertificate`, `movieDuration`, `movieRating`, `movieReleaseDate`, `movieLanguage`, `movieStatus`, `moviePosture`) VALUES
(5, 'Thappad', 'This movie defines  a real problem of our Indian society', 'Anubhav Sinha', 'Kishan Kumar', 'Drama', 'U/A', '02:30:15', 4.125, '2020-03-20', 'Hindi', 'Released', NULL),
(8, 'Shubh Mangal Zyada Saavdhan', ' The film tells the story of a gay man and his partner, who have trouble convincing the former\'s parents of their relation.', 'Hitesh Kewalya', 'Bhusan kumar', 'Romantic comedy', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Released', NULL),
(10, 'Panga', 'The story depicts the jovial life of a kabaddi player.', 'Ashwiny Iyer Tiwari', 'Fox Star Studios', 'Drama', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Released', NULL),
(11, 'Black Widow', 'Black Widow is an upcoming American superhero film based on the Marvel Comics character of the same name.', 'Cate Shortland', 'Kevin Feige', 'Action thriller', 'U/A', '01:58:00', 4, '2020-11-06', 'English', 'Upcoming', NULL),
(14, 'Gangubai Kathiawadi\r\n', 'It is based on a chapter of Hussain Zaidi\'s book Mafia Queens of Mumbai about Gangubai Kothewali, the madam of a brothel in Kamathipura.', 'Sanjay Leela Bhansali', 'Sanjay Leela Bhansali', 'Biographical crime', 'A', '02:30:00', 4.5, '2020-09-11', 'Hindi', 'Upcoming', NULL),
(18, 'Gulabo Sitabo\r\n', 'Eponymous glove puppet characters, Gulabo and Sitabo are from Uttar Pradesh, their story is full of local humour and songs, depicting day-to-day struggle of common man.', 'Shoojit Sircar', 'Ronnie Lahiri', 'Comedy drama', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Upcoming', NULL),
(19, 'Sooryavanshi', 'Based on real story. Most powerful diologe delivery', 'Rohit Shetty', 'Karan Johar', 'Action', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Upcoming', NULL),
(23, 'baaghi3', 'Bakwasssssssssssssssssssssssssssssssssssssssssssssssssssss', 'Om Raut', 'Bhusan kumar', 'Action', 'None', '02:30:00', 0, '2020-02-20', 'Hindi', 'Upcoming', NULL),
(27, 'Geeta', 'This is a fab movie that every one must watch.', 'Om Raut', 'Bhusan', 'Romantic', 'U/A', '02:30:00', 4, '2020-04-21', 'Hindi', 'Released', NULL),
(28, '3 Idiots', 'This movie is dso comady and you have to watch it', 'Om Raut', 'Bhusan kumar', 'Comedy', 'U/A', '02:30:00', 4.5, '2020-04-21', 'Hindi', 'Released', NULL);

--
-- Triggers `movie`
--
DROP TRIGGER IF EXISTS `insertInArchive`;
DELIMITER $$
CREATE TRIGGER `insertInArchive` AFTER INSERT ON `movie` FOR EACH ROW INSERT INTO moviearchive VALUES(new.movieId,new.movieName,new.movieDiscription,new.movieDirector,new.movieProducer,new.movieGenre,new.movieCertificate,new.movieDuration,new.movieRating,new.movieReleaseDate,new.movieLanguage,new.movieStatus,NULL)
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `moviedelete1`;
DELIMITER $$
CREATE TRIGGER `moviedelete1` BEFORE DELETE ON `movie` FOR EACH ROW begin

DELETE FROM forslot WHERE forslot.fsmovieId=old.movieId;


end
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `moviedelete2`;
DELIMITER $$
CREATE TRIGGER `moviedelete2` BEFORE DELETE ON `movie` FOR EACH ROW DELETE FROM timmingofmovie WHERE timmingofmovie.slotMovieId=old.movieId
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `moviedelete3`;
DELIMITER $$
CREATE TRIGGER `moviedelete3` BEFORE DELETE ON `movie` FOR EACH ROW DELETE FROM seatbooked WHERE seatbooked.bmovieId=old.movieid
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `moviedelete4`;
DELIMITER $$
CREATE TRIGGER `moviedelete4` BEFORE DELETE ON `movie` FOR EACH ROW DELETE FROM moviecast WHERE moviecast.mcmovieId=old.movieId
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `updateArchieve`;
DELIMITER $$
CREATE TRIGGER `updateArchieve` AFTER UPDATE ON `movie` FOR EACH ROW UPDATE moviearchive SET moviearchive.movieName=new.movieName, moviearchive.movieDiscription=new.movieDiscription,moviearchive.movieDirector=new.movieDirector,moviearchive.movieProducer=new.movieProducer,moviearchive.movieGenre=new.movieGenre,moviearchive.movieCertificate=new.movieCertificate,moviearchive.movieDuration=new.movieDuration,moviearchive.movieRating=new.movieRating,moviearchive.movieReleaseDate=new.movieReleaseDate,moviearchive.movieLanguage=new.movieLanguage,moviearchive.movieStatus=new.movieStatus,moviearchive.moviePosture=new.moviePosture WHERE moviearchive.movieId=new.movieId
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `moviearchive`
--

DROP TABLE IF EXISTS `moviearchive`;
CREATE TABLE IF NOT EXISTS `moviearchive` (
  `movieId` int(11) NOT NULL,
  `movieName` varchar(40) NOT NULL,
  `movieDiscription` mediumtext NOT NULL,
  `movieDirector` varchar(30) NOT NULL,
  `movieProducer` varchar(30) NOT NULL,
  `movieGenre` varchar(20) NOT NULL,
  `movieCertificate` varchar(10) NOT NULL,
  `movieDuration` time NOT NULL,
  `movieRating` float NOT NULL,
  `movieReleaseDate` date NOT NULL,
  `movieLanguage` varchar(20) NOT NULL,
  `movieStatus` varchar(20) NOT NULL,
  `moviePosture` blob,
  PRIMARY KEY (`movieId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `moviearchive`
--

INSERT INTO `moviearchive` (`movieId`, `movieName`, `movieDiscription`, `movieDirector`, `movieProducer`, `movieGenre`, `movieCertificate`, `movieDuration`, `movieRating`, `movieReleaseDate`, `movieLanguage`, `movieStatus`, `moviePosture`) VALUES
(3, 'Tanhaji', 'Movie is based on history of Tanhaji from Maratha samrat. The lead actors are Ajay and Kajol', 'Om Raut', 'Bhusan', 'Period drama', 'U/A', '02:30:00', 4.57812, '2020-02-20', 'Hindi', 'Released', NULL),
(4, 'Avengers', 'Hollywood movie. Which might you love.', 'tony stark', 'rout', 'action', 'U/A', '02:30:00', 4.5, '2019-04-20', 'englishMovie', 'Released', NULL),
(5, 'Thappad', 'This movie defines  a real problem of our Indian society', 'Anubhav Sinha', 'Kishan Kumar', 'Drama', 'U/A', '02:30:15', 4.125, '2020-03-20', 'Hindi', 'Released', NULL),
(8, 'Shubh Mangal Zyada Saavdhan', ' The film tells the story of a gay man and his partner, who have trouble convincing the former\'s parents of their relation.', 'Hitesh Kewalya', 'Bhusan kumar', 'Romantic comedy', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Released', NULL),
(10, 'Panga', 'The story depicts the jovial life of a kabaddi player.', 'Ashwiny Iyer Tiwari', 'Fox Star Studios', 'Drama', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Released', NULL),
(11, 'Black Widow', 'Black Widow is an upcoming American superhero film based on the Marvel Comics character of the same name.', 'Cate Shortland', 'Kevin Feige', 'Action thriller', 'U/A', '01:58:00', 4, '2020-11-06', 'English', 'Upcoming', NULL),
(14, 'Gangubai Kathiawadi\r\n', 'It is based on a chapter of Hussain Zaidi\'s book Mafia Queens of Mumbai about Gangubai Kothewali, the madam of a brothel in Kamathipura.', 'Sanjay Leela Bhansali', 'Sanjay Leela Bhansali', 'Biographical crime', 'A', '02:30:00', 4.5, '2020-09-11', 'Hindi', 'Upcoming', NULL),
(18, 'Gulabo Sitabo\r\n', 'Eponymous glove puppet characters, Gulabo and Sitabo are from Uttar Pradesh, their story is full of local humour and songs, depicting day-to-day struggle of common man.', 'Shoojit Sircar', 'Ronnie Lahiri', 'Comedy drama', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Upcoming', NULL),
(19, 'Sooryavanshi', 'Based on real story. Most powerful diologe delivery', 'Rohit Shetty', 'Karan Johar', 'Action', 'U/A', '02:30:00', 4.5, '2020-02-20', 'Hindi', 'Upcoming', NULL),
(23, 'baaghi3', 'Bakwasssssssssssssssssssssssssssssssssssssssssssssssssssss', 'Om Raut', 'Bhusan kumar', 'Action', 'None', '02:30:00', 0, '2020-02-20', 'Hindi', 'Upcoming', NULL),
(27, 'Geeta', 'This is a fab movie that every one must watch.', 'Om Raut', 'Bhusan', 'Romantic', 'U/A', '02:30:00', 4, '2020-04-21', 'Hindi', 'Released', NULL),
(28, '3 Idiots', 'This movie is dso comady and you have to watch it', 'Om Raut', 'Bhusan kumar', 'Comedy', 'U/A', '02:30:00', 4.5, '2020-04-21', 'Hindi', 'Released', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `moviecast`
--

DROP TABLE IF EXISTS `moviecast`;
CREATE TABLE IF NOT EXISTS `moviecast` (
  `mcmovieId` int(11) NOT NULL,
  `mccastname` varchar(50) NOT NULL,
  KEY `mcmovieId` (`mcmovieId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `moviecast`
--

INSERT INTO `moviecast` (`mcmovieId`, `mccastname`) VALUES
(14, 'Alia Bhatt'),
(11, 'Scarlett Johansson'),
(5, 'Taapsee Pannu'),
(8, 'Ayushmann Khurrana'),
(8, 'Jitendra Kumar'),
(18, 'Ayushmann Khurrana'),
(18, 'Amitabh Bachchan'),
(19, 'Akshay Kumar'),
(10, 'Kangana Ranaut'),
(23, 'tiger shroff'),
(23, ' shraddha kapor'),
(27, 'Arjun readdy'),
(27, ' geeta'),
(28, 'Amir khan'),
(28, ' karina kapoor');

-- --------------------------------------------------------

--
-- Table structure for table `movieweekly`
--

DROP TABLE IF EXISTS `movieweekly`;
CREATE TABLE IF NOT EXISTS `movieweekly` (
  `mwMovieId` int(11) NOT NULL,
  `mwNoUser` int(11) NOT NULL,
  `date` date NOT NULL,
  KEY `movieweekly_ibfk_1` (`mwMovieId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `movieweekly`
--

INSERT INTO `movieweekly` (`mwMovieId`, `mwNoUser`, `date`) VALUES
(4, 26, '2020-04-10'),
(4, 20, '2020-04-11'),
(4, 18, '2020-04-12'),
(4, 15, '2020-04-13'),
(4, 20, '2020-04-14'),
(4, 22, '2020-04-15'),
(4, 28, '2020-04-16'),
(3, 25, '2020-04-17'),
(5, 22, '2020-04-17'),
(3, 20, '2020-04-18'),
(3, 19, '2020-04-19'),
(5, 16, '2020-04-19'),
(5, 12, '2020-04-20'),
(3, 26, '2020-04-20'),
(8, 25, '2020-04-20'),
(10, 20, '2020-04-20'),
(27, 2, '2020-04-21'),
(5, 3, '2020-04-21'),
(3, 9, '2020-04-21');

-- --------------------------------------------------------

--
-- Table structure for table `screen`
--

DROP TABLE IF EXISTS `screen`;
CREATE TABLE IF NOT EXISTS `screen` (
  `screenId` int(11) NOT NULL,
  `screenTheaterId` int(11) NOT NULL,
  `screenCapacity` int(11) NOT NULL,
  `screenType` varchar(10) NOT NULL,
  PRIMARY KEY (`screenId`,`screenTheaterId`),
  KEY `screenTheaterId` (`screenTheaterId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `screen`
--

INSERT INTO `screen` (`screenId`, `screenTheaterId`, `screenCapacity`, `screenType`) VALUES
(1, 1, 20, '2D'),
(1, 2, 50, '2D'),
(2, 1, 20, '3D'),
(2, 2, 50, '2D');

-- --------------------------------------------------------

--
-- Table structure for table `seat`
--

DROP TABLE IF EXISTS `seat`;
CREATE TABLE IF NOT EXISTS `seat` (
  `seatId` char(2) NOT NULL,
  `seatType` varchar(15) NOT NULL,
  `seatEprice` int(11) NOT NULL,
  PRIMARY KEY (`seatId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `seat`
--

INSERT INTO `seat` (`seatId`, `seatType`, `seatEprice`) VALUES
('G1', 'Gold', 20),
('G2', 'gold', 20),
('G3', 'gold', 20),
('P1', 'platinum', 40),
('P2', 'patinum', 40),
('P3', 'Platinum', 40),
('S1', 'silver', 0),
('S2', 'silver', 0),
('S3', 'silver', 0);

-- --------------------------------------------------------

--
-- Table structure for table `seatbooked`
--

DROP TABLE IF EXISTS `seatbooked`;
CREATE TABLE IF NOT EXISTS `seatbooked` (
  `buserId` int(11) DEFAULT NULL,
  `bmovieId` int(11) NOT NULL,
  `btheaterId` int(11) NOT NULL,
  `bscreenId` int(11) NOT NULL,
  `bseatId` char(2) NOT NULL,
  `bslot` varchar(20) DEFAULT NULL,
  `paymentStatus` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`bmovieId`,`btheaterId`,`bscreenId`,`bseatId`),
  KEY `bscreenId` (`bscreenId`,`btheaterId`),
  KEY `bseatId` (`bseatId`),
  KEY `buserId` (`buserId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `seatbooked`
--

INSERT INTO `seatbooked` (`buserId`, `bmovieId`, `btheaterId`, `bscreenId`, `bseatId`, `bslot`, `paymentStatus`) VALUES
(1, 5, 1, 2, 'G2', '\'time2\'', 1),
(8, 5, 1, 2, 'S2', '\'time2\'', 1),
(8, 5, 1, 2, 'S3', '\'time2\'', 1),
(1, 27, 2, 1, 'S2', '\'time1\'', 1),
(1, 27, 2, 1, 'S3', '\'time1\'', 1),
(1, 28, 1, 2, 'S2', '\'time3\'', 1),
(1, 28, 1, 2, 'S3', '\'time3\'', 1);

-- --------------------------------------------------------

--
-- Table structure for table `slotweekly`
--

DROP TABLE IF EXISTS `slotweekly`;
CREATE TABLE IF NOT EXISTS `slotweekly` (
  `swSlot` varchar(20) NOT NULL,
  `swTheaterId` int(11) NOT NULL,
  `swNoUser` int(11) NOT NULL,
  `swdate` date NOT NULL,
  KEY `swTheaterId` (`swTheaterId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `slotweekly`
--

INSERT INTO `slotweekly` (`swSlot`, `swTheaterId`, `swNoUser`, `swdate`) VALUES
('time1', 1, 10, '2020-04-11'),
('time2', 1, 12, '2020-04-11'),
('time3', 2, 15, '2020-04-11'),
('time2', 2, 20, '2020-04-11'),
('time1', 1, 1, '2020-04-12'),
('time2', 1, 1, '2020-04-12'),
('time1', 2, 1, '2020-04-12'),
('time3', 2, 2, '2020-04-12'),
('time1', 1, 11, '2020-04-17'),
('time1', 2, 5, '2020-04-17');

-- --------------------------------------------------------

--
-- Table structure for table `theater`
--

DROP TABLE IF EXISTS `theater`;
CREATE TABLE IF NOT EXISTS `theater` (
  `theaterId` int(11) NOT NULL AUTO_INCREMENT,
  `theaterName` varchar(30) NOT NULL,
  `location` varchar(30) NOT NULL,
  PRIMARY KEY (`theaterId`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `theater`
--

INSERT INTO `theater` (`theaterId`, `theaterName`, `location`) VALUES
(1, 'PVR', 'ahmedabad'),
(2, 'Cineplex', 'ahmedabad');

-- --------------------------------------------------------

--
-- Table structure for table `theatertotal`
--

DROP TABLE IF EXISTS `theatertotal`;
CREATE TABLE IF NOT EXISTS `theatertotal` (
  `ttheaterId` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  KEY `ttheaterId` (`ttheaterId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `theatertotal`
--

INSERT INTO `theatertotal` (`ttheaterId`, `total`) VALUES
(2, 1200),
(1, 100),
(1, 120),
(2, 500),
(1, 300);

-- --------------------------------------------------------

--
-- Table structure for table `timmingofmovie`
--

DROP TABLE IF EXISTS `timmingofmovie`;
CREATE TABLE IF NOT EXISTS `timmingofmovie` (
  `slotMovieId` int(11) NOT NULL,
  `slotTheaterId` int(11) NOT NULL,
  `slotScreenId` int(11) NOT NULL,
  `time1` varchar(8) NOT NULL,
  `time2` varchar(8) NOT NULL,
  `time3` varchar(8) NOT NULL,
  PRIMARY KEY (`slotMovieId`,`slotTheaterId`,`slotScreenId`),
  KEY `slotScreenId` (`slotScreenId`,`slotTheaterId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `timmingofmovie`
--

INSERT INTO `timmingofmovie` (`slotMovieId`, `slotTheaterId`, `slotScreenId`, `time1`, `time2`, `time3`) VALUES
(5, 1, 2, 'False', 'True', 'False'),
(5, 2, 1, 'False', 'False', 'True'),
(5, 2, 2, 'True', 'False', 'False'),
(14, 1, 1, 'False', 'False', 'True'),
(14, 1, 2, 'True', 'False', 'False'),
(18, 1, 2, 'False', 'False', 'False'),
(27, 2, 1, 'True', 'False', 'False'),
(28, 1, 2, 'False', 'False', 'True');

--
-- Triggers `timmingofmovie`
--
DROP TRIGGER IF EXISTS `checkClash`;
DELIMITER $$
CREATE TRIGGER `checkClash` BEFORE INSERT ON `timmingofmovie` FOR EACH ROW BEGIN
		if (new.time1='True') THEN
             if 'True' in (SELECT time1 from timmingofmovie where slotTheaterId=new.slotTheaterId 								and slotScreenId=new.slotScreenId) THEN
       		 signal sqlstate '45000' set message_text ='MyTriggerError:There is clash with other movie screen timming (9:30)';
             END IF;       
        end IF;
        if (new.time2='True') THEN
             if 'True' in (SELECT time2 from timmingofmovie where slotTheaterId=new.slotTheaterId 								and slotScreenId=new.slotScreenId) THEN
       		 signal sqlstate '45000' set message_text = 'MyTriggerError:There is clash with other movie screen timming (2:30)';
             END IF;       
        end IF;
        if (new.time3='True') THEN
             if 'True' in (SELECT time3 from timmingofmovie where slotTheaterId=new.slotTheaterId 								and slotScreenId=new.slotScreenId) THEN 
       		 signal sqlstate '45000' set message_text = 'MyTriggerError:There is clash with other movie screen timming (8:00)';
             END IF;       
        end IF;

      
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `checkPrimaryConstraintSlot`;
DELIMITER $$
CREATE TRIGGER `checkPrimaryConstraintSlot` BEFORE INSERT ON `timmingofmovie` FOR EACH ROW BEGIN
           if (EXISTS( SELECT * from timmingofmovie where timmingofmovie.slotMovieId=new.slotMovieId and timmingofmovie.slotTheaterId=new.slotTheaterId and timmingofmovie.slotScreenId=new.slotScreenId)) THEN
       		 signal sqlstate '48000' set message_text ='You have already inserted record for same movie in same screen of theater';
             END IF;       
        
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `userId` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(30) NOT NULL,
  `userPassword` varchar(15) NOT NULL,
  `userFirstName` varchar(30) NOT NULL,
  `userLastName` varchar(30) NOT NULL,
  `userEmail` varchar(30) NOT NULL,
  `userBirthdate` date NOT NULL,
  `userContact` bigint(10) NOT NULL,
  PRIMARY KEY (`userId`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`userId`, `username`, `userPassword`, `userFirstName`, `userLastName`, `userEmail`, `userBirthdate`, `userContact`) VALUES
(1, 'dppawar', 'abcabc@@', 'dipika', 'pawar', 'dipikapawar2001@gmail.com', '2001-07-12', 6354769630),
(2, 'aanship', 'abcabc123123', 'aanshi', 'patwari', 'aanshipatwari@gmail.com', '2000-11-10', 9904003599),
(7, 'mirindani', 'abcabc@@', 'miracle', 'rindani', 'miraclerindani@gmail.com', '2000-10-22', 6354769630),
(8, 'nilu', 'abcabc@@', 'nildeep', 'jadav', 'nilujadav@gmail.com', '1998-09-24', 6354769630),
(9, 'boomi', 'qwert@@', 'bhumiti', 'gohel', 'bhumiti.g@gmail.com', '2000-11-06', 9904003566),
(11, 'masi', 'abcabc@@', 'mansi', 'dobariya', 'mansi.d@gmail.com', '2015-09-28', 6354897630),
(18, 'manav', 'abcabc@@', 'manav', 'vagrecha', 'manavkumar.v@gmail.com', '1998-09-28', 6578963564),
(19, 'frency', 'abcabc@@', 'frency', 'chauhan', 'frencychauhan@gmail.com', '1998-09-28', 6354769630),
(20, 'nirvu', 'abcabc@@', 'nirva', 'sangani', 'sangani.nirva@gmail.com', '2016-09-28', 6354769330);

--
-- Triggers `user`
--
DROP TRIGGER IF EXISTS `addAccount`;
DELIMITER $$
CREATE TRIGGER `addAccount` AFTER INSERT ON `user` FOR EACH ROW BEGIN
        INSERT INTO useraccount
        VALUES(new.userId,NULL,50000,CURRENT_DATE());
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `checkDuplicateUsername`;
DELIMITER $$
CREATE TRIGGER `checkDuplicateUsername` BEFORE INSERT ON `user` FOR EACH ROW BEGIN
           if (EXISTS( SELECT * from user where user.username=new.username)) THEN
       		 signal sqlstate '47000' set message_text ='These username is already exists';
             END IF;       
        
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `useraccount`
--

DROP TABLE IF EXISTS `useraccount`;
CREATE TABLE IF NOT EXISTS `useraccount` (
  `accountUserId` int(11) NOT NULL,
  `accountId` int(11) NOT NULL AUTO_INCREMENT,
  `accountBalance` int(11) NOT NULL,
  `updateDate` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`accountId`),
  KEY `userId` (`accountUserId`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `useraccount`
--

INSERT INTO `useraccount` (`accountUserId`, `accountId`, `accountBalance`, `updateDate`) VALUES
(9, 6, 50000, NULL),
(1, 7, 38670, '2020-04-21 00:00:00'),
(8, 8, 38651, '2020-04-19 00:00:00'),
(11, 10, 50000, NULL),
(18, 11, 49600, '2020-04-17 00:00:00'),
(19, 12, 23160, '2020-04-19 00:00:00'),
(20, 13, 49040, '2020-04-20 00:00:00');

--
-- Triggers `useraccount`
--
DROP TRIGGER IF EXISTS `accountDeduct`;
DELIMITER $$
CREATE TRIGGER `accountDeduct` BEFORE UPDATE ON `useraccount` FOR EACH ROW BEGIN
           if(new.accountBalance<0) THEN
       		 signal sqlstate '46000' set message_text ='MyTriggerError:You do not have enuff balance in our account.';
             END IF;       
        
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `usercombobridge`
--

DROP TABLE IF EXISTS `usercombobridge`;
CREATE TABLE IF NOT EXISTS `usercombobridge` (
  `ucbUserId` int(11) NOT NULL,
  `ucbComboId` int(11) NOT NULL,
  `ucbTheaterId` int(11) NOT NULL,
  `ucbComboQuantity` int(11) NOT NULL,
  `ucbTotalPrice` int(11) NOT NULL,
  `paymentStatus` int(11) NOT NULL DEFAULT '0',
  KEY `ucbcomboId` (`ucbComboId`,`ucbTheaterId`),
  KEY `ucbUserId` (`ucbUserId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `usercombobridge`
--

INSERT INTO `usercombobridge` (`ucbUserId`, `ucbComboId`, `ucbTheaterId`, `ucbComboQuantity`, `ucbTotalPrice`, `paymentStatus`) VALUES
(1, 1, 2, 7, 1050, 1),
(1, 2, 2, 0, 0, 1),
(20, 2, 1, 1, 100, 1),
(20, 4, 1, 1, 200, 1),
(1, 1, 2, 3, 300, 1),
(1, 2, 2, 2, 200, 1),
(1, 2, 1, 3, 300, 1);

-- --------------------------------------------------------

--
-- Table structure for table `usermovie`
--

DROP TABLE IF EXISTS `usermovie`;
CREATE TABLE IF NOT EXISTS `usermovie` (
  `umUserId` int(11) NOT NULL,
  `umMovieId` int(11) NOT NULL,
  `umReview` varchar(200) DEFAULT NULL,
  `umRating` float DEFAULT NULL,
  KEY `umMovieId` (`umMovieId`),
  KEY `umUserId` (`umUserId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `usermovie`
--

INSERT INTO `usermovie` (`umUserId`, `umMovieId`, `umReview`, `umRating`) VALUES
(1, 27, 'very good movie ..u have to watch.fjlk,dlkas,', 3.5),
(1, 28, NULL, NULL);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `combo`
--
ALTER TABLE `combo`
  ADD CONSTRAINT `combo_ibfk_1` FOREIGN KEY (`comboTheaterId`) REFERENCES `theater` (`theaterId`);

--
-- Constraints for table `forslot`
--
ALTER TABLE `forslot`
  ADD CONSTRAINT `forslot_ibfk_1` FOREIGN KEY (`fsmovieId`) REFERENCES `movie` (`movieId`),
  ADD CONSTRAINT `forslot_ibfk_2` FOREIGN KEY (`fsscreenId`,`fstheaterId`) REFERENCES `screen` (`screenId`, `screenTheaterId`);

--
-- Constraints for table `moviecast`
--
ALTER TABLE `moviecast`
  ADD CONSTRAINT `moviecast_ibfk_1` FOREIGN KEY (`mcmovieId`) REFERENCES `movie` (`movieId`);

--
-- Constraints for table `movieweekly`
--
ALTER TABLE `movieweekly`
  ADD CONSTRAINT `movieweekly_ibfk_1` FOREIGN KEY (`mwMovieId`) REFERENCES `moviearchive` (`movieId`);

--
-- Constraints for table `screen`
--
ALTER TABLE `screen`
  ADD CONSTRAINT `screen_ibfk_1` FOREIGN KEY (`screenTheaterId`) REFERENCES `theater` (`theaterId`);

--
-- Constraints for table `seatbooked`
--
ALTER TABLE `seatbooked`
  ADD CONSTRAINT `seatbooked_ibfk_1` FOREIGN KEY (`bmovieId`) REFERENCES `movie` (`movieId`),
  ADD CONSTRAINT `seatbooked_ibfk_2` FOREIGN KEY (`bscreenId`,`btheaterId`) REFERENCES `screen` (`screenId`, `screenTheaterId`),
  ADD CONSTRAINT `seatbooked_ibfk_3` FOREIGN KEY (`bseatId`) REFERENCES `seat` (`seatId`),
  ADD CONSTRAINT `seatbooked_ibfk_4` FOREIGN KEY (`buserId`) REFERENCES `user` (`userId`);

--
-- Constraints for table `slotweekly`
--
ALTER TABLE `slotweekly`
  ADD CONSTRAINT `slotweekly_ibfk_1` FOREIGN KEY (`swTheaterId`) REFERENCES `theater` (`theaterId`);

--
-- Constraints for table `theatertotal`
--
ALTER TABLE `theatertotal`
  ADD CONSTRAINT `theatertotal_ibfk_1` FOREIGN KEY (`ttheaterId`) REFERENCES `theater` (`theaterId`);

--
-- Constraints for table `timmingofmovie`
--
ALTER TABLE `timmingofmovie`
  ADD CONSTRAINT `timmingofmovie_ibfk_1` FOREIGN KEY (`slotMovieId`) REFERENCES `movie` (`movieId`),
  ADD CONSTRAINT `timmingofmovie_ibfk_2` FOREIGN KEY (`slotScreenId`,`slotTheaterId`) REFERENCES `screen` (`screenId`, `screenTheaterId`);

--
-- Constraints for table `useraccount`
--
ALTER TABLE `useraccount`
  ADD CONSTRAINT `useraccount_ibfk_1` FOREIGN KEY (`accountUserId`) REFERENCES `user` (`userId`);

--
-- Constraints for table `usercombobridge`
--
ALTER TABLE `usercombobridge`
  ADD CONSTRAINT `usercombobridge_ibfk_2` FOREIGN KEY (`ucbComboId`,`ucbTheaterId`) REFERENCES `combo` (`comboId`, `comboTheaterId`),
  ADD CONSTRAINT `usercombobridge_ibfk_3` FOREIGN KEY (`ucbUserId`) REFERENCES `user` (`userId`);

--
-- Constraints for table `usermovie`
--
ALTER TABLE `usermovie`
  ADD CONSTRAINT `usermovie_ibfk_1` FOREIGN KEY (`umMovieId`) REFERENCES `moviearchive` (`movieId`),
  ADD CONSTRAINT `usermovie_ibfk_2` FOREIGN KEY (`umUserId`) REFERENCES `user` (`userId`);

DELIMITER $$
--
-- Events
--
DROP EVENT `updatetableHistory`$$
CREATE DEFINER=`root`@`localhost` EVENT `updatetableHistory` ON SCHEDULE EVERY 1 DAY STARTS '2020-04-17 00:00:00' ENDS '2020-04-30 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL `noUserMovie`()$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
