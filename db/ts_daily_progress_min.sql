# ************************************************************
# Sequel Pro SQL dump
# Version 4500
#
# http://www.sequelpro.com/
# https://github.com/sequelpro/sequelpro
#
# Host: 127.0.0.1 (MySQL 5.6.27)
# Database: tracksys3_development
# Generation Time: 2016-02-09 18:20:47 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table academic_statuses
# ------------------------------------------------------------

DROP TABLE IF EXISTS `academic_statuses`;

CREATE TABLE `academic_statuses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `customers_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_academic_statuses_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

LOCK TABLES `academic_statuses` WRITE;
/*!40000 ALTER TABLE `academic_statuses` DISABLE KEYS */;

INSERT INTO `academic_statuses` (`id`, `name`, `created_at`, `updated_at`, `customers_count`)
VALUES
	(1,'Non-UVA','2009-04-03 17:45:14','2009-04-03 17:45:14',1480),
	(4,'Staff','2009-04-06 08:51:22','2009-04-06 08:51:22',237),
	(5,'Faculty','2009-04-06 09:20:29','2009-04-06 09:20:29',234),
	(6,'Undergraduate Student','2009-04-08 09:36:27','2009-04-08 09:36:27',93),
	(7,'Graduate Student','2009-05-05 17:29:48','2009-05-05 17:29:48',185),
	(8,'Continuing Education','2009-07-28 11:49:25','2009-07-28 11:49:25',8);

/*!40000 ALTER TABLE `academic_statuses` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table active_admin_comments
# ------------------------------------------------------------

DROP TABLE IF EXISTS `active_admin_comments`;

CREATE TABLE `active_admin_comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_id` int(11) NOT NULL,
  `resource_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `author_id` int(11) DEFAULT NULL,
  `author_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `body` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `namespace` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_active_admin_comments_on_author_type_and_author_id` (`author_type`,`author_id`),
  KEY `index_active_admin_comments_on_namespace` (`namespace`),
  KEY `index_admin_notes_on_resource_type_and_resource_id` (`resource_type`,`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table addresses
# ------------------------------------------------------------

DROP TABLE IF EXISTS `addresses`;

CREATE TABLE `addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `addressable_id` int(11) NOT NULL,
  `addressable_type` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `address_type` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `post_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `addresses` DISABLE KEYS */;

INSERT INTO `addresses` (`id`, `addressable_id`, `addressable_type`, `address_type`, `last_name`, `first_name`, `address_1`, `address_2`, `city`, `state`, `country`, `post_code`, `phone`, `organization`, `created_at`, `updated_at`)
VALUES
	(4,4,'Customer','primary',NULL,NULL,'160 McCormick Rd','','Charlottesville','Virginia','United States','22903','434.924.3021','','2015-12-17 15:17:02','2015-12-17 15:17:02');

/*!40000 ALTER TABLE `addresses` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table agencies
# ------------------------------------------------------------

DROP TABLE IF EXISTS `agencies`;

CREATE TABLE `agencies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_billable` tinyint(1) NOT NULL DEFAULT '0',
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ancestry` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `names_depth_cache` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `orders_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_agencies_on_name` (`name`),
  KEY `index_agencies_on_ancestry` (`ancestry`)
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `agencies` WRITE;
/*!40000 ALTER TABLE `agencies` DISABLE KEYS */;

INSERT INTO `agencies` (`id`, `name`, `description`, `is_billable`, `last_name`, `first_name`, `created_at`, `updated_at`, `ancestry`, `names_depth_cache`, `orders_count`)
VALUES
	(62,'General External Orders',NULL,0,NULL,NULL,'2011-12-08 15:27:52','2011-12-08 17:25:16',NULL,'General External Orders',108);

/*!40000 ALTER TABLE `agencies` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table automation_messages
# ------------------------------------------------------------

DROP TABLE IF EXISTS `automation_messages`;

CREATE TABLE `automation_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `app` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `processor` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `message_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `message` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `class_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `backtrace` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `active_error` tinyint(1) NOT NULL DEFAULT '0',
  `messagable_id` int(11) NOT NULL,
  `messagable_type` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `workflow_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_automation_messages_on_active_error` (`active_error`),
  KEY `index_automation_messages_on_messagable_id_and_messagable_type` (`messagable_id`,`messagable_type`),
  KEY `index_automation_messages_on_message_type` (`message_type`),
  KEY `index_automation_messages_on_processor` (`processor`),
  KEY `index_automation_messages_on_workflow_type` (`workflow_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table availability_policies
# ------------------------------------------------------------

DROP TABLE IF EXISTS `availability_policies`;

CREATE TABLE `availability_policies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bibls_count` int(11) DEFAULT '0',
  `components_count` int(11) DEFAULT '0',
  `master_files_count` int(11) DEFAULT '0',
  `units_count` int(11) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `repository_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `availability_policies` WRITE;
/*!40000 ALTER TABLE `availability_policies` DISABLE KEYS */;

INSERT INTO `availability_policies` (`id`, `name`, `bibls_count`, `components_count`, `master_files_count`, `units_count`, `created_at`, `updated_at`, `repository_url`, `pid`)
VALUES
	(1,'Public',7150,9275,546319,15468,'2012-05-07 14:05:52','2013-01-03 17:35:47','http://localhost:8080','uva-lib:2141109'),
	(2,'VIVA only',0,0,0,0,'2012-05-07 14:06:16','2013-01-03 17:38:37','http://localhost:8080','uva-lib:2141111'),
	(3,'UVA only',622,6699,345918,766,'2012-05-07 14:06:21','2013-01-03 17:38:56','http://localhost:8080','uva-lib:2141110'),
	(4,'Restricted',0,0,0,12,'2012-05-07 14:06:25','2013-01-03 17:39:35','http://localhost:8080','uva-lib:2141112');

