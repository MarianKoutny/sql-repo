/*
 * SQL PROJECT ENGETO MARIAN KOUTNÝ
 */


/*
1. Výpis tabulek potřebných k projektu:
 */

SELECT * FROM czechia_region cr;
SELECT * FROM czechia_district cd;
SELECT * FROM czechia_price_category cpc ORDER BY name ASC ;
SELECT * FROM czechia_price cp;
SELECT * FROM czechia_payroll cp;
SELECT * FROM czechia_payroll_industry_branch cpib;
SELECT * FROM czechia_payroll_calculation cpc; 
SELECT * FROM czechia_payroll_unit cpu;
SELECT * FROM czechia_payroll_value_type cpvt;
SELECT * FROM countries c;
SELECT * FROM economies e;

/*
2. Seznámení se s tabulkami, spočtění průměrných mezd, cen atd.
 */


/* 
2a) Průměrná mzda v jednotlivých oborech za dané roky. (kód 200)
 */

SELECT 
	round (sum (cp.value)/count(cp.payroll_year),0) AS average_salary,
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
2b) Průměrné ceny potravin v daných letech a krajích
 */

SELECT 
	YEAR(cp.date_from) AS 'year',
	round(sum(cp.value)/count(YEAR(cp.date_from)),2) AS avg_price,
	cpc.name AS food,
	cr.name AS region
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
JOIN czechia_region cr
	ON cp.region_code = cr.code
GROUP BY YEAR(cp.date_from), cpc.name, cr.name
ORDER BY YEAR(cp.date_from), cpc.name, cr.name ASC;


/*
2c) Průměrná cena jednotlivých potravin v daných letech (nerozděleno na kraje)
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


-------------------------------------------------------------------------------------------------------------------



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

SELECT * FROM t_mk_wage tmw;

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
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
JOIN czechia_region cr
	ON cp.region_code = cr.code
WHERE cr.name IS NOT NULL
GROUP BY cpc.name, cr.name, YEAR(cp.date_from)
ORDER BY rok, food
);
 
SELECT * FROM t_mk_price tmp;


CREATE OR REPLACE TABLE t_mk_extra AS (
SELECT 
	round(sum(tmp.avg_price)/count(tmp.rok),2) AS avg_price_year,
	tmp.food AS food,
	tmp.rok AS rok
FROM t_mk_price tmp
WHERE tmp.region IS NOT NULL
GROUP BY tmp.food, tmp.rok
ORDER BY rok, food
);
 
SELECT * FROM t_mk_extra tme;

/*
 * Pomocná tabulka průměrných cen v daném roce v daném kraji.
 */


SELECT 
	round(avg(tmp.avg_price),2) AS food_price,
	tmp.food,
	tmp.rok
FROM t_mk_price tmp
GROUP BY tmp.food, tmp.rok;


-- DROP TABLE t_mk_price;


SELECT * FROM t_mk_price tmp;

SELECT * FROM t_mk_wage tmw;
SELECT * FROM t_mk_extra tme;

CREATE OR REPLACE TABLE t_mkf AS (
SELECT
	tmw.branch,
	tmw.payroll_year,
	tmw.avg_wage_per_branch_year,
	tme.food,
	tme.avg_price_year
FROM t_mk_wage tmw
LEFT JOIN t_mk_extra tme ON tmw.payroll_year = tme.rok
);


SELECT * FROM t_mkf tm;


ALTER TABLE t_mkf 
MODIFY COLUMN branch varchar(70);

CREATE OR REPLACE INDEX i_tm_branch ON t_mkf(branch);

SELECT 
	tm.branch,
	tm.avg_wage_per_branch_year 	
FROM t_mkf tm
WHERE tm.payroll_year IN (2001,2021);


SELECT
	tm.branch,
	tm.avg_wage_per_branch_year,
	tm.payroll_year,
	CASE 
		WHEN tm.payroll_year = 2001 THEN 'mes1'
		WHEN tm.payroll_year = 2021 THEN 'mes2'
		ELSE 'not_important'
	END AS measure,
	'mes2'-'mes1'
	-- round( ( tm.avg_wage_per_branch_year - tm2.avg_wage_per_branch_year ) / tm2.avg_wage_per_branch_year * 100, 2 ) as salary_growth_pct
FROM t_mkf tm
-- JOIN t_mkf tm2 ON tm.payroll_year -1 = tm2.payroll_year
-- AND tm.branch = tm2.branch 
-- WHERE tm.payroll_year IN (2001)
ORDER BY tm.branch, tm.payroll_year;


SELECT 
	-- tm.branch,
	tm.payroll_year,
	-- tm.avg_wage_per_branch_year,
	tm.food,
	tm.avg_price_year,
	round(tm.avg_wage_per_branch_year/tm.avg_price_year,0) AS how_much_I_can_buy,
	round(sum(tm.avg_wage_per_branch_year)/count(tm.avg_wage_per_branch_year),0) AS avg_salary_all
FROM t_mkf tm
WHERE tm.food = 'Chléb konzumní kmínový' AND tm.payroll_year IN (2006)
ORDER BY tm.branch, tm.payroll_year, tm.food;


/*
SELECT DISTINCT 
	tm.branch, 
	tm.avg_wage_per_branch_year AS wage,
	tm.payroll_year AS cur_year,
	tm2.payroll_year AS prev_year,
	round( ( tm.avg_wage_per_branch_year - tm2.avg_wage_per_branch_year ) / tm2.avg_wage_per_branch_year * 100, 2 ) as salary_growth_pct
FROM t_mkf tm
JOIN t_mkf tm2 
ON tm.payroll_year -1 = tm2.payroll_year 
AND tm.branch = tm2.branch
AND tm.payroll_year = 2017
ORDER BY tm.branch, tm.payroll_year;
*/

CREATE OR REPLACE TABLE t_ec AS (
SELECT 
	e.country,
	e.`year`,
	e.GDP 
FROM economies e
JOIN countries c ON e.country = c.country 
WHERE c.government_type NOT LIKE '%Territory%' and c.government_type NOT LIKE '%of%'
and c.government_type NOT LIKE '%administrated%'and c.government_type NOT LIKE '%occupied%'
AND e.GDP IS NOT NULL  AND e.`year` BETWEEN 1999 AND 2020
GROUP BY e.`year`, e.GDP
ORDER BY e.country ASC, e.`year` DESC 
);

SELECT * FROM t_ec te;

CREATE OR REPLACE TABLE t_secondary AS (
SELECT te.country, te.GDP, te.year, te2.YEAR as year_prev, -- pozor, chyba v referenčním příkladu
    round( ( te.GDP - te2.GDP ) / te2.GDP * 100, 2 ) as GDP_growth
FROM t_ec te 
JOIN t_ec te2 
    ON te.country = te2.country 
    AND te.YEAR - 1 = te2.YEAR
    AND te.year <= 2020
);

SELECT * FROM t_secondary ts;

SELECT * FROM t_secondary ts 
WHERE country = "Czech republic" AND ts.`year` BETWEEN 2001 AND 2020;

SELECT DISTINCT 
	avg_price,
	food,
	payroll_year
FROM t_mkf tm;