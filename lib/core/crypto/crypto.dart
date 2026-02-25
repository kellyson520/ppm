/// 密码学模块 - 统一导出
/// 
/// 架构层次：
/// 1. crypto_core.dart    - 接口与数据格式（Kdf, AeadCipher, CiphertextEnvelope...）
/// 2. providers/           - 算法实现（AES-GCM, PBKDF2, HKDF...）
/// 3. crypto_registry.dart - Provider 注册表
/// 4. crypto_policy.dart   - 策略引擎（防降级、套件选择）
/// 5. crypto_facade.dart   - 门面 API（业务层入口）
/// 6. crypto_service.dart  - 兼容层（包装 CryptoFacade）
/// 7. key_manager.dart     - 密钥管理

// 核心接口与数据格式
export 'crypto_core.dart';

// Provider 注册与策略
export 'crypto_registry.dart';
export 'crypto_policy.dart';

// 门面层（新代码推荐使用）
export 'crypto_facade.dart';

// 兼容层（旧代码使用）
export 'crypto_service.dart';

// 密钥管理
export 'key_manager.dart';

// 算法 Provider（按需导出）
export 'providers/aes_gcm_provider.dart';
export 'providers/pbkdf2_provider.dart';
export 'providers/hkdf_provider.dart';
