## Why use Flink over Kafka for processing data?

- Flink API makes it easier to handle:
    - checkpointing
    - job recovery
    - late-arriving data
    - windowing
    - parallelism
- Similar analogy to why use Spark vs Pandas or Polars

## When to use streaming vs batch?

- Use streaming if there is an automated process that will change something on the other end of your pipeline based on real-time data. Ex:
    - Quarantining an employee laptop that got hacked
    - Surge pricing
- Otherwise, usually not worth it to provide streaming data just for humans to look at.
- Micro-batch will be easier to maintain compared to real-time streaming.
    - For micro-batch, hourly or every 15 minutes are good choices if you are using Spark.
    - If you try to do every 5 minutes for Spark probably not worth it since takes 1 minute to kick off the Spark job anyway.
- Note that owning a streaming job is more like owning a REST server.

## Spark streaming vs Flink streaming?

- Spark streaming is micro-batch, whereas Flink is actually continuous processing.
- Spark is a pull architecture, whereas Flink is a push architecture.

## What is the best strategy for re-keying or re-partitioning the data?

- Re-keying or re-partitioning the data is cumbersome.
- With Flink, best approach is to create a new topic and dump the data there:
    - Create another job to read all data from old topic and move the data to the new topic.
    - Then have to update producers/consumers to use the new topic.
- Good to overprovision slightly, but ultimately the above migration pattern is better compared to substantially overprovisioning.
- If topics experience a lot of growth and jobs get a lot of backpressure (signal: Flink slower), then know that your job does not have enough parallelism.
    - Should only have to change the parallelism in response to backpressure at most once per month, more commonly once per quarter or once per year.

## When to use Kafka vs other alternatives like RabbitMQ?

- Kafka designed for scale.
- Kafka doesn't have the same level of guarantees like RabbitMQ, but is easier to scale and distribute Kafka.
    - Similar to analogy of when to pick PostgreSQL vs Cassandra:
    - PostgreSQL has strong ACID guarantees, whereas Cassandra has weaker guarantees.
- Kafka is often used for offline jobs, whereas RabbitMQ is great if you want the data to show up in a UI.
- Also would pick RabbitMQ if know data is not going to be very large (e.g. more than up to 10s or 100s of GBs).
- RabbitMQ can also route data in addition to being a broker, whereas Kafka is basically a giant firehose that sends data in one direction.