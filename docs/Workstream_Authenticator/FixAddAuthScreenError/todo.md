# Task: Fix AddAuthScreen Error

## 问题描述
在 `lib/ui/screens/add_auth_screen.dart` 第 378 行存在错误。初步观察可能是本地化字段 `accountRequired` 缺失。

## TODO
- [x] 运行 `flutter analyze` 确认错误信息
- [x] 检查 `AppLocalizations` 是否包含 `accountRequired`
- [x] 如果缺失，在 `.arb` 文件中添加
- [x] 重新生成本地化文件
- [x] 验证修复
