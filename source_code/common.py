from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = BASE_DIR / "Bai_thuc_hanh"
OUTPUT_DIR = BASE_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

def p(name: str) -> str:
    return str(DATA_DIR / name)

def parse_movie(line):
    movie_id, title, genres = line.strip().split(",", 2)
    return movie_id, title, genres

def parse_rating(line):
    user_id, movie_id, rating, timestamp = line.strip().split(",")
    return user_id, movie_id, float(rating), int(timestamp)

def parse_user(line):
    user_id, gender, age, occupation, zipcode = line.strip().split(",")
    return user_id, gender, int(age), occupation, zipcode

def parse_occupation(line):
    occ_id, occ_name = line.strip().split(",", 1)
    return occ_id, occ_name

def load_movies(sc):
    return sc.textFile(p("movies.txt")).map(parse_movie)

def load_ratings(sc):
    r1 = sc.textFile(p("ratings_1.txt"))
    r2 = sc.textFile(p("ratings_2.txt"))
    return r1.union(r2).map(parse_rating)

def load_users(sc):
    return sc.textFile(p("users.txt")).map(parse_user)

def load_occupations(sc):
    return sc.textFile(p("occupation.txt")).map(parse_occupation)

def write_lines(filename, title, rows):
    out = OUTPUT_DIR / filename
    with open(out, "w", encoding="utf-8") as f:
        f.write(title + "\n")
        for row in rows:
            f.write(str(row) + "\n")

    print(title)
    for row in rows:
        print(row)
    print(f"Đã xuất file: {out}")