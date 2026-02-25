// VaultService 业务编排集成测试
//
// 目标：模拟真实的 Service 编排流程，验证依赖调用顺序和异常传播。
// 消除：业务代码逻辑正确但编排顺序错误导致的 Bug。
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/services/vault_service.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import 'package:ztd_password_manager/core/crypto/key_manager.dart';
import 'package:ztd_password_manager/core/storage/database_service.dart';
import 'package:ztd_password_manager/core/events/event_store.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../helpers/test_helpers.dart';

// 生成 Mock
@GenerateMocks(
    [DatabaseService, CryptoService, KeyManager, EventStore, Transaction])
import 'vault_orchestration_test.mocks.dart'; // ignore_for_file: dangling_library_doc_comments

void main() {
  late VaultService vaultService;
  late MockDatabaseService mockDb;
  late MockCryptoService mockCrypto;
  late MockKeyManager mockKeyManager;
  late MockEventStore mockEventStore;

  setUp(() {
    mockDb = MockDatabaseService();
    mockCrypto = MockCryptoService();
    mockKeyManager = MockKeyManager();
    mockEventStore = MockEventStore();

    // 修复构造函数参数名
    vaultService = VaultService(
      database: mockDb,
      cryptoService: mockCrypto,
      keyManager: mockKeyManager,
    );

    // 关联 EventStore (VaultService 内部会从 mockDb 获取 eventStore)
    when(mockDb.eventStore).thenReturn(mockEventStore);

    // 完善 Session 状态加载 Mock
    when(mockKeyManager.getSearchKey()).thenAnswer((_) async => Uint8List(32));
    when(mockKeyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
  });

  group('VaultService 业务编排校验', () {
    test('未解锁 createCard 应该抛出 StateError (守卫校验)', () async {
      final payload = makePasswordPayload();

      // 验证：如果尚未解锁，应该抛出异常而【不】执行后续逻辑
      expect(
          () => vaultService.createCard(payload), throwsA(isA<StateError>()));

      verifyNever(mockCrypto.encryptString(any, any));
      verifyNever(mockDb.saveCard(any));
    });

    test('完整创建流程编排契约 (模拟解锁状态)', () async {
      final payload = makePasswordPayload();
      final key = Uint8List(32);

      // 模拟 unlock 成功的副作用
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(key);
      when(mockKeyManager.getSearchKey())
          .thenAnswer((_) async => Uint8List(32));
      when(mockKeyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
      when(mockCrypto.sha256String(any)).thenReturn('mock-db-key');
      when(mockDb.initialize(any)).thenAnswer((_) async => Future.value());
      when(mockDb.eventStore).thenReturn(mockEventStore);

      // 执行解锁动作
      await vaultService.unlock('master-password');
      expect(vaultService.isUnlocked, isTrue);

      // 配置后续 Mock
      when(mockCrypto.encryptString(any, any)).thenReturn(makeEncryptedData());
      when(mockCrypto.generateBlindIndexes(any, any)).thenReturn(['idx1']);

      // 模拟事务执行
      // 注意：VaultService.createCard 内部使用了 _database.transaction
      // 这里需要模拟 transaction 的回调执行
      when(mockDb.transaction(any)).thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[0] as Function;
        await callback(MockTransaction()); // 传递 MockTransaction 而非 null
      });

      when(mockDb.saveCard(any, txn: anyNamed('txn')))
          .thenAnswer((_) async => Future.value());
      when(mockEventStore.appendEvent(any, txn: anyNamed('txn')))
          .thenAnswer((_) async => Future.value());

      // 执行创建动作
      await vaultService.createCard(payload);

      // [3] 验证编排契约
      verify(mockCrypto.encryptString(any, any)).called(1);
      verify(mockDb.transaction(any)).called(1);
      verify(mockDb.saveCard(any, txn: anyNamed('txn'))).called(1);
      verify(mockEventStore.appendEvent(any, txn: anyNamed('txn'))).called(1);
    });
  });
}
