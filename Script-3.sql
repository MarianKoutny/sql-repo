/*
 SQL PROJECT - ENGETO DATOVÁ AKADEMIE (START 22/02/2024) - MARIAN KOUTNÝ
 */

/*
1. Výpis datových setů potřebných k projektu
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
2. Vytvoření pomocných tabulek, pomoci kterých se dostaneme k první finální tabulce
 */


/*
2a) Vývoj průměrných platů v jednotlivých odvětvích mezi lety 2000 a 2021 - pomocná tabulka t_mk_wage
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
2b) Vývoj průměrných cen jednotlivých potravin v letech 2006 až 2018 v daných krajích - tabulka t_mk_price
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
2c) Vývoj průměrných cen potravin v letech 2006 až 2018 (průměr za všechny kraje) - pomocná tabulka t_mk_price_general
 */

CREATE OR REPLACE TABLE t_mk_price_general AS (
SELECT 
	tmp.food AS foodstuff,
	tmp.rok AS rok,
	round(sum(tmp.avg_price)/count(tmp.rok),2) AS avg_price_year
FROM t_mk_price tmp
WHERE tmp.region IS NOT NULL
GROUP BY tmp.food, tmp.rok
ORDER BY tmp.rok, tmp.food
);
 

SELECT * FROM t_mk_wage tmw;
SELECT * FROM t_mk_price_general tmg;


/*
3. Vytvoření první finální tabulky t_Marian_Koutny_project_SQL_primary_final:
 */

CREATE OR REPLACE TABLE t_Marian_Koutny_project_SQL_primary_final AS (
SELECT
	tmw.branch,
	tmw.payroll_year,
	tmw.avg_wage_per_branch,
	tmg.foodstuff,
	tmg.avg_price_year
FROM t_mk_wage tmw
LEFT JOIN t_mk_price_general tmg ON tmw.payroll_year = tmg.rok
);

/*
3a) Modifikace sloupce a vytvoření indexu
 */

ALTER TABLE t_marian_koutny_project_sql_primary_final 
MODIFY COLUMN branch varchar(70);

CREATE OR REPLACE INDEX i_tm_branch ON t_marian_koutny_project_sql_primary_final(branch);


/*
4. Vytvoření pomocné tabulky pro sekundární tabulku projektu - tabulka t_ec
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
5. Vytvoření druhé finální tabulky t_marian_koutny_project_sql_secondary_final
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
    AND te.year <= 2021
WHERE te.continent = 'Europe');


/*
5a) DROP již nepotřebných pomocných tabulek
 */
DROP TABLE t_mk_price_general;
DROP TABLE t_mk_price;
DROP TABLE t_mk_wage;
DROP TABLE t_ec;


/*5b) Náhled do obou finálních tabulek
 */

SELECT * FROM t_marian_koutny_project_sql_primary_final tm;
SELECT * FROM t_marian_koutny_project_sql_secondary_final ts;


-------------------------------------------------------------------------------------------------------------------------------
/*
VÝZKUMNÉ OTÁZKY PRO ANALYTICKÉ ODDĚLENÍ
 */

/*
 1. ROSTOU V PRŮBĚHU LET MZDY VE VŠECH ODVĚTVÍCH, NEBO V NĚKTERÝCH KLESAJÍ?
 */


-- 1.1 Růst průměrného platu mezi roky 2000 a 2021

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
GROUP BY  tm.payroll_year, tm2.payroll_year;


-- 1.2 Přehled celkového růstu mezd v jednotlivých odvětvích za sledované období

SELECT DISTINCT 
	tm.branch,
	tm.avg_wage_per_branch AS salary_2021,
	tm2.avg_wage_per_branch AS salary_2000,
	round((tm.avg_wage_per_branch-tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch*100,2) as total_salary_growth_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.payroll_year -21 = tm2.payroll_year
AND tm.branch = tm2.branch
ORDER BY round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) DESC, 
tm.branch, tm.payroll_year;


