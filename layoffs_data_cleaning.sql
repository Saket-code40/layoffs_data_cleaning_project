-- Step 1: Load Raw Data into Staging Table

-- Create a staging table structure
CREATE TABLE world_layoffs.layoffs_staging LIKE world_layoffs.layoffs;

-- Insert raw data into staging table
INSERT INTO world_layoffs.layoffs_staging
SELECT * FROM world_layoffs.layoffs;


-- Step 2: Remove Duplicates

-- Identify duplicate rows based on key columns
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
         ) AS row_num
  FROM world_layoffs.layoffs_staging
) AS duplicates
WHERE row_num > 1;

-- Create a cleaned version of the table keeping only unique rows
DROP TABLE IF EXISTS world_layoffs.layoffs_clean;

CREATE TABLE world_layoffs.layoffs_clean AS
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
         ) AS row_num
  FROM world_layoffs.layoffs_staging
) AS temp
WHERE row_num = 1;

-- Replace old staging table with cleaned one
DROP TABLE world_layoffs.layoffs_staging;
RENAME TABLE world_layoffs.layoffs_clean TO world_layoffs.layoffs_staging;

-- Recheck for duplicates to confirm
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
       COUNT(*) AS duplicate_count
FROM world_layoffs.layoffs_staging
GROUP BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
HAVING COUNT(*) > 1;


-- Step 3: Standardize and Clean Data

-- Disable safe update mode
SET SQL_SAFE_UPDATES = 0;

-- a) Replace blank industries with NULL
UPDATE world_layoffs.layoffs_staging
SET industry = NULL
WHERE industry = '';

-- b) Fill missing industry values using other records from same company
UPDATE world_layoffs.layoffs_staging t1
JOIN world_layoffs.layoffs_staging t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- c) Standardize inconsistent industry labels
UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry IN (' Crypto Currency', 'CryptoCurrency');

-- d) Clean country values (remove trailing dot)
UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

-- e) Convert `date` column to DATE data type
UPDATE world_layoffs.layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN `date` DATE;

-- Check distinct dates
SELECT DISTINCT `date` FROM world_layoffs.layoffs_staging ORDER BY `date`;


-- Step 4: Handle NULL and Redundant Values

-- Identify rows where both total_laid_off and percentage_laid_off are NULL
SELECT * FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Count NULLs in important columns
SELECT 
  COUNT(*) AS total_rows,
  SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS null_total_laid_off,
  SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS null_percentage_laid_off,
  SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS null_funds_raised,
  SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS null_industry
FROM world_layoffs.layoffs_staging;

-- Optional: Set total_laid_off NULLs to 0 (or drop based on business logic)
UPDATE world_layoffs.layoffs_staging
SET total_laid_off = 0
WHERE total_laid_off IS NULL;

-- Remove fully null rows (useless data)
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Final Clean-Up: Drop technical helper columns
ALTER TABLE world_layoffs.layoffs_staging
DROP COLUMN row_num;

-- Final Preview
SELECT * FROM world_layoffs.layoffs_staging LIMIT 10;
