import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../core/crypto/file_crypto_service.dart';
import '../core/storage/file_storage_service.dart';
import '../core/diagnostics/crash_report_service.dart';

/// 文件保险库服务 — 加密/解密文件的业务编排层
///
/// 协调 FileCryptoService（加密引擎）+ FileStorageService（元数据）+ 文件系统
class FileVaultService {
  final FileCryptoService _crypto;
  final FileStorageService _storage;
  final Uint8List Function() _getSessionDEK;
  final _uuid = const Uuid();

  FileVaultService({
    required FileCryptoService crypto,
    required FileStorageService storage,
    required Uint8List Function() getSessionDEK,
  })  : _crypto = crypto,
        _storage = storage,
        _getSessionDEK = getSessionDEK;

  /// Encrypt a file and store it in the vault.
  /// Returns the [FileRecord] for the encrypted file.
  Future<FileRecord> encryptFile({
    required String sourcePath,
    String? displayName,
  }) async {
    final dek = _getSessionDEK();
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Source file not found: $sourcePath');
    }

    final plaintext = await file.readAsBytes();
    final fileName = displayName ?? file.uri.pathSegments.last;

    final envelope = _crypto.encrypt(
      sessionDEK: dek,
      fileName: fileName,
      plaintext: plaintext,
    );

    // Save encrypted envelope to vault storage
    final vaultDir = await _getVaultDir();
    final fileId = _uuid.v4();
    final encPath = '${vaultDir.path}/$fileId.ztdf';
    await File(encPath).writeAsBytes(envelope);

    final record = FileRecord(
      fileId: fileId,
      fileName: fileName,
      mimeType: _guessMime(fileName),
      originalSize: plaintext.length,
      encryptedSize: envelope.length,
      createdAt: DateTime.now(),
      storagePath: encPath,
    );

    await _storage.saveRecord(record);
    return record;
  }

  /// Decrypt a file from the vault.
  /// Returns the [DecryptedFile] with original bytes.
  Future<DecryptedFile> decryptFile(String fileId) async {
    final dek = _getSessionDEK();
    final record = await _storage.getRecord(fileId);
    if (record == null) throw Exception('File record not found: $fileId');

    final encFile = File(record.storagePath);
    if (!await encFile.exists()) throw Exception('Encrypted file missing: ${record.storagePath}');

    final envelope = await encFile.readAsBytes();
    return _crypto.decrypt(sessionDEK: dek, envelope: envelope);
  }

  /// Decrypt a file and write to [outputPath].
  Future<void> decryptToPath(String fileId, String outputPath) async {
    final decrypted = await decryptFile(fileId);
    await File(outputPath).writeAsBytes(decrypted.bytes);
  }

  /// List all stored encrypted files.
  Future<List<FileRecord>> listFiles() async {
    return await _storage.listRecords();
  }

  /// Delete an encrypted file and its record.
  Future<void> deleteFile(String fileId) async {
    final record = await _storage.getRecord(fileId);
    if (record != null) {
      final f = File(record.storagePath);
      if (await f.exists()) await f.delete();
    }
    await _storage.deleteRecord(fileId);
  }

  Future<Directory> _getVaultDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/encrypted_files');
    if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
    return vaultDir;
  }

  String _guessMime(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'txt': 'text/plain',
      'json': 'application/json',
      'zip': 'application/zip',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}
