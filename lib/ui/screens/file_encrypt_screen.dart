import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/file_vault_service.dart';

/// 加密新文件 — 选择文件 → 预览 → 加密保存
class FileEncryptScreen extends StatefulWidget {
  final FileVaultService fileVaultService;
  final VoidCallback onComplete;

  const FileEncryptScreen({
    super.key,
    required this.fileVaultService,
    required this.onComplete,
  });

  @override
  State<FileEncryptScreen> createState() => _FileEncryptScreenState();
}

class _FileEncryptScreenState extends State<FileEncryptScreen> {
  String? _selectedPath;
  String? _selectedName;
  int? _selectedSize;
  bool _isEncrypting = false;
  double _progress = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPath = result.files.single.path;
        _selectedName = result.files.single.name;
        _selectedSize = result.files.single.size;
      });
    }
  }

  Future<void> _encrypt() async {
    if (_selectedPath == null) return;
    setState(() { _isEncrypting = true; _progress = 0; });

    try {
      // Simulate progress
      for (var i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _progress = (i + 1) / 5);
      }

      await widget.fileVaultService.encryptFile(
        sourcePath: _selectedPath!,
        displayName: _selectedName,
      );

      if (mounted) {
        setState(() { _isEncrypting = false; _progress = 1; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件已加密保存'), behavior: SnackBarBehavior.floating),
        );
        widget.onComplete();
        Navigator.of(context).pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isEncrypting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加密失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          const Text('加密新文件', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 24),

          // File picker area
          GestureDetector(
            onTap: _isEncrypting ? null : _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2), width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedPath != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                    size: 48,
                    color: _selectedPath != null ? const Color(0xFF00BFA6) : const Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedPath != null ? _selectedName! : '点击选择文件',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedSize != null) ...[
                    const SizedBox(height: 4),
                    Text(_formatSize(_selectedSize!), style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ],
              ),
            ),
          ),

          if (_isEncrypting) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selectedPath != null && !_isEncrypting) ? _encrypt : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isEncrypting ? '加密中...' : '加密并保存',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
