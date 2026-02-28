import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/vault_service.dart';
import '../../services/auth_service.dart';
import '../../core/models/models.dart';
import '../widgets/password_card_item.dart';
import '../widgets/responsive_layout.dart';
import 'add_password_screen.dart';
import 'password_detail_screen.dart';
import 'authenticator_screen.dart';
import 'add_auth_screen.dart';
import 'settings_screen.dart';
import '../../l10n/app_localizations.dart';

/// Vault 主页 - 三重鼎立架构
///
/// 底部导航栏：
/// 1. 密码 (Password) - 密码管理
/// 2. 验证器 (Authenticator) - TOTP 二步验证
/// 3. 设置 (Settings) - 配置管理
class VaultScreen extends StatefulWidget {
  final VaultService vaultService;
  final VoidCallback onLockRequested;

  const VaultScreen({
    super.key,
    required this.vaultService,
    required this.onLockRequested,
  });

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  int _currentIndex = 0;
  bool _isModalOpen = false;

  // Services
  final AuthService _authService = AuthService();

  // Password tab state
  final _searchController = TextEditingController();
  List<PasswordCard> _cards = [];
  List<PasswordCard> _filteredCards = [];
  Map<String, PasswordPayload> _payloads = {};
  PasswordCard? _selectedPasswordCard;
  bool _isLoading = true;
  VaultStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cards = await widget.vaultService.getAllCards();
      final stats = await widget.vaultService.getStats();

      final Map<String, PasswordPayload> payloads = {};
      for (final card in cards) {
        final payload = await widget.vaultService.decryptCard(card);
        if (payload != null) {
          payloads[card.cardId] = payload;
        }
      }

