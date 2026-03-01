import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/vault_service.dart';
import '../../core/models/auth_card.dart';
import '../../core/crypto/totp_generator.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/bouncing_widget.dart';
import 'auth_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// Authenticator 页面 - 三重鼎立之验证器
///
/// 加密策略
/// - 列表状态：卡片名称显示为盲索引摘要（轻度加密）
/// - 点击卡片：按需解密，显示 TOTP 验证码
/// - 验证码每 30 秒自动刷新
class AuthenticatorScreen extends StatefulWidget {
  final VaultService vaultService;
  final AuthService authService;
  final Uint8List? dek;
  final Uint8List? searchKey;
  final String? deviceId;
  final Function(bool)? onModalStateChanged;

  const AuthenticatorScreen({
    super.key,
    required this.vaultService,
    required this.authService,
    this.dek,
    this.searchKey,
    this.deviceId,
    this.onModalStateChanged,
  });

  @override
  State<AuthenticatorScreen> createState() => _AuthenticatorScreenState();
}

class _AuthenticatorScreenState extends State<AuthenticatorScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  List<AuthCard> _cards = [];
  List<AuthCard> _filteredCards = [];
  AuthCard? _selectedAuthCard;
  bool _isLoading = true;

  // TOTP 刷新
  Timer? _totpTimer;
  final Map<String, _DecryptedEntry> _decryptedEntries = {}; // 展开的卡片缓存

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTotpTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _totpTimer?.cancel();
    _decryptedEntries.clear();
    super.dispose();
  }

  void _startTotpTimer() {
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _decryptedEntries.isNotEmpty) {
        setState(() {
          // 刷新所有已解密条目的验证码
          for (final entry in _decryptedEntries.values) {
            entry.code = TOTPGenerator.generateCode(
              entry.payload.secret,
              algorithm: entry.payload.algorithm,
              digits: entry.payload.digits,
              period: entry.payload.period,
            );
            entry.remaining = TOTPGenerator.getRemainingSeconds(
              period: entry.payload.period,
            );
            entry.progress = TOTPGenerator.getProgress(
              period: entry.payload.period,
            );
          }
        });
      }
    });
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });

    try {
      _cards = widget.authService.getActiveCards();
      _filteredCards = _cards;
    } on Exception {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCards = _cards;
      } else if (widget.dek != null) {
        final lowerQuery = query.toLowerCase();
        _filteredCards = _cards.where((card) {
          final payload = widget.authService.decryptCard(card, widget.dek!);
          if (payload != null) {
            return payload.issuer.toLowerCase().contains(lowerQuery) ||
                payload.account.toLowerCase().contains(lowerQuery);
          }
          return false;
        }).toList();
      } else if (widget.searchKey != null) {
        _filteredCards = widget.authService.search(query, widget.searchKey!);
      }
    });
  }

  /// 按需解密 - 切换卡片展开/折叠状态
  void _toggleCard(AuthCard card) {
    setState(() {
      if (_decryptedEntries.containsKey(card.cardId)) {
        // 折叠 - 擦除内存中的密文
        _decryptedEntries.remove(card.cardId);
        HapticFeedback.lightImpact();
      } else {
        // 展开 - 按需解密
        if (widget.dek != null) {
          final payload = widget.authService.decryptCard(card, widget.dek!);
          if (payload != null) {
            final code = TOTPGenerator.generateCode(
              payload.secret,
              algorithm: payload.algorithm,
              digits: payload.digits,
              period: payload.period,
            );
            _decryptedEntries[card.cardId] = _DecryptedEntry(
              payload: payload,
              code: code,
              remaining:
                  TOTPGenerator.getRemainingSeconds(period: payload.period),
              progress: TOTPGenerator.getProgress(period: payload.period),
            );
            HapticFeedback.mediumImpact();
          }
        }
      }
    });
  }

  /// 复制验证码到剪贴板
  void _copyCode(String code) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${l10n.codeCopied}: $code'),
          ],
        ),
        backgroundColor: const Color(0xFF00BFA6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // 10 秒后清除剪贴板
    Future.delayed(const Duration(seconds: 10), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  Future<void> _navigateToAuthDetail(AuthCard card) async {
    final entry = _decryptedEntries[card.cardId];
    if (entry == null) return;

    if (ResponsiveLayout.isExpanded(context)) {
      setState(() {
        _selectedAuthCard = card;
      });
      return;
    }

    // 触发父级 3D 缩放效果
    widget.onModalStateChanged?.call(true);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => AuthDetailScreen(
        authService: widget.authService,
        card: card,
        payload: entry.payload,
        dek: widget.dek,
        searchKey: widget.searchKey,
        deviceId: widget.deviceId,
      ),
    );

    widget.onModalStateChanged?.call(false);

    if (result == true) {
      _loadData();
      _decryptedEntries.remove(card.cardId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (ResponsiveLayout.isExpanded(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildAuthListColumn(l10n),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            flex: 3,
            child: _selectedAuthCard == null ||
                    !_decryptedEntries.containsKey(_selectedAuthCard!.cardId)
                ? Center(
                    child: Text(
                      l10n.noAuthenticators,
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  )
                : AuthDetailScreen(
                    key: ValueKey(_selectedAuthCard!.cardId),
                    authService: widget.authService,
                    card: _selectedAuthCard!,
                    payload:
                        _decryptedEntries[_selectedAuthCard!.cardId]!.payload,
                    dek: widget.dek,
                    searchKey: widget.searchKey,
                    deviceId: widget.deviceId,
                    isEmbedded: true,
                  ),
          ),
        ],
      );
    } else {
      return _buildAuthListColumn(l10n);
    }
  }

  Widget _buildAuthListColumn(AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: Colors.transparent, // 避免背景颜色变差
          expandedHeight: 140,
          collapsedHeight: 64,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              l10n.authenticator,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            background: Container(
              color: Colors.transparent, // iOS 扁平无色底
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _search,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l10n.searchAuthenticator,
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withValues(alpha: 0.5)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.white.withValues(alpha: 0.5)),
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

        // 顶层统计
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text('ACCOUNTS',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const Spacer(),
                Text('${_cards.length} items',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ),

        // 卡片列表
        _isLoading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            : _filteredCards.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState(l10n))
                : SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final card = _filteredCards[index];
                          final entry = _decryptedEntries[card.cardId];
                          return _buildAuthCardItem(card, entry, l10n);
                        },
                        childCount: _filteredCards.length,
                      ),
                    ),
                  ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)), // 为悬浮栏留白
      ],
    );
  }

  Widget _buildAuthCardItem(
      AuthCard card, _DecryptedEntry? entry, AppLocalizations l10n) {
    final isExpanded = entry != null;

    return BouncingWidget(
      onTap: () => _toggleCard(card),
      onLongPress: isExpanded ? () => _navigateToAuthDetail(card) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded
              ? const Color(0xFF16213E).withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          // 仅在展开态添加细微高光发散阴影，否则扁平化
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：图标 + 名称 + 锁状态
            Row(
              children: [
                // 发行方图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isExpanded
                          ? [const Color(0xFF00BFA6), const Color(0xFF6C63FF)]
                          : [
                              const Color(0xFF6C63FF).withValues(alpha: 0.6),
                              const Color(0xFF00BFA6).withValues(alpha: 0.6)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpanded ? Icons.shield : Icons.lock,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // 名称信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpanded
                            ? entry.payload.issuer.isNotEmpty
                                ? entry.payload.issuer
                                : entry.payload.account
                            : l10n.clickToDecrypt,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isExpanded ? Colors.white : Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isExpanded && entry.payload.issuer.isNotEmpty)
                        Text(
                          entry.payload.account,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (!isExpanded)
                        Text(
                          'ID: ${card.cardId.substring(0, card.cardId.length > 12 ? 12 : card.cardId.length)}...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                // 解锁状态
                Icon(
                  isExpanded ? Icons.lock_open : Icons.lock_outline,
                  color: isExpanded
                      ? const Color(0xFF00BFA6)
                      : Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),

            // 展开区域：TOTP 验证码
            if (isExpanded) ...[
              const SizedBox(height: 16),
              // 分隔线
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 验证码区域
              Row(
                children: [
                  // 倒计时环
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1.0 - entry.progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            entry.remaining <= 5
                                ? Colors.red
                                : entry.remaining <= 10
                                    ? Colors.orange
                                    : const Color(0xFF00BFA6),
                          ),
                        ),
                        Text(
                          '${entry.remaining}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: entry.remaining <= 5
                                ? Colors.red
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 验证码
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _copyCode(entry.code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatCode(entry.code),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 6,
                                fontFamily: 'monospace',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.copy_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 底部操作栏
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToAuthDetail(card),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: Text(l10n.details,
                        style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 格式化验证码显示 (123 456)
  String _formatCode(String code) {
    if (code.length <= 3) return code;
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? l10n.noAuthenticators
                : l10n.noMatches,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty)
            Text(
              l10n.clickToAddAuth,
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

/// 已解密条目缓存（内存中临时存储）
class _DecryptedEntry {
  final AuthPayload payload;
  String code;
  int remaining;
  double progress;

  _DecryptedEntry({
    required this.payload,
    required this.code,
    required this.remaining,
    required this.progress,
  });
}
