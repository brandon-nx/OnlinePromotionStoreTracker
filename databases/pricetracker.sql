-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 29, 2024 at 06:03 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pricetracker`
--

-- --------------------------------------------------------

--
-- Table structure for table `itemdetails`
--

CREATE TABLE `itemdetails` (
  `detailsID` varchar(255) NOT NULL,
  `itemID` varchar(255) NOT NULL,
  `trackID` varchar(255) NOT NULL,
  `rateID` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `itemID` varchar(255) NOT NULL,
  `itemTitle` varchar(255) NOT NULL,
  `URL` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ratings`
--

CREATE TABLE `ratings` (
  `rateID` varchar(255) NOT NULL,
  `averageRating` int(255) NOT NULL,
  `1StarRating` int(255) NOT NULL,
  `2StarRating` varchar(255) NOT NULL,
  `3StarRating` varchar(255) NOT NULL,
  `4StarRating` varchar(255) NOT NULL,
  `5StarRating` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `trackdetails`
--

CREATE TABLE `trackdetails` (
  `trackID` varchar(255) NOT NULL,
  `price` float NOT NULL,
  `stock` int(255) NOT NULL,
  `quantitySold` int(255) NOT NULL,
  `dateCollected` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `itemdetails`
--
ALTER TABLE `itemdetails`
  ADD PRIMARY KEY (`detailsID`),
  ADD KEY `fk_trackID` (`trackID`),
  ADD KEY `fk_rateID` (`rateID`),
  ADD KEY `fk_itemID` (`itemID`) USING BTREE;

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`itemID`);

--
-- Indexes for table `ratings`
--
ALTER TABLE `ratings`
  ADD PRIMARY KEY (`rateID`);

--
-- Indexes for table `trackdetails`
--
ALTER TABLE `trackdetails`
  ADD PRIMARY KEY (`trackID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `itemdetails`
--
ALTER TABLE `itemdetails`
  ADD CONSTRAINT `fk_itemID` FOREIGN KEY (`itemID`) REFERENCES `items` (`itemID`),
  ADD CONSTRAINT `fk_rateID` FOREIGN KEY (`rateID`) REFERENCES `ratings` (`rateID`),
  ADD CONSTRAINT `fk_trackID` FOREIGN KEY (`trackID`) REFERENCES `trackdetails` (`trackID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
