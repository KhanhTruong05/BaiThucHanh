from common import load_movies, load_ratings, OUTPUT_DIR
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bai1").getOrCreate()
sc = spark.sparkContext
movies_rdd = load_movies(sc)
ratings_rdd = load_ratings(sc)

movie_title_rdd = movies_rdd.map(lambda x: (x[0], x[1]))

movie_stats = (
    ratings_rdd
    .map(lambda x: (x[1], (x[2], 1)))
    .reduceByKey(lambda a, b: (a[0] + b[0], a[1] + b[1]))
    .mapValues(lambda v: (v[0] / v[1], v[1]))
)

result = movie_stats.join(movie_title_rdd).map(
    lambda x: (x[0], x[1][1], x[1][0][0], x[1][0][1])
)

qualified = result.filter(lambda r: r[3] >= 5)
top_10 = qualified.takeOrdered(10, key=lambda r: -r[2])
best = qualified.takeOrdered(1, key=lambda r: -r[2])

with open(OUTPUT_DIR / "output_bai1.txt", "w", encoding="utf-8") as f:
    f.write("Top 10 phim có số lượt rating >= 5 theo điểm trung bình giảm dần\n")
    for row in top_10:
        f.write(str(row) + "\n")
    f.write("\nPhim có điểm trung bình cao nhất\n")
    f.write(str(best[0]) if best else "Không có phim thỏa điều kiện")

print("Top 10 phim có số lượt rating >= 5 theo điểm trung bình giảm dần")
for row in top_10:
    print(row)
print("\nPhim có điểm trung bình cao nhất")
print(best[0] if best else "Không có phim thỏa điều kiện")
