SELECT 
	*
FROM czechia_payroll cp;
WHERE cp.value IS NOT NULL AND cp.value_type_code = 5958 AND industry_branch_code = 'A' AND payroll_year = 2000;
WHERE industry_branch_code  IS NULL ;



SELECT * FROM countries c;
SELECT * FROM economies e;


SELECT *FROM countries c
LEFT JOIN economies e
ON e.country = c.country;


-- CREATE OR REPLACE VIEW mk AS (
SELECT 
	cp.id AS id_record,
	cp.value AS average_salary_or_No_of_people,
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
WHERE cpvt.code = 5958 AND cpib.name IS NOT NULL AND payroll_year = 2000
;
-- );


SELECT 
	industry_branch_code, 
	sum (value)/count (payroll_year),
	payroll_year
FROM czechia_payroll cp
WHERE value_type_code = 5958 AND industry_branch_code  IS NOT NULL
GROUP BY industry_branch_code, payroll_year  ;


/* 
Prumerna mzda v kazdem obdobi za dany rok, bere se prumer prepocteny s kodem 200.
Netusim, ktery vyber co predstavuje.
 */

SELECT 
	sum (cp.value)/count(cp.payroll_year) AS average_salary,
	cp.payroll_year,
	cpib.name AS industry_branch
FROM czechia_payroll cp
LEFT JOIN czechia_payroll_industry_branch cpib
	ON cp.industry_branch_code = cpib.code
LEFT JOIN czechia_payroll_calculation cpc
	ON cp.calculation_code = cpc.code
LEFT JOIN czechia_payroll_unit cpu
	ON cp.unit_code = cpu.code
LEFT JOIN czechia_payroll_value_type cpvt
	ON cp.value_type_code = cpvt.code
WHERE cpvt.code = 5958 AND cpib.name IS NOT NULL AND cpc.code = 200
GROUP BY cpib.code , cp.payroll_year;

SELECT * FROM mk;
/*WHERE mk.value_type IS NULL;*/


SELECT * FROM czechia_region cr;
SELECT * FROM czechia_price_category cpc;
SELECT * FROM czechia_district cd;
SELECT * FROM czechia_price cp;

CREATE OR REPLACE VIEW mk2 AS (
SELECT 
	cp.id,
	cp.value AS price,
	cp.category_code AS food_category,
	cpc.name AS food,
	DATE_FORMAT (cp.date_from, '%d.%m.%Y') AS date_from,
	DATE_FORMAT (cp.date_to, '%d.%m.%Y') AS date_to,
	year(cp.date_from) AS `year`,
	cp.region_code,
	cr.name AS region
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
LEFT JOIN czechia_region cr
	ON cp.region_code = cr.code
);
	


SELECT * FROM mk;
SELECT * FROM mk2;

DROP VIEW mk2;

ALTER VIEW mk2 ALTER COLUMN date_from datetime;
WHERE mk2.region IS NOT NULL
ORDER BY YEAR(date_from),MONTH(date_from), DAY(date_from);


/*tohle neni dobre*/
SELECT * FROM mk2;
LEFT JOIN mk
	ON mk2.`year` = mk.payroll_year;
 

SELECT 
	*
FROM czechia_price cp
JOIN czechia_payroll cpay
	ON year(cp.date_from)= cpay.payroll_year;
	

SELECT
	cpc.name AS food_category,
	cpib.name AS industry,
	cpay.value AS average_wages,
	cp.value AS food_price,
	cpay.payroll_year,
	date_format(cp.date_from, '%d.%m.%Y') AS price_measured_from,
	date_format(cp.date_to, '%d. %m. %Y') AS price_measured_to
FROM czechia_price cp
JOIN czechia_payroll cpay
	ON year(cp.date_from) = cpay.payroll_year
LEFT JOIN czechia_payroll_industry_branch cpib
	ON cpay.industry_branch_code = cpib.code
LEFT JOIN czechia_payroll_calculation cpc
	ON cpay.calculation_code = cpc.code
LEFT JOIN czechia_payroll_unit cpu
	ON cpay.unit_code = cpu.code
LEFT JOIN czechia_payroll_value_type cpvt
	ON cpay.value_type_code = cpvt.code
WHERE cpay.value_type_code = 5958;


CREATE INDEX i_mk ON czechia_price(id);

CREATE OR REPLACE VIEW v_mk AS (
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
WHERE cpay.unit_code = 200 OR cpay.value_type_code = 5958
);


SELECT * FROM v_mk vm
WHERE vm.avg_salary = 22281;



CREATE OR REPLACE VIEW v_mk2 AS (
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
);


SELECT * FROM v_mk2 vm2
WHERE vm2.region IS NOT NULL;


SELECT cp.id, cp.value, cp.date_from, cp.date_to, cr.name, cpc.name FROM czechia_price cp
JOIN czechia_price_category cpc
ON cp.category_code = cpc.code
JOIN czechia_region cr
ON cp.region_code = cr.code;