-- 1.3 Detailní vývoj mezd v jednotlivých odvětvích v letech 2000 až 2021

SELECT DISTINCT
	tm.branch,
	tm.payroll_year AS cur_year,
	tm.avg_wage_per_branch AS salary_cur_year,
	tm2.payroll_year AS prev_year,
	tm2.avg_wage_per_branch AS salary_prev_year,
	round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) as salary_raise_pct,
	CASE 
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) > 0 THEN 'Increase'
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) = 0 THEN 'No change'
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) < 0 THEN 'Decrease'
	END AS Increase_Decrease_of_salary
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.payroll_year -1 = tm2.payroll_year
AND tm.branch = tm2.branch
ORDER BY tm.branch, tm.payroll_year;


-- 1.4 Odvětví a roky, v kterých mzdy klesají (vytvoření náhledu)

CREATE OR REPLACE VIEW v_mk AS (
SELECT DISTINCT
	tm.branch,
	tm.payroll_year AS cur_year,
	tm.avg_wage_per_branch AS salary_cur_year,
	tm2.payroll_year AS prev_year,
	tm2.avg_wage_per_branch AS salary_prev_year,
	round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) as salary_decrease_pct,
	CASE 
		WHEN round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) > 0 THEN 'Increase'
		WHEN round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) = 0 THEN 'No change'
		WHEN round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) < 0 THEN 'Decrease'
	END AS salary_decrease
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 
ON tm.branch = tm2.branch
    AND tm.payroll_year -1 = tm2.payroll_year
WHERE round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 )<0
ORDER BY tm.payroll_year, round((tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) ASC, 
tm.branch
);


-- 1.5 Přehled jednotlivých poklesů mezd v daných odvětvích ve sledovaném období

SELECT 
	vm.branch,
	vm.cur_year,
	vm.salary_decrease_pct,
	vm.salary_decrease
FROM v_mk vm
ORDER BY vm.salary_decrease_pct, vm.branch, vm.cur_year;


-- 1.6 Počet odvětví, ve kterých klesaly průměrné mzdy v daných letech

SELECT 
	vm.cur_year AS `year`,
	count (*) AS No_of_branches_w_salary_decrease
FROM v_mk vm
GROUP BY vm.cur_year;


-- 1.7 Přehled odvětví, která byla zasažena poklesem mezd ve sledovaném období, a četnost poklesů mezd

SELECT 
	vm.branch,
	count (*) AS How_many_times_salary_decreased_in_branch
FROM v_mk vm
GROUP BY vm.branch
ORDER BY count (*) DESC;





/*
 * 2. KOLIK JE MOŽNÉ SI KOUPIT LITRŮ MLÉKA A KILOGRAMŮ CHLEBA ZA PRVNÍ A POSLEDNÍ SROVNATELNÉ OBDOBÍ V DOSTUPNÝCH DATECH CEN A MEZD?
 */

-- 2.1 Přehled, kolik kg chleba si můžeme koupit v prvním a posledním sledovaném období (roky 2006 a 2018)

SELECT 
	tm.payroll_year AS `year`,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch),0) AS average_salary,
	tm.avg_price_year AS price_of_bread_per_kg,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch)/tm.avg_price_year,0) AS Kgs_of_bread_we_can_buy
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL AND tm.foodstuff = 'Chléb konzumní kmínový'
AND tm.payroll_year IN (2006,2018)
GROUP BY tm.payroll_year, tm.avg_price_year;


-- 2.2 Přehled, kolik litrů mléka si můžeme koupit v prvním a posledním sledovaném období (roky 2006 a 2018)

SELECT 
	tm.payroll_year AS `year`,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch),0) AS average_salary,
	tm.avg_price_year AS price_milk_per_liter,
	round(sum(tm.avg_wage_per_branch )/count(tm.avg_wage_per_branch)/tm.avg_price_year,0) AS Litres_of_milk_we_can_buy
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL AND tm.foodstuff = 'Mléko polotučné pasterované'
AND tm.payroll_year IN (2006,2018)
GROUP BY tm.payroll_year, tm.avg_price_year;


