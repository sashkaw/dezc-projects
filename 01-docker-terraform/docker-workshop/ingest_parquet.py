import pandas as pd
import click
from sqlalchemy import create_engine


def ingest_data(
    url: str,
    engine,
    target_table: str,
) -> pd.DataFrame:
    df = pd.read_parquet(path=url)

    df.head(0).to_sql(name=target_table, con=engine, if_exists="replace")

    print(f"Table {target_table} created")

    df.to_sql(name=target_table, con=engine, if_exists="append")

    print(f"Inserted data: {len(df)}")

    print(f"done ingesting to {target_table}")

    return df


@click.command()
@click.option("--pg-user", default="root", help="PostgreSQL username")
@click.option("--pg-pass", default="root", help="PostgreSQL password")
@click.option("--pg-host", default="localhost", help="PostgreSQL host")
@click.option("--pg-port", default="5432", help="PostgreSQL port")
@click.option("--pg-db", default="ny_taxi", help="PostgreSQL database name")
@click.option("--target-table", default="yellow_taxi_data", help="Target table name")
@click.option("--url-suffix", help="URL suffix")
@click.option("--file-name", help="File name")
def main(
    pg_user,
    pg_pass,
    pg_host,
    pg_port,
    pg_db,
    target_table,
    url_suffix,
    file_name,
):
    engine = create_engine(
        f"postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}"
    )

    url_prefix = f"https://d37ci6vzurychx.cloudfront.net/{url_suffix}"

    url = f"{url_prefix}/{file_name}"

    params = dict(
        url=url,
        engine=engine,
        target_table=target_table,
    )
    ingest_data(**params)


if __name__ == "__main__":
    main()
