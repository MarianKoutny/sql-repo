-- ČÁST PRVNÍ - VYTVOŘENÍ FINÁLNÍCH ZDROJOVÝCH TABULEK PRO VÝZKUMNÉ OTÁZKY

-- 1. Vytvoření pomocných tabulek, pomoci kterých se dostaneme k první finální tabulce


/*
1a) Vývoj průměrných platů v jednotlivých odvětvích mezi lety 2000 a 2021 - pomocná tabulka t_mk_wage
 */

CREATE OR REPLACE TABLE t_mk_wage AS (
SELECT
	cpib.name AS branch,
	cp.payroll_year,
	round(sum (value)/count (payroll_year),0) AS avg_wage_per_branch
FROM czechia_payroll cp
LEFT JOIN czechia_payroll_industry_branch cpib
ON cp.industry_branch_code = cpib.code
WHERE value_type_code = 5958 AND industry_branch_code IS NOT NULL
GROUP BY cpib.name, cp.payroll_year
);

SELECT * FROM t_mk_wage tmw;


/*
1b) Vývoj průměrných cen jednotlivých potravin v letech 2006 až 2018 v daných krajích - tabulka t_mk_price
 */

CREATE OR REPLACE TABLE t_mk_price AS (
SELECT 
	cpc.name AS food,
	year(cp.date_from) AS `year`,
	cr.name AS region,
	round(sum(cp.value)/count(YEAR(cp.date_from)),2) AS avg_price
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
	ON cp.region_code = cr.code
WHERE cr.name IS NOT NULL
GROUP BY cpc.name, cr.name, YEAR(cp.date_from)
ORDER BY `year`, food
);
 
SELECT * FROM t_mk_price tmp;


/*
1c) Vývoj průměrných cen potravin v letech 2006 až 2018 (průměr za všechny kraje) - pomocná tabulka t_mk_price_general
 */

CREATE OR REPLACE TABLE t_mk_price_general AS (
SELECT 
	tmp.food AS foodstuff,
	tmp.`year` AS `year`,
	round(sum(tmp.avg_price)/count(tmp.`year`),2) AS avg_price_year
FROM t_mk_price tmp
WHERE tmp.region IS NOT NULL
GROUP BY tmp.food, tmp.`year`
ORDER BY tmp.`year`, tmp.food
);
 

SELECT * FROM t_mk_wage tmw;
SELECT * FROM t_mk_price_general tmg;



-- 2. Vytvoření první finální tabulky t_Marian_Koutny_project_SQL_primary_final:

CREATE OR REPLACE TABLE t_Marian_Koutny_project_SQL_primary_final AS (
SELECT
	tmw.branch,
	tmw.payroll_year,
	tmw.avg_wage_per_branch,
	tmg.foodstuff,
	tmg.avg_price_year
FROM t_mk_wage tmw
LEFT JOIN t_mk_price_general tmg ON tmw.payroll_year = tmg.`year`
);

/*
2a) Modifikace sloupce a vytvoření indexu
 */

ALTER TABLE t_marian_koutny_project_sql_primary_final MODIFY COLUMN branch varchar(70);
CREATE OR REPLACE INDEX i_tm_branch ON t_marian_koutny_project_sql_primary_final(branch);


-- 3. Vytvoření pomocné tabulky pro sekundární tabulku projektu - tabulka t_ec

CREATE OR REPLACE TABLE t_ec AS (
SELECT 
	e.country,
	e.`year`,
	e.GDP,
	e.gini,
	e.population,
	c.continent
FROM economies e
JOIN countries c ON e.country = c.country 
WHERE c.government_type NOT LIKE '%Territory%' AND c.government_type NOT LIKE '%of%'
AND c.government_type NOT LIKE '%administrated%'AND c.government_type NOT LIKE '%occupied%'
AND e.GDP IS NOT NULL  AND e.`year` BETWEEN 2000 AND 2021
ORDER BY e.country ASC, e.`year` DESC 
);

SELECT * FROM t_ec te;


-- 4. Vytvoření druhé finální tabulky t_marian_koutny_project_sql_secondary_final

CREATE OR REPLACE TABLE t_marian_koutny_project_sql_secondary_final AS (
SELECT 
	te.country, 
	round(te.GDP,0) AS GDP,
	te.YEAR AS cur_year, 
	te2.YEAR AS year_prev,
	round( ( te.GDP - te2.GDP ) / te2.GDP * 100, 2 ) AS GDP_growth,
	te.population AS population_cur_y,
	te.gini
FROM t_ec te 
JOIN t_ec te2 
    ON te.country = te2.country 
    AND te.YEAR - 1 = te2.YEAR
    AND te.year <= 2021
WHERE te.continent = 'Europe'
);


/*
4a) DROP již nepotřebných pomocných tabulek
 */
DROP TABLE t_mk_price_general;
DROP TABLE t_mk_price;
DROP TABLE t_mk_wage;
DROP TABLE t_ec;


/* 
4b) Náhled do obou finálních tabulek
 */

SELECT * FROM t_marian_koutny_project_sql_primary_final tm;
SELECT * FROM t_marian_koutny_project_sql_secondary_final ts;