/*!40000 ALTER TABLE `availability_policies` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table bibls
# ------------------------------------------------------------

DROP TABLE IF EXISTS `bibls`;

CREATE TABLE `bibls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `is_approved` tinyint(1) NOT NULL DEFAULT '0',
  `is_personal_item` tinyint(1) NOT NULL DEFAULT '0',
  `resource_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `genre` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_manuscript` tinyint(1) NOT NULL DEFAULT '0',
  `is_collection` tinyint(1) NOT NULL DEFAULT '0',
  `title` text COLLATE utf8_unicode_ci,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `series_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creator_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creator_name_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `catalog_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title_control` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `barcode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `call_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `copy` int(11) DEFAULT NULL,
  `volume` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `location` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `year` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `year_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_external_update` datetime DEFAULT NULL,
  `pid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_in_catalog` tinyint(1) NOT NULL DEFAULT '0',
  `issue` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `citation` text COLLATE utf8_unicode_ci,
  `exemplar` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_bibl_id` int(11) NOT NULL DEFAULT '0',
  `desc_metadata` text COLLATE utf8_unicode_ci,
  `rels_ext` text COLLATE utf8_unicode_ci,
  `solr` longtext COLLATE utf8_unicode_ci,
  `dc` text COLLATE utf8_unicode_ci,
  `rels_int` text COLLATE utf8_unicode_ci,
  `discoverability` tinyint(1) DEFAULT '1',
  `indexing_scenario_id` int(11) DEFAULT NULL,
  `date_dl_ingest` datetime DEFAULT NULL,
  `date_dl_update` datetime DEFAULT NULL,
  `automation_messages_count` int(11) DEFAULT '0',
  `units_count` int(11) DEFAULT '0',
  `availability_policy_id` int(11) DEFAULT NULL,
  `use_right_id` int(11) DEFAULT NULL,
  `dpla` tinyint(1) DEFAULT '0',
  `cataloging_source` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `collection_facet` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `index_destination_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_bibls_on_availability_policy_id` (`availability_policy_id`),
  KEY `index_bibls_on_barcode` (`barcode`),
  KEY `index_bibls_on_call_number` (`call_number`),
  KEY `index_bibls_on_catalog_key` (`catalog_key`),
  KEY `index_bibls_on_cataloging_source` (`cataloging_source`),
  KEY `index_bibls_on_dpla` (`dpla`),
  KEY `index_bibls_on_indexing_scenario_id` (`indexing_scenario_id`),
  KEY `index_bibls_on_parent_bibl_id` (`parent_bibl_id`),
  KEY `index_bibls_on_pid` (`pid`),
  KEY `index_bibls_on_use_right_id` (`use_right_id`),
  CONSTRAINT `bibls_availability_policy_id_fk` FOREIGN KEY (`availability_policy_id`) REFERENCES `availability_policies` (`id`),
  CONSTRAINT `bibls_indexing_scenario_id_fk` FOREIGN KEY (`indexing_scenario_id`) REFERENCES `indexing_scenarios` (`id`),
  CONSTRAINT `bibls_use_right_id_fk` FOREIGN KEY (`use_right_id`) REFERENCES `use_rights` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15227 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `bibls` WRITE;
/*!40000 ALTER TABLE `bibls` DISABLE KEYS */;

INSERT INTO `bibls` (`id`, `is_approved`, `is_personal_item`, `resource_type`, `genre`, `is_manuscript`, `is_collection`, `title`, `description`, `series_title`, `creator_name`, `creator_name_type`, `catalog_key`, `title_control`, `barcode`, `call_number`, `copy`, `volume`, `location`, `year`, `year_type`, `date_external_update`, `pid`, `created_at`, `updated_at`, `is_in_catalog`, `issue`, `citation`, `exemplar`, `parent_bibl_id`, `desc_metadata`, `rels_ext`, `solr`, `dc`, `rels_int`, `discoverability`, `indexing_scenario_id`, `date_dl_ingest`, `date_dl_update`, `automation_messages_count`, `units_count`, `availability_policy_id`, `use_right_id`, `dpla`, `cataloging_source`, `collection_facet`, `index_destination_id`)
VALUES
	(8153,1,0,'mixed material',NULL,1,0,'Papers of John Dos Passos',NULL,NULL,'Dos Passos, John, 1896-1970','personal','u3523359',NULL,'3523359-1001','MSS 5950',1,NULL,'STACKS',NULL,NULL,'2013-05-15 11:26:07','uva-lib:707283','2009-12-23 14:17:41','2013-05-15 11:26:07',1,NULL,'John Dos Passos Papers, 1865-1999, Accession #5950, etc., Special Collections, University of Virginia Library, Charlottesville, Va.',NULL,0,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,0,122,NULL,NULL,0,'VA@',NULL,NULL),
	(15226,1,0,'text','newspaper',0,1,'The Daily progress',NULL,NULL,NULL,NULL,'u1870648','o24520244','X006024666','Micfilm N-US Va-6',1,NULL,'3EAST','1892-','publication','2013-05-15 11:57:19','uva-lib:2065830','2012-10-10 19:38:21','2013-12-20 21:21:29',0,NULL,NULL,'000021659_0006.tif',15784,NULL,NULL,NULL,NULL,NULL,0,1,'2012-11-28 16:26:35','2013-12-20 21:21:29',0,0,1,NULL,1,'VA@',NULL,3);

/*!40000 ALTER TABLE `bibls` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table bibls_components
# ------------------------------------------------------------

DROP TABLE IF EXISTS `bibls_components`;

CREATE TABLE `bibls_components` (
  `bibl_id` int(11) DEFAULT NULL,
  `component_id` int(11) DEFAULT NULL,
  KEY `bibl_id` (`bibl_id`),
  KEY `component_id` (`component_id`),
  CONSTRAINT `bibls_components_ibfk_1` FOREIGN KEY (`bibl_id`) REFERENCES `bibls` (`id`),
  CONSTRAINT `bibls_components_ibfk_2` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `bibls_components` WRITE;
/*!40000 ALTER TABLE `bibls_components` DISABLE KEYS */;

INSERT INTO `bibls_components` (`bibl_id`, `component_id`)
VALUES
	(15226,497769);

