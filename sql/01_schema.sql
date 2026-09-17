-- =====================================================================
-- FLO CRM Analytics — SQL Exercises
-- 01_schema.sql
-- =====================================================================
-- Soru 1 / Question 1:
--  "Customers isimli bir veritabanı ve verilen veri setindeki
--   değişkenleri içerecek FLO isimli bir tablo oluşturunuz."
--  -> Create a database named "Customers" and, inside it, a table
--     named "FLO" holding the dataset's variables.
--
-- Dialect: MySQL 8.0+ (works with only minor tweaks on PostgreSQL /
-- SQL Server — see notes at the bottom of this file).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS Customers;
USE Customers;

DROP TABLE IF EXISTS FLO;

CREATE TABLE FLO (
    master_id                          VARCHAR(36)     NOT NULL PRIMARY KEY,
    order_channel                      VARCHAR(20),      -- Android App, Ios App, Desktop, Mobile
    last_order_channel                 VARCHAR(20),      -- + "Offline"
    first_order_date                   DATE,
    last_order_date                    DATE,
    last_order_date_online             DATE,
    last_order_date_offline            DATE,
    order_num_total_ever_online        DECIMAL(10,2),
    order_num_total_ever_offline       DECIMAL(10,2),
    customer_value_total_ever_offline  DECIMAL(12,2),
    customer_value_total_ever_online   DECIMAL(12,2),
    interested_in_categories_12        VARCHAR(255),     -- e.g. "[KADIN, ERKEK]"
    store_type                         VARCHAR(10)       -- e.g. "A", "A,B", "A,B,C"
);

-- ---------------------------------------------------------------------
-- Loading the data (flo_data_20K.csv -> FLO)
-- ---------------------------------------------------------------------
-- Option A — MySQL server-side load (fastest, requires FILE privilege
-- and secure_file_priv access to the CSV's folder):
--
-- LOAD DATA INFILE '/path/to/data/flo_data_20K.csv'
-- INTO TABLE FLO
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;
--
-- Option B — any client tool's "Import CSV" wizard
-- (DBeaver / MySQL Workbench / TablePlus), mapping columns 1:1.
--
-- Option C — this repo's own scripts/build_database.py, which loads
-- the same CSV into a local SQLite file so the queries in
-- sql/02_solutions.sql can be verified end-to-end without a MySQL
-- server (see scripts/run_solutions.py for the SQLite-flavored run).
-- ---------------------------------------------------------------------

-- Portability notes:
--  * PostgreSQL: swap VARCHAR(36) PK generation concerns aside, this
--    schema runs as-is (CREATE DATABASE must be issued outside a
--    transaction / from a different connection).
--  * SQL Server: replace "CREATE DATABASE IF NOT EXISTS" with
--    "IF DB_ID('Customers') IS NULL CREATE DATABASE Customers;" and
--    DECIMAL syntax is unchanged.
