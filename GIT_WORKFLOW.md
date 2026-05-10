# Git 工作流指南

本文档定义了 ZTD Password Manager 项目的 Git 使用规范和最佳实践。

---

## 目录

1. [仓库结构](#1-仓库结构)
2. [分支策略](#2-分支策略)
3. [提交规范](#3-提交规范)
4. [Pull Request 流程](#4-pull-request-流程)
5. [版本发布](#5-版本发布)
6. [常见操作](#6-常见操作)

---

## 1. 仓库结构

```
ppm/
├── .github/
│   └── workflows/
│       └── ci.yml           # CI/CD 配置
├── lib/                      # 源代码
├── test/                     # 测试文件
├── docs/                     # 文档
├── android/                  # Android 平台代码
├── ios/                      # iOS 平台代码
├── STANDARDS.md              # 项目规范（本文件相关）
└── README.md                 # 项目说明
```

---

## 2. 分支策略

### 2.1 长期分支

| 分支 | 用途 | 保护状态 |
|------|------|----------|
| `main` | 主分支，稳定可发布 | 保护，禁止直接推送 |

### 2.2 临时分支

```bash
# 功能开发
feature/<功能名>
示例: feature/biometric-auth, feature/webdav-sync

# Bug 修复
fix/<问题描述>
示例: fix/login-crash, fix/sync-timeout

# 重构
refactor/<范围>
示例: refactor/crypto-module

# 文档
docs/<主题>
示例: docs/api-docs, docs/contributing
```

### 2.3 创建分支

```bash
# 从 main 创建功能分支
git checkout main
git pull origin main
git checkout -b feature/my-feature

# 从特定 commit 创建（用于热修复）
git checkout -b hotfix/urgent-fix 5eb0d5e
```

---

## 3. 提交规范

### 3.1 提交信息格式

```
<类型>(<范围>): <简短描述>

[可选正文]

[可选脚注]
```

### 3.2 类型说明

| 类型 | 描述 | 使用场景 |
|------|------|----------|
| `feat` | 新功能 | 添加新功能 |
| `fix` | 错误修复 | 修复 bug |
| `docs` | 文档 | 文档更新 |
| `style` | 格式 | 不影响代码含义的格式调整 |
| `refactor` | 重构 | 代码重构，不修复问题或添加功能 |
| `perf` | 性能 | 性能改进 |
| `test` | 测试 | 添加或修改测试 |
| `chore` | 构建 | 构建系统或辅助工具变更 |

### 3.3 范围说明

| 范围 | 说明 |
|------|------|
| `crypto` | 密码学模块 |
| `ui` | 用户界面 |
| `sync` | 同步功能 |
| `auth` | 认证模块 |
| `crdt` | CRDT 合并 |
| `ci` | CI/CD |
| `android` | Android 平台 |
| `ios` | iOS 平台 |

### 3.4 示例

```bash
# 功能提交
git commit -m "feat(crypto): 添加 Argon2id 密钥派生支持

实现基于 Argon2id 的 KDF，支持内存硬度参数配置。
使用 PointyCastle 库实现，兼容现有 AES-GCM 加密流程。

相关: #45"

# 修复提交
git commit -m "fix(sync): 修复 WebDAV 连接超时问题

添加指数退避重试机制，最多重试 3 次。
修复并发写入导致的数据库锁定问题。

Closes: #67"

# 重构提交
git commit -m "refactor(crypto): 简化 CryptoFacade 接口

移除已废弃的 legacyEncrypt 方法。
统一使用 CiphertextEnvelope 作为返回值。
性能无影响，API 向后兼容。"

# 版本发布
git commit -m "chore(release): bump version to 0.2.19

- 更新 pubspec.yaml 版本号
- 更新 CHANGELOG.md
- 准备发布 v0.2.19"
```

### 3.5 提交最佳实践

- **原子提交**: 每个提交只做一件事
- **频繁提交**: 避免大量更改后一次性提交
- **描述清晰**: 标题不超过 72 字符
- **关联 Issue**: 使用 `Closes: #123` 或 `Fixes: #456`

---

## 4. Pull Request 流程

### 4.1 创建 PR

```bash
# 1. 确保代码已提交
git add .
git commit -m "feat(my-feature): 完成功能实现"

# 2. 推送分支
git push origin feature/my-feature

# 3. 在 GitHub 创建 PR
gh pr create --title "feat: 添加新功能" --body "## 描述..."
```

### 4.2 PR 模板

```markdown
## 描述
<!-- 简要描述这个 PR 做什么 -->

## 变更类型
- [ ] 新功能 (feat)
- [ ] 错误修复 (fix)
- [ ] 重构 (refactor)
- [ ] 文档 (docs)
- [ ] CI/CD (ci)

## 测试
- [ ] 添加了测试
- [ ] 现有测试通过
- [ ] 不需要测试

## 检查清单
- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过
- [ ] 代码符合命名规范
- [ ] 公共 API 有文档注释
- [ ] 更新了相关文档

## 截图（UI 变更）
<!-- 如果有 UI 变更，添加截图 -->
```

### 4.3 Review 流程

```
1. 提交代码
   ↓
2. CI 自动检查 (flutter analyze, flutter test)
   ↓
3. 至少 1 人 Review
   ↓
4. 修复 Review 反馈
   ↓
5. 合并到 main
   ↓
6. 删除功能分支
```

### 4.4 Review 注意事项

**Reviewer 职责：**
- 检查代码逻辑是否正确
- 检查是否引入安全问题
- 检查是否符合代码规范
- 检查是否有测试覆盖
- 提供建设性反馈

**Author 职责：**
- 响应所有 Review 意见
- 不要忽略 Reviewer 的建议
- 确保所有检查通过后再合并

### 4.5 合并策略

```bash
# 使用 Squash and Merge（推荐）
# 将所有提交压缩为一个，保持 main 历史整洁

# 或 Rebase and Merge（用于保持完整历史）
git rebase main
git push --force-with-lease
```

---

## 5. 版本发布

### 5.1 版本号规则

采用 [语义化版本](https://semver.org/)：

```
主版本.次版本.修订版本[-预发布版本]
示例: 0.2.19, 1.0.0-beta.1
```

| 部分 | 说明 | 变更场景 |
|------|------|----------|
| 主版本 | 不兼容的 API 变更 | 重构导致破坏性变更 |
| 次版本 | 向后兼容的功能新增 | 添加新功能 |
| 修订版本 | 向后兼容的问题修复 | Bug 修复 |

### 5.2 发布流程

```bash
# 1. 更新版本号
# 编辑 pubspec.yaml
version: 0.2.20+20

# 2. 更新 CHANGELOG.md
# 添加新版本条目

# 3. 提交版本更新
git add .
git commit -m "chore(release): bump version to 0.2.20"

# 4. 创建 tag
git tag v0.2.20

# 5. 推送到远程
git push origin main
git push origin v0.2.20

# 6. CI 自动执行
# - 运行所有检查
# - 构建 Android APK
# - 构建 Android AppBundle
# - 构建 Web
# - 创建 GitHub Release（如果配置了）
```

### 5.3 热修复流程

```bash
# 1. 从 main 创建热修复分支
git checkout main
git pull origin main
git checkout -b hotfix/security-patch

# 2. 修复问题并提交
git add .
git commit -m "fix(security): 修复 XX 漏洞

CVE-XXXX-XXXX

修复方案：
- ..."

# 3. 推送并创建 PR
git push origin hotfix/security-patch

# 4. 合并到 main
# 完成 Review 后合并

# 5. 标记修复版本
git tag v0.2.21
git push origin v0.2.21

# 6. 删除热修复分支
git branch -d hotfix/security-patch
git push origin --delete hotfix/security-patch
```

---

## 6. 常见操作

### 6.1 同步 main 到功能分支

```bash
# 方法 1: Rebase（推荐）
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# 方法 2: Merge
git checkout feature/my-feature
git fetch origin
git merge origin/main
```

### 6.2 撤销更改

```bash
# 撤销未提交的更改
git checkout -- file.dart
git restore file.dart

# 撤销已暂存的更改
git restore --staged file.dart

# 撤销上一次提交（保留更改）
git reset HEAD~1

# 撤销上一次提交（丢弃更改）
git reset --hard HEAD~1
```

### 6.3 清理分支

```bash
# 删除已合并的本地分支
git branch --merged main | grep -v "main" | xargs git branch -d

# 删除远程已不存在的分支
git fetch --prune
```

### 6.4 查看历史

```bash
# 查看提交历史
git log --oneline --graph --all

# 查看某个文件的修改历史
git log -p file.dart

# 查看某次提交的详情
git show 5eb0d5e
```

### 6.5 暂存工作

```bash
# 暂存当前更改
git stash
git stash save "正在进行的工作"

# 查看暂存列表
git stash list

# 恢复暂存
git stash apply
git stash pop

# 恢复特定暂存
git stash apply stash@{0}
```

---

## 紧急情况处理

### CI 失败导致无法合并

1. 立即查看 CI 日志
2. 在本地复现问题
3. 修复后推送更新
4. 等待 CI 重新检查

### 不小心推送到 main

```bash
# 如果 CI 未通过
# 1. 立即撤销
git revert HEAD
git push origin main

# 2. 修复问题后重新提交

# 如果 CI 通过但需要撤销
# 1. 创建 revert PR
gh pr create --revert 123
```

---

*本文档由项目维护者维护，最后更新：2026-05-10*
