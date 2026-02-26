/// PasswordBloc 状态机测试
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/blocs/password/password_bloc.dart';
import 'package:ztd_password_manager/services/vault_service.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import '../../helpers/test_helpers.dart';
import 'password_bloc_test.mocks.dart';

@GenerateMocks([VaultService])
void main() {
  late MockVaultService mockVaultService;
  late PasswordBloc passwordBloc;

  setUp(() {
    mockVaultService = MockVaultService();
    passwordBloc = PasswordBloc(vaultService: mockVaultService);
  });

  tearDown(() {
    passwordBloc.close();
  });

  // ==================== [1] 加载数据 ====================

  group('PasswordLoadRequested', () {
    final cards = [makePasswordCard(), makePasswordCard(cardId: kTestCardId2)];

    blocTest<PasswordBloc, PasswordState>(
      '成功加载 → Loading → Loaded',
      build: () {
        when(mockVaultService.getAllCards()).thenAnswer((_) async => cards);
        return passwordBloc;
      },
      act: (b) => b.add(PasswordLoadRequested()),
      expect: () => [
        isA<PasswordLoading>(),
        isA<PasswordLoaded>().having((s) => s.cards, 'cards', equals(cards)),
      ],
      verify: (_) => verify(mockVaultService.getAllCards()).called(1),
    );

    blocTest<PasswordBloc, PasswordState>(
      '加载失败 → Loading → Error(不吞异常)',
      build: () {
        when(mockVaultService.getAllCards())
            .thenThrow(Exception('DB connection failed'));
        return passwordBloc;
      },
      act: (b) => b.add(PasswordLoadRequested()),
      expect: () => [
        isA<PasswordLoading>(),
        isA<PasswordError>().having(
            (s) => s.message, 'error msg', contains('DB connection failed')),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      '加载空列表 → Loaded(cards empty)',
      build: () {
        when(mockVaultService.getAllCards()).thenAnswer((_) async => []);
        return passwordBloc;
      },
      act: (b) => b.add(PasswordLoadRequested()),
      expect: () => [
        isA<PasswordLoading>(),
        isA<PasswordLoaded>().having((s) => s.cards, 'empty', isEmpty),
      ],
    );
  });

  // ==================== [2] 搜索 ====================

  group('PasswordSearchRequested', () {
    final results = [makePasswordCard()];

    blocTest<PasswordBloc, PasswordState>(
      '搜索成功 → Loading → Loaded(含 query)',
      build: () {
        when(mockVaultService.search('github'))
            .thenAnswer((_) async => results);
        return passwordBloc;
      },
      act: (b) => b.add(const PasswordSearchRequested('github')),
      expect: () => [
        isA<PasswordLoading>(),
        isA<PasswordLoaded>()
            .having((s) => s.query, 'query', equals('github'))
            .having((s) => s.cards, 'cards', equals(results)),
      ],
      verify: (_) => verify(mockVaultService.search('github')).called(1),
    );

    blocTest<PasswordBloc, PasswordState>(
      '搜索空关键词 → Loading → Loaded(全量)',
      build: () {
        final all = [
          makePasswordCard(),
          makePasswordCard(cardId: kTestCardId2)
        ];
        when(mockVaultService.search('')).thenAnswer((_) async => all);
        return passwordBloc;
      },
      act: (b) => b.add(const PasswordSearchRequested('')),
      expect: () => [
        isA<PasswordLoading>(),
        isA<PasswordLoaded>().having((s) => s.query, 'empty query', equals('')),
      ],
    );
  });

  // ==================== [3] 新增 ====================

  group('PasswordAddRequested', () {
    final payload = makePasswordPayload();
    final updatedCards = [makePasswordCard()];

    blocTest<PasswordBloc, PasswordState>(
      '新增成功 → OperationInProgress → Loading → Loaded',
      build: () {
        when(mockVaultService.createCard(payload))
            .thenAnswer((_) async => makePasswordCard());
        when(mockVaultService.getAllCards())
            .thenAnswer((_) async => updatedCards);
        return passwordBloc;
      },
      act: (b) => b.add(PasswordAddRequested(payload)),
      expect: () => [
        isA<PasswordOperationInProgress>(),
        isA<PasswordLoading>(),
        isA<PasswordLoaded>(),
      ],
      verify: (_) {
        verify(mockVaultService.createCard(payload)).called(1);
        verify(mockVaultService.getAllCards()).called(1); // 自动触发重载
      },
    );

    blocTest<PasswordBloc, PasswordState>(
      '新增失败 → OperationInProgress → Error',
      build: () {
        when(mockVaultService.createCard(payload))
            .thenThrow(StateError('Vault not unlocked'));
        return passwordBloc;
      },
      act: (b) => b.add(PasswordAddRequested(payload)),
      expect: () => [
        isA<PasswordOperationInProgress>(),
        isA<PasswordError>().having(
            (s) => s.message, 'contains error', contains('Vault not unlocked')),
      ],
    );
  });

  // ==================== [4] 更新 ====================

  group('PasswordUpdateRequested', () {
    final payload = makePasswordPayload(title: 'Updated Title');
    final updatedCards = [makePasswordCard()];

    blocTest<PasswordBloc, PasswordState>(
      '更新成功 → OperationInProgress → Loading → Loaded',
      build: () {
        when(mockVaultService.updateCard(kTestCardId1, payload))
            .thenAnswer((_) async => makePasswordCard());
        when(mockVaultService.getAllCards())
            .thenAnswer((_) async => updatedCards);
        return passwordBloc;
      },
      act: (b) => b.add(PasswordUpdateRequested(kTestCardId1, payload)),
      expect: () => [
        isA<PasswordOperationInProgress>(),
        isA<PasswordLoading>(),
        isA<PasswordLoaded>(),
      ],
    );

    blocTest<PasswordBloc, PasswordState>(
      '更新失败 → OperationInProgress → Error',
      build: () {
        when(mockVaultService.updateCard(kTestCardId1, payload))
            .thenThrow(Exception('Card not found'));
        return passwordBloc;
      },
      act: (b) => b.add(PasswordUpdateRequested(kTestCardId1, payload)),
      expect: () => [
        isA<PasswordOperationInProgress>(),
        isA<PasswordError>(),
      ],
    );
  });

  // ==================== [5] 删除 ====================

  group('PasswordDeleteRequested', () {
    final remainingCards = <PasswordCard>[];

    blocTest<PasswordBloc, PasswordState>(
      '删除成功 → OperationInProgress → Loading → Loaded(空列表)',
      build: () {
        when(mockVaultService.deleteCard(kTestCardId1))
            .thenAnswer((_) async => true);
        when(mockVaultService.getAllCards())
            .thenAnswer((_) async => remainingCards);
        return passwordBloc;
      },
      act: (b) => b.add(const PasswordDeleteRequested(kTestCardId1)),
      expect: () => [
        isA<PasswordOperationInProgress>(),
        isA<PasswordLoading>(),
        isA<PasswordLoaded>()
            .having((s) => s.cards, 'empty after delete', isEmpty),
      ],
      verify: (_) {
        verify(mockVaultService.deleteCard(kTestCardId1)).called(1);
        verify(mockVaultService.getAllCards()).called(1);
      },
    );

    blocTest<PasswordBloc, PasswordState>(
      '删除失败 → OperationInProgress → Error',
      build: () {
        when(mockVaultService.deleteCard(kTestCardId1))
            .thenThrow(Exception('DB write failed'));
        return passwordBloc;
      },
      act: (b) => b.add(const PasswordDeleteRequested(kTestCardId1)),
      expect: () => [
        isA<PasswordOperationInProgress>(),
        isA<PasswordError>(),
      ],
    );
  });

  // ==================== [6] 初始状态 ====================

  test('初始状态为 PasswordInitial', () {
    expect(passwordBloc.state, isA<PasswordInitial>());
  });
}
