/*
 * Vypis tabulek potrebnych k praci.
 */

SELECT * FROM czechia_region cr;
SELECT * FROM czechia_district cd;

SELECT * FROM czechia_price_category cpc ORDER BY name ASC ;
SELECT * FROM czechia_price cp;k
WHERE category_code = 116103 AND YEAR(date_from) = 2006 AND region_code = 'CZ010';

SELECT * FROM czechia_payroll cp;
SELECT * FROM czechia_payroll_industry_branch cpib;
SELECT * FROM czechia_payroll_calculation cpc; 
SELECT * FROM czechia_payroll_unit cpu;
SELECT * FROM czechia_payroll_value_type cpvt;

SELECT * FROM countries c;
SELECT * FROM economies e WHERE country = 'Czech republic' AND GDP IS NOT NULL;

/*
 * Prumerna mzda v sektoru A pro rok 2000 pro fyzicky i prepocteny pocet.
 */

SELECT 
	*
FROM czechia_payroll cp
WHERE cp.value IS NOT NULL AND cp.value_type_code = 5958 AND industry_branch_code = 'A' AND payroll_year = 2000;


/*
 * Platy v jednotlivych sektorech v roce 2000 po ctvrtletich, oba prepocty.
 */

SELECT 
	cp.id AS id_record,
	cp.value AS average_salary,
	cp.payroll_year,
	cp.payroll_quarter,
	cpib.name AS industry_branch,
	cpc.code AS payroll_code,
	cpu.name AS unit_name
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
	ON cp.industry_branch_code = cpib.code
JOIN czechia_payroll_calculation cpc
	ON cp.calculation_code = cpc.code
JOIN czechia_payroll_unit cpu
	ON cp.unit_code = cpu.code
JOIN czechia_payroll_value_type cpvt
	ON cp.value_type_code = cpvt.code
WHERE cpvt.code = 5958 AND cpib.name IS NOT NULL AND payroll_year = 2000;


/* 
Prumerna mzda v kazdem oboru za dany rok. (Bere se prumer prepocteny s kodem 200, netusim, ktery vyber co predstavuje)
 */

SELECT 
	sum (cp.value)/count(cp.payroll_year) AS average_salary,
	cp.payroll_year,
	cpib.name AS industry_branch
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
	ON cp.industry_branch_code = cpib.code
JOIN czechia_payroll_calculation cpc
	ON cp.calculation_code = cpc.code
JOIN czechia_payroll_unit cpu
	ON cp.unit_code = cpu.code
JOIN czechia_payroll_value_type cpvt
	ON cp.value_type_code = cpvt.code
WHERE cpvt.code = 5958 AND cpib.name IS NOT NULL AND cpc.code = 200
GROUP BY cpib.code , cp.payroll_year;


/*
 * Ceny jednotlivych potravin v danych krajich podle roku
 */

CREATE TABLE t_mk_price AS (
SELECT 
	round(sum(cp.value)/count(YEAR(cp.date_from)),2) AS avg_price,
	cpc.name AS food,
	year(cp.date_from) AS `year`,
	cr.name AS region
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
	ON cp.region_code = cr.code
WHERE cr.name IS NOT NULL
GROUP BY cpc.name, cr.name, YEAR(cp.date_from)
);


/*
 * Pomocná tabulka průměrných cen v daném roce v daném kraji.
 */

SELECT * FROM t_mk_price tmp;

SELECT 
    cp.id AS id,
	cp.value AS price,
	cp.category_code AS product_code,
	cpc.name AS product_name,
	date_format(cp.date_from, '%Y-%m-%d') AS measured_from,
	date_format(cp.date_to, '%Y-%m-%d') AS measured_to,
	cp.region_code,
	cr.name AS region,
	cpay.value AS avg_salary,
	cpib.name AS branch,
	cpay.payroll_year
FROM czechia_price cp
JOIN czechia_payroll cpay
	ON YEAR(cp.date_from) = cpay.payroll_year
LEFT JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
	ON cp.region_code = cr.code
LEFT JOIN czechia_payroll_industry_branch cpib
	ON cpay.industry_branch_code = cpib.code
WHERE cpay.unit_code = 200 OR cpay.value_type_code = 5958;



SELECT 
    cp.id AS id,
	cp.value AS price,
	cp.category_code AS product_code,
	cpc.name AS product_name,
	date_format(cp.date_from, '%Y-%m-%d') AS measured_from,
	date_format(cp.date_to, '%Y-%m-%d') AS measured_to,
	cp.region_code,
	cr.name AS region,
	cpay.value AS avg_salary,
	cpib.name AS branch,
	cpay.payroll_year
