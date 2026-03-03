-- 1. Création de l'environnement métier
CREATE DATABASE IF NOT EXISTS AEROCLOUD_DB;
CREATE SCHEMA IF NOT EXISTS AEROCLOUD_DB.GOLD;
USE DATABASE AEROCLOUD_DB;
USE SCHEMA GOLD;

-- 2. Création de la table finale (Data Warehouse)
CREATE OR REPLACE TABLE FLIGHTS_ANALYTICS (
    ICAO24 STRING,
    CALLSIGN STRING,
    ORIGIN_COUNTRY STRING,
    LONGITUDE FLOAT,
    LATITUDE FLOAT,
    ALTITUDE_BARO FLOAT,
    ON_GROUND BOOLEAN,
    VELOCITY FLOAT,
    TRUE_TRACK FLOAT,
    INGESTION_TIMESTAMP TIMESTAMP
);

-- 3. Configuration du format de fichier (Databricks a écrit du Parquet sous le capot de Delta)
CREATE OR REPLACE FILE FORMAT PARQUET_FORMAT
    TYPE = PARQUET
    COMPRESSION = SNAPPY;

-- 4. Création du Stage Externe pointant vers ton Azure Data Lake
-- RAPPEL : Retire le "?" au début de ton jeton SAS si Azure l'a mis.
CREATE OR REPLACE STAGE AZURE_SILVER_STAGE
    URL = 'azure://aerocloudstorage.blob.core.windows.net/silver/flights/'
    CREDENTIALS = (AZURE_SAS_TOKEN = 'sp=rl&st=2026-03-03T15:55:38Z&se=2026-03-08T00:10:38Z&spr=https&sv=2024-11-04&sr=c&sig=jAjKlA9BVyqpKGTxiLuXkWbrrDRLCjQR3sZ7PHJ9sUQ%3D')
    FILE_FORMAT = PARQUET_FORMAT;

-- 5. Test de connexion (Si ça marche, tu verras la liste de tes fichiers .parquet !)
LIST @AZURE_SILVER_STAGE;

-- 6. Chargement des données dans la table avec gestion des erreurs
COPY INTO FLIGHTS_ANALYTICS
FROM @AZURE_SILVER_STAGE
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = 'CONTINUE';

-- 7. Vérification finale !
SELECT * FROM FLIGHTS_ANALYTICS LIMIT 100;

SELECT
    ORIGIN_COUNTRY,
    COUNT(*) AS NOMBRE_DE_VOLS
FROM
    FLIGHTS_ANALYTICS
GROUP BY
    ORIGIN_COUNTRY
ORDER BY
    NOMBRE_DE_VOLS DESC
LIMIT 10;