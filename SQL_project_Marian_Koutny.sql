-- ČÁST DRUHÁ - VÝZKUMNÉ OTÁZKY PRO ANALYTICKÉ ODDĚLENÍ


/*
 1. ROSTOU V PRŮBĚHU LET MZDY VE VŠECH ODVĚTVÍCH, NEBO V NĚKTERÝCH KLESAJÍ?
 */

-- 1.1 Růst průměrného platu mezi roky 2000 a 2021

SELECT 
	tm.payroll_year AS prev_year,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary_prev_year,
	tm.payroll_year +1 AS current_year,
	lead(round(avg(tm.avg_wage_per_branch),0),1) OVER (ORDER BY tm.payroll_year) AS avg_salary_current_year,
	round((lead(round(avg(tm.avg_wage_per_branch),0),1) OVER (ORDER BY tm.payroll_year) - 
	round(avg(tm.avg_wage_per_branch),0))/round(avg(tm.avg_wage_per_branch),0)*100,2) AS salary_raise_pct
FROM t_marian_koutny_project_sql_primary_final tm
GROUP BY  tm.payroll_year, tm.payroll_year+1
LIMIT 21;

-- nebo

SELECT 
	tm.payroll_year AS prev_year,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary_prev_year,
	tm2.payroll_year AS current_year,
	round(avg(tm2.avg_wage_per_branch),0) AS avg_salary_current_year,
	round(((avg(tm2.avg_wage_per_branch) - avg(tm.avg_wage_per_branch))/avg(tm.avg_wage_per_branch))*100,2) AS salary_raise_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON
tm2.payroll_year -1 = tm.payroll_year
AND tm2.branch = tm.branch
GROUP BY  tm.payroll_year, tm2.payroll_year;


-- 1.2 Přehled celkového růstu mezd v jednotlivých odvětvích za sledované období

SELECT
	tm.branch,
	tm2.avg_wage_per_branch AS salary_2000,
	tm.avg_wage_per_branch AS salary_2021,
	round((tm.avg_wage_per_branch-tm2.avg_wage_per_branch)/tm2.avg_wage_per_branch*100,2) AS total_salary_increase_pct
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.payroll_year -21 = tm2.payroll_year
AND tm.branch = tm2.branch
ORDER BY round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) DESC, 
tm.branch, tm.payroll_year;


-- 1.3 Detailní vývoj mezd v jednotlivých odvětvích v letech 2000 až 2021

SELECT DISTINCT
	tm.branch,
	tm2.payroll_year AS prev_year,
	tm2.avg_wage_per_branch AS salary_prev_year,
	tm.payroll_year AS cur_year,
	tm.avg_wage_per_branch AS salary_cur_year,
	round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) AS salary_increase_pct,
	CASE 
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) > 0 THEN 'Increase'
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) = 0 THEN 'No change'
		WHEN round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) < 0 THEN 'Decrease'
	END AS increase_decrease_of_salary
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
	round( ( tm.avg_wage_per_branch - tm2.avg_wage_per_branch ) / tm2.avg_wage_per_branch * 100, 2 ) AS salary_decrease_pct,
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
	vm.cur_year AS `year`,
	vm.salary_decrease_pct
FROM v_mk vm
ORDER BY vm.salary_decrease_pct, vm.branch, vm.cur_year;


-- 1.6 Počet odvětví, ve kterých klesaly průměrné mzdy v daných letech

SELECT
	vm.cur_year AS `year`,
	count (*) AS count_of_branches_with_salary_decrease
FROM v_mk vm
GROUP BY vm.cur_year;


-- 1.7 Přehled odvětví, která byla zasažena poklesem mezd ve sledovaném období, a četnost poklesů mezd

SELECT 
	vm.branch,
	count (*) AS frequency_of_salary_decrease_in_branch
FROM v_mk vm
GROUP BY vm.branch
ORDER BY count (*) DESC;




/*
2. KOLIK JE MOŽNÉ SI KOUPIT LITRŮ MLÉKA A KILOGRAMŮ CHLEBA ZA PRVNÍ A POSLEDNÍ SROVNATELNÉ OBDOBÍ V DOSTUPNÝCH DATECH CEN A MEZD?
 */

-- 2.1 Přehled, kolik litrů mléka a kolik kg chleba si můžeme koupit v prvním a posledním sledovaném období (roky 2006 a 2018)

WITH milk_2006 AS (
		SELECT * FROM t_marian_koutny_project_sql_primary_final tm
		WHERE tm.foodstuff = 'Mléko polotučné pasterované'
		AND tm.payroll_year = 2006
),
milk_2018 AS (
		SELECT * FROM t_marian_koutny_project_sql_primary_final tm
		WHERE tm.foodstuff = 'Mléko polotučné pasterované'
		AND tm.payroll_year = 2018
),
bread_2006 AS (
		SELECT * FROM t_marian_koutny_project_sql_primary_final tm
		WHERE tm.foodstuff = 'Chléb konzumní kmínový'
		AND tm.payroll_year = 2006
),
bread_2018 AS (
		SELECT * FROM t_marian_koutny_project_sql_primary_final tm
		WHERE tm.foodstuff = 'Chléb konzumní kmínový'
		AND tm.payroll_year = 2018
)
SELECT 
	round(sum(avg_wage_per_branch)/count(avg_wage_per_branch)/avg_price_year,0) AS litres_of_milk_or_kgs_of_bread_we_can_buy
