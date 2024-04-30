/*
 SQL PROJECT - ENGETO DATOVÁ AKADEMIE (START 22/02/2024) - MARIAN KOUTNÝ
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
-------------------------------------------------------------------------------------------------------------------
/*
2. Vytvoření pomocných tabulek, pomoci kterých se dostanu k první finální tabulce:
 */


/*
2a) Vývoj průměrných platů v jednotlivých odvětvích - pomocná tabulka t_mk_wage:
 */

CREATE OR REPLACE TABLE t_mk_wage AS (
SELECT 
	cpib.name AS branch,
	cp.payroll_year,
	round(sum (value)/count (payroll_year),0) AS avg_wage_per_branch
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
ON cp.industry_branch_code = cpib.code
WHERE value_type_code = 5958 AND industry_branch_code IS NOT NULL
GROUP BY cpib.name, cp.payroll_year
);

SELECT * FROM t_mk_wage tmw;


/*
2b) Vývoj cen jednotlivých potravin v daných letech a krajích - tabulka t_mk_price:
 */

CREATE OR REPLACE TABLE t_mk_price AS (
SELECT 
	cpc.name AS food,
	year(cp.date_from) AS rok,
	cr.name AS region,
	round(sum(cp.value)/count(YEAR(cp.date_from)),2) AS avg_price
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


/*
2c) Vývoj ceny potravin v jednotlivých letech (průmerováno za všechny kraje) - pomocná tabulka t_mk_extra:
 */

CREATE OR REPLACE TABLE t_mk_extra AS (
SELECT 
	tmp.food AS foodstuff,
	tmp.rok AS rok,round(sum(tmp.avg_price)/count(tmp.rok),2) AS avg_price_year
FROM t_mk_price tmp
WHERE tmp.region IS NOT NULL
GROUP BY tmp.food, tmp.rok
ORDER BY tmp.rok, tmp.food
);
 

SELECT * FROM t_mk_wage tmw;
SELECT * FROM t_mk_extra tme;


/*
3. Vytvoření první finální tabulky t_Marian_Koutny_project_SQL_primary_final:
 */

CREATE OR REPLACE TABLE t_Marian_Koutny_project_SQL_primary_final AS (
SELECT
	tmw.branch,
	tmw.payroll_year,
	tmw.avg_wage_per_branch,
	tme.foodstuff,
	tme.avg_price_year
FROM t_mk_wage tmw
LEFT JOIN t_mk_extra tme ON tmw.payroll_year = tme.rok
);

/*
3a) Modifikace sloupce a vytvoření indexu:
 */

ALTER TABLE t_marian_koutny_project_sql_primary_final 
MODIFY COLUMN branch varchar(70);

CREATE OR REPLACE INDEX i_tm_branch ON t_marian_koutny_project_sql_primary_final(branch);

SELECT * FROM t_marian_koutny_project_sql_primary_final tm;



/*
4. Vytvoření pomocné tabulky pro sekundární tabulku projektu:
 */

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
WHERE c.government_type NOT LIKE '%Territory%' and c.government_type NOT LIKE '%of%'
and c.government_type NOT LIKE '%administrated%'and c.government_type NOT LIKE '%occupied%'
AND e.GDP IS NOT NULL  AND e.`year` BETWEEN 2000 AND 2021
ORDER BY e.country ASC, e.`year` DESC 
);

SELECT * FROM t_ec te;


/*
5. Vytvoření druhé finální tabulky t_marian_koutny_project_sql_secondary_final:
 */

CREATE OR REPLACE TABLE t_marian_koutny_project_sql_secondary_final AS (
SELECT 
	te.country, 
	round(te.GDP,0) AS GDP,
	te.YEAR AS cur_year, 
	te2.YEAR as year_prev,
	round( ( te.GDP - te2.GDP ) / te2.GDP * 100, 2 ) as GDP_growth,
	te.population AS population_cur_y,
	te.gini
FROM t_ec te 
JOIN t_ec te2 
    ON te.country = te2.country 
    AND te.YEAR - 1 = te2.YEAR
    AND te.year <= 2019
WHERE te.continent = 'Europe');

SELECT * FROM t_marian_koutny_project_sql_secondary_final ts;


/*
5a) DROP již nepotřebných pomocných tabulek
 */
DROP TABLE t_mk_extra;
DROP TABLE t_mk_price;
DROP TABLE t_mk_wage;
DROP TABLE t_ec;


/*5b) Náhled do obou finálních tabulek
 */

SELECT * FROM t_marian_koutny_project_sql_primary_final tm;
SELECT * FROM t_marian_koutny_project_sql_secondary_final ts;



/*
 * Prumerne platy v jednotlivych letech (nerozliseno na odvetvi)
 */
SELECT 
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary,
	tm.payroll_year 
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL 
GROUP BY  tm.payroll_year;

------------------------------------------------------------------------------------------------------
/*
VÝZKUMNÉ OTÁZKY PRO ANALYTICKÉ ODDĚLENÍ
 */

/*
 * 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 */

