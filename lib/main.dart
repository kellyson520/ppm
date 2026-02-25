import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/diagnostics/crash_report_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/lock_screen.dart';
import 'ui/screens/vault_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/screens/crash_report_screen.dart';
import 'services/vault_service.dart';
import 'services/auth_service.dart';
import 'blocs/vault/vault_bloc.dart';
import 'blocs/password/password_bloc.dart';
import 'blocs/auth/auth_bloc.dart';

/// 全局 Navigator Key，供 CrashReportService 在 Widget 树外进行界面跳转
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        // ── 崩溃日志系统初始化 ────────────────────────────────────────────────────
        final crashService = CrashReportService.instance;

        // 注入崩溃 UI 路由回调
        crashService.setHandler((CrashInfo info) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => CrashReportScreen(crashInfo: info),
              ),
              (route) => false, // 清空历史路由，防止用户回退到损坏状态
            );
          } else {
            // 早期崩溃兜底逻辑：Navigator 还未绑定（MaterialApp 还没渲染）
            // 直接通过一个新的 MaterialApp 容器显示错误界面
            runApp(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(brightness: Brightness.dark),
                home: CrashReportScreen(crashInfo: info),
              ),
            );
          }
        });

        // 注册 Flutter 框架同步异常钩子
        crashService.registerFlutterErrorHook();
        // 注册 Dart 平台层异常钩子
        crashService.registerPlatformErrorHook();
        // ──────────────────────────────────────────────────────────────────────────

        // Set preferred orientations
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        // Set system UI overlay style
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF1A1A2E),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );

        runApp(const ZTDPasswordManagerApp());
      } on Object catch (e, stack) {
        debugPrint('CRITICAL MAIN ERROR: $e');
        debugPrint(stack.toString());

        // 尝试手动上报早期异常
        CrashReportService.instance.reportZoneError(e, stack);
      }
    },
    (Object error, StackTrace stack) {
      CrashReportService.instance.reportZoneError(error, stack);
    },
  );
}

class ZTDPasswordManagerApp extends StatefulWidget {
  const ZTDPasswordManagerApp({super.key});

  @override
  State<ZTDPasswordManagerApp> createState() => _ZTDPasswordManagerAppState();
}

class _ZTDPasswordManagerAppState extends State<ZTDPasswordManagerApp> {
  late final VaultService _vaultService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _vaultService = VaultService();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _vaultService.dispose();
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _vaultService),
        RepositoryProvider.value(value: _authService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => VaultBloc(vaultService: _vaultService)
              ..add(VaultCheckRequested()),
          ),
          BlocProvider(
            create: (context) => PasswordBloc(vaultService: _vaultService),
          ),
          BlocProvider(
            create: (context) => AuthBloc(authService: _authService),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ZTD Password Manager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF1A1A2E),
            cardColor: const Color(0xFF16213E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A2E),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF0F3460),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
              ),
            ),
            iconTheme: const IconThemeData(
              color: Colors.white70,
            ),
            fontFamily: 'Inter',
          ),
          home: const AppNavigator(),
        ),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        switch (state.status) {
          case VaultStatus.initial:
          case VaultStatus.loading:
            return const SplashScreen();

          case VaultStatus.setupRequired:
            return const SetupScreen();

          case VaultStatus.locked:
            return const LockScreen();

          case VaultStatus.unlocked:
            return VaultScreen(
              vaultService: context.read<VaultService>(),
              onLockRequested: () {
                context.read<VaultBloc>().add(VaultLockRequested());
              },
            );

          case VaultStatus.error:
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Failed to initialize vault',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<VaultBloc>().add(VaultCheckRequested());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