/*!40000 ALTER TABLE `bibls_components` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table bibls_ead_refs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `bibls_ead_refs`;

CREATE TABLE `bibls_ead_refs` (
  `bibl_id` int(11) DEFAULT NULL,
  `ead_ref_id` int(11) DEFAULT NULL,
  KEY `bibl_id` (`bibl_id`),
  KEY `ead_ref_id` (`ead_ref_id`),
  CONSTRAINT `bibls_ead_refs_ibfk_1` FOREIGN KEY (`bibl_id`) REFERENCES `bibls` (`id`),
  CONSTRAINT `bibls_ead_refs_ibfk_2` FOREIGN KEY (`ead_ref_id`) REFERENCES `ead_refs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table bibls_legacy_identifiers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `bibls_legacy_identifiers`;

CREATE TABLE `bibls_legacy_identifiers` (
  `legacy_identifier_id` int(11) DEFAULT NULL,
  `bibl_id` int(11) DEFAULT NULL,
  KEY `index_bibls_legacy_identifiers_on_bibl_id` (`bibl_id`),
  KEY `index_bibls_legacy_identifiers_on_legacy_identifier_id` (`legacy_identifier_id`),
  CONSTRAINT `bibls_legacy_identifiers_bibl_id_fk` FOREIGN KEY (`bibl_id`) REFERENCES `bibls` (`id`),
  CONSTRAINT `bibls_legacy_identifiers_legacy_identifier_id_fk` FOREIGN KEY (`legacy_identifier_id`) REFERENCES `legacy_identifiers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table checkins
# ------------------------------------------------------------

DROP TABLE IF EXISTS `checkins`;

CREATE TABLE `checkins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_id` int(11) NOT NULL DEFAULT '0',
  `staff_member_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `staff_member_id` (`staff_member_id`),
  KEY `unit_id` (`unit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table component_types
# ------------------------------------------------------------

DROP TABLE IF EXISTS `component_types`;

CREATE TABLE `component_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `components_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_component_types_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `component_types` WRITE;
/*!40000 ALTER TABLE `component_types` DISABLE KEYS */;

