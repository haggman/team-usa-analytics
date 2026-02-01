# Team USA Analytics

AI-powered sports analytics platform built on Google Cloud. Hands-on lab exploring Colab Enterprise, BigQuery, BigQuery ML, AlloyDB vector search, and ADK.

## Repository Structure

```
team-usa-analytics/
├── terraform/          # Infrastructure as Code (AlloyDB, networking, APIs)
├── notebooks/          # Colab Enterprise notebooks (data exploration, AlloyDB setup)
├── agent/              # ADK agent starter code
├── solution/           # Complete working solutions
│   ├── notebooks/
│   └── agent/
└── README.md
```

## Data

Lab data is hosted on Google Cloud Storage:
- `gs://class-demo/team-usa/final/team_usa_athletes.csv` — 12,222 athletes × 29 columns
- `gs://class-demo/team-usa/final/team_usa_results.csv` — 24,945 results × 10 columns
