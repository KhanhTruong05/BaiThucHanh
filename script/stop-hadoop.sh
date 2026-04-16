#!/bin/bash

# ============================================================================
# HADOOP STOP SCRIPT
# ============================================================================

export HADOOP_HOME=${HADOOP_HOME:-/home/lenovo/hadoop}

echo "🛑 Dừng các dịch vụ Hadoop..."

# Kill all Hadoop processes
pkill -9 -f "NameNode|DataNode|ResourceManager|NodeManager|MRAppMaster" 2>/dev/null || true

echo "✅ Tất cả dịch vụ Hadoop đã được dừng"
echo ""
echo "Các quy trình còn lại:"
jps
