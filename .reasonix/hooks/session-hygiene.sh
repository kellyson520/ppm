#!/bin/bash
# Reasonix Hook: session-hygiene
# 每 N 轮自动执行，清理内存碎片，防止 VPS 负载飙升
#
# 安装: 放入 ~/.reasonix/hooks/ 或 .reasonix/hooks/
# 触发: Reasonix 内部轮次计数到达阈值时自动调用

set -e

echo "[session-hygiene] $(date '+%H:%M:%S') — 开始清理"

# 1. 清理 CI 临时下载
rm -f /tmp/ci-*.zip /tmp/push-*.py 2>/dev/null || true
count_zip=$(ls /tmp/ci-*.zip 2>/dev/null | wc -l)
echo "  CI temp files cleaned (remaining: $count_zip)"

# 2. 清理 CI 报告解压目录
rm -rf /tmp/ci-reports /tmp/ci-reports[0-9]* /tmp/ci-ui /tmp/ci-bugfix /tmp/ci-fix* 2>/dev/null || true

# 3. 清理 /tmp 中超过 1 小时的临时 Python 脚本
find /tmp -name '*.py' -mmin +60 -delete 2>/dev/null || true

# 4. 释放内核 dentries/inodes 缓存 (安全操作)
sync
echo 2 > /proc/sys/vm/drop_caches 2>/dev/null || true

# 5. 报告
echo "  Memory: $(free -h | awk '/^Mem/ {print $7" available"}')"
echo "  Load: $(cat /proc/loadavg | awk '{print $1,$2,$3}')"
echo "[session-hygiene] 完成"
