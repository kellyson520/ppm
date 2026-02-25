import 'crypto_core.dart';
import 'crypto_registry.dart';

/// 密码学策略引擎
/// 
/// 职责：
/// 1. 选择默认加密套件
/// 2. 校验解密时的套件可用性（防降级攻击）
/// 3. 根据平台能力和安全策略输出配置
class CryptoPolicyEngine {
  final CryptoRegistry _registry;

  /// 当前默认加密套件 ID（新数据使用此套件加密）
  String _defaultSuiteId = 'ZTDPM_SUITE_2026_01';

  /// 最低可接受的安全等级
  int _minSecurityLevel = 0;

  /// 单例
  static CryptoPolicyEngine? _instance;
  factory CryptoPolicyEngine({CryptoRegistry? registry}) {
    _instance ??= CryptoPolicyEngine._internal(
      registry: registry ?? CryptoRegistry(),
    );
    return _instance!;
  }

  CryptoPolicyEngine._internal({
    required CryptoRegistry registry,
  }) : _registry = registry;

  // ==================== 策略查询 ====================

  /// 获取默认加密套件
  CryptoSuite get defaultSuite {
    final suite = _registry.getSuite(_defaultSuiteId);
    if (suite == null) {
      throw StateError(
        '默认套件 "$_defaultSuiteId" 未注册，系统不安全！',
      );
    }
    return suite;
  }

  /// 获取默认套件 ID
  String get defaultSuiteId => _defaultSuiteId;

  /// 设置默认套件 ID
  set defaultSuiteId(String suiteId) {
    final suite = _registry.getSuite(suiteId);
    if (suite == null) {
      throw ArgumentError('套件 "$suiteId" 未注册');
    }
    if (suite.securityLevel < _minSecurityLevel) {
      throw ArgumentError(
        '套件 "$suiteId" 安全等级 ${suite.securityLevel} 低于最低要求 $_minSecurityLevel',
      );
    }
    _defaultSuiteId = suiteId;
  }

  /// 设置最低安全等级
  set minSecurityLevel(int level) {
    _minSecurityLevel = level;
  }

  // ==================== 解密校验 ====================

  /// 校验套件是否允许解密
  /// 
  /// 防降级攻击：
  /// 1. 套件必须在 AllowedSuites 集合中
  /// 2. 套件安全等级不低于最低可接受等级
  /// 
  /// 返回 null 表示通过，否则返回拒绝原因
  String? validateForDecryption(String suiteId) {
    // 检查是否在允许列表
    if (!_registry.isSuiteAllowed(suiteId)) {
      return '套件 "$suiteId" 不在允许列表中，疑似降级攻击';
    }

    // 检查安全等级
    final suite = _registry.getSuite(suiteId);
    if (suite == null) {
      return '套件 "$suiteId" 未注册';
    }

    if (suite.securityLevel < _minSecurityLevel) {
      return '套件 "$suiteId" 安全等级 ${suite.securityLevel} 低于要求 $_minSecurityLevel';
    }

    return null; // 通过
  }

  /// 检查套件是否可以用于加密（必须是默认套件）
  bool canEncryptWith(String suiteId) {
    return suiteId == _defaultSuiteId;
  }

  // ==================== 策略信息 ====================

  /// 获取所有允许解密的套件
  List<CryptoSuite> get allowedDecryptionSuites {
    return _registry.allowedSuiteIds
        .map((id) => _registry.getSuite(id))
        .whereType<CryptoSuite>()
        .where((s) => s.securityLevel >= _minSecurityLevel)
        .toList();
  }

  /// 获取策略摘要（用于调试/审计）
  Map<String, dynamic> get policySummary => {
    'defaultSuiteId': _defaultSuiteId,
    'minSecurityLevel': _minSecurityLevel,
    'allowedSuiteCount': _registry.allowedSuiteIds.length,
    'registeredAeadCount': _registry.aeadProviderIds.length,
    'registeredKdfCount': _registry.kdfProviderIds.length,
  };
}
