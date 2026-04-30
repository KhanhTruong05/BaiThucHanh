from datetime import datetime
from common import load_ratings, write_lines
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bai6").getOrCreate()
sc = spark.sparkContext
def timestamp_to_year(timestamp):
    return datetime.utcfromtimestamp(timestamp).year

ratings_rdd = load_ratings(sc)

year_pairs = ratings_rdd.map(lambda x: (timestamp_to_year(x[3]), (x[2], 1)))

year_stats = (
    year_pairs
    .reduceByKey(lambda a, b: (a[0] + b[0], a[1] + b[1]))
    .mapValues(lambda v: (v[0] / v[1], v[1]))
    .sortByKey()
)

rows = year_stats.collect()
write_lines("output_bai6.txt", "Thống kê rating theo năm", rows)
