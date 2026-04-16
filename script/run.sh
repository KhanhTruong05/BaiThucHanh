#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
B1_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
B2_ROOT="$(cd "$B1_ROOT/.." && pwd)/BaiThucHanh2"

find_java_home() {
    if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        echo "$JAVA_HOME"
        return 0
    fi

    local java_paths=(
        "/usr/lib/jvm/java-17-openjdk-amd64"
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/default-java"
        "/usr/lib/jvm/java-11-openjdk-amd64"
        "/usr/lib/jvm/java"
        "/opt/java/openjdk"
    )

    for path in "${java_paths[@]}"; do
        if [ -x "$path/bin/java" ]; then
            echo "$path"
            return 0
        fi
    done

    local java_bin
    java_bin=$(command -v java 2>/dev/null || true)
    if [ -n "$java_bin" ]; then
        echo "$(dirname "$(dirname "$java_bin")")"
        return 0
    fi

    return 1
}

find_hadoop_home() {
    if [ -n "${HADOOP_HOME:-}" ] && [ -x "$HADOOP_HOME/bin/hadoop" ]; then
        echo "$HADOOP_HOME"
        return 0
    fi

    local hadoop_paths=(
        "/home/$(whoami)/hadoop"
        "/usr/local/hadoop"
        "/opt/hadoop"
        "/usr/share/hadoop"
    )

    for path in "${hadoop_paths[@]}"; do
        if [ -x "$path/bin/hadoop" ]; then
            echo "$path"
            return 0
        fi
    done

    local hadoop_bin
    hadoop_bin=$(command -v hadoop 2>/dev/null || true)
    if [ -n "$hadoop_bin" ]; then
        echo "$(dirname "$(dirname "$hadoop_bin")")"
        return 0
    fi

    return 1
}

find_pig() {
    local pig_bin
    pig_bin=$(command -v pig 2>/dev/null || true)
    if [ -n "$pig_bin" ]; then
        echo "$pig_bin"
        return 0
    fi

    local pig_paths=(
        "/home/$(whoami)/pig/bin/pig"
        "/opt/pig/bin/pig"
        "/usr/local/pig/bin/pig"
    )

    for path in "${pig_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

print_help() {
    cat <<'HELP'
Cú pháp: ./run.sh [b1|b2] [1 | 2 | 3 | 4 | 5 | all | help]

Dự án:
  b1, project1    : Chạy BaiThucHanh1 (Java Hadoop)
  b2, project2    : Chạy BaiThucHanh2 (Pig)

Tùy chọn chung:
  help    : Hiển thị hướng dẫn này
  all     : Chạy tất cả bài cho dự án đang chọn

Tùy chọn BaiThucHanh1:
  1       : Chỉ chạy Bài 1
  2       : Chỉ chạy Bài 2
  3       : Chỉ chạy Bài 3
  4       : Chỉ chạy Bài 4

Tùy chọn BaiThucHanh2:
  1       : Chỉ chạy Bài 1
  2       : Chỉ chạy Bài 2
  3       : Chỉ chạy Bài 3
  4       : Chỉ chạy Bài 4
  5       : Chỉ chạy Bài 5

Ví dụ:
  ./run.sh            # Chạy BaiThucHanh1 tất cả bài
  ./run.sh b1 2       # Chạy BaiThucHanh1 Bài 2
  ./run.sh b2          # Chạy BaiThucHanh2 tất cả bài
  ./run.sh b2 3        # Chạy BaiThucHanh2 Bài 3
HELP
}

PROJECT_TYPE="b1"
if [ $# -gt 0 ]; then
    case "$1" in
        b2|project2)
            PROJECT_TYPE="b2"
            shift
            ;;
        b1|project1)
            PROJECT_TYPE="b1"
            shift
            ;;
        help|-h|--help)
            print_help
            exit 0
            ;;
    esac
fi

PROJECT_ARG="${1:-all}"
if [ "$PROJECT_ARG" = "help" ] || [ "$PROJECT_ARG" = "-h" ] || [ "$PROJECT_ARG" = "--help" ]; then
    print_help
    exit 0
fi

if [ "$PROJECT_TYPE" = "b2" ] && [ ! -d "$B2_ROOT" ]; then
    echo "❌ Lỗi: Không tìm thấy BaiThucHanh2 tại $B2_ROOT"
    exit 1
fi

if [ "$PROJECT_TYPE" = "b1" ] && [ ! -d "$B1_ROOT" ]; then
    echo "❌ Lỗi: Không tìm thấy BaiThucHanh1 tại $B1_ROOT"
    exit 1
fi

