# Bài Thực Hành 3 - Spark RDD

## 1. Mô tả dữ liệu

Bài này sử dụng 4 nhóm dữ liệu:

1. `movies (2).txt`
   - Schema: `MovieID, Title, Genres`
   - Ví dụ: `1001,The Godfather (1972),Crime|Drama`

2. `ratings_1 (2).txt`, `ratings_2 (2).txt`
   - Schema: `UserID, MovieID, Rating, Timestamp`
   - Hai file rating được gộp bằng `union`.

3. `users (2).txt`
   - Schema: `UserID, Gender, Age, Occupation, Zip-code`

4. `occupation.txt`
   - Schema: `ID, Occupation`

Yêu cầu của đề: thực hiện bằng **RDD**, không dùng DataFrame để xử lý chính.

---

## 2. Cách chạy bài

Đặt thư mục theo cấu trúc:

```text
BaiThucHanh3_solution/
├── Bai_thuc_hanh/
│   ├── movies (2).txt
│   ├── ratings_1 (2).txt
│   ├── ratings_2 (2).txt
│   ├── users (2).txt
│   └── occupation.txt
├── source_code/
│   ├── common.py
│   ├── Bai1.py
│   ├── Bai2.py
│   ├── Bai3.py
│   ├── Bai4.py
│   ├── Bai5.py
│   └── Bai6.py
├── output/
└── run_all.sh
```

Chạy từng bài:

```bash
python3 source_code/Bai1.py
python3 source_code/Bai2.py
python3 source_code/Bai3.py
python3 source_code/Bai4.py
python3 source_code/Bai5.py
python3 source_code/Bai6.py
```

Hoặc chạy toàn bộ:

```bash
bash run_all.sh
```

Kết quả được ghi vào thư mục `output/`.

---

## 3. Giải thích chi tiết từng bài

### Bài 1: Tính điểm trung bình và tổng số lượt đánh giá cho mỗi phim

**Mục tiêu:**

- Tính điểm trung bình của từng phim.
- Đếm tổng số lượt đánh giá của từng phim.
- Lọc các phim có ít nhất 5 lượt đánh giá.
- Tìm phim có điểm trung bình cao nhất.

**Ý tưởng xử lý bằng RDD:**

1. Đọc `movies (2).txt`, tạo RDD dạng `(MovieID, Title)`.
2. Đọc và gộp hai file rating bằng `union`.
3. Từ rating, tạo cặp `(MovieID, (Rating, 1))`.
4. Dùng `reduceByKey` để cộng tổng điểm và tổng số lượt đánh giá.
5. Dùng `mapValues` để tính trung bình: `avg = total_rating / count`.
6. Join với movie title để có tên phim.
7. Lọc phim có số lượt rating >= 5.
8. Sắp xếp giảm dần theo điểm trung bình.

**Cấu trúc kết quả:**

```text
(MovieID, Title, AverageRating, CountRating)
```

---

### Bài 2: Phân tích đánh giá theo thể loại phim

**Mục tiêu:**

- Tính điểm rating trung bình cho từng thể loại phim.

**Ý tưởng xử lý:**

1. Từ file movies, tạo map `(MovieID, [Genres])`.
2. Từ ratings, tạo map `(MovieID, Rating)`.
3. Join rating với danh sách thể loại của phim.
4. Một phim có thể thuộc nhiều thể loại, nên dùng `flatMap` để tách thành nhiều cặp:

```text
(Genre, (Rating, 1))
```

5. Dùng `reduceByKey` để cộng tổng điểm và tổng số lượt.
6. Tính trung bình rating cho từng thể loại.
7. Lấy Top 10 thể loại có điểm trung bình cao nhất.

**Cấu trúc kết quả:**

```text
(Genre, (AverageRating, CountRating))
```

---

### Bài 3: Phân tích đánh giá theo giới tính

**Mục tiêu:**

- Tính điểm rating trung bình của mỗi phim theo từng giới tính nam/nữ.

**Ý tưởng xử lý:**

