python3 spark_standalone.py \
    --input_green="data/pq/green/2020/*/" \
    --output="data/report-2020"

URL="spark://localhost:7077"

# NOTE: Add this to zshrc
# alias spark-submit="$SPARK_HOME/bin/spark-submit"
# NOTE: Error that Spark cannot detect schema could mean
# that Spark cannot find the input files -> make sure running
# `spark-submit` command from the directory containing `data/`
spark-submit \
    --master="${URL}" \
    spark_standalone.py \
        --input_green="data/pq/green/2021/*/" \
        --output="data/report-2021"

