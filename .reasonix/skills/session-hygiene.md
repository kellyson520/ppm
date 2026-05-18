---
name: session-hygiene
description: 定时清理内存碎片，释放系统资源，防止长时间运行 Reasonix Code 导致 VPS 负载飙升
---
# Session Hygiene — 内存碎片清理

## 目的
长时间运行 Reasonix Code 会累积内存碎片和临时文件，导致 VPS 负载逐渐飙升。此技能执行系统级清理，降低资源压力。

## 适用场景
- 会话运行超过 30 分钟
- 感觉响应变慢
- 每次 CI 构建完成后
- 系统负载（load average）超过 CPU 核心数

## 操作步骤

### 1. 检查当前系统负载
```bash
echo "=== Load Average ===" && cat /proc/loadavg && echo "=== Memory ===" && free -h && echo "=== Top Processes ===" && ps aux --sort=-%mem | head -8
```

### 2. 清理 Python/Dart 进程缓存
```bash
# 清理孤儿 Dart 进程
pkill -f "dart:.*snapshot" 2>/dev/null || true
pkill -f "pub get" 2>/dev/null || true

# 清理 Flutter build 缓存
rm -rf /root/ppm/.dart_tool/ 2>/dev/null || true
rm -rf /root/ppm/build/ 2>/dev/null || true
```

### 3. 释放系统页缓存
```bash
# 清理 dentries 和 inodes (安全操作，不丢失数据)
sync && echo 2 > /proc/sys/vm/drop_caches 2>/dev/null || true

# 或者使用 sysctl
sysctl -w vm.drop_caches=2 2>/dev/null || true
```

### 4. 清理 Reasonix 自身临时文件
```bash
# 清理临时 zip / 下载
rm -f /tmp/ci-*.zip /tmp/push-*.py /tmp/*.py 2>/dev/null || true
rm -rf /tmp/ci-reports /tmp/ci-reports2 /tmp/ci-reports3 /tmp/ci-ui /tmp/ci-bugfix /tmp/ci-fix3 2>/dev/null || true
```

### 5. 报告
```bash
echo "=== After Cleanup ===" && free -h && cat /proc/loadavg
```

## 自动化钩子 (Hook)
将此 playbook 注入到 Reasonix 的 `after_turn` 钩子中，每 5 轮自动执行一次步骤 1 + 3 + 4。

## 注意事项
- `drop_caches` 需要 root 权限
- `drop_caches=2` 仅清理 dentries/inodes，不影响应用数据
- 不会影响正在运行的构建或 CI 流程
