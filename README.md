# AeroCloud Insights : End-to-End Data Pipeline

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Azure](https://img.shields.io/badge/Azure-Functions%20%7C%20ADLS%20Gen2-blue)
![Databricks](https://img.shields.io/badge/Databricks-PySpark-orange)
![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Warehouse-lightblue)
![Python](https://img.shields.io/badge/Python-3.11-yellow)

## Présentation du projet
**AeroCloud Insights** est un projet de Data Engineering complet (de l'ingestion à l'analyse) visant à traiter et analyser les données de vols en temps réel au-dessus de la France. 

Ce projet a été réalisé pour démontrer la maîtrise d'une architecture Data moderne (Architecture Medallion / Lakehouse) et l'intégration continue (DataOps) en utilisant les standards de l'industrie aéronautique et technologique (Airbus, Capgemini).

## Architecture Technique

L'architecture repose sur une approche **Medallion** (Bronze ➔ Silver ➔ Gold) répartie sur trois plateformes Cloud majeures :

1. **Ingestion (Couche Bronze) - Microsoft Azure :** * Une **Azure Function** (Python, Serverless) déclenchée par Timer interroge l'API OpenSky Network toutes les 5 minutes.
   * Les données brutes (JSON) sont ingérées dans un **Azure Data Lake Storage Gen2** (ADLS).
2. **Processing (Couche Silver) - Azure Databricks :**
   * Un cluster **Databricks** lit les données brutes en continu.
   * Un script **PySpark** s'occupe de l'aplatissement (flattening) du JSON complexe, du nettoyage des données aberrantes, et de l'ajout de métadonnées de traçabilité.
   * Les données raffinées sont stockées au format compressé **Delta Lake / Parquet**.
3. **Analytics (Couche Gold) - Snowflake :**
   * Un entrepôt de données **Snowflake** est connecté au Data Lake via un *External Stage* sécurisé par un jeton SAS.
   * Les données sont chargées et modélisées en SQL pour être prêtes à l'emploi par les outils de BI (Data Warehousing).
4. **DataOps & CI/CD - GitHub Actions :**
   * Le déploiement de l'infrastructure d'ingestion est automatisé via un workflow **GitHub Actions** à chaque *push* sur la branche principale (Remote Build sur serveur Linux Azure).

## Structure du Répertoire

```text
AeroCloud-Data-Pipeline/
├── .github/workflows/
│   └── deploy_function.yml         # CI/CD Pipeline pour le déploiement Azure
├── src/
│   ├── ingestion/                  # Code de l'Azure Function (Python)
│   │   ├── function_app.py
│   │   ├── requirements.txt
│   │   └── host.json
│   ├── processing/                 # Code de transformation Databricks
│   │   └── 01_Bronze_to_Silver_OpenSky.ipynb
│   └── analytics/                  # Scripts DDL/DML Snowflake
│       └── 02_Snowflake_Setup.sql
├── .gitignore                      # Sécurité et nettoyage de l'environnement
└── README.md