      setState(() {
        _cards = cards;
        _filteredCards = cards;
        _payloads = payloads;
        _stats = stats;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.anErrorOccurred);
      }
    }
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCards = _cards;
      } else {
        _filteredCards = _cards.where((card) {
          return card.cardId.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToAddPassword() {
    // 触发底层主界面深沉缩放动画
    setState(() {
      _isModalOpen = true;
    });

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 依赖内部内容的玻璃效果
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.4), // 环境变暗
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 300),
      )..drive(CurveTween(curve: Curves.easeOutCubic)),
      builder: (context) => AddPasswordScreen(
        vaultService: widget.vaultService,
      ),
    ).then((result) {
      if (mounted) {
        setState(() {
          _isModalOpen = false;
        });
        if (result == true) {
          _loadData();
          final l10n = AppLocalizations.of(context)!;
          _showSuccess(l10n.passwordSaved);
        }
      }
    });
  }

  void _navigateToPasswordDetail(PasswordCard card) {
    if (ResponsiveLayout.isExpanded(context)) {
      setState(() {
        _selectedPasswordCard = card;
      });
    } else {
      // 触发底层主界面深沉缩放动画
      setState(() {
        _isModalOpen = true;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, // 依赖内部内容的玻璃效果
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.4), // 环境变暗
        transitionAnimationController: AnimationController(
          vsync: Navigator.of(context),
          duration: const Duration(milliseconds: 400),
          reverseDuration: const Duration(milliseconds: 300),
        )..drive(CurveTween(curve: Curves.easeOutCubic)),
        builder: (context) => PasswordDetailScreen(
          vaultService: widget.vaultService,
          card: card,
          isEmbedded: false,
        ),
      ).then((_) {
        // 模态框关闭后，取消主界面的缩小状态
        if (mounted) {
          setState(() {
            _isModalOpen = false;
          });
          // 重新加载可能的数据更新
          _loadData();
        }
      });
    }
  }

  AppBar _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(_getTitle(l10n)),
      leading: IconButton(
        icon: const Icon(Icons.lock_outline),
        onPressed: widget.onLockRequested,
        tooltip: l10n.lockVault,
      ),
      actions: [
        if (_currentIndex == 0 &&
            _stats != null &&
            _stats!.pendingSyncCount > 0)
          Badge(
            label: Text('${_stats!.pendingSyncCount}'),
            child: IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                _showSuccess(l10n.syncStarted);
              },
            ),
          )
        else if (_currentIndex == 0)
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              _showSuccess(l10n.alreadyUpToDate);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ResponsiveLayout(
      compact: _buildCompact(l10n),
      medium: _buildTablet(l10n),
      expanded: _buildTablet(l10n), // Phase 3 将进一步实现 Expanded 的横屏 Master-Detail
    );
  }

  Widget _buildCompact(AppLocalizations l10n) {
    // 强制去除 Scaffold 自带的 Background 以利用外层的深色宇宙径向渐变
    return Scaffold(
      backgroundColor: Colors.transparent, // 透过 Scaffold 看到背景
      // 废弃默认的 bottomNavigationBar, 改用 Stack 悬浮 Dock
      // appBar: _buildAppBar(l10n), // 废弃传统顶栏，将在列表内变为 SliverAppBar
      body: Stack(
        children: [
          // 第一层：宇宙深渊背景光效
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                // 以底部中心为圆心的一片巨大的幽暗紫色微光
                gradient: RadialGradient(
                  center: Alignment(0, 1.2),
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E1C3A), // 幽暗的紫黑微光
                    Color(0xFF101018), // 基础极深黑底
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // 第二层：主内容包裹层 (弹窗 3D 沉降)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            // 假设打开弹窗时缩小，通过 Matrix 处理 Z 轴下沉
            // ignore: deprecated_member_use
            transform: _isModalOpen
                ? (Matrix4.identity()
                  ..setTranslationRaw(0.0,
                      MediaQuery.of(context).size.height * 0.04, 0.0) // 往下坠一点
                  // ignore: deprecated_member_use
                  ..scale(0.92, 0.92, 1.0)) // 缩小比例
                : Matrix4.identity(),
            decoration: BoxDecoration(
              // 当缩小的时候给个圆角以符合 iOS 视差设计
              borderRadius:
                  _isModalOpen ? BorderRadius.circular(32) : BorderRadius.zero,
            ),
            clipBehavior: _isModalOpen ? Clip.hardEdge : Clip.none,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isModalOpen ? 0.6 : 1.0, // 背景变暗退到二线
              child: SafeArea(
                bottom: false, // 底部延伸下去，避免出现黑边
                child: _buildBody(l10n),
              ),
            ),
          ),

          // 第三层：浮动玻璃岛 (Floating Glass Dock)
          Positioned(
            bottom: 30, // 悬浮距离
            left: MediaQuery.of(context).size.width * 0.1, // 两侧留空 10%
            right: MediaQuery.of(context).size.width * 0.1,
            child: _buildFloatingDock(l10n),
          ),

          // 悬浮创建按钮 (放在 Dock 外围右侧上方)
          if (_currentIndex != 2)
            Positioned(
              bottom: 110,
              right: 24,
              child: FloatingActionButton(
                onPressed: _currentIndex == 0
                    ? _navigateToAddPassword
                    : _navigateToAddAuth,
                backgroundColor: _currentIndex == 0
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF00BFA6),
                elevation: 4,
                highlightElevation: 0,
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }

  /// 替代传统的 SafeArea 底栏，使用 BackdropFilter 和圆角构建的极细玻璃浮岛
  Widget _buildFloatingDock(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0x991C1C28), // 提供极低透明度的底板深色
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), // Apple HIG 一根反光的细白边
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDockItem(
                index: 0,
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield,
                color: const Color(0xFF6C63FF),
              ),
              _buildDockItem(
                index: 1,
                icon: Icons.access_time_outlined,
                activeIcon: Icons.access_time_filled,
                color: const Color(0xFF00BFA6),
              ),
              _buildDockItem(
                index: 2,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required Color color,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 加入极轻的物理回馈
        HapticFeedback.lightImpact();
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 图标
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? color : Colors.white54,
              size: 26,
            ),
            // 底板原点指示器 (Apple 喜欢在选中的项下面亮一个小点)
            Positioned(
              bottom: 6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 1.0 : 0.0,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet(AppLocalizations l10n) {
    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Row(
        children: [
          _buildNavigationRail(l10n),
          const VerticalDivider(thickness: 1, width: 1),
          // 为了确保后续扩大布局或表单能够安全地不溢出
          Expanded(child: SafeArea(child: ClipRect(child: _buildBody(l10n)))),
        ],
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return l10n.passwordVault;
      case 1:
        return l10n.authenticator;
      case 2:
        return l10n.settings;
      default:
        return l10n.appTitle;
    }
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return _buildPasswordTab(l10n);
      case 1:
        return AuthenticatorScreen(
          vaultService: widget.vaultService,
          authService: _authService,
          dek: widget.vaultService.sessionDek,
          searchKey: widget.vaultService.sessionSearchKey,
          deviceId: widget.vaultService.deviceId,
          onModalStateChanged: (isOpen) =>
              setState(() => _isModalOpen = isOpen),
        );
      case 2:
        return _buildSettingsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPasswordTab(AppLocalizations l10n) {
    if (ResponsiveLayout.isExpanded(context)) {
      // Expanded: Master-Detail
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master: List
          Expanded(
            flex: 2,
            child: _buildPasswordListColumn(l10n),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Detail: Screen
          Expanded(
            flex: 3,
            child: _selectedPasswordCard == null
                ? Center(
                    child: Text(
                      l10n.noPasswords, // Alternatively a placeholder 'Select a password'
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  )
                : PasswordDetailScreen(
                    // Important: Use ValueKey to force recreation when selection changes
                    key: ValueKey(_selectedPasswordCard!.cardId),
                    vaultService: widget.vaultService,
                    card: _selectedPasswordCard!,
                    isEmbedded: true,
                  ),
          ),
        ],
      );
    } else {
      // Compact / Medium
      return _buildPasswordListColumn(l10n);
    }
  }

  Widget _buildPasswordListColumn(AppLocalizations l10n) {
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // 苹果风大标题与模糊搜索框
        SliverAppBar.large(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent, // 避免 M3 默认颜色污染
          expandedHeight: 180,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              _getTitle(l10n),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                  ),
            ),
            background: Padding(
              padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: TextField(
                  controller: _searchController,
                  onChanged: _search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.searchPassword,
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08), // 高通透输入框
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withValues(alpha: 0.5)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 顶层控制状态（统计等，可选留存也可作为 SliverToBoxAdapter）
        if (_stats != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text('RECENT',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const Spacer(),
                  Text('${_stats!.cardCount} items',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          ),

        // 密码列表区
        _isLoading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            : _filteredCards.isEmpty
                ? SliverFillRemaining(
                    child: _buildEmptyState(l10n),
                  )
                : ResponsiveLayout.isMedium(context)
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 8,
                            childAspectRatio: 3.5,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final card = _filteredCards[index];
                              return PasswordCardItem(
                                card: card,
                                payload: _payloads[card.cardId],
                                onTap: () => _navigateToPasswordDetail(card),
                              );
                            },
                            childCount: _filteredCards.length,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final card = _filteredCards[index];
                              return PasswordCardItem(
                                card: card,
                                payload: _payloads[card.cardId],
                                onTap: () => _navigateToPasswordDetail(card),
                              );
                            },
                            childCount: _filteredCards.length,
                          ),
                        ),
                      ),

        // 垫底高度防止内容被 Dock 遮挡
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        )
      ],
    );
  }

  Widget _buildSettingsTab() {
    // 直接嵌入设置页面内容（而非导航跳转）
    return SettingsScreen(
      vaultService: widget.vaultService,
      onLockRequested: widget.onLockRequested,
      isEmbedded: true,
    );
  }

  void _navigateToAddAuth() {
    // 触发底层主界面深沉缩放动画
    setState(() {
      _isModalOpen = true;
    });

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 依赖内部内容的玻璃效果
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.4), // 环境变暗
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 300),
      )..drive(CurveTween(curve: Curves.easeOutCubic)),
      builder: (context) => AddAuthScreen(
        authService: _authService,
        dek: widget.vaultService.sessionDek,
        searchKey: widget.vaultService.sessionSearchKey,
        deviceId: widget.vaultService.deviceId,
      ),
    ).then((result) {
      if (mounted) {
        setState(() {
          _isModalOpen = false;
        });
        // The AuthenticatorScreen inside _buildBody will handle its own refresh
      }
    });
  }

  Widget _buildNavigationRail(AppLocalizations l10n) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: const Color(0xFF16213E),
      indicatorColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
      leading: _currentIndex != 2
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                onPressed: _currentIndex == 0
                    ? _navigateToAddPassword
                    : _navigateToAddAuth,
                backgroundColor: _currentIndex == 0
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF00BFA6),
                child: const Icon(Icons.add),
              ),
            )
          : const SizedBox(height: 72), // Placeholder for FAB space
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.lock_outline),
          selectedIcon: const Icon(Icons.lock, color: Color(0xFF6C63FF)),
          label: Text(
            l10n.passwords,
            style: TextStyle(
              color:
                  _currentIndex == 0 ? const Color(0xFF6C63FF) : Colors.white54,
            ),
          ),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.verified_user_outlined),
          selectedIcon:
              const Icon(Icons.verified_user, color: Color(0xFF00BFA6)),
          label: Text(
            l10n.authenticator,
            style: TextStyle(
              color:
                  _currentIndex == 1 ? const Color(0xFF00BFA6) : Colors.white54,
            ),
          ),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings, color: Color(0xFFFF6B6B)),
          label: Text(
            l10n.settings,
            style: TextStyle(
              color:
                  _currentIndex == 2 ? const Color(0xFFFF6B6B) : Colors.white54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? l10n.noPasswords : l10n.noMatches,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty)
            Text(
              l10n.clickToAdd,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}