FROM czechia_payroll cpay
JOIN czechia_price cp
	ON cpay.payroll_year = YEAR(cp.date_from)
LEFT JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
	ON cp.region_code = cr.code
LEFT JOIN czechia_payroll_industry_branch cpib
	ON cpay.industry_branch_code = cpib.code
WHERE cpay.unit_code = 200 OR cpay.value_type_code = 5958
ORDER BY cpib.name DESC ;


/*
 * Prumerne ceny jednotlivych potravin v roce 2006 v CR.
 */

SELECT 
	YEAR(cp.date_from) AS 'year',
	round(sum(cp.value)/count(YEAR(cp.date_from)),3) AS avg_price,
	cpc.name AS food
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE YEAR(cp.date_from)= 2006
GROUP BY cpc.name, YEAR(cp.date_from)
ORDER BY cpc.name;

/*
 * Prumerna cena potravin v jednotlivych letech.
 */

SELECT 
	YEAR(cp.date_from) AS 'year',
	round(sum(cp.value)/count(YEAR(cp.date_from)),3) AS avg_price,
	cpc.name AS food
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE cp.value IS NOT NULL
GROUP BY cpc.name, YEAR(cp.date_from)
ORDER BY cpc.name;


/*
 * Prumerne ceny potravin v danych letech a krajich
 */

SELECT 
	YEAR(cp.date_from) AS 'year',
	sum(cp.value)/count(YEAR(cp.date_from)) AS avg_price,
	cpc.name AS food,
	cr.name AS region
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
JOIN czechia_region cr
	ON cp.region_code = cr.code
GROUP BY YEAR(cp.date_from), cpc.name, cr.name
ORDER BY YEAR(cp.date_from), cpc.name, cr.name ASC;


SELECT cp.id, cp.value, cp.date_from, cp.date_to, cr.name, cpc.name FROM czechia_price cp
JOIN czechia_price_category cpc
ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
ON cp.region_code = cr.code;


SELECT
        base.date,
        (sum(base.confirmed)*1000000)/sum(a.population) as confirmed_per_milion
FROM (
          SELECT 
                date,
                country,
                confirmed 
          FROM covid19_basic cb
         ) base
LEFT JOIN 
         (
          SELECT
                  country,
                  population
          FROM lookup_table lt 
          WHERE province is null
         ) a
ON base.country = a.country
GROUP BY base.date
ORDER BY base.date;


---------------------------------------------------------------------------------------------------------------



/*
 * Prumerne platy (unit prepocteny+fyzicky, tedy kod 100 i 200) v jednotlivych odvetvich jdouci v x letech po sobe.
 */

CREATE OR REPLACE TABLE t_mk_wage AS (
SELECT 
	cpib.name AS branch, 
	round(sum (value)/count (payroll_year),0) AS avg_wage_per_branch_year,
	cp.payroll_year
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
ON cp.industry_branch_code = cpib.code
WHERE value_type_code = 5958 AND industry_branch_code IS NOT NULL
GROUP BY industry_branch_code, payroll_year
);

SELECT * FROM t_mk_wage;

/*
 * Ceny jednotlivych potravin v danych krajich podle roku
 */

CREATE OR REPLACE TABLE t_mk_price AS (
SELECT 
	round(sum(cp.value)/count(YEAR(cp.date_from)),2) AS avg_price,
	cpc.name AS food,
	year(cp.date_from) AS rok,
	cr.name AS region
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
	ON cp.region_code = cr.code
WHERE cr.name IS NOT NULL
GROUP BY cpc.name, cr.name, YEAR(cp.date_from)
);
 

/*
 * Pomocná tabulka průměrných cen v daném roce v daném kraji.
 */



ORDER BY tmp.rok ASC, tmp.food ASC ;

SELECT 
	round(avg(tmp.avg_price),2) AS food_price,
	tmp.food,
	tmp.rok
FROM t_mk_price tmp
GROUP BY tmp.food, tmp.rok;


DROP TABLE t_mk_price;


SELECT * FROM t_mk_price tmp;
SELECT * FROM t_mk_wage;

CREATE OR REPLACE TABLE t_mkf AS (
SELECT 
	tmw.branch,
	tmw.payroll_year,
	tmw.avg_wage_per_branch_year,
	tmp.food,
	tmp.avg_price,
	tmp.region
FROM t_mk_wage tmw
LEFT JOIN t_mk_price tmp ON tmw.payroll_year = tmp.rok
);


SELECT * FROM t_mkf tm;