from common import load_movies, load_ratings, write_lines
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bai2").getOrCreate()
sc = spark.sparkContext
movies_rdd = load_movies(sc)
ratings_rdd = load_ratings(sc)

movie_genres_rdd = movies_rdd.map(lambda x: (x[0], x[2].split("|")))
movie_rating_rdd = ratings_rdd.map(lambda x: (x[1], x[2]))

genre_rating_pairs = (
    movie_rating_rdd
    .join(movie_genres_rdd)
    .flatMap(lambda x: [(genre, (x[1][0], 1)) for genre in x[1][1]])
)

genre_stats = (
    genre_rating_pairs
    .reduceByKey(lambda a, b: (a[0] + b[0], a[1] + b[1]))
    .mapValues(lambda v: (v[0] / v[1], v[1]))
)

top_10 = genre_stats.takeOrdered(10, key=lambda r: -r[1][0])
write_lines("output_bai2.txt", "Top 10 thể loại theo điểm rating trung bình", top_10)
