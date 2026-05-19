import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/file_vault_service.dart';
import '../../core/storage/file_storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/context_menu.dart';
import '../../l10n/app_localizations.dart';
import 'file_encrypt_screen.dart';

/// 加密文件列表页
class FileListScreen extends StatefulWidget {
  final FileVaultService fileVaultService;

  const FileListScreen({super.key, required this.fileVaultService});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  List<FileRecord> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await widget.fileVaultService.listFiles();
      if (mounted) setState(() { _files = files; _isLoading = false; });
    } on Exception {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mime.contains('zip') || mime.contains('compressed')) return Icons.folder_zip_rounded;
    if (mime.startsWith('text/')) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_files.isEmpty) {
      return EmptyState(
        icon: Icons.folder_off_rounded,
        title: '暂无加密文件',
        subtitle: '点击右上角 + 加密新文件',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return BouncingWidget(
          onTap: () => _decryptFile(file),
          onLongPress: () => _showFileMenu(context, file),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  ),
                  child: Icon(_fileIcon(file.mimeType), color: const Color(0xFF6C63FF), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file.fileName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${_formatSize(file.originalSize)} · ${_formatDate(file.createdAt)}',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showFileMenu(BuildContext context, FileRecord file) {
    showContextMenu(context: context, options: [
      ContextMenuOption(
        icon: Icons.download_rounded,
        label: '解密并导出',
        onTap: () => _decryptFile(file),
      ),
      ContextMenuOption(
        icon: Icons.copy_rounded,
        label: '复制文件名',
        onTap: () {
          Clipboard.setData(ClipboardData(text: file.fileName));
          HapticFeedback.lightImpact();
        },
      ),
      ContextMenuOption(
        icon: Icons.delete_rounded,
        label: '删除',
        onTap: () => _deleteFile(file),
        destructive: true,
      ),
    ]);
  }

  Future<void> _decryptFile(FileRecord file) async {
    try {
      final decrypted = await widget.fileVaultService.decryptFile(file.fileId);
      // Show success with file info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已解密: ${decrypted.fileName} (${_formatSize(decrypted.bytes.length)})'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('解密失败: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _deleteFile(FileRecord file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除文件？', style: TextStyle(color: Colors.white)),
        content: Text('确定删除 "${file.fileName}"？此操作不可撤销。',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Color(0xFFFF6B6B)))),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.fileVaultService.deleteFile(file.fileId);
      _loadFiles();
    }
  }
}
