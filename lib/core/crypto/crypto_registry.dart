import 'crypto_core.dart';
import 'providers/aes_gcm_provider.dart';
import 'providers/pbkdf2_provider.dart';

/// 密码学 Provider 注册表
///
/// 管理多个算法 Provider 的注册与查找。
/// 支持算法热插拔：新增算法只需注册新 Provider，无需改动业务代码。
class CryptoRegistry {
  /// AEAD 算法注册表
  final Map<String, AeadCipher> _aeadProviders = {};

  /// KDF 算法注册表
  final Map<String, Kdf> _kdfProviders = {};

  /// 算法套件注册表
  final Map<String, CryptoSuite> _suites = {};

  /// 允许解密的套件 ID 集合（防降级：只有在此集合中的套件才会被解密）
  final Set<String> _allowedSuiteIds = {};

  /// 单例
  static final CryptoRegistry _instance = CryptoRegistry._internal();
  factory CryptoRegistry() => _instance;

  CryptoRegistry._internal() {
    // 注册内置 Providers
    _registerBuiltinProviders();
  }

  /// 注册内置 Provider 与默认套件
  void _registerBuiltinProviders() {
    // 注册 AEAD Providers
    final aesGcm = AesGcmProvider();
    _aeadProviders[aesGcm.id] = aesGcm;

    // 注册 KDF Providers
    final pbkdf2 = Pbkdf2Provider();
    _kdfProviders[pbkdf2.id] = pbkdf2;

    // 注册默认套件
    const defaultSuite = CryptoSuite(
      id: 'ZTDPM_SUITE_2026_01',
      displayName: 'AES-256-GCM + PBKDF2-SHA256 (v2026.01)',
      aeadId: 'aes-256-gcm',
      kdfId: 'pbkdf2-hmac-sha256',
      securityLevel: 1,
    );
    _suites[defaultSuite.id] = defaultSuite;
    _allowedSuiteIds.add(defaultSuite.id);

    // 兼容旧版无套件标识的数据
    const legacySuite = CryptoSuite(
      id: 'ZTDPM_LEGACY_V1',
      displayName: 'Legacy AES-256-GCM (backward compat)',
      aeadId: 'aes-256-gcm',
      kdfId: 'pbkdf2-hmac-sha256',
      securityLevel: 0,
    );
    _suites[legacySuite.id] = legacySuite;
    _allowedSuiteIds.add(legacySuite.id);
  }

  // ==================== Provider 注册 ====================

  /// 注册 AEAD 算法 Provider
  void registerAead(AeadCipher provider) {
    _aeadProviders[provider.id] = provider;
  }

  /// 注册 KDF 算法 Provider
  void registerKdf(Kdf provider) {
    _kdfProviders[provider.id] = provider;
  }

  /// 注册算法套件
  void registerSuite(CryptoSuite suite) {
    _suites[suite.id] = suite;
    _allowedSuiteIds.add(suite.id);
  }

  // ==================== Provider 查找 ====================

  /// 获取 AEAD Provider
  AeadCipher? getAead(String id) => _aeadProviders[id];

  /// 获取 KDF Provider
  Kdf? getKdf(String id) => _kdfProviders[id];

  /// 获取算法套件
  CryptoSuite? getSuite(String suiteId) => _suites[suiteId];

  /// 获取所有已注册的套件
  List<CryptoSuite> get allSuites => _suites.values.toList();

  /// 获取所有已注册的 AEAD Provider ID
  List<String> get aeadProviderIds => _aeadProviders.keys.toList();

  /// 获取所有已注册的 KDF Provider ID
  List<String> get kdfProviderIds => _kdfProviders.keys.toList();

  // ==================== 防降级 ====================

  /// 检查套件是否允许解密
  bool isSuiteAllowed(String suiteId) => _allowedSuiteIds.contains(suiteId);

  /// 移除套件许可（标记为不安全，拒绝解密）
  void revokeSuite(String suiteId) {
    _allowedSuiteIds.remove(suiteId);
  }

  /// 获取允许的套件 ID 集合
  Set<String> get allowedSuiteIds => Set.unmodifiable(_allowedSuiteIds);
}
