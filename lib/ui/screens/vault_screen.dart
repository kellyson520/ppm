import 'package:flutter/material.dart';
import '../../services/vault_service.dart';
import '../../services/auth_service.dart';
import '../../core/models/models.dart';
import '../widgets/password_card_item.dart';
import 'add_password_screen.dart';
import 'password_detail_screen.dart';
import 'authenticator_screen.dart';
import 'add_auth_screen.dart';
import 'settings_screen.dart';

/// Vault 主页�?- 三重鼎立架构
/// 
/// 底部导航栏：
/// 1. 密码 (Password) - 密码管理
/// 2. 验证�?(Authenticator) - TOTP 二步验证
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
  
  // Services
  final AuthService _authService = AuthService();
  
  // Password tab state
  final _searchController = TextEditingController();
  List<PasswordCard> _cards = [];
  List<PasswordCard> _filteredCards = [];
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
      
      setState(() {
        _cards = cards;
        _filteredCards = cards;
        _stats = stats;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load vault data');
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

  Future<void> _navigateToAddPassword() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddPasswordScreen(
          vaultService: widget.vaultService,
        ),
      ),
    );

    if (result == true) {
      _loadData();
      _showSuccess('Password saved successfully');
    }
  }

  Future<void> _navigateToPasswordDetail(PasswordCard card) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordDetailScreen(
          vaultService: widget.vaultService,
          card: card,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          icon: const Icon(Icons.lock_outline),
          onPressed: widget.onLockRequested,
          tooltip: '锁定保险�?,
        ),
        actions: [
          if (_currentIndex == 0 && _stats != null && _stats!.pendingSyncCount > 0)
            Badge(
              label: Text('${_stats!.pendingSyncCount}'),
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () {
                  _showSuccess('Sync started');
                },
              ),
            )
          else if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                _showSuccess('Already up to date');
              },
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _currentIndex == 2 
          ? null // 设置页面不需�?FAB
          : FloatingActionButton.extended(
              onPressed: _currentIndex == 0
                  ? _navigateToAddPassword
                  : _navigateToAddAuth,
              icon: const Icon(Icons.add),
              label: Text(_currentIndex == 0 ? '添加密码' : '添加验证'),
              backgroundColor: _currentIndex == 0
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF00BFA6),
            ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '密码保险�?;
      case 1:
        return '身份验证�?;
      case 2:
        return '设置';
      default:
        return 'ZTD Vault';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildPasswordTab();
      case 1:
        return AuthenticatorScreen(
          vaultService: widget.vaultService,
          authService: _authService,
          // DEK/SearchKey 通过 VaultService 会话获取
          // 这里�?null 是因为安全考虑，实际使用时需�?VaultService 获取
          dek: null,
          searchKey: null,
          deviceId: null,
        );
      case 2:
        return _buildSettingsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPasswordTab() {
    return Column(
      children: [
        // 搜索�?
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: '搜索密码...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        // 统计�?
        if (_stats != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatChip(
                  Icons.password,
                  '${_stats!.cardCount}',
                  '密码',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.history,
                  '${_stats!.eventCount}',
                  '事件',
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        // 密码列表
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCards.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = _filteredCards[index];
                          return PasswordCardItem(
                            card: card,
                            onTap: () => _navigateToPasswordDetail(card),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    // 直接嵌入设置页面内容（而非导航跳转�?
    return SettingsScreen(
      vaultService: widget.vaultService,
      onLockRequested: widget.onLockRequested,
      isEmbedded: true,
    );
  }

  void _navigateToAddAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAuthScreen(
          authService: _authService,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  /// 底部导航�?- 三重鼎立
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.lock_outline,
                activeIcon: Icons.lock,
                label: '密码',
                color: const Color(0xFF6C63FF),
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.verified_user_outlined,
                activeIcon: Icons.verified_user,
                label: '验证�?,
                color: const Color(0xFF00BFA6),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: '设置',
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? color : Colors.white54,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            _searchController.text.isEmpty
                ? '暂无密码'
                : '未找到匹配项',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty)
            Text(
              '点击右下�?+ 按钮添加第一个密�?,
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
