/// AuthBloc 状态机测试 — TOTP/认证卡片管理
library;

import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/blocs/auth/auth_bloc.dart';
import 'package:ztd_password_manager/services/auth_service.dart';
import 'package:ztd_password_manager/core/models/auth_card.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import '../../helpers/test_helpers.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  late MockAuthService mockAuthService;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthService = MockAuthService();
    authBloc = AuthBloc(authService: mockAuthService);
  });

  tearDown(() {
    authBloc.close();
  });

  // ==================== [1] 加载 ====================

  group('AuthLoadRequested', () {
    final cards = [makeAuthCard(), makeAuthCard(cardId: kTestCardId2)];

    blocTest<AuthBloc, AuthState>(
      '成功加载 → Loading → Loaded',
      build: () {
        when(mockAuthService.getActiveCards()).thenReturn(cards);
        return authBloc;
      },
      act: (b) => b.add(AuthLoadRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthLoaded>().having((s) => s.cards, 'cards', equals(cards)),
      ],
      verify: (_) => verify(mockAuthService.getActiveCards()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      '加载失败 → Loading → Error (不吞异常)',
      build: () {
        when(mockAuthService.getActiveCards()).thenThrow(Exception('DB error'));
        return authBloc;
      },
      act: (b) => b.add(AuthLoadRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.message, 'message', contains('internal error')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '空列表 → Loaded(empty)',
      build: () {
        when(mockAuthService.getActiveCards()).thenReturn([]);
        return authBloc;
      },
      act: (b) => b.add(AuthLoadRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthLoaded>().having((s) => s.cards, 'empty', isEmpty),
      ],
    );
  });

  // ==================== [2] 搜索 ====================

  group('AuthSearchRequested', () {
    final allCards = [makeAuthCard(), makeAuthCard(cardId: kTestCardId2)];

    blocTest<AuthBloc, AuthState>(
      '搜索 → 返回全部卡片 (当前实现直接返回全部)',
      build: () {
        when(mockAuthService.getActiveCards()).thenReturn(allCards);
        return authBloc;
      },
      act: (b) => b.add(const AuthSearchRequested('test')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthLoaded>()
            .having((s) => s.cards, 'cards', allCards)
            .having((s) => s.query, 'query', 'test'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '搜索失败 → Error',
      build: () {
        when(mockAuthService.getActiveCards()).thenThrow(Exception('search failed'));
        return authBloc;
      },
      act: (b) => b.add(const AuthSearchRequested('')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.message, 'msg', contains('internal error')),
      ],
    );
  });

  // ==================== [3] 添加 ====================

  group('AuthAddRequested', () {
    const payload = AuthPayload(
      issuer: 'GitHub',
      account: 'test@example.com',
      secret: 'JBSWY3DPEHPK3PXP',
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
    );
    final dek = Uint8List(32);
    final searchKey = Uint8List(16);
    const deviceId = 'device-1';

    blocTest<AuthBloc, AuthState>(
      '添加成功 → OperationInProgress → Loaded',
      build: () {
        when(mockAuthService.createCard(
          payload: anyNamed('payload'),
          dek: anyNamed('dek'),
          searchKey: anyNamed('searchKey'),
          deviceId: anyNamed('deviceId'),
        )).thenReturn(makeAuthCard());
        when(mockAuthService.getActiveCards()).thenReturn([]);
        return authBloc;
      },
      act: (b) => b.add(AuthAddRequested(
        payload: payload,
        dek: dek,
        searchKey: searchKey,
        deviceId: deviceId,
      )),
      expect: () => [
        isA<AuthOperationInProgress>(),
        isA<AuthLoading>(),
        isA<AuthLoaded>(),
      ],
      verify: (_) {
        verify(mockAuthService.createCard(
          payload: payload,
          dek: dek,
          searchKey: searchKey,
          deviceId: deviceId,
        )).called(1);
        verify(mockAuthService.getActiveCards()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      '添加失败 → Error',
      build: () {
        when(mockAuthService.createCard(
          payload: anyNamed('payload'),
          dek: anyNamed('dek'),
          searchKey: anyNamed('searchKey'),
          deviceId: anyNamed('deviceId'),
        )).thenThrow(Exception('create failed'));
        return authBloc;
      },
      act: (b) => b.add(AuthAddRequested(
        payload: payload,
        dek: dek,
        searchKey: searchKey,
        deviceId: deviceId,
      )),
      expect: () => [
        isA<AuthOperationInProgress>(),
        isA<AuthError>().having((s) => s.message, 'msg', contains('internal error')),
      ],
    );
  });

  // ==================== [4] 更新 ====================

  group('AuthUpdateRequested', () {
    const payload = AuthPayload(
      issuer: 'Updated',
      account: 'updated@test.com',
      secret: 'NEWSECRET',
    );
    final dek = Uint8List(32);
    final searchKey = Uint8List(16);
    const deviceId = 'device-1';

    blocTest<AuthBloc, AuthState>(
      '更新成功 → OperationInProgress → Loaded',
      build: () {
        when(mockAuthService.updateCard(
          cardId: anyNamed('cardId'),
          newPayload: anyNamed('newPayload'),
          dek: anyNamed('dek'),
          searchKey: anyNamed('searchKey'),
          deviceId: anyNamed('deviceId'),
        )).thenReturn(null);
        when(mockAuthService.getActiveCards()).thenReturn([]);
        return authBloc;
      },
      act: (b) => b.add(AuthUpdateRequested(
        cardId: 'card-1',
        payload: payload,
        dek: dek,
        searchKey: searchKey,
        deviceId: deviceId,
      )),
      expect: () => [
        isA<AuthOperationInProgress>(),
        isA<AuthLoading>(),
        isA<AuthLoaded>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '更新失败 → Error (不可恢复)',
      build: () {
        when(mockAuthService.updateCard(
          cardId: anyNamed('cardId'),
          newPayload: anyNamed('newPayload'),
          dek: anyNamed('dek'),
          searchKey: anyNamed('searchKey'),
          deviceId: anyNamed('deviceId'),
        )).thenThrow(Exception('update failed'));
        return authBloc;
      },
      act: (b) => b.add(AuthUpdateRequested(
        cardId: 'card-1',
        payload: payload,
        dek: dek,
        searchKey: searchKey,
        deviceId: deviceId,
      )),
      expect: () => [
        isA<AuthOperationInProgress>(),
        isA<AuthError>().having((s) => s.message, 'msg', contains('internal error')),
      ],
    );
  });

  // ==================== [5] 删除 ====================

  group('AuthDeleteRequested', () {
    blocTest<AuthBloc, AuthState>(
      '删除成功 → OperationInProgress → Loaded',
      build: () {
        when(mockAuthService.deleteCard(any, any)).thenReturn(true);
        when(mockAuthService.getActiveCards()).thenReturn([]);
        return authBloc;
      },
      act: (b) => b.add(const AuthDeleteRequested('card-1', 'device-1')),
      expect: () => [
        isA<AuthOperationInProgress>(),
        isA<AuthLoading>(),
        isA<AuthLoaded>(),
      ],
      verify: (_) => verify(mockAuthService.deleteCard('card-1', 'device-1')).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      '删除失败 → Error',
      build: () {
        when(mockAuthService.deleteCard(any, any)).thenThrow(Exception('delete failed'));
        return authBloc;
      },
      act: (b) => b.add(const AuthDeleteRequested('card-1', 'device-1')),
      expect: () => [
        isA<AuthOperationInProgress>(),
        isA<AuthError>().having((s) => s.message, 'msg', contains('internal error')),
      ],
    );
  });
}