-- Rust prumerneho platu v danych letech (nezohledneno odvetvi)
SELECT 
	tm.payroll_year AS prev_year,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary_prev_year,
	tm2.payroll_year AS current_year,
	round(avg(tm2.avg_wage_per_branch),0) AS avg_salary_current_year,
	round(((avg(tm2.avg_wage_per_branch) - avg(tm.avg_wage_per_branch))/avg(tm.avg_wage_per_branch))*100,2) AS salary_raise
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON
tm2.payroll_year -1 = tm.payroll_year
AND tm2.branch = tm.branch
WHERE tm.avg_price_year IS NOT NULL 
GROUP BY  tm.payroll_year, tm2.payroll_year;


/*
 * a) Celkový růst mezd v jednotlivých odvětvích mezi roky 2000 a 2021
 */

SELECT DISTINCT 
	tm.branch,
	tm.avg_wage_per_branch AS salary_2021,
	tm2.avg_wage_per_branch AS salary_2000,
	round((tm.avg_wage_per_branch-tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch*100,2) as tota_salary_growth_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.payroll_year -21 = tm2.payroll_year
AND tm.branch = tm2.branch
ORDER BY round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) DESC, 
tm.branch, tm.payroll_year;


/*
 * b) Růst/pokles mezd v odvětvích po jednoletých letech (2000 až 2021)
 */

SELECT DISTINCT 
	tm.branch,
	tm.payroll_year,
--	tm.avg_wage_per_branch_year AS salary_2021,
--	tm2.avg_wage_per_branch_year AS salary_2000,
	round(sum(tm.avg_wage_per_branch)/count(tm.avg_wage_per_branch),0) AS avg_salary_all,
	round((tm.avg_wage_per_branch-tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch*100,2) as total_salary_growth_percentage
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.payroll_year -1 = tm2.payroll_year
AND tm.branch = tm2.branch
GROUP BY tm.payroll_year,tm.branch,round((tm.avg_wage_per_branch-tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch*100,2)
ORDER BY tm.branch,tm.payroll_year,
round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch) / tm2.avg_wage_per_branch * 100, 2 ) DESC;

SELECT DISTINCT 
	tm.branch,
	tm.payroll_year AS cur_year,
	tm.avg_wage_per_branch AS salary_cur_year,
	tm2.payroll_year AS prev_year,
	tm2.avg_wage_per_branch AS salary_prev_year,
	round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) as salary_raise_pct,
	CASE 
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) > 0 THEN 'Mzda roste'
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) = 0 THEN 'Mzda stagnuje'
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) < 0 THEN 'Mzda klesá'
	END AS Increase_Decrease_of_salary
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.payroll_year -1 = tm2.payroll_year
AND tm.branch = tm2.branch
ORDER BY tm.branch, tm.payroll_year;


/*
 * c) Odvětví a roky, v kterých mzdy klesají
 */

CREATE OR REPLACE VIEW v_mk AS (
SELECT DISTINCT
	tm.branch,
	tm.payroll_year AS cur_year,
	tm.avg_wage_per_branch AS salary_cur_year,
	tm2.payroll_year AS prev_year,
	tm2.avg_wage_per_branch AS salary_prev_year,
	round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) as salary_growth,
	CASE 
		WHEN round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) > 0 THEN 'Mzda roste'
		WHEN round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) = 0 THEN 'Mzda stagnuje'
		WHEN round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) < 0 THEN 'Mzda klesá'
	END AS salary_decrease
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 
ON tm.branch = tm2.branch
    AND tm.payroll_year -1 = tm2.payroll_year
WHERE round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 )<0
ORDER BY tm.payroll_year, round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) ASC, 
tm.branch
);

SELECT 
	vm.branch,
	vm.cur_year,
	vm.salary_growth AS salary_decrease_pct
FROM v_mk vm
ORDER BY vm.branch, vm.cur_year;

SELECT 
	vm.cur_year,
	count (*) AS No_of_branches_w_salary_decrease
FROM v_mk vm
GROUP BY vm.cur_year;

SELECT 
	vm.branch,
	count (*) AS How_many_times_salary_decreased_in_branch
FROM v_mk vm
GROUP BY vm.branch
ORDER BY count (*) DESC;


/*
 * 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 */


SELECT 
	tm.payroll_year,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch),0) AS average_salary,
	tm.avg_price_year AS price_of_bread_per_kg,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch)/tm.avg_price_year,0) AS Kgs_of_bread_we_can_buy
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL AND tm.foodstuff = 'Chléb konzumní kmínový'
AND tm.payroll_year IN (2006,2018)
GROUP BY tm.payroll_year, tm.avg_price_year;

SELECT 
	tm.payroll_year,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch),0) AS average_salary,
	tm.avg_price_year AS price_milk_per_liter,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch)/tm.avg_price_year,0) AS Litres_of_milk_we_can_buy
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL AND tm.foodstuff = 'Mléko polotučné pasterované'
AND tm.payroll_year IN (2006,2018)
GROUP BY tm.payroll_year, tm.avg_price_year;