if [ "$PROJECT_TYPE" = "b1" ]; then
    JAVA_HOME=$(find_java_home) || {
        echo "❌ Không tìm thấy Java."
        exit 1
    }
    export JAVA_HOME

    HADOOP_HOME=$(find_hadoop_home) || {
        echo "❌ Không tìm thấy Hadoop."
        exit 1
    }
    export HADOOP_HOME
    export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
else
    PIG_CMD=$(find_pig) || {
        echo "❌ Không tìm thấy Pig."
        exit 1
    }
fi

PROJECT_ROOT="$B1_ROOT"
if [ "$PROJECT_TYPE" = "b2" ]; then
    PROJECT_ROOT="$B2_ROOT"
fi

SOURCE_CODE_DIR="$PROJECT_ROOT/source_code"
OUTPUT_DIR="$PROJECT_ROOT/output"
DATA_DIR="$PROJECT_ROOT/bai_thuc_hanh"
HDFS_USER_DIR="/user/$(whoami)/BaiThucHanh1"

mkdir -p "$OUTPUT_DIR"

run_b1_job() {
    local BAI_NUM=$1
    local CLASS_NAME="Bai${BAI_NUM}"
    local OUTPUT_HDFS="$HDFS_USER_DIR/output_bai${BAI_NUM}"
    local OUTPUT_LOCAL="$OUTPUT_DIR/output${BAI_NUM}.txt"

    echo "======================================"
    echo "🚀 Chạy BaiThucHanh1 Bài ${BAI_NUM} (${CLASS_NAME})"
    echo "======================================"
    cd "$SOURCE_CODE_DIR"

    javac -classpath "$(hadoop classpath)" "${CLASS_NAME}.java"
    jar cf "${CLASS_NAME}.jar" "${CLASS_NAME}"*.class

    hdfs dfs -rm -r -f "$OUTPUT_HDFS" 2>/dev/null || true

    if [ "$CLASS_NAME" = "Bai3" ] || [ "$CLASS_NAME" = "Bai4" ]; then
        hadoop jar "${CLASS_NAME}.jar" "${CLASS_NAME}" \
            "$HDFS_USER_DIR/bai_thuc_hanh/ratings_1.txt" \
            "$HDFS_USER_DIR/bai_thuc_hanh/ratings_2.txt" \
            "$HDFS_USER_DIR/bai_thuc_hanh/movies.txt" \
            "$HDFS_USER_DIR/bai_thuc_hanh/users.txt" \
            "$OUTPUT_HDFS"
    else
        hadoop jar "${CLASS_NAME}.jar" "${CLASS_NAME}" \
            "$HDFS_USER_DIR/bai_thuc_hanh/ratings_1.txt" \
            "$HDFS_USER_DIR/bai_thuc_hanh/ratings_2.txt" \
            "$HDFS_USER_DIR/bai_thuc_hanh/movies.txt" \
            "$OUTPUT_HDFS"
    fi

    hdfs dfs -getmerge "$OUTPUT_HDFS/part-r-*" "$OUTPUT_LOCAL"
    echo "✅ Kết quả Bài ${BAI_NUM}: $OUTPUT_LOCAL"
}

run_b2_job() {
    local BAI_NUM=$1
    local PIG_FILE="$SOURCE_CODE_DIR/bai${BAI_NUM}.pig"

    echo "======================================"
    echo "🚀 Chạy BaiThucHanh2 Bài ${BAI_NUM}"
    echo "======================================"
    cd "$PROJECT_ROOT"

    if [ ! -f "$PIG_FILE" ]; then
        echo "❌ File Pig không tồn tại: $PIG_FILE"
        exit 1
    fi

    rm -rf "$OUTPUT_DIR/output_bai${BAI_NUM}" "$OUTPUT_DIR/output_bai${BAI_NUM}_*"
    "$PIG_CMD" -x local -f "$PIG_FILE"
    echo "✅ Kết quả Bài ${BAI_NUM}: $OUTPUT_DIR"
}

if [ "$PROJECT_TYPE" = "b1" ]; then
    if [ "$PROJECT_ARG" = "all" ]; then
        run_b1_job 1
        run_b1_job 2
        run_b1_job 3
        run_b1_job 4
    else
        case "$PROJECT_ARG" in
            1|2|3|4)
                run_b1_job "$PROJECT_ARG"
                ;;
            *)
                print_help
                exit 1
                ;;
        esac
    fi
else
    if [ "$PROJECT_ARG" = "all" ]; then
        run_b2_job 1
        run_b2_job 2
        run_b2_job 3
        run_b2_job 4
        run_b2_job 5
    else
        case "$PROJECT_ARG" in
            1|2|3|4|5)
                run_b2_job "$PROJECT_ARG"
                ;;
            *)
                print_help
                exit 1
                ;;
        esac
    fi
fi