-- 2.3 Detailní rozbor, kolik kg chleba a litrů mléka si můžeme koupit podle oboru, ve kterém pracujeme v letech 2006 a 2018

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





/*
 * 3. KTERÁ KATEGORIE POTRAVIN ZDRAŽUJE NEJPOMALEJI (JE U NÍ NEJNIŽŠÍ PERCENTUÁLNÍ MEZIROČNÍ NÁRŮST)?
*/

-- pozn. Jakostní víno je z výběru odebráno pro příliš malý vzorek

-- 3.1 Potravina, která za pozorované období měla nejnižší jednoletý meziroční nárůst ceny

SELECT DISTINCT
 	tm2.payroll_year AS start_year,
 	tm.payroll_year AS end_year,
	tm.foodstuff,
	tm2.avg_price_year AS price_start_year,
	tm.avg_price_year AS price_end_year,
	round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) as price_decrease_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
AND tm.payroll_year -1 = tm2.payroll_year
WHERE tm.avg_price_year IS NOT NULL
ORDER BY round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) ASC,tm.foodstuff, tm.payroll_year
LIMIT 1;


-- 3.2 Přehled celkového zdražování jednotlivých potravin mezi lety 2006 a 2018

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
 * 4. EXISTUJE ROK, VE KTERÉM BYL MEZIROČNÍ NÁRŮST CEN POTRAVIN VÝRAZNĚ VYŠŠÍ NEŽ RŮST MEZD (VĚTŠÍ NEŽ 10 %)?
*/


-- 4.1 Prumerny plat v danem roce ve vsech odvetvich dohromady

SELECT 
	tm.payroll_year AS `year`,
	round(sum(tm.avg_wage_per_branch)/count(tm.avg_wage_per_branch),0) AS avg_slr_year
FROM t_marian_koutny_project_sql_primary_final tm
GROUP BY tm.payroll_year;


-- 4.2 Průmerná cena jednotlivých potravin v daných letech

SELECT 
	tm.payroll_year AS `year`,
	tm.foodstuff,
	round(sum(tm.avg_price_year)/count(tm.avg_price_year),2) AS avg_price_per_year
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL
GROUP BY tm.payroll_year, tm.foodstuff;


-- 4.3 Vytvoření pohledu, na němž se bude porovnávat rozdíl nárůstu cen a mezd

CREATE OR REPLACE VIEW v_mk2 AS (
SELECT 
	tm.payroll_year AS `year`,
	round(sum(tm.avg_wage_per_branch)/count(tm.avg_wage_per_branch),0) AS avg_slr_year,
	tm.foodstuff,
	round(sum(tm.avg_price_year)/count(tm.avg_price_year),2) AS avg_price_per_year
FROM t_marian_koutny_project_sql_primary_final tm
WHERE tm.avg_price_year IS NOT NULL
GROUP BY tm.payroll_year, tm.foodstuff
);


-- 4.4 Rozdíl mezi růstem cen potravin a růstem mezd ve sledovaném období

SELECT 
	vm.foodstuff,
	vm.avg_price_per_year AS price,
	vm2.avg_price_per_year AS prev_price,
	vm.`year`,
	vm2.`year` AS previous,
	vm.avg_slr_year AS salary,
	vm2.avg_slr_year AS prev_salary,
	round((vm.avg_price_per_year - vm2.avg_price_per_year)/vm2.avg_price_per_year * 100 ,2) AS price_raise_pct,
	round((vm.avg_slr_year - vm2.avg_slr_year)/vm2.avg_slr_year *100, 2) AS salary_raise_pct,
	round((vm.avg_price_per_year - vm2.avg_price_per_year)/vm2.avg_price_per_year * 100 ,2) - 
	round((vm.avg_slr_year - vm2.avg_slr_year)/vm2.avg_slr_year *100, 2) AS raise_diff