SELECT 
	tm.branch,
	tm.payroll_year,
	tm.avg_wage_per_branch,
	tm.foodstuff,
	tm.avg_price_year,
	round (tm.avg_wage_per_branch/tm.avg_price_year,0) AS how_much
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.foodstuff IN ('Mléko polotučné pasterované','Chléb konzumní kmínový')
AND tm.payroll_year IN (2006,2018)
ORDER BY tm.payroll_year ,tm.foodstuff, round (tm.avg_wage_per_branch/tm.avg_price_year,0)DESC, tm.branch;


SELECT DISTINCT 
	tm.branch,
	tm.payroll_year,
	tm.avg_wage_per_branch,
	tm.foodstuff,
	tm.avg_price_year,
	max (round (tm.avg_wage_per_branch/tm.avg_price_year,0)) AS how_much
--	min (round (tm.avg_wage_per_branch_year/tm.avg_price_year,0)) AS how_much
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.foodstuff = 'Chléb konzumní kmínový'
AND tm.payroll_year = 2006
GROUP BY tm.branch,tm.payroll_year,tm.avg_wage_per_branch,tm.foodstuff,tm.avg_price_year
ORDER BY round (tm.avg_wage_per_branch/tm.avg_price_year,0)DESC, tm.branch,tm.foodstuff,tm.payroll_year
LIMIT 1;


/*
 * 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
*/


SELECT DISTINCT 
 	tm2.payroll_year AS start_year,
 	tm.payroll_year AS end_year,
	tm.foodstuff AS item,
	tm2.avg_price_year AS price_start_year,
	tm.avg_price_year AS price_end_year,
	round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) as price_increase_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
AND tm.payroll_year -1 = tm2.payroll_year
WHERE tm.avg_price_year IS NOT NULL
ORDER BY round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) ASC,tm.foodstuff, tm.payroll_year
LIMIT 1;


SELECT DISTINCT
	tm.foodstuff AS item,
	tm2.avg_price_year AS price_2006,
	tm.avg_price_year AS price_2018,
	round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) as price_increase
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
AND tm.payroll_year -12 = tm2.payroll_year
WHERE tm.avg_price_year IS NOT NULL
ORDER BY round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) ASC, tm.foodstuff;



/*
 * 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
*/


-- Prumerny plat v danem roce ve vsech odvetvich dohromady
SELECT 
	tm.payroll_year,
	round(sum(tm.avg_wage_per_branch)/count(tm.avg_wage_per_branch),0) AS avg_slr_year
FROM t_marian_koutny_project_sql_primary_final tm
-- WHERE tm.avg_price_year IS NOT NULL
GROUP BY tm.payroll_year;


SELECT 
	tm.branch,
	tm.payroll_year,
	tm.foodstuff,
	round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) AS price_raise,
	tm.avg_wage_per_branch,
	round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch) / tm2.avg_wage_per_branch * 100, 2 ) AS salary_raise,
	round((tm.avg_price_year-tm2.avg_price_year)/tm2.avg_price_year*100,2) - round((tm.avg_wage_per_branch- tm2.avg_wage_per_branch) / tm2.avg_wage_per_branch * 100, 2 ) AS diff
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.branch = tm2.branch
	AND tm.foodstuff = tm2.foodstuff
    AND tm.payroll_year -1 = tm2.payroll_year
WHERE round((tm.avg_price_year-tm2.avg_price_year)/tm2.avg_price_year*100,2)-round((tm.avg_wage_per_branch-tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch*100,2)>10
ORDER BY round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) - round(( tm.avg_wage_per_branch - tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch * 100,2) DESC,
tm.payroll_year;



/*
 *5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
 *projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
*/

SELECT * FROM countries c WHERE continent = 'Europe' AND government_type NOT LIKE '%Dependent%'
AND government_type NOT LIKE '%Independent%' AND  government_type NOT LIKE '%part%' AND country = 'Liechtenstein';

SELECT * FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.foodstuff = 'Papriky';
SELECT * FROM t_marian_koutny_project_sql_secondary_final ts;
WHERE ts.cur_year = 1999;
SELECT
count (DISTINCT ts.country)
FROM t_marian_koutny_project_sql_secondary_final ts;

SELECT
	tm.branch,
	tm.payroll_year AS `year`,
	tm.avg_wage_per_branch AS salary,
	tm.foodstuff,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) AS pr_up,
	ts.GDP_growth AS GDPup,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) - ts.GDP_growth AS pr_GDP_d,
	round(( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) AS wage_up,
	round(( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2) - ts.GDP_growth AS w_GDP_d
--	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) - round( ( tm.avg_wage_per_branch_year - tm2.avg_wage_per_branch_year ) / tm2.avg_wage_per_branch_year * 100, 2 ) AS diff
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.branch = tm2.branch
	AND tm.foodstuff = tm2.foodstuff
    AND tm.payroll_year -1 = tm2.payroll_year
JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year = ts.cur_year
WHERE ts.country = 'Czech republic'
ORDER BY round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) - ts.GDP_growth DESC,
round(( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2) - ts.GDP_growth DESC;