INSERT INTO `component_types` (`id`, `name`, `description`, `created_at`, `updated_at`, `components_count`)
VALUES
	(1,'box',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(2,'folder',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(3,'envelope',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(5,'tray',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(6,'book',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(7,'class',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(8,'collection',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(9,'file',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(10,'fonds',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(11,'guide',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(12,'item',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(13,'recordgrp',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(14,'series',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(15,'subfonds',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(16,'subgrp',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(17,'subseries',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL),
	(18,'otherlevel',NULL,'2015-12-18 11:28:34','2015-12-18 11:28:34',NULL);

/*!40000 ALTER TABLE `component_types` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table components
# ------------------------------------------------------------

DROP TABLE IF EXISTS `components`;

CREATE TABLE `components` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `component_type_id` int(11) NOT NULL DEFAULT '0',
  `parent_component_id` int(11) NOT NULL DEFAULT '0',
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `content_desc` text COLLATE utf8_unicode_ci,
  `idno` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `barcode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `seq_number` int(11) DEFAULT NULL,
  `pid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `desc_metadata` text COLLATE utf8_unicode_ci,
  `rels_ext` text COLLATE utf8_unicode_ci,
  `solr` longtext COLLATE utf8_unicode_ci,
  `dc` text COLLATE utf8_unicode_ci,
  `rels_int` text COLLATE utf8_unicode_ci,
  `discoverability` tinyint(1) DEFAULT '1',
  `indexing_scenario_id` int(11) DEFAULT NULL,
  `level` text COLLATE utf8_unicode_ci,
  `ead_id_att` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_ead_ref_id` int(11) DEFAULT NULL,
  `ead_ref_id` int(11) DEFAULT NULL,
  `availability_policy_id` int(11) DEFAULT NULL,
  `date_dl_ingest` datetime DEFAULT NULL,
  `date_dl_update` datetime DEFAULT NULL,
  `use_right_id` int(11) DEFAULT NULL,
  `master_files_count` int(11) NOT NULL DEFAULT '0',
  `automation_messages_count` int(11) NOT NULL DEFAULT '0',
  `exemplar` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ancestry` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pids_depth_cache` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ead_id_atts_depth_cache` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `followed_by_id` int(11) DEFAULT NULL,
  `legacy_ead` text COLLATE utf8_unicode_ci,
  `physical_desc` text COLLATE utf8_unicode_ci,
  `scope_content` text COLLATE utf8_unicode_ci,
  `index_destination_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_components_on_ancestry` (`ancestry`),
  KEY `index_components_on_availability_policy_id` (`availability_policy_id`),
  KEY `index_components_on_component_type_id` (`component_type_id`),
  KEY `ead_ref_id` (`ead_ref_id`),
  KEY `index_components_on_followed_by_id` (`followed_by_id`),
  KEY `index_components_on_indexing_scenario_id` (`indexing_scenario_id`),
  KEY `index_components_on_use_right_id` (`use_right_id`),
  CONSTRAINT `components_availability_policy_id_fk` FOREIGN KEY (`availability_policy_id`) REFERENCES `availability_policies` (`id`),
  CONSTRAINT `components_component_type_id_fk` FOREIGN KEY (`component_type_id`) REFERENCES `component_types` (`id`),
  CONSTRAINT `components_indexing_scenario_id_fk` FOREIGN KEY (`indexing_scenario_id`) REFERENCES `indexing_scenarios` (`id`),
  CONSTRAINT `components_use_right_id_fk` FOREIGN KEY (`use_right_id`) REFERENCES `use_rights` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=497770 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `components` WRITE;
/*!40000 ALTER TABLE `components` DISABLE KEYS */;

INSERT INTO `components` (`id`, `component_type_id`, `parent_component_id`, `title`, `label`, `date`, `content_desc`, `idno`, `barcode`, `seq_number`, `pid`, `created_at`, `updated_at`, `desc_metadata`, `rels_ext`, `solr`, `dc`, `rels_int`, `discoverability`, `indexing_scenario_id`, `level`, `ead_id_att`, `parent_ead_ref_id`, `ead_ref_id`, `availability_policy_id`, `date_dl_ingest`, `date_dl_update`, `use_right_id`, `master_files_count`, `automation_messages_count`, `exemplar`, `ancestry`, `pids_depth_cache`, `ead_id_atts_depth_cache`, `followed_by_id`, `legacy_ead`, `physical_desc`, `scope_content`, `index_destination_id`)
VALUES
	(410296,12,0,'Pen-and-ink sketches (4)/bullfighters, bulls and horses/by Jose Robles 1913',NULL,'1913','Pen-and-ink sketches (4)/bullfighters, bulls and horses/by Jose Robles 1913',NULL,NULL,NULL,'uva-lib:1734582','2012-07-08 01:28:58','2012-07-08 01:28:58',NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,'d1e8436',NULL,NULL,NULL,NULL,NULL,NULL,0,0,NULL,'14072/14076/410281','uva-lib:1330360/uva-lib:1330364/uva-lib:1734567','viu01215/d1e8241/d1e8319',NULL,NULL,NULL,NULL,NULL),
	(497769,11,0,'Daily Progress Digitized Microfilm',NULL,NULL,'The Charlottesville, VA area newspaper, published daily from 1892 to the present. Issues from 1892 through 1923 have been digitized from the Library\'s set of microfilm and are available for viewing online.',NULL,NULL,NULL,'uva-lib:2137307','2012-11-16 20:55:19','2013-10-18 12:58:38',NULL,NULL,NULL,NULL,NULL,1,1,NULL,'',NULL,NULL,1,'2012-11-28 16:26:45','2013-10-18 12:58:38',NULL,0,47,NULL,NULL,'uva-lib:2137307','',NULL,NULL,NULL,NULL,NULL);

/*!40000 ALTER TABLE `components` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table components_containers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `components_containers`;

CREATE TABLE `components_containers` (
  `container_id` int(11) DEFAULT NULL,
  `component_id` int(11) DEFAULT NULL,
  KEY `component_id` (`component_id`),
  KEY `container_id` (`container_id`),
  CONSTRAINT `components_containers_ibfk_1` FOREIGN KEY (`container_id`) REFERENCES `containers` (`id`),
  CONSTRAINT `components_containers_ibfk_2` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table components_legacy_identifiers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `components_legacy_identifiers`;

CREATE TABLE `components_legacy_identifiers` (
  `component_id` int(11) DEFAULT NULL,
  `legacy_identifier_id` int(11) DEFAULT NULL,
  KEY `component_id` (`component_id`),
  KEY `legacy_identifier_id` (`legacy_identifier_id`),
  CONSTRAINT `components_legacy_identifiers_ibfk_1` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`),
  CONSTRAINT `components_legacy_identifiers_ibfk_2` FOREIGN KEY (`legacy_identifier_id`) REFERENCES `legacy_identifiers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table container_types
# ------------------------------------------------------------

DROP TABLE IF EXISTS `container_types`;

CREATE TABLE `container_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_container_types_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table containers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `containers`;

CREATE TABLE `containers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `barcode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `container_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sequence_no` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_container_id` int(11) NOT NULL DEFAULT '0',
  `legacy_component_id` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `container_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `containers_container_type_id_fk` (`container_type_id`),
  CONSTRAINT `containers_container_type_id_fk` FOREIGN KEY (`container_type_id`) REFERENCES `container_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table customers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `customers`;

CREATE TABLE `customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `department_id` int(11) DEFAULT NULL,
  `academic_status_id` int(11) NOT NULL DEFAULT '0',
  `heard_about_service_id` int(11) DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `master_files_count` int(11) DEFAULT '0',
  `orders_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_customers_on_academic_status_id` (`academic_status_id`),
  KEY `index_customers_on_department_id` (`department_id`),
  KEY `index_customers_on_email` (`email`),
  KEY `index_customers_on_first_name` (`first_name`),
  KEY `index_customers_on_heard_about_service_id` (`heard_about_service_id`),
  KEY `index_customers_on_last_name` (`last_name`),
  CONSTRAINT `customers_academic_status_id_fk` FOREIGN KEY (`academic_status_id`) REFERENCES `academic_statuses` (`id`),
  CONSTRAINT `customers_department_id_fk` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  CONSTRAINT `customers_heard_about_service_id_fk` FOREIGN KEY (`heard_about_service_id`) REFERENCES `heard_about_services` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2555 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;

INSERT INTO `customers` (`id`, `department_id`, `academic_status_id`, `heard_about_service_id`, `last_name`, `first_name`, `email`, `created_at`, `updated_at`, `master_files_count`, `orders_count`)
VALUES
	(4,1,2,3,'Foster','Lou','lf6f@virginia.edu','2015-12-17 15:17:02','2015-12-17 15:17:02',0,1),
	(2554,NULL,1,3,'Nanney','Lisa','l.nanney@gmail.com','2015-12-02 17:09:35','2015-12-02 17:09:35',86,1);

/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table delayed_jobs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `delayed_jobs`;

CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) NOT NULL DEFAULT '0',
  `attempts` int(11) NOT NULL DEFAULT '0',
  `handler` text COLLATE utf8_unicode_ci NOT NULL,
  `last_error` text COLLATE utf8_unicode_ci,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `queue` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `delayed_jobs_priority` (`priority`,`run_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table delivery_methods
# ------------------------------------------------------------

DROP TABLE IF EXISTS `delivery_methods`;

CREATE TABLE `delivery_methods` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_internal_use_only` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_delivery_methods_on_label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table delivery_methods_orders
# ------------------------------------------------------------

DROP TABLE IF EXISTS `delivery_methods_orders`;

CREATE TABLE `delivery_methods_orders` (
  `delivery_method_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  KEY `index_delivery_methods_orders_on_delivery_method_id` (`delivery_method_id`),
  KEY `index_delivery_methods_orders_on_order_id` (`order_id`),
  CONSTRAINT `delivery_methods_orders_delivery_method_id_fk` FOREIGN KEY (`delivery_method_id`) REFERENCES `delivery_methods` (`id`),
  CONSTRAINT `delivery_methods_orders_order_id_fk` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table departments
# ------------------------------------------------------------

DROP TABLE IF EXISTS `departments`;

CREATE TABLE `departments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `customers_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_departments_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `departments` WRITE;
/*!40000 ALTER TABLE `departments` DISABLE KEYS */;

INSERT INTO `departments` (`id`, `name`, `created_at`, `updated_at`, `customers_count`)
VALUES
	(1,'University of Virginia Library','2015-12-17 14:51:11','2015-12-17 14:51:11',2);

/*!40000 ALTER TABLE `departments` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table ead_refs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ead_refs`;

CREATE TABLE `ead_refs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_ead_ref_id` int(11) NOT NULL DEFAULT '0',
  `bibl_id` int(11) DEFAULT '0',
  `ead_id_att` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `level` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `content_desc` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `desc_metadata` text COLLATE utf8_unicode_ci,
  `rels_ext` text COLLATE utf8_unicode_ci,
  `solr` longtext COLLATE utf8_unicode_ci,
  `dc` text COLLATE utf8_unicode_ci,
  `availability` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rels_int` text COLLATE utf8_unicode_ci,
  `discoverability` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `bibl_id` (`bibl_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table ead_refs_master_files
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ead_refs_master_files`;

CREATE TABLE `ead_refs_master_files` (
  `ead_ref_id` int(11) DEFAULT NULL,
  `master_file_id` int(11) DEFAULT NULL,
  KEY `ead_ref_id` (`ead_ref_id`),
  KEY `master_file_id` (`master_file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table heard_about_resources
# ------------------------------------------------------------

DROP TABLE IF EXISTS `heard_about_resources`;

CREATE TABLE `heard_about_resources` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_approved` tinyint(1) NOT NULL DEFAULT '0',
  `is_internal_use_only` tinyint(1) NOT NULL DEFAULT '0',
  `units_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_heard_about_resources_on_description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table heard_about_services
# ------------------------------------------------------------

DROP TABLE IF EXISTS `heard_about_services`;

CREATE TABLE `heard_about_services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_approved` tinyint(1) NOT NULL DEFAULT '0',
  `is_internal_use_only` tinyint(1) NOT NULL DEFAULT '0',
  `customers_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_heard_about_services_on_description` (`description`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `heard_about_services` WRITE;
/*!40000 ALTER TABLE `heard_about_services` DISABLE KEYS */;

INSERT INTO `heard_about_services` (`id`, `description`, `created_at`, `updated_at`, `is_approved`, `is_internal_use_only`, `customers_count`)
VALUES
	(1,'UVA Library web site','2015-12-17 14:51:11','2015-12-17 14:51:11',1,0,0),
	(2,'Visual Resource Center','2015-12-17 14:51:11','2015-12-17 14:51:11',1,0,0),
	(3,'Colleague','2015-12-17 14:51:11','2015-12-17 14:51:11',1,0,1),
	(4,'Scholars Lab','2015-12-17 14:51:11','2015-12-17 14:51:11',1,0,1);

/*!40000 ALTER TABLE `heard_about_services` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table image_tech_meta
# ------------------------------------------------------------

DROP TABLE IF EXISTS `image_tech_meta`;

CREATE TABLE `image_tech_meta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `master_file_id` int(11) NOT NULL DEFAULT '0',
  `image_format` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `width` int(11) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `resolution` int(11) DEFAULT NULL,
  `color_space` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `depth` int(11) DEFAULT NULL,
  `compression` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `color_profile` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `equipment` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `software` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `model` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exif_version` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `capture_date` datetime DEFAULT NULL,
  `iso` int(11) DEFAULT NULL,
  `exposure_bias` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exposure_time` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `aperture` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `focal_length` decimal(10,0) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_image_tech_meta_on_master_file_id` (`master_file_id`),
  CONSTRAINT `image_tech_meta_master_file_id_fk` FOREIGN KEY (`master_file_id`) REFERENCES `master_files` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table index_destinations
# ------------------------------------------------------------

DROP TABLE IF EXISTS `index_destinations`;

CREATE TABLE `index_destinations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nickname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `hostname` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'localhost',
  `port` varchar(255) COLLATE utf8_unicode_ci DEFAULT '8080',
  `protocol` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'http',
  `context` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'solr',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `bibls_count` int(11) DEFAULT NULL,
  `units_count` int(11) DEFAULT NULL,
  `components_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table indexing_scenarios
# ------------------------------------------------------------

DROP TABLE IF EXISTS `indexing_scenarios`;

CREATE TABLE `indexing_scenarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `datastream_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `repository_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `bibls_count` int(11) DEFAULT '0',
  `components_count` int(11) DEFAULT '0',
  `master_files_count` int(11) DEFAULT '0',
  `units_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `indexing_scenarios` WRITE;
/*!40000 ALTER TABLE `indexing_scenarios` DISABLE KEYS */;

INSERT INTO `indexing_scenarios` (`id`, `name`, `pid`, `datastream_name`, `repository_url`, `created_at`, `updated_at`, `bibls_count`, `components_count`, `master_files_count`, `units_count`)
VALUES
	(1,'Default','uva-lib:defaultTransformation','XSLT','http://fedora-prod02.lib.virginia.edu:8080','2011-11-29 18:22:49','2011-11-29 18:22:49',7324,27379,987203,8744),
	(2,'Holsinger, Jackson Davis and Visual History','uva-lib:holsingerTransformation','XSLT','http://fedora-prod02.lib.virginia.edu:8080','2011-11-29 18:22:49','2014-01-30 14:52:37',6,0,49988,60),
	(3,'WSLS','uva-lib:wslsTransformation','XSLT','http://fedora-prod02.lib.virginia.edu:8080','2011-11-30 11:05:23','2011-11-30 11:05:23',0,0,0,0);

/*!40000 ALTER TABLE `indexing_scenarios` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table intended_uses
# ------------------------------------------------------------

DROP TABLE IF EXISTS `intended_uses`;

CREATE TABLE `intended_uses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_internal_use_only` tinyint(1) NOT NULL DEFAULT '0',
  `is_approved` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `units_count` int(11) DEFAULT '0',
  `deliverable_format` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deliverable_resolution` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deliverable_resolution_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_intended_uses_on_description` (`description`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `intended_uses` WRITE;
/*!40000 ALTER TABLE `intended_uses` DISABLE KEYS */;

INSERT INTO `intended_uses` (`id`, `description`, `is_internal_use_only`, `is_approved`, `created_at`, `updated_at`, `units_count`, `deliverable_format`, `deliverable_resolution`, `deliverable_resolution_unit`)
VALUES
	(100,'Classroom Instruction',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:21',310,'jpeg','300','dpi'),
	(101,'Digital Archive',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:06',2666,'tiff','Highest Possible','dpi'),
	(102,'GIS Processing',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:06',72,'tiff','Highest Possible','dpi'),
	(103,'Online Exhibit',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:21',255,'jpeg','300','dpi'),
	(104,'Personal Research',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:21',1774,'jpeg','300','dpi'),
	(105,'Physical Exhibit',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:06',1192,'tiff','Highest Possible','dpi'),
	(106,'Presentation',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:21',407,'jpeg','300','dpi'),
	(107,'Print Publication (academic)',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:06',1332,'tiff','Highest Possible','dpi'),
	(108,'Print Publication (non-academic)',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:06',999,'tiff','Highest Possible','dpi'),
	(109,'Web Publication',0,1,'2010-03-15 17:59:44','2012-05-30 21:18:21',654,'jpeg','300','dpi'),
	(110,'Digital Collection Building',1,1,'2010-03-15 18:04:53','2010-03-15 18:04:53',20265,NULL,NULL,NULL),
	(111,'Sharing with Colleagues',0,1,'2011-01-19 17:10:23','2012-05-30 21:18:21',76,'jpeg','300','dpi');

/*!40000 ALTER TABLE `intended_uses` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table invoices
# ------------------------------------------------------------

DROP TABLE IF EXISTS `invoices`;

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0',
  `date_invoice` datetime DEFAULT NULL,
  `invoice_content` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `invoice_number` int(11) DEFAULT NULL,
  `fee_amount_paid` int(11) DEFAULT NULL,
  `date_fee_paid` datetime DEFAULT NULL,
  `date_second_notice_sent` datetime DEFAULT NULL,
  `transmittal_number` text COLLATE utf8_unicode_ci,
  `notes` text COLLATE utf8_unicode_ci,
  `invoice_copy` mediumblob,
  `permanent_nonpayment` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_invoices_on_order_id` (`order_id`),
  CONSTRAINT `invoices_order_id_fk` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table legacy_identifiers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `legacy_identifiers`;

CREATE TABLE `legacy_identifiers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `legacy_identifier` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_legacy_identifiers_on_label` (`label`),
  KEY `index_legacy_identifiers_on_legacy_identifier` (`legacy_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table legacy_identifiers_master_files
# ------------------------------------------------------------

DROP TABLE IF EXISTS `legacy_identifiers_master_files`;

CREATE TABLE `legacy_identifiers_master_files` (
  `legacy_identifier_id` int(11) DEFAULT NULL,
  `master_file_id` int(11) DEFAULT NULL,
  KEY `index_legacy_identifiers_master_files_on_legacy_identifier_id` (`legacy_identifier_id`),
  KEY `index_legacy_identifiers_master_files_on_master_file_id` (`master_file_id`),
  CONSTRAINT `legacy_identifiers_master_files_legacy_identifier_id_fk` FOREIGN KEY (`legacy_identifier_id`) REFERENCES `legacy_identifiers` (`id`),
  CONSTRAINT `legacy_identifiers_master_files_master_file_id_fk` FOREIGN KEY (`master_file_id`) REFERENCES `master_files` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table legacy_identifiers_units
# ------------------------------------------------------------

DROP TABLE IF EXISTS `legacy_identifiers_units`;

CREATE TABLE `legacy_identifiers_units` (
  `legacy_identifier_id` int(11) DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  KEY `units_legacy_ids_index` (`unit_id`,`legacy_identifier_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table master_files
# ------------------------------------------------------------

DROP TABLE IF EXISTS `master_files`;

CREATE TABLE `master_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_id` int(11) NOT NULL DEFAULT '0',
  `component_id` int(11) DEFAULT NULL,
  `tech_meta_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `filename` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `filesize` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_archived` datetime DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `transcription_text` text COLLATE utf8_unicode_ci,
  `desc_metadata` text COLLATE utf8_unicode_ci,
  `rels_ext` text COLLATE utf8_unicode_ci,
  `solr` longtext COLLATE utf8_unicode_ci,
  `dc` text COLLATE utf8_unicode_ci,
  `rels_int` text COLLATE utf8_unicode_ci,
  `discoverability` tinyint(1) DEFAULT '0',
  `md5` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `indexing_scenario_id` int(11) DEFAULT NULL,
  `availability_policy_id` int(11) DEFAULT NULL,
  `automation_messages_count` int(11) DEFAULT '0',
  `use_right_id` int(11) DEFAULT NULL,
  `date_dl_ingest` datetime DEFAULT NULL,
  `date_dl_update` datetime DEFAULT NULL,
  `dpla` tinyint(1) DEFAULT '0',
  `creator_death_date` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creation_date` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `primary_author` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_master_files_on_availability_policy_id` (`availability_policy_id`),
  KEY `index_master_files_on_component_id` (`component_id`),
  KEY `index_master_files_on_date_dl_ingest` (`date_dl_ingest`),
  KEY `index_master_files_on_date_dl_update` (`date_dl_update`),
  KEY `index_master_files_on_dpla` (`dpla`),
  KEY `index_master_files_on_filename` (`filename`),
  KEY `index_master_files_on_indexing_scenario_id` (`indexing_scenario_id`),
  KEY `index_master_files_on_pid` (`pid`),
  KEY `index_master_files_on_tech_meta_type` (`tech_meta_type`),
  KEY `index_master_files_on_title` (`title`),
  KEY `index_master_files_on_unit_id` (`unit_id`),
  KEY `index_master_files_on_use_right_id` (`use_right_id`),
  CONSTRAINT `master_files_availability_policy_id_fk` FOREIGN KEY (`availability_policy_id`) REFERENCES `availability_policies` (`id`),
  CONSTRAINT `master_files_component_id_fk` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`),
  CONSTRAINT `master_files_indexing_scenario_id_fk` FOREIGN KEY (`indexing_scenario_id`) REFERENCES `indexing_scenarios` (`id`),
  CONSTRAINT `master_files_unit_id_fk` FOREIGN KEY (`unit_id`) REFERENCES `units` (`id`),
  CONSTRAINT `master_files_use_right_id_fk` FOREIGN KEY (`use_right_id`) REFERENCES `use_rights` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table orders
# ------------------------------------------------------------

DROP TABLE IF EXISTS `orders`;

CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL DEFAULT '0',
  `agency_id` int(11) DEFAULT NULL,
  `order_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_approved` tinyint(1) NOT NULL DEFAULT '0',
  `order_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_request_submitted` datetime DEFAULT NULL,
  `date_order_approved` datetime DEFAULT NULL,
  `date_deferred` datetime DEFAULT NULL,
  `date_canceled` datetime DEFAULT NULL,
  `date_permissions_given` datetime DEFAULT NULL,
  `date_started` datetime DEFAULT NULL,
  `date_due` date DEFAULT NULL,
  `date_customer_notified` datetime DEFAULT NULL,
  `fee_estimated` decimal(7,2) DEFAULT NULL,
  `fee_actual` decimal(7,2) DEFAULT NULL,
  `entered_by` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `special_instructions` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `staff_notes` text COLLATE utf8_unicode_ci,
  `email` text COLLATE utf8_unicode_ci,
  `date_patron_deliverables_complete` datetime DEFAULT NULL,
  `date_archiving_complete` datetime DEFAULT NULL,
  `date_finalization_begun` datetime DEFAULT NULL,
  `date_fee_estimate_sent_to_customer` datetime DEFAULT NULL,
  `units_count` int(11) DEFAULT '0',
  `automation_messages_count` int(11) DEFAULT '0',
  `invoices_count` int(11) DEFAULT '0',
  `master_files_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_orders_on_agency_id` (`agency_id`),
  KEY `index_orders_on_customer_id` (`customer_id`),
  KEY `index_orders_on_date_archiving_complete` (`date_archiving_complete`),
  KEY `index_orders_on_date_due` (`date_due`),
  KEY `index_orders_on_date_order_approved` (`date_order_approved`),
  KEY `index_orders_on_date_request_submitted` (`date_request_submitted`),
  KEY `index_orders_on_order_status` (`order_status`),
  CONSTRAINT `orders_agency_id_fk` FOREIGN KEY (`agency_id`) REFERENCES `agencies` (`id`),
  CONSTRAINT `orders_customer_id_fk` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8808 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;

INSERT INTO `orders` (`id`, `customer_id`, `agency_id`, `order_status`, `is_approved`, `order_title`, `date_request_submitted`, `date_order_approved`, `date_deferred`, `date_canceled`, `date_permissions_given`, `date_started`, `date_due`, `date_customer_notified`, `fee_estimated`, `fee_actual`, `entered_by`, `special_instructions`, `created_at`, `updated_at`, `staff_notes`, `email`, `date_patron_deliverables_complete`, `date_archiving_complete`, `date_finalization_begun`, `date_fee_estimate_sent_to_customer`, `units_count`, `automation_messages_count`, `invoices_count`, `master_files_count`)
VALUES
	(5341,4,NULL,'approved',1,'Daily Progress','2015-12-17 00:00:00',NULL,NULL,NULL,NULL,NULL,'2016-02-19',NULL,NULL,NULL,NULL,'','2015-12-17 15:43:27','2015-12-17 15:43:27','','--- \'\'\n',NULL,NULL,NULL,NULL,0,0,0,0),
	(8807,2554,62,'approved',1,NULL,'2015-12-02 17:19:31','2016-01-04 16:09:18',NULL,NULL,'2015-12-21 00:00:00',NULL,'2016-01-29',NULL,225.00,225.00,NULL,'Copy materials in red folders in boxes. Please copy both sides of two-sided documents.','2015-12-02 17:19:31','2016-01-19 11:52:19',NULL,NULL,NULL,NULL,'2016-01-19 11:52:19','2015-12-21 09:48:23',7,16,0,86);

/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table schema_migrations
# ------------------------------------------------------------

DROP TABLE IF EXISTS `schema_migrations`;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `schema_migrations` WRITE;
/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;

INSERT INTO `schema_migrations` (`version`)
VALUES
	('1'),
	('10'),
	('11'),
	('12'),
	('13'),
	('14'),
	('15'),
	('17'),
	('18'),
	('19'),
	('2'),
	('20'),
	('20110928162337'),
	('20110928162338'),
	('20120511001631'),
	('20120511192657'),
	('20120511213357'),
	('20120517174109'),
	('20120517215000'),
	('20120517215019'),
	('20120525145728'),
	('20120525160947'),
	('20120525165817'),
	('20120614192218'),
	('20120618141922'),
	('20120710200935'),
	('20120814202451'),
	('20121128214634'),
	('20121211165044'),
	('20130102212557'),
	('20130103174050'),
	('20130104221035'),
	('20130112175604'),
	('20130222170200'),
	('20130325230618'),
	('20130325230745'),
	('20130327193607'),
	('20130510225224'),
	('20130510231635'),
	('20130510233323'),
	('20130515143428'),
	('20131112204918'),
	('20131217222024'),
	('20131218195708'),
	('20140128080847'),
	('20140128191958'),
	('20140128200629'),
	('20140307170741'),
	('20160114210202'),
	('20160127165855'),
	('20160202160508'),
	('20160202162321'),
	('20160208213347'),
	('21'),
	('22'),
	('23'),
	('24'),
	('25'),
	('26'),
	('3'),
	('4'),
	('5'),
	('6'),
	('7'),
	('8'),
	('9'),
	('98'),
	('99');

/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table sessions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `sessions`;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;

INSERT INTO `sessions` (`id`, `session_id`, `data`, `created_at`, `updated_at`)
VALUES
	(1,'17eeddb909728a597a6a4c9996191ec0','BAh7B0kiEF9jc3JmX3Rva2VuBjoGRUZJIjFHZkV4dWR2WENTSFl3S0g2M3FP\nRHIwcitZTmdCRnVka2gwc2JFeW8xNDQwPQY7AEZJIgpmbGFzaAY7AFRvOiVB\nY3Rpb25EaXNwYXRjaDo6Rmxhc2g6OkZsYXNoSGFzaAk6CkB1c2VkbzoIU2V0\nBjoKQGhhc2h7BjoLbm90aWNlVDoMQGNsb3NlZEY6DUBmbGFzaGVzewY7Ckki\nXEl0ZW1zIGluIC9kaWdpc2Vydi1wcm9kdWN0aW9uL2ZpbmFsaXphdGlvbi8x\nMF9kcm9wb2ZmIGhhdmUgYmVndW4gZmluYWxpemF0aW9uIHdvcmtmbG93LgY7\nAFQ6CUBub3cw\n','2015-12-17 14:55:14','2016-01-20 13:46:27'),
	(2,'3ad85f6f7346f3b368bad3084153a2f0','BAh7BkkiEF9jc3JmX3Rva2VuBjoGRUZJIjE2clRJQi95aktOMHBrMkRROW1s\nQVlQNnU3d3pwdVoxNU82enJrV0V5OUVFPQY7AEY=\n','2016-02-09 13:18:55','2016-02-09 13:18:55');

/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table sql_reports
# ------------------------------------------------------------

DROP TABLE IF EXISTS `sql_reports`;

CREATE TABLE `sql_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sql` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table staff_members
# ------------------------------------------------------------

DROP TABLE IF EXISTS `staff_members`;

CREATE TABLE `staff_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `access_level_id` int(11) NOT NULL DEFAULT '0',
  `computing_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `automation_messages_count` int(11) DEFAULT '0',
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_staff_members_on_computing_id` (`computing_id`),
  KEY `access_level_id` (`access_level_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `staff_members` WRITE;
/*!40000 ALTER TABLE `staff_members` DISABLE KEYS */;

INSERT INTO `staff_members` (`id`, `access_level_id`, `computing_id`, `last_name`, `first_name`, `is_active`, `created_at`, `updated_at`, `automation_messages_count`, `email`)
VALUES
	(1,1,'lf6f','Lou','Foster',1,NULL,NULL,0,'lf6f@virginia.edu'),
	(2,1,'aec6v','Curley','Andrew',1,'2009-03-31 15:24:13','2013-01-16 03:41:47',18161,'andrew.curley@gmail.com');

/*!40000 ALTER TABLE `staff_members` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table unit_import_sources
# ------------------------------------------------------------

DROP TABLE IF EXISTS `unit_import_sources`;

CREATE TABLE `unit_import_sources` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_id` int(11) NOT NULL DEFAULT '0',
  `standard` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `version` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `source` longtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `index_unit_import_sources_on_unit_id` (`unit_id`),
  CONSTRAINT `unit_import_sources_unit_id_fk` FOREIGN KEY (`unit_id`) REFERENCES `units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table units
# ------------------------------------------------------------

DROP TABLE IF EXISTS `units`;

CREATE TABLE `units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0',
  `bibl_id` int(11) DEFAULT NULL,
  `heard_about_resource_id` int(11) DEFAULT NULL,
  `unit_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_materials_received` datetime DEFAULT NULL,
  `date_materials_returned` datetime DEFAULT NULL,
  `unit_extent_estimated` int(11) DEFAULT NULL,
  `unit_extent_actual` int(11) DEFAULT NULL,
  `patron_source_url` text COLLATE utf8_unicode_ci,
  `special_instructions` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `intended_use_id` int(11) DEFAULT NULL,
  `exclude_from_dl` tinyint(1) NOT NULL DEFAULT '0',
  `staff_notes` text COLLATE utf8_unicode_ci,
  `use_right_id` int(11) DEFAULT NULL,
  `date_queued_for_ingest` datetime DEFAULT NULL,
  `date_archived` datetime DEFAULT NULL,
  `date_patron_deliverables_ready` datetime DEFAULT NULL,
  `include_in_dl` tinyint(1) DEFAULT '0',
  `date_dl_deliverables_ready` datetime DEFAULT NULL,
  `remove_watermark` tinyint(1) DEFAULT '0',
  `master_file_discoverability` tinyint(1) DEFAULT '0',
  `indexing_scenario_id` int(11) DEFAULT NULL,
  `checked_out` tinyint(1) DEFAULT '0',
  `availability_policy_id` int(11) DEFAULT NULL,
  `master_files_count` int(11) DEFAULT '0',
  `automation_messages_count` int(11) DEFAULT '0',
  `index_destination_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_units_on_availability_policy_id` (`availability_policy_id`),
  KEY `index_units_on_bibl_id` (`bibl_id`),
  KEY `index_units_on_date_archived` (`date_archived`),
  KEY `index_units_on_date_dl_deliverables_ready` (`date_dl_deliverables_ready`),
  KEY `index_units_on_heard_about_resource_id` (`heard_about_resource_id`),
  KEY `index_units_on_indexing_scenario_id` (`indexing_scenario_id`),
  KEY `index_units_on_intended_use_id` (`intended_use_id`),
  KEY `index_units_on_order_id` (`order_id`),
  KEY `index_units_on_use_right_id` (`use_right_id`),
  CONSTRAINT `units_availability_policy_id_fk` FOREIGN KEY (`availability_policy_id`) REFERENCES `availability_policies` (`id`),
  CONSTRAINT `units_bibl_id_fk` FOREIGN KEY (`bibl_id`) REFERENCES `bibls` (`id`),
  CONSTRAINT `units_heard_about_resource_id_fk` FOREIGN KEY (`heard_about_resource_id`) REFERENCES `heard_about_resources` (`id`),
  CONSTRAINT `units_indexing_scenario_id_fk` FOREIGN KEY (`indexing_scenario_id`) REFERENCES `indexing_scenarios` (`id`),
  CONSTRAINT `units_intended_use_id_fk` FOREIGN KEY (`intended_use_id`) REFERENCES `intended_uses` (`id`),
  CONSTRAINT `units_order_id_fk` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  CONSTRAINT `units_use_right_id_fk` FOREIGN KEY (`use_right_id`) REFERENCES `use_rights` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=33530 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `units` WRITE;
/*!40000 ALTER TABLE `units` DISABLE KEYS */;

INSERT INTO `units` (`id`, `order_id`, `bibl_id`, `heard_about_resource_id`, `unit_status`, `date_materials_received`, `date_materials_returned`, `unit_extent_estimated`, `unit_extent_actual`, `patron_source_url`, `special_instructions`, `created_at`, `updated_at`, `intended_use_id`, `exclude_from_dl`, `staff_notes`, `use_right_id`, `date_queued_for_ingest`, `date_archived`, `date_patron_deliverables_ready`, `include_in_dl`, `date_dl_deliverables_ready`, `remove_watermark`, `master_file_discoverability`, `indexing_scenario_id`, `checked_out`, `availability_policy_id`, `master_files_count`, `automation_messages_count`, `index_destination_id`)
VALUES
	(33529,8807,8153,NULL,'approved','2015-12-29 00:00:00',NULL,NULL,4,NULL,'Pages to Digitize: 4\r\nCall Number: 5950\r\nTitle: Dos Passos papers\r\nVolumne: Box 122\r\n\r\nStaff Note: DO NOT SCAN BLANK VERSOS. \r\n','2015-12-02 17:19:31','2016-01-18 14:44:51',104,0,NULL,NULL,NULL,NULL,NULL,0,NULL,0,0,NULL,0,NULL,4,28,NULL);

/*!40000 ALTER TABLE `units` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table use_rights
# ------------------------------------------------------------

DROP TABLE IF EXISTS `use_rights`;

CREATE TABLE `use_rights` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `bibls_count` int(11) DEFAULT '0',
  `components_count` int(11) DEFAULT '0',
  `master_files_count` int(11) DEFAULT '0',
  `units_count` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_use_rights_on_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;



# Dump of table versions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `versions`;

CREATE TABLE `versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `item_id` int(11) NOT NULL,
  `event` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `whodunnit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `object` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_versions_on_item_type_and_item_id` (`item_type`,`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `versions` WRITE;
/*!40000 ALTER TABLE `versions` DISABLE KEYS */;

INSERT INTO `versions` (`id`, `item_type`, `item_id`, `event`, `whodunnit`, `object`, `created_at`)
VALUES
	(4,'Customer',4,'create','Unknown',NULL,'2015-12-17 15:17:02'),
	(5,'Customer',5,'create','Unknown',NULL,'2015-12-17 15:37:50');

/*!40000 ALTER TABLE `versions` ENABLE KEYS */;
UNLOCK TABLES;



/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
