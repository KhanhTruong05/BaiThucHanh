from common import load_movies, load_ratings, load_users, write_lines
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bai3").getOrCreate()
sc = spark.sparkContext
movies_rdd = load_movies(sc)
ratings_rdd = load_ratings(sc)
users_rdd = load_users()

movie_title_rdd = movies_rdd.map(lambda x: (x[0], x[1]))
user_gender_rdd = users_rdd.map(lambda x: (x[0], x[1]))
ratings_by_user_rdd = ratings_rdd.map(lambda x: (x[0], (x[1], x[2])))

movie_gender_pairs = (
    ratings_by_user_rdd
    .join(user_gender_rdd)
    .map(lambda x: ((x[1][0][0], x[1][1]), (x[1][0][1], 1)))
)

movie_gender_stats = (
    movie_gender_pairs
    .reduceByKey(lambda a, b: (a[0] + b[0], a[1] + b[1]))
    .mapValues(lambda v: (v[0] / v[1], v[1]))
)

result = movie_gender_stats.map(
    lambda x: (x[0][0], (x[0][1], x[1][0], x[1][1]))
).join(movie_title_rdd).map(
    lambda x: (x[0], x[1][1], x[1][0][0], x[1][0][1], x[1][0][2])
)

top_20 = result.takeOrdered(20, key=lambda r: -r[3])
write_lines("output_bai3.txt", "Top 20 movie-gender theo điểm rating trung bình", top_20)