FROM v_mk2 vm
JOIN v_mk2 vm2 ON vm.`year`-1 = vm2.`year`
AND vm2.foodstuff = vm.foodstuff
WHERE round((vm.avg_price_per_year - vm2.avg_price_per_year)/vm2.avg_price_per_year * 100 ,2) - 
	round((vm.avg_slr_year - vm2.avg_slr_year)/vm2.avg_slr_year *100, 2) > 10
ORDER BY round((vm.avg_price_per_year - vm2.avg_price_per_year)/vm2.avg_price_per_year * 100 ,2) - 
	round((vm.avg_slr_year - vm2.avg_slr_year)/vm2.avg_slr_year *100, 2) DESC;


-- 4.5 Rozdíl mezi růstem cen a mezd v daném období vztaženo na detail v jednotlivých odvětvích

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
5. MÁ VÝŠKA HDP VLIV NA ZMĚNY VE MZDÁCH A CENÁCH POTRAVIN? NEBOLI, POKUD HDP VZROSTE VÝRAZNĚJI V JEDNOM ROCE, 
   PROJEVÍ SE TO NA CENÁCH POTRAVIN ČI MZDÁCH VE STEJNÉM NEBO NÁSDUJÍCÍM ROCE VÝRAZNĚJŠÍM RŮSTEM?
*/

SELECT * FROM t_marian_koutny_project_sql_secondary_final ts
WHERE ts.country = 'Czech republic';


SELECT DISTINCT 
	tm.payroll_year AS `year`,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary,
	ts.GDP,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2) AS salary_raise_pct,
	ts.GDP_growth AS GDP_raise_pct
FROM t_marian_koutny_project_sql_primary_final tm
LEFT JOIN t_marian_koutny_project_sql_primary_final tm2 
ON tm.payroll_year -1 = tm2.payroll_year
LEFT JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year = ts.cur_year
WHERE ts.country = 'Czech republic'
GROUP BY tm.payroll_year, ts.GDP_growth;

SELECT DISTINCT 
	tm.payroll_year AS `year`,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary_year,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2) AS salary_raise_pct,
	ts.cur_year AS GDP_year,
	ts.GDP,
	ts.GDP_growth AS GDP_raise_pct,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2)- ts.GDP_growth AS diff
FROM t_marian_koutny_project_sql_primary_final tm
LEFT JOIN t_marian_koutny_project_sql_primary_final tm2 
ON tm.payroll_year -1 = tm2.payroll_year
LEFT JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year -1 = ts.cur_year
WHERE ts.country = 'Czech republic'
GROUP BY tm.payroll_year, ts.GDP_growth, ts.cur_year;


-- Rust GDP v porovnani s rustem cen a mezd ve stejnem roce 

SELECT DISTINCT 
	tm.payroll_year AS `year`,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary_year,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2) AS salary_raise_pct,
	tm.foodstuff,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) AS price_raise_pct,
	ts.GDP_growth AS GDP_raise_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
    AND tm.payroll_year -1 = tm2.payroll_year
JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year = ts.cur_year
WHERE ts.country = 'Czech republic' AND ts.GDP_growth > 3
GROUP BY tm.payroll_year, tm.foodstuff, round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2), ts.GDP_growth;


-- Rust GDP v porovnani s rustem cen a mezd v dalsim roce 

SELECT DISTINCT 
	ts.cur_year,
	ts.GDP_growth AS GDP_raise_cur_year,
	tm.payroll_year AS next_year,
--	round(avg(tm.avg_wage_per_branch),0) AS avg_salary_next_year,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2) AS salary_raise_next_year_pct,
	tm.foodstuff,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) AS price_raise_next_year_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
    AND tm.payroll_year -1 = tm2.payroll_year
JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year -1 = ts.cur_year
WHERE ts.country = 'Czech republic' AND ts.GDP_growth > 4.8
GROUP BY tm.payroll_year, tm.foodstuff, round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2), 
ts.cur_year, ts.GDP_growth
ORDER BY tm.payroll_year,tm.foodstuff;