1. Từ users, tạo RDD `(UserID, Gender)`.
2. Từ ratings, tạo RDD `(UserID, (MovieID, Rating))`.
3. Join theo `UserID` để gắn giới tính vào mỗi rating.
4. Tạo key tổng hợp `(MovieID, Gender)`.
5. Value là `(Rating, 1)`.
6. Reduce để tính tổng điểm và số lượt đánh giá cho từng cặp `(MovieID, Gender)`.
7. Join với movies để lấy tên phim.
8. Lấy Top 20 theo điểm trung bình.

**Cấu trúc kết quả:**

```text
(MovieID, Title, Gender, AverageRating, CountRating)
```

---

### Bài 4: Phân tích đánh giá theo nhóm tuổi

**Mục tiêu:**

- Phân nhóm tuổi người dùng.
- Tính điểm rating trung bình của mỗi phim theo từng nhóm tuổi.

**Các nhóm tuổi sử dụng:**

```text
Under18
18-24
25-34
35-44
45-54
55+
```

**Ý tưởng xử lý:**

1. Từ users, chuyển `Age` thành `AgeGroup`.
2. Tạo RDD `(UserID, AgeGroup)`.
3. Từ ratings, tạo RDD `(UserID, (MovieID, Rating))`.
4. Join theo `UserID` để biết mỗi rating thuộc nhóm tuổi nào.
5. Tạo key `(MovieID, AgeGroup)`.
6. Reduce để tính tổng rating và số lượt.
7. Tính trung bình.
8. Join với movies để lấy tên phim.
9. Lấy Top 20 theo điểm trung bình.

**Cấu trúc kết quả:**

```text
(MovieID, Title, AgeGroup, AverageRating, CountRating)
```

---

### Bài 5: Phân tích đánh giá theo nghề nghiệp

**Mục tiêu:**

- Tính điểm rating trung bình và tổng số lượt đánh giá cho từng nghề nghiệp.

**Ý tưởng xử lý:**

1. Từ ratings, tạo RDD `(UserID, Rating)`.
2. Từ users, tạo RDD `(UserID, OccupationID)`.
3. Join theo `UserID` để gắn nghề nghiệp vào từng rating.
4. Tạo cặp `(OccupationID, (Rating, 1))`.
5. Reduce để tính tổng điểm và số lượt đánh giá.
6. Tính trung bình rating.
7. Join với `occupation.txt` để lấy tên nghề nghiệp.
8. Lấy Top 10 nghề nghiệp có điểm trung bình cao nhất.

**Cấu trúc kết quả:**

```text
(OccupationID, OccupationName, AverageRating, CountRating)
```

---

### Bài 6: Phân tích đánh giá theo thời gian

**Mục tiêu:**

- Tính tổng số lượt đánh giá và điểm trung bình theo từng năm.

**Ý tưởng xử lý:**

1. Đọc và gộp hai file ratings.
2. Lấy `Timestamp` dạng Unix timestamp.
3. Chuyển timestamp sang năm bằng:

```python
datetime.utcfromtimestamp(timestamp).year
```

4. Tạo cặp `(Year, (Rating, 1))`.
5. Reduce để tính tổng điểm và tổng số lượt theo năm.
6. Tính trung bình.
7. Sắp xếp theo năm.

**Cấu trúc kết quả:**

```text
(Year, (AverageRating, CountRating))
```

---

## 4. Lưu ý khi nộp bài

Nên nộp các phần sau:

1. Thư mục `source_code/` chứa file `.py`.
2. Thư mục `output/` chứa kết quả từng bài.
3. Ảnh chụp màn hình khi chạy lệnh, nên có:
   - `whoami`
   - `pwd`
   - `ls`
   - lệnh chạy từng bài
   - kết quả output hiển thị trên terminal
4. Nếu nộp GitHub, nên bỏ file zip gốc và chỉ giữ code, data cần thiết, output và screenshot.

---

## 5. Điểm cải thiện so với code ban đầu

Code trong thư mục này đã được chỉnh để dễ chạy hơn:

- Không hard-code đường dẫn kiểu `/home/khoa/...`.
- Dùng đường dẫn tương đối theo vị trí thư mục bài làm.
- Tách hàm đọc dữ liệu và parse dữ liệu vào `common.py` để tránh lặp code.
- Mỗi bài vẫn là một file riêng, đúng yêu cầu nộp bài.
- Kết quả được tự động ghi vào thư mục `output/`.