FROM milk_2006
UNION 
SELECT 
	round(sum(avg_wage_per_branch )/count(avg_wage_per_branch)/avg_price_year,0) AS litres_of_milk_or_kgs_of_bread_we_can_buy
FROM milk_2018
UNION 
SELECT 
	round(sum(avg_wage_per_branch )/count(avg_wage_per_branch)/avg_price_year,0) AS litres_of_milk_or_kgs_of_bread_we_can_buy
FROM bread_2006
UNION 
SELECT 
	round(sum(avg_wage_per_branch )/count(avg_wage_per_branch)/avg_price_year,0) AS litres_of_milk_or_kgs_of_bread_we_can_buy
FROM bread_2018;




/*
3. KTERÁ KATEGORIE POTRAVIN ZDRAŽUJE NEJPOMALEJI (JE U NÍ NEJNIŽŠÍ PERCENTUÁLNÍ MEZIROČNÍ NÁRŮST)?
*/

-- 3.1 Potravina, která za pozorované období měla nejnižší jednoletý meziroční nárůst ceny

SELECT DISTINCT
 	tm2.payroll_year AS start_year,
 	tm.payroll_year AS end_year,
	tm.foodstuff,
	tm2.avg_price_year AS price_start_year,
	tm.avg_price_year AS price_end_year,
	round((tm.avg_price_year - tm2.avg_price_year )/tm2.avg_price_year * 100,2) as price_decrease_pct
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
4. EXISTUJE ROK, VE KTERÉM BYL MEZIROČNÍ NÁRŮST CEN POTRAVIN VÝRAZNĚ VYŠŠÍ NEŽ RŮST MEZD (VĚTŠÍ NEŽ 10 %)?
*/

-- 4.1 Vytvoření pohledu, na němž se bude porovnávat rozdíl nárůstu cen a mezd

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


-- 4.2 Rozdíl mezi růstem cen potravin a růstem mezd ve sledovaném období, kde byl růst cen potravin o více než 10% vyšší
-- než růst mezd.

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
ORDER BY vm.`year`, round((vm.avg_price_per_year - vm2.avg_price_per_year)/vm2.avg_price_per_year * 100 ,2) - 
	round((vm.avg_slr_year - vm2.avg_slr_year)/vm2.avg_slr_year *100, 2) DESC;


-- 4.3 Rozdíl mezi růstem cen a mezd v daném období vztaženo na detail v jednotlivých odvětvích

SELECT 
	tm.branch,
	tm.payroll_year,
	tm.avg_wage_per_branch,
	tm.foodstuff,
	round( ( tm.avg_price_year - tm2.avg_price_year ) / tm2.avg_price_year * 100, 2 ) AS price_raise,
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

-- 5.1 Vývoj růstu HDP a průměrné mzdy a jejich souvislost ve stejném roce

SELECT DISTINCT
	tm.payroll_year AS `year`,
	round(avg(tm.avg_wage_per_branch),0) AS avg_salary,
	ts.GDP,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2) AS salary_raise_pct,
	ts.GDP_growth AS GDP_raise_pct,
	round(((avg(tm.avg_wage_per_branch) - avg(tm2.avg_wage_per_branch))/avg(tm2.avg_wage_per_branch))*100,2)- ts.GDP_growth AS diff
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 
ON tm.payroll_year -1 = tm2.payroll_year
JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year = ts.cur_year
WHERE ts.country = 'Czech republic' AND ts.GDP_growth > 5
GROUP BY tm.payroll_year, ts.GDP_growth, ts.GDP;


-- 5.2 Vývoj růstu HDP v roce x a průměrné mzdy v roce x+1 a jejich souvislost

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
WHERE ts.country = 'Czech republic' AND ts.GDP_growth > 5
GROUP BY tm.payroll_year, ts.GDP_growth, ts.cur_year, ts.GDP;


-- 5.3 Růst HDP a cen potravin a jejich srovnání ve stejném roce 

SELECT DISTINCT 
	tm.payroll_year AS `year`,
	tm.foodstuff,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) AS price_raise_pct,
	ts.GDP_growth AS GDP_raise_pct,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) - ts.GDP_growth AS diff
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
    AND tm.payroll_year -1 = tm2.payroll_year
JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year = ts.cur_year
WHERE ts.country = 'Czech republic' AND ts.GDP_growth > 5;


-- 5.4 Růst HDP v roce x a cen potravin v roce x+1 a jejich srovnání

SELECT DISTINCT 
	tm.payroll_year AS price_year,
	tm.foodstuff,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) AS price_raise_pct,
	tm2.payroll_year AS GDP_year,
	ts.GDP_growth AS GDP_raise_pct,
	round(( tm.avg_price_year - tm2.avg_price_year)/tm2.avg_price_year*100,2) - ts.GDP_growth AS difference
FROM t_marian_koutny_project_sql_primary_final tm
JOIN t_marian_koutny_project_sql_primary_final tm2 ON tm.foodstuff = tm2.foodstuff
    AND tm.payroll_year -1 = tm2.payroll_year
JOIN t_marian_koutny_project_sql_secondary_final ts ON tm.payroll_year -1 = ts.cur_year
WHERE ts.country = 'Czech republic' AND ts.GDP_growth > 5
ORDER BY tm.foodstuff;