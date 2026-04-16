#!/bin/bash

set -e

# ============================================================================
# HADOOP STARTUP SCRIPT
# ============================================================================

# Xác định HADOOP_HOME
export HADOOP_HOME=${HADOOP_HOME:-/home/lenovo/hadoop}
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}

if [ ! -d "$HADOOP_HOME" ]; then
    echo "❌ Lỗi: HADOOP_HOME không tìm thấy: $HADOOP_HOME"
    exit 1
fi

echo "🔍 Kiểm tra trạng thái dịch vụ Hadoop..."
echo "HADOOP_HOME: $HADOOP_HOME"

# Kill any existing processes
echo "🧹 Dừng các dịch vụ cũ..."
pkill -9 -f "NameNode|DataNode|ResourceManager|NodeManager|MRAppMaster" 2>/dev/null || true
sleep 2

# Clean up old data
echo "🧹 Làm sạch dữ liệu cũ..."
rm -rf /home/lenovo/hadoop_tmp
mkdir -p /home/lenovo/hadoop_tmp

# Format HDFS
echo "📝 Định dạng HDFS NameNode..."
$HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive > /dev/null 2>&1

# Start services with proper logging
echo "🚀 Khởi động NameNode..."
$HADOOP_HOME/bin/hdfs namenode > /tmp/namenode.log 2>&1 &
NAMENODE_PID=$!
sleep 3

echo "🚀 Khởi động DataNode..."
$HADOOP_HOME/bin/hdfs datanode > /tmp/datanode.log 2>&1 &
DATANODE_PID=$!
sleep 3

echo "🚀 Khởi động ResourceManager..."
$HADOOP_HOME/bin/yarn resourcemanager > /tmp/rm.log 2>&1 &
RM_PID=$!
sleep 3

echo "🚀 Khởi động NodeManager..."
$HADOOP_HOME/bin/yarn nodemanager > /tmp/nm.log 2>&1 &
NM_PID=$!
sleep 3

# Verify services
echo "⏳ Đang kiểm tra các dịch vụ..."
for i in {1..10}; do
    jps_output=$(jps 2>/dev/null)
    if echo "$jps_output" | grep -q "NameNode" && \
       echo "$jps_output" | grep -q "DataNode" && \
       echo "$jps_output" | grep -q "ResourceManager" && \
       echo "$jps_output" | grep -q "NodeManager"; then
        echo "✅ Tất cả dịch vụ Hadoop đã khởi động thành công!"
        echo ""
        jps
        echo ""
        echo "✅ Dịch vụ Hadoop sẵn sàng"
        exit 0
    fi
    echo "⏳ Chờ dịch vụ khởi động... [$i/10]"
    sleep 2
done

echo "❌ Lỗi: Không thể khởi động tất cả các dịch vụ Hadoop"
echo "NameNode log:"
tail -20 /tmp/namenode.log
echo ""
echo "DataNode log:"
tail -20 /tmp/datanode.log
exit 1
