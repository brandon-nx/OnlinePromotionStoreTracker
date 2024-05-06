-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               8.0.36-0ubuntu0.22.04.1 - (Ubuntu)
-- Server OS:                    Linux
-- HeidiSQL Version:             12.6.0.6765
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping structure for table pricetracker.productdetails
CREATE TABLE IF NOT EXISTS `productdetails` (
  `detailsID` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `productID` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `trackID` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`detailsID`),
  KEY `fk_productID` (`productID`) USING BTREE,
  KEY `fk_trackID` (`trackID`),
  CONSTRAINT `fk_productdetails_productID` FOREIGN KEY (`productID`) REFERENCES `products` (`productID`),
  CONSTRAINT `fk_productdetails_trackID` FOREIGN KEY (`trackID`) REFERENCES `trackdetails` (`trackID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data exporting was unselected.

-- Dumping structure for table pricetracker.products
CREATE TABLE IF NOT EXISTS `products` (
  `productID` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `productName` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `URL` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `category` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`productID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data exporting was unselected.

-- Dumping structure for table pricetracker.trackdetails
CREATE TABLE IF NOT EXISTS `trackdetails` (
  `trackID` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `price` float NOT NULL,
  `stock` int NOT NULL,
  `dateCollected` datetime NOT NULL,
  PRIMARY KEY (`trackID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data exporting was unselected.

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
