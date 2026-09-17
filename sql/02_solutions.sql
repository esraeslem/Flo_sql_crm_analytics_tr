-- =====================================================================
-- FLO CRM Analytics — SQL Exercises
-- 02_solutions.sql — Questions 2 through 16, fully solved
-- =====================================================================
-- Dialect: MySQL 8.0+ (uses CTEs and window functions — RANK() OVER()).
-- Run sql/01_schema.sql first, then load the CSV (see notes there).
--
-- Every query below was verified against the real 19,945-row dataset
-- via the repo's SQLite reproduction — see scripts/run_solutions.py
-- and README.md → "Results" for the actual numbers returned.
-- =====================================================================

USE Customers;

-- ---------------------------------------------------------------------
-- Q2 — Kaç farklı müşteri alışveriş yapmış?
--      How many distinct customers made a purchase?
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT master_id) AS musteri_sayisi
FROM FLO;


-- ---------------------------------------------------------------------
-- Q3 — Toplam alışveriş sayısı ve toplam ciro.
--      Total number of orders and total revenue.
-- ---------------------------------------------------------------------
SELECT
    SUM(order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris_sayisi,
    SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS toplam_ciro
FROM FLO;


-- ---------------------------------------------------------------------
-- Q4 — Alışveriş başına ortalama ciro.
--      Average revenue per order.
-- ---------------------------------------------------------------------
SELECT
    SUM(customer_value_total_ever_offline + customer_value_total_ever_online)
    / SUM(order_num_total_ever_online + order_num_total_ever_offline) AS alisveris_basi_ort_ciro
FROM FLO;


-- ---------------------------------------------------------------------
-- Q5 — Son alışveriş kanalı (last_order_channel) kırılımında toplam
--      ciro ve alışveriş sayısı.
--      Total revenue and order count broken down by last_order_channel.
-- ---------------------------------------------------------------------
SELECT
    last_order_channel,
    SUM(order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris,
    SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS toplam_ciro
FROM FLO
GROUP BY last_order_channel
ORDER BY toplam_ciro DESC;


-- ---------------------------------------------------------------------
-- Q6 — store_type kırılımında toplam ciro.
--      Total revenue broken down by store_type.
-- ---------------------------------------------------------------------
SELECT
    store_type,
    SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS toplam_ciro
FROM FLO
GROUP BY store_type
ORDER BY toplam_ciro DESC;


-- ---------------------------------------------------------------------
-- Q7 — Yıl kırılımında alışveriş sayıları (first_order_date yılı baz
--      alınarak).
--      Order counts by year, based on the customer's first_order_date.
-- ---------------------------------------------------------------------
SELECT
    YEAR(first_order_date) AS yil,
    SUM(order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris
FROM FLO
GROUP BY YEAR(first_order_date)
ORDER BY yil;


-- ---------------------------------------------------------------------
-- Q8 — Son alışveriş kanalı kırılımında alışveriş başına ortalama ciro.
--      Average revenue per order, broken down by last_order_channel.
-- ---------------------------------------------------------------------
SELECT
    last_order_channel,
    SUM(customer_value_total_ever_offline + customer_value_total_ever_online)
    / SUM(order_num_total_ever_online + order_num_total_ever_offline) AS ort_ciro_alisveris_basi
FROM FLO
GROUP BY last_order_channel
ORDER BY ort_ciro_alisveris_basi DESC;


-- ---------------------------------------------------------------------
-- Q9 — Son 12 ayda en çok ilgi gören kategori.
--      Most popular category in the last 12 months.
--
--  interested_in_categories_12 is stored as a bracketed, comma-separated
--  list (e.g. "[ERKEK, COCUK, KADIN, AKTIFSPOR]"). We normalize it to a
--  comma-wrapped token string (",ERKEK,COCUK,KADIN,AKTIFSPOR,") so a
--  LIKE '%,COCUK,%' match can't be fooled by "AKTIFCOCUK" containing
--  "COCUK" as a substring.
-- ---------------------------------------------------------------------
WITH cat_counts AS (
    SELECT 'KADIN' AS kategori, COUNT(*) AS musteri_sayisi FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,KADIN,%'
    UNION ALL
    SELECT 'ERKEK', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,ERKEK,%'
    UNION ALL
    SELECT 'COCUK', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,COCUK,%'
    UNION ALL
    SELECT 'AKTIFCOCUK', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,AKTIFCOCUK,%'
    UNION ALL
    SELECT 'AKTIFSPOR', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,AKTIFSPOR,%'
)
SELECT * FROM cat_counts ORDER BY musteri_sayisi DESC;
-- En çok ilgi gören kategori sonuç setinin ilk satırıdır (AKTIFSPOR).


-- ---------------------------------------------------------------------
-- Q10 — En çok tercih edilen store_type.
--       Most preferred store_type.
-- ---------------------------------------------------------------------
SELECT store_type, COUNT(*) AS musteri_sayisi
FROM FLO
GROUP BY store_type
ORDER BY musteri_sayisi DESC
LIMIT 1;


-- ---------------------------------------------------------------------
-- Q11 — Son alışveriş kanalı (last_order_channel) bazında en çok ilgi
--       gören kategori ve o kategoriden kaç müşterinin alışveriş yaptığı.
--       Top category per last_order_channel, with the customer count.
--
--  Not: veri setinde kategori bazlı ciro tutulmadığından (her müşterinin
--  tek bir toplam cirosu var), "ne kadarlık alışveriş yapıldığı" o
--  kategoriyle ilgilenen müşteri/sipariş sayısı olarak hesaplanmıştır.
--  Note: the dataset has no per-category revenue field (only one total
--  per customer), so "how much was bought" is measured as the count of
--  customers/orders interested in that category.
-- ---------------------------------------------------------------------
WITH cat_counts AS (
    SELECT last_order_channel, 'KADIN' AS kategori, COUNT(*) AS musteri_sayisi FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,KADIN,%'
        GROUP BY last_order_channel
    UNION ALL
    SELECT last_order_channel, 'ERKEK', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,ERKEK,%'
        GROUP BY last_order_channel
    UNION ALL
    SELECT last_order_channel, 'COCUK', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,COCUK,%'
        GROUP BY last_order_channel
    UNION ALL
    SELECT last_order_channel, 'AKTIFCOCUK', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,AKTIFCOCUK,%'
        GROUP BY last_order_channel
    UNION ALL
    SELECT last_order_channel, 'AKTIFSPOR', COUNT(*) FROM FLO
        WHERE CONCAT(',', REPLACE(REPLACE(REPLACE(interested_in_categories_12,'[',''),']',''),' ',''), ',') LIKE '%,AKTIFSPOR,%'
        GROUP BY last_order_channel
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY last_order_channel ORDER BY musteri_sayisi DESC) AS rnk
    FROM cat_counts
)
SELECT last_order_channel, kategori, musteri_sayisi
FROM ranked
WHERE rnk = 1
ORDER BY last_order_channel;


-- ---------------------------------------------------------------------
-- Q12 — En çok alışveriş yapan kişinin ID'si.
--       ID of the customer with the most total orders.
-- ---------------------------------------------------------------------
SELECT
    master_id,
    (order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris
FROM FLO
ORDER BY toplam_alisveris DESC
LIMIT 1;


-- ---------------------------------------------------------------------
-- Q13 — En çok alışveriş yapan kişinin alışveriş başına ortalama
--       cirosu ve alışveriş sıklığı (ortalama gün).
--       For that top customer: average revenue per order and average
--       purchase frequency in days (customer lifespan / order count).
-- ---------------------------------------------------------------------
SELECT
    master_id,
    (order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris,
    (customer_value_total_ever_offline + customer_value_total_ever_online)
        / (order_num_total_ever_online + order_num_total_ever_offline) AS alisveris_basi_ort_ciro,
    DATEDIFF(last_order_date, first_order_date)
        / (order_num_total_ever_online + order_num_total_ever_offline) AS ort_alisveris_sikligi_gun
FROM FLO
ORDER BY toplam_alisveris DESC
LIMIT 1;


-- ---------------------------------------------------------------------
-- Q14 — Ciro bazında ilk 100 kişinin ortalama alışveriş sıklığı (gün).
--       Average purchase frequency (days) across the top 100 customers
--       ranked by total revenue.
-- ---------------------------------------------------------------------
SELECT AVG(
    DATEDIFF(last_order_date, first_order_date)
    / (order_num_total_ever_online + order_num_total_ever_offline)
) AS ilk100_ort_alisveris_sikligi_gun
FROM (
    SELECT last_order_date, first_order_date,
           order_num_total_ever_online, order_num_total_ever_offline
    FROM FLO
    ORDER BY (customer_value_total_ever_offline + customer_value_total_ever_online) DESC
    LIMIT 100
) AS top100;


-- ---------------------------------------------------------------------
-- Q15 — Son alışveriş kanalı (last_order_channel) kırılımında en çok
--       alışveriş yapan müşteri.
--       Top customer (by total orders) within each last_order_channel.
-- ---------------------------------------------------------------------
WITH ranked AS (
    SELECT
        master_id, last_order_channel,
        (order_num_total_ever_online + order_num_total_ever_offline) AS toplam_alisveris,
        RANK() OVER (
            PARTITION BY last_order_channel
            ORDER BY (order_num_total_ever_online + order_num_total_ever_offline) DESC
        ) AS rnk
    FROM FLO
)
SELECT last_order_channel, master_id, toplam_alisveris
FROM ranked
WHERE rnk = 1
ORDER BY last_order_channel;


-- ---------------------------------------------------------------------
-- Q16 — En son alışveriş yapan kişinin ID'si (aynı max tarihte birden
--       fazla müşteri varsa hepsi getirilir).
--       ID(s) of the most recent purchaser(s) — ties on the max date
--       are all returned.
-- ---------------------------------------------------------------------
SELECT master_id, last_order_date
FROM FLO
WHERE last_order_date = (SELECT MAX(last_order_date) FROM FLO)
ORDER BY master_id;
