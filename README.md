# dbt-jitsu
This [dbt package](https://docs.getdbt.com/docs/package-management):
* Transforms pageviews into sessions
* For User stitching please enable builtin Jitsu feature [Retroactive User Recognition](https://jitsu.com/docs/other-features/retroactive-user-recognition)


## Installation instructions
New to dbt packages? Read more about them [here](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/).
1. Include this package in your `packages.yml`
2. Run `dbt deps`
3. Include the following in your `dbt_project.yml` directly within your `vars:` block (making sure to handle indenting appropriately). **Update the value to point to your table that includes pageviews**.

```YAML
# dbt_project.yml
config-version: 2
...

vars:
  jitsu_events_table_prefix:    ##table name prefix
  project_id:                ##suffix of table name. Handy if you have separate tables per tenant
  jitsu_events_table_filter: "event_type='pageview'"      ## required if you have a single table for all events and only want to filter on pageviews

```

4. Optionally configure extra parameters by adding them to your own `dbt_project.yml` file – see [dbt_project.yml](dbt_project.yml)
   for more details:

```YAML
# dbt_project.yml
config-version: 2

...

vars:
   jitsu:
    jitsu_events_table: "{{ source('jitsu', 'pageviews') }}"
    jitsu_sessionization_trailing_window: 3
    jitsu_session_inactivity_cutoff: 30 * 60
    jitsu_pass_through_columns: ['event_type']
    jitsu_model_materialized: incremental

```
5. Execute `dbt seed` -- this project includes a CSV that must be seeded for it
   the package to run successfully.
6. Execute `dbt run --vars '{project_id: ''}' ` – the Jitsu Sessions models will get built

## Database support
This package has been tested on
PostgreSQL, ClickHouse, Redshift and BigQuery.

### ClickHouse implementation details
This package relies heavily on SQL window functions.
Because Window functions are considered as an [experimental feature in ClickHouse](https://clickhouse.tech/docs/en/sql-reference/window-functions/)
we cannot guarantee stable results of using this package with ClickHouse database

Currently, this package doesn't support incremental materialization with ClickHouse. Please set
`jitsu_model_materialized` to `table`

## Contributing
Additional contributions to this repo are very welcome!
