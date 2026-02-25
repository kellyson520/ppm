import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../core/models/auth_card.dart';
import 'qr_scanner_screen.dart';

/// 添加验证器页面
/// 
/// 支持导入方式：
/// 1. 手动输入 - 填写发行方、账号、密钥等
/// 2. URI 导入 - 粘贴 otpauth:// URI
/// 3. 二维码扫描 - 扫描 2FA 设置二维码
class AddAuthScreen extends StatefulWidget {
  final AuthService authService;
  final Uint8List? dek;
  final Uint8List? searchKey;
  final String? deviceId;
  final AuthCard? editCard;
  final AuthPayload? editPayload;

  const AddAuthScreen({
    super.key,
    required this.authService,
    this.dek,
    this.searchKey,
    this.deviceId,
    this.editCard,
    this.editPayload,
  });

  @override
  State<AddAuthScreen> createState() => _AddAuthScreenState();
}

class _AddAuthScreenState extends State<AddAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // 手动输入字段
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _notesController = TextEditingController();
  
  // URI 导入字段
  final _uriController = TextEditingController();
  
  String _algorithm = 'SHA1';
  int _digits = 6;
  int _period = 30;
  bool _isLoading = false;
  bool _showSecret = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.editPayload != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final payload = widget.editPayload!;
    _issuerController.text = payload.issuer;
    _accountController.text = payload.account;
    _secretController.text = payload.secret;
    _algorithm = payload.algorithm;
    _digits = payload.digits;
    _period = payload.period;
    _notesController.text = payload.notes ?? '';
    _uriController.text = payload.toOtpAuthUri();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    _notesController.dispose();
    _uriController.dispose();
    super.dispose();
  }

  /// 从 URI 解析并填充表单
  void _parseUri() {
    final uri = _uriController.text.trim();
    if (uri.isEmpty || !uri.startsWith('otpauth://')) {
      _showError('请输入有效的 otpauth:// URI');
      return;
    }

    try {
      final payload = AuthPayload.fromOtpAuthUri(uri);
      setState(() {
        _issuerController.text = payload.issuer;
        _accountController.text = payload.account;
        _secretController.text = payload.secret;
        _algorithm = payload.algorithm;
        _digits = payload.digits;
        _period = payload.period;
      });
      
      // 切换到手动输入 tab 让用户确认
      _tabController.animateTo(0);
      _showSuccess('URI 解析成功，请确认信息');
    } on Exception catch (e) {
      _showError('URI 解析失败: $e');
    }
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _uriController.text = data.text!;
      });
      HapticFeedback.lightImpact();
    }
  }

  /// 打开二维码扫描界面
  Future<void> _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && result.startsWith('otpauth://')) {
      try {
        final payload = AuthPayload.fromOtpAuthUri(result);
        setState(() {
          _issuerController.text = payload.issuer;
          _accountController.text = payload.account;
          _secretController.text = payload.secret;
          _algorithm = payload.algorithm;
          _digits = payload.digits;
          _period = payload.period;
          _uriController.text = result;
        });
        
        // 切换到手动输入 tab 让用户确认/编辑
        _tabController.animateTo(0);
        _showSuccess('二维码解析成功，请确认信息');
      } on Exception catch (e) {
        _showError('二维码解析失败: $e');
      }
    }
  }

  /// 保存
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.dek == null || widget.searchKey == null || widget.deviceId == null) {
      _showError('加密密钥未就绪');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = AuthPayload(
        issuer: _issuerController.text.trim(),
        account: _accountController.text.trim(),
        secret: _secretController.text.trim().toUpperCase().replaceAll(RegExp(r'\s'), ''),
        algorithm: _algorithm,
        digits: _digits,
        period: _period,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.editCard != null) {
        widget.authService.updateCard(
          cardId: widget.editCard!.cardId,
          newPayload: payload,
          dek: widget.dek!,
          searchKey: widget.searchKey!,
          deviceId: widget.deviceId!,
        );
      } else {
        widget.authService.createCard(
          payload: payload,
          dek: widget.dek!,
          searchKey: widget.searchKey!,
          deviceId: widget.deviceId!,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      _showError('保存失败: $e');
    }
  }

  /// 批量导入
  Future<void> _batchImport() async {
    final text = _uriController.text.trim();
    if (text.isEmpty) {
      _showError('请输入内容');
      return;
    }
    if (widget.dek == null || widget.searchKey == null || widget.deviceId == null) {
      _showError('加密密钥未就绪');
      return;
    }

    final imported = widget.authService.importFromText(
      text,
      widget.dek!,
      widget.searchKey!,
      widget.deviceId!,
    );

    if (imported.isNotEmpty) {
      _showSuccess('成功导入 ${imported.length} 个验证器');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      _showError('未找到有效的 otpauth:// URI');
    }
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
        backgroundColor: const Color(0xFF00BFA6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editCard != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑验证器' : '添加验证器'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
        ],
        bottom: isEditing
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6C63FF),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: '手动输入', icon: Icon(Icons.edit, size: 18)),
                  Tab(text: 'URI 导入', icon: Icon(Icons.link, size: 18)),
                  Tab(text: '扫码导入', icon: Icon(Icons.qr_code_scanner, size: 18)),
                ],
              ),
      ),
      body: Form(
        key: _formKey,
        child: isEditing
            ? _buildManualInputForm()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildManualInputForm(),
                  _buildUriImportForm(),
                  _buildQrScanTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildManualInputForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 发行方
        TextFormField(
          controller: _issuerController,
          decoration: const InputDecoration(
            labelText: '发行方 *',
            hintText: '例如: GitHub, Google, Binance',
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入发行方名称';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // 账号
        TextFormField(
          controller: _accountController,
          decoration: const InputDecoration(
            labelText: '账号 *',
            hintText: 'your@email.com',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入账号';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // 密钥 (Base32)
        TextFormField(
          controller: _secretController,
          obscureText: !_showSecret,
          decoration: InputDecoration(
            labelText: '密钥 (Secret) *',
            hintText: 'JBSWY3DPEHPK3PXP',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(
                _showSecret ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _showSecret = !_showSecret;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入密钥';
            }
            // 基本的 Base32 验证
            final cleaned = value.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
            if (!RegExp(r'^[A-Z2-7=]+$').hasMatch(cleaned)) {
              return '密钥格式无效（仅支持 Base32 字符）';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 24),

        // 高级选项
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text(
              '高级选项',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            leading: const Icon(Icons.tune, size: 20, color: Colors.white60),
            children: [
              // 算法选择
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('哈希算法', style: TextStyle(color: Colors.white70)),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'SHA1', label: Text('SHA1')),
                        ButtonSegment(value: 'SHA256', label: Text('SHA256')),
                        ButtonSegment(value: 'SHA512', label: Text('SHA512')),
                      ],
                      selected: {_algorithm},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _algorithm = selected.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 位数
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('验证码位数', style: TextStyle(color: Colors.white70)),
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 6, label: Text('6 位')),
                        ButtonSegment(value: 8, label: Text('8 位')),
                      ],
                      selected: {_digits},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _digits = selected.first;
                        });
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              // 周期
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('刷新周期', style: TextStyle(color: Colors.white70)),
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 30, label: Text('30s')),
                        ButtonSegment(value: 60, label: Text('60s')),
                      ],
                      selected: {_period},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _period = selected.first;
                        });
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 备注
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: '备注',
            hintText: '额外信息...',
            prefixIcon: Icon(Icons.notes),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildUriImportForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 说明卡片
        Card(
          color: const Color(0xFF0F3460),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, 
                         color: Color(0xFF6C63FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '导入方式',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '粘贴 otpauth:// URI 或多个 URI（每行一个）来批量导入。\n'
                  '格式: otpauth://totp/Label?secret=XXX&issuer=YYY',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // URI 输入
        TextFormField(
          controller: _uriController,
          decoration: InputDecoration(
            labelText: 'otpauth:// URI',
            hintText: 'otpauth://totp/GitHub:user@example.com?secret=...',
            prefixIcon: const Icon(Icons.link),
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste),
              onPressed: _pasteFromClipboard,
              tooltip: '从剪贴板粘贴',
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),

        // 操作按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _parseUri,
                icon: const Icon(Icons.article_outlined, size: 18),
                label: const Text('解析并编辑'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _batchImport,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('快速导入'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 二维码扫描 Tab 页面
  Widget _buildQrScanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 扫描图标动画容器
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    const Color(0xFF00BFA6).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 72,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              '扫描 2FA 设置二维码',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '使用相机扫描应用程序提供的\n二维码即可快速添加验证器',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            // 开始扫描按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openQrScanner,
                icon: const Icon(Icons.camera_alt, size: 22),
                label: const Text(
                  '开始扫描',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 支持说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  _SupportItem(
                    icon: Icons.check_circle_outline,
                    text: '支持 Google Authenticator 格式',
                  ),
                  SizedBox(height: 8),
                  _SupportItem(
                    icon: Icons.check_circle_outline,
                    text: '支持 TOTP / HOTP 协议',
                  ),
                  SizedBox(height: 8),
                  _SupportItem(
                    icon: Icons.check_circle_outline,
                    text: '自动识别 otpauth:// URI',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 支持项展示组件
class _SupportItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SupportItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00BFA6)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
