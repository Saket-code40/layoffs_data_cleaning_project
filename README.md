# layoffs_data_cleaning_project

# 🧹 Layoffs 2022 Data Cleaning Project (SQL)

## 📁 Overview

This project involves cleaning a real-world dataset about layoffs in tech companies during 2022. The goal is to transform a messy CSV file into a clean, analysis-ready SQL table. This cleaned data can then be used for business insights, dashboarding (e.g. in Power BI or Tableau), and deeper data analysis.

---

## 🗂 Dataset

- **Source**: [Kaggle - Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
- **Fields**: Company, Location, Industry, Total Laid Off, Percentage Laid Off, Date, Stage, Country, Funds Raised (in millions)

---

## 🧰 Tools Used

- MySQL (v8+)
- SQL Window Functions
- Data Cleaning & Transformation Techniques

---

## 🎯 Project Objectives

- ✅ Remove duplicate records  
- ✅ Standardize inconsistent entries  
- ✅ Handle NULL and blank values  
- ✅ Fix date formatting  
- ✅ Clean up country/industry inconsistencies  
- ✅ Prepare the dataset for analysis

---

## ⚙️ Cleaning Steps Summary

### 1️⃣ Create Staging Table
```sql
CREATE TABLE layoffs_staging LIKE layoffs;
INSERT INTO layoffs_staging SELECT * FROM layoffs;
