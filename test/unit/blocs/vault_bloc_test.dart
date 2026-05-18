/// VaultBloc 状态机测试 — 密码库生命周期管理
library;

import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/blocs/vault/vault_bloc.dart';
import 'package:ztd_password_manager/services/vault_service.dart';
import '../../helpers/test_helpers.dart';

import 'vault_bloc_test.mocks.dart';

@GenerateMocks([VaultService])
void main() {
  late MockVaultService mockVaultService;
  late VaultBloc vaultBloc;

  setUp(() {
    mockVaultService = MockVaultService();
    vaultBloc = VaultBloc(vaultService: mockVaultService);
  });

  tearDown(() {
    vaultBloc.close();
  });

  // ==================== [1] 检查密码库 ====================

  group('VaultCheckRequested', () {
    blocTest<VaultBloc, VaultState>(
      '未初始化 → loading→setupRequired',
      build: () {
        when(mockVaultService.isInitialized()).thenAnswer((_) async => false);
        return vaultBloc;
      },
      act: (b) => b.add(VaultCheckRequested()),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        const VaultState(status: VaultStatus.setupRequired),
      ],
      verify: (_) => verify(mockVaultService.isInitialized()).called(1),
    );

    blocTest<VaultBloc, VaultState>(
      '已初始化但锁定 → loading→locked',
      build: () {
        when(mockVaultService.isInitialized()).thenAnswer((_) async => true);
        return vaultBloc;
      },
      act: (b) => b.add(VaultCheckRequested()),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        const VaultState(status: VaultStatus.locked),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      '检查抛出异常 → loading→error',
      build: () {
        when(mockVaultService.isInitialized()).thenThrow(Exception('DB corrupt'));
        return vaultBloc;
      },
      act: (b) => b.add(VaultCheckRequested()),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        predicate<VaultState>(
          (s) => s.status == VaultStatus.error && (s.errorMessage ?? '').contains('DB corrupt'),
        ),
      ],
    );
  });

  // ==================== [2] 初始化密码库 ====================

  group('VaultInitializeRequested', () {
    blocTest<VaultBloc, VaultState>(
      '初始化成功 → loading→unlocked',
      build: () {
        when(mockVaultService.initialize(any, entropy: anyNamed('entropy')))
            .thenAnswer((_) async {});
        return vaultBloc;
      },
      act: (b) => b.add(const VaultInitializeRequested('mypassword')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        const VaultState(status: VaultStatus.unlocked),
      ],
      verify: (_) =>
          verify(mockVaultService.initialize('mypassword', entropy: null)).called(1),
    );

    blocTest<VaultBloc, VaultState>(
      '初始化失败 → loading→error',
      build: () {
        when(mockVaultService.initialize(any, entropy: anyNamed('entropy')))
            .thenThrow(Exception('Init failed'));
        return vaultBloc;
      },
      act: (b) => b.add(VaultInitializeRequested('mypassword', entropy: Uint8List(0))),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        predicate<VaultState>(
          (s) => s.status == VaultStatus.error && (s.errorMessage ?? '').contains('Init failed'),
        ),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      '初始化成功（带熵） → unlocked',
      build: () {
        final entropy = Uint8List.fromList([1, 2, 3, 4]);
        when(mockVaultService.initialize(any, entropy: anyNamed('entropy')))
            .thenAnswer((_) async {});
        return vaultBloc;
      },
      act: (b) => b.add(VaultInitializeRequested('mypassword', entropy: Uint8List.fromList([1, 2, 3, 4]))),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        const VaultState(status: VaultStatus.unlocked),
      ],
    );
  });

  // ==================== [3] 解锁密码库 ====================

  group('VaultUnlockRequested', () {
    blocTest<VaultBloc, VaultState>(
      '解锁成功 → loading→unlocked',
      build: () {
        when(mockVaultService.unlock('correct')).thenAnswer((_) async => true);
        return vaultBloc;
      },
      act: (b) => b.add(const VaultUnlockRequested('correct')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        const VaultState(status: VaultStatus.unlocked),
      ],
      verify: (_) => verify(mockVaultService.unlock('correct')).called(1),
    );

    blocTest<VaultBloc, VaultState>(
      '密码错误 → loading→locked(with error)',
      build: () {
        when(mockVaultService.unlock('wrong')).thenAnswer((_) async => false);
        return vaultBloc;
      },
      act: (b) => b.add(const VaultUnlockRequested('wrong')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        predicate<VaultState>(
          (s) => s.status == VaultStatus.locked && (s.errorMessage ?? '').contains('Invalid master password'),
        ),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      '解锁抛出异常 → loading→error',
      build: () {
        when(mockVaultService.unlock('crash')).thenThrow(Exception('Key derivation failed'));
        return vaultBloc;
      },
      act: (b) => b.add(const VaultUnlockRequested('crash')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        predicate<VaultState>(
          (s) => s.status == VaultStatus.error && (s.errorMessage ?? '').contains('Key derivation failed'),
        ),
      ],
    );
  });

  // ==================== [4] 锁定密码库 ====================

  group('VaultLockRequested', () {
    blocTest<VaultBloc, VaultState>(
      '锁定成功 → locked',
      build: () {
        when(mockVaultService.lock()).thenAnswer((_) async {});
        return vaultBloc;
      },
      act: (b) => b.add(VaultLockRequested()),
      expect: () => [const VaultState(status: VaultStatus.locked)],
      verify: (_) => verify(mockVaultService.lock()).called(1),
    );
  });

  // ==================== [5] 更改主密码 ====================

  group('VaultChangePasswordRequested', () {
    blocTest<VaultBloc, VaultState>(
      '更改密码成功 → loading→unlocked',
      build: () {
        when(mockVaultService.changeMasterPassword('old', 'new'))
            .thenAnswer((_) async => true);
        return vaultBloc;
      },
      act: (b) => b.add(const VaultChangePasswordRequested(oldPassword: 'old', newPassword: 'new')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        const VaultState(status: VaultStatus.unlocked),
      ],
      verify: (_) => verify(mockVaultService.changeMasterPassword('old', 'new')).called(1),
    );

    blocTest<VaultBloc, VaultState>(
      '更改密码失败（原密码错） → unlock(with error)',
      build: () {
        when(mockVaultService.changeMasterPassword('wrong', 'new'))
            .thenAnswer((_) async => false);
        return vaultBloc;
      },
      act: (b) => b.add(const VaultChangePasswordRequested(oldPassword: 'wrong', newPassword: 'new')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        predicate<VaultState>(
          (s) => s.status == VaultStatus.unlocked
              && (s.errorMessage ?? '').contains('Failed to change password'),
        ),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      '更改密码抛出异常 → unlock(with error msg)',
      build: () {
        when(mockVaultService.changeMasterPassword('old', 'new'))
            .thenThrow(Exception('Key rotation failed'));
        return vaultBloc;
      },
      act: (b) => b.add(const VaultChangePasswordRequested(oldPassword: 'old', newPassword: 'new')),
      expect: () => [
        const VaultState(status: VaultStatus.loading),
        predicate<VaultState>(
          (s) => s.status == VaultStatus.unlocked
              && (s.errorMessage ?? '').contains('Key rotation failed'),
        ),
      ],
    );
  });
}
