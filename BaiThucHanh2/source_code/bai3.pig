raw_line = LOAD 'bai_thuc_hanh/hotel-review.csv' USING TextLoader() AS (line:chararray);

parsed = FOREACH raw_line GENERATE
    REGEX_EXTRACT(line, '^(\\d+);(.*);([^;]+);([^;]+);([^;]+)$', 1) AS id,
    REGEX_EXTRACT(line, '^(\\d+);(.*);([^;]+);([^;]+);([^;]+)$', 2) AS review,
    REGEX_EXTRACT(line, '^(\\d+);(.*);([^;]+);([^;]+);([^;]+)$', 3) AS aspect,
    REGEX_EXTRACT(line, '^(\\d+);(.*);([^;]+);([^;]+);([^;]+)$', 4) AS category,
    REGEX_EXTRACT(line, '^(\\d+);(.*);([^;]+);([^;]+);([^;]+)$', 5) AS sentiment;

data = FILTER parsed BY id IS NOT NULL;

normalized = FOREACH data GENERATE
    category,
    LOWER(sentiment) AS sentiment;

negative = FILTER normalized BY sentiment == 'negative';
negative_count = FOREACH (GROUP negative BY category) GENERATE group AS category, COUNT(negative) AS total_negative;
top_negative_aspect = FOREACH (GROUP negative_count ALL) {
    sorted = ORDER negative_count BY total_negative DESC, category ASC;
    top1 = LIMIT sorted 1;
    GENERATE FLATTEN(top1) AS (category, total_negative);
};

positive = FILTER normalized BY sentiment == 'positive';
positive_count = FOREACH (GROUP positive BY category) GENERATE group AS category, COUNT(positive) AS total_positive;
top_positive_aspect = FOREACH (GROUP positive_count ALL) {
    sorted = ORDER positive_count BY total_positive DESC, category ASC;
    top1 = LIMIT sorted 1;
    GENERATE FLATTEN(top1) AS (category, total_positive);
};

STORE top_negative_aspect INTO 'output/output_bai3_top_negative_aspect' USING PigStorage(';');
STORE top_positive_aspect INTO 'output/output_bai3_top_positive_aspect' USING PigStorage(';');
