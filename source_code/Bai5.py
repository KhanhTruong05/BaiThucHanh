from common import load_ratings, load_users, load_occupations, write_lines
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bai5").getOrCreate()
sc = spark.sparkContext
ratings_rdd = load_ratings(sc)
users_rdd = load_users()
occupation_rdd = load_occupations()

ratings_by_user_rdd = ratings_rdd.map(lambda x: (x[0], x[2]))
user_occid_rdd = users_rdd.map(lambda x: (x[0], x[3]))

occ_rating_pairs = (
    ratings_by_user_rdd
    .join(user_occid_rdd)
    .map(lambda x: (x[1][1], (x[1][0], 1)))
)

occ_stats = (
    occ_rating_pairs
    .reduceByKey(lambda a, b: (a[0] + b[0], a[1] + b[1]))
    .mapValues(lambda v: (v[0] / v[1], v[1]))
)

result = occ_stats.join(occupation_rdd).map(
    lambda x: (x[0], x[1][1], x[1][0][0], x[1][0][1])
)

top_10 = result.takeOrdered(10, key=lambda r: -r[2])
write_lines("output_bai5.txt", "Top 10 nghề nghiệp theo điểm rating trung bình", top_10)
