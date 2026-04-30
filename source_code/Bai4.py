from common import load_movies, load_ratings, load_users, write_lines
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bai4").getOrCreate()
sc = spark.sparkContext
def age_to_group(age):
    if age < 18:
        return "Under18"
    if age <= 24:
        return "18-24"
    if age <= 34:
        return "25-34"
    if age <= 44:
        return "35-44"
    if age <= 54:
        return "45-54"
    return "55+"

movies_rdd = load_movies(sc)
ratings_rdd = load_ratings(sc)
users_rdd = load_users()

movie_title_rdd = movies_rdd.map(lambda x: (x[0], x[1]))
user_age_group_rdd = users_rdd.map(lambda x: (x[0], age_to_group(x[2])))
ratings_by_user_rdd = ratings_rdd.map(lambda x: (x[0], (x[1], x[2])))

movie_age_pairs = (
    ratings_by_user_rdd
    .join(user_age_group_rdd)
    .map(lambda x: ((x[1][0][0], x[1][1]), (x[1][0][1], 1)))
)

movie_age_stats = (
    movie_age_pairs
    .reduceByKey(lambda a, b: (a[0] + b[0], a[1] + b[1]))
    .mapValues(lambda v: (v[0] / v[1], v[1]))
)

result = movie_age_stats.map(
    lambda x: (x[0][0], (x[0][1], x[1][0], x[1][1]))
).join(movie_title_rdd).map(
    lambda x: (x[0], x[1][1], x[1][0][0], x[1][0][1], x[1][0][2])
)

top_20 = result.takeOrdered(20, key=lambda r: -r[3])
write_lines("output_bai4.txt", "Top 20 movie-age_group theo điểm rating trung bình", top_20)
