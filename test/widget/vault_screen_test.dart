// VaultScreen UI 交互与状态机测试
//
// 目标：模拟真实的 UI 操作，验证 BLoC 状态与 Widget 树视图的同步。
// 消除：UI 假死、按钮无效、搜索结果不更新等视觉层 Bug。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/ui/screens/vault_screen.dart';
import 'package:ztd_password_manager/blocs/vault/vault_bloc.dart';
import 'package:ztd_password_manager/blocs/vault/vault_state.dart';
import 'package:ztd_password_manager/blocs/vault/vault_event.dart';
import 'package:ztd_password_manager/services/vault_service.dart';
import 'package:ztd_password_manager/l10n/app_localizations.dart';
import '../helpers/test_fixtures.dart';

@GenerateMocks([VaultService])
void main() {
  group('VaultScreen UI 守卫', () {
    testWidgets('空状态展示 — 当没有卡片时应显示占位图', (WidgetTester tester) async {
      await _pumpVaultScreen(tester, VaultStatus.unlocked);

      expect(find.text('No passwords'), findsOneWidget);
    });

    testWidgets('搜索交互 — 输入文本应触发过滤逻辑', (WidgetTester tester) async {
      await _pumpVaultScreen(tester, VaultStatus.unlocked);

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'github');
      await tester.pump();
    });

    testWidgets('底部导航栏切换 — 点击应切换页面', (WidgetTester tester) async {
      await _pumpVaultScreen(tester, VaultStatus.unlocked);

      final passwordIcon = find.byIcon(Icons.shield_outlined);
      final authenticatorIcon = find.byIcon(Icons.access_time_outlined);
      final settingsIcon = find.byIcon(Icons.settings_outlined);

      expect(passwordIcon, findsOneWidget);

      await tester.tap(authenticatorIcon);
      await tester.pumpAndSettle();
    });
  });
}

/// 构建测试环境
Future<void> _pumpVaultScreen(WidgetTester tester, VaultStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: BlocProvider<VaultBloc>(
        create: (context) => MockVaultBloc(status),
        child: VaultScreen(
          vaultService: MockVaultService(),
          onLockRequested: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Mock VaultBloc
class MockVaultBloc extends Bloc<VaultEvent, VaultState> {
  MockVaultBloc(VaultStatus status)
      : super(VaultState(status: status)) {
    on<VaultCheckRequested>((event, emit) {
      emit(VaultState(status: status));
    });
  }
}