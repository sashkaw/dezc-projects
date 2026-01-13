## Setup

### dbt

- To install dbt core:
```
cd "04-analytics-engineering"

python3 -m venv venv

source venv/bin/activate

python -m pip install dbt-core dbt-bigquery

# Get path to dbt core installation
which dbt

nano ~/.zshrc

# Add this line to end of .zshrc file
# This avoids conflicts with dbt Cloud CLI installation
alias dbtcore="/path/to/dbt/core

source ~/.zshrc
```

- To add BigQuery connection:

    - Add service account JSON to this directory as `04-analytics-engineering/service-account.json`

    - Add below config to `~/.dbt/profiles.yml`

```
taxi_rides_ny:  # Profile name (matches dbt_project.yml)
  target: dev  # Default target to use
  outputs:
    dev: # Development environment
      type: bigquery # Required: snowflake, bigquery, databricks, redshift, postgres, etc
      method: service-account
      # Connection identifiers (placeholder examples, see adapter-specific pages for supported configs)
      project: dezc-dev
      dataset: example_dataset
      keyfile: service-account.json
      threads: 3
      location: us-west1
```
  
