#!/bin/bash
# build_prod_tables.sh
#
# Fallback script for Task 2. If the Data Engineering Agent created a pipeline
# that doesn't match the expected structure, run this script to build the
# production tables directly from the staging data.
#
# This runs the same transformations as the Dataform SQLX files — normalizing
# schemas, standardizing formats, deduplicating, and merging Olympic and
# Paralympic sources — but executes them as standard BigQuery SQL via the
# bq command-line tool.
#
# Usage:
#   cd ~/team-usa-analytics
#   chmod +x build_prod_tables.sh
#   ./build_prod_tables.sh
#
# After running, skip to Task 2.7 to validate the output.

set -euo pipefail

echo "============================================="
echo "  Building production tables from staging data"
echo "============================================="
echo ""

# -----------------------------------------------
# 1. Create the athletes production table
# -----------------------------------------------
echo "Creating team_usa.athletes..."

bq query --use_legacy_sql=false --nouse_cache '
CREATE OR REPLACE TABLE `team_usa.athletes` AS
WITH

-- Normalize Olympic athletes to canonical schema
olympic_normalized AS (
  SELECT
    athlete_id,
    TRIM(Name) AS name,
    CASE TRIM(Sex)
      WHEN '"'"'M'"'"' THEN '"'"'Male'"'"'
      WHEN '"'"'F'"'"' THEN '"'"'Female'"'"'
      ELSE TRIM(Sex)
    END AS gender,
    COALESCE(
      SAFE.PARSE_DATE('"'"'%m/%d/%Y'"'"', CAST(birth_date AS STRING)),
      SAFE.PARSE_DATE('"'"'%Y-%m-%d'"'"', CAST(birth_date AS STRING))
    ) AS birth_date,
    CAST(Height AS FLOAT64) AS height_cm,
    CAST(Weight AS FLOAT64) AS weight_kg,
    '"'"'Olympic'"'"' AS games_type,
    TRIM(Season) AS games_season,
    TRIM(Sport) AS primary_sport,
    CAST(NULL AS STRING) AS classification_code,
    CAST(first_games_year AS FLOAT64) AS first_games_year,
    CAST(last_games_year AS FLOAT64) AS last_games_year,
    CAST(games_count AS FLOAT64) AS games_count,
    CAST(Gold AS FLOAT64) AS gold_count,
    CAST(Silver AS FLOAT64) AS silver_count,
    CAST(Bronze AS FLOAT64) AS bronze_count,
    CAST(medal_total AS FLOAT64) AS total_medals,
    profile_summary,
    embedding
  FROM `team_usa_staging.stg_olympic_athletes`
),

-- Normalize Paralympic athletes to canonical schema
paralympic_normalized AS (
  SELECT
    athlete_id,
    TRIM(name) AS name,
    TRIM(gender) AS gender,
    COALESCE(
      SAFE.PARSE_DATE('"'"'%m/%d/%Y'"'"', CAST(birth_date AS STRING)),
      SAFE.PARSE_DATE('"'"'%Y-%m-%d'"'"', CAST(birth_date AS STRING))
    ) AS birth_date,
    CAST(height AS FLOAT64) AS height_cm,
    CAST(weight AS FLOAT64) AS weight_kg,
    '"'"'Paralympic'"'"' AS games_type,
    TRIM(games_season) AS games_season,
    TRIM(discipline) AS primary_sport,
    TRIM(sport_class) AS classification_code,
    CAST(first_games_year AS FLOAT64) AS first_games_year,
    CAST(last_games_year AS FLOAT64) AS last_games_year,
    CAST(games_count AS FLOAT64) AS games_count,
    CAST(gold_count AS FLOAT64) AS gold_count,
    CAST(silver_count AS FLOAT64) AS silver_count,
    CAST(bronze_count AS FLOAT64) AS bronze_count,
    CAST(total_medals AS FLOAT64) AS total_medals,
    profile_summary,
    embedding
  FROM `team_usa_staging.stg_paralympic_athletes`
),

-- Stack both sources
unioned AS (
  SELECT * FROM olympic_normalized
  UNION ALL
  SELECT * FROM paralympic_normalized
),

-- Deduplicate on athlete_id
deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY athlete_id ORDER BY name) AS _rn
  FROM unioned
)

SELECT
  athlete_id, name, gender, birth_date, height_cm, weight_kg,
  games_type, games_season, primary_sport, classification_code,
  first_games_year, last_games_year, games_count,
  gold_count, silver_count, bronze_count, total_medals,
  profile_summary, embedding
FROM deduped
WHERE _rn = 1;
'

echo "  ✅ team_usa.athletes created"
echo ""

# -----------------------------------------------
# 2. Create the results production table
# -----------------------------------------------
echo "Creating team_usa.results..."

bq query --use_legacy_sql=false --nouse_cache '
CREATE OR REPLACE TABLE `team_usa.results` AS
WITH

-- Normalize Olympic results
olympic_normalized AS (
  SELECT
    athlete_id,
    TRIM(Name) AS athlete_name,
    CAST(Year AS INT64) AS games_year,
    TRIM(Season) AS games_season,
    '"'"'Olympic'"'"' AS games_type,
    TRIM(Sport) AS sport,
    TRIM(Discipline) AS discipline,
    TRIM(Event) AS event,
    TRIM(Medal) AS medal,
    CAST(NULL AS STRING) AS classification_code
  FROM `team_usa_staging.stg_olympic_results`
),

-- Normalize Paralympic results
paralympic_normalized AS (
  SELECT
    athlete_id,
    TRIM(athlete_name) AS athlete_name,
    CAST(games_year AS INT64) AS games_year,
    TRIM(games_season) AS games_season,
    '"'"'Paralympic'"'"' AS games_type,
    TRIM(sport) AS sport,
    TRIM(discipline_name) AS discipline,
    TRIM(event) AS event,
    TRIM(medal) AS medal,
    TRIM(sport_class) AS classification_code
  FROM `team_usa_staging.stg_paralympic_results`
),

-- Stack both sources
unioned AS (
  SELECT * FROM olympic_normalized
  UNION ALL
  SELECT * FROM paralympic_normalized
),

-- Deduplicate on composite key
deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY athlete_id, games_year, event, athlete_name
      ORDER BY athlete_name
    ) AS _rn
  FROM unioned
)

SELECT
  athlete_id, athlete_name, games_year, games_season,
  games_type, sport, discipline, event, medal, classification_code
FROM deduped
WHERE _rn = 1;
'

echo "  ✅ team_usa.results created"
echo ""

# -----------------------------------------------
# 3. Quick validation
# -----------------------------------------------
echo "Validating row counts..."
echo ""

bq query --use_legacy_sql=false --nouse_cache '
SELECT '"'"'athletes'"'"' AS table_name, COUNT(*) AS row_count
FROM `team_usa.athletes`
UNION ALL
SELECT '"'"'results'"'"', COUNT(*)
FROM `team_usa.results`
ORDER BY table_name;
'

echo ""
echo "============================================="
echo "  Expected: athletes = 11,843 | results = 24,198"
echo "  If your counts match, skip to Task 2.7."
echo "============================================="
