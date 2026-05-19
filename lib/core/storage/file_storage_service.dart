import 'dart:convert';
import 'dart:typed_data';
import '../models/models.dart';
import 'database_service.dart';

/// 加密文件记录
class FileRecord {
  final String fileId;
  final String fileName;
  final String mimeType;
  final int originalSize;
  final int encryptedSize;
  final DateTime createdAt;
  final String storagePath; // 文件系统路径

  const FileRecord({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.originalSize,
    required this.encryptedSize,
    required this.createdAt,
    required this.storagePath,
  });

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'fileName': fileName,
        'mimeType': mimeType,
        'originalSize': originalSize,
        'encryptedSize': encryptedSize,
        'createdAt': createdAt.toIso8601String(),
        'storagePath': storagePath,
      };

  factory FileRecord.fromJson(Map<String, dynamic> json) => FileRecord(
        fileId: json['fileId'] as String,
        fileName: json['fileName'] as String,
        mimeType: json['mimeType'] as String,
        originalSize: json['originalSize'] as int,
        encryptedSize: json['encryptedSize'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        storagePath: json['storagePath'] as String,
      );
}

/// 加密文件元数据存储服务
///
/// 使用 DatabaseService 的 SQLCipher 连接存储文件记录。
/// 文件内容以 ZTDF 信封格式存储在文件系统，元数据存在加密数据库。
class FileStorageService {
  final DatabaseService _db;
  static const _tableFiles = 'encrypted_files';

  FileStorageService({required DatabaseService db}) : _db = db;

  Future<void> initialize() async {
    await _db.db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableFiles (
        file_id TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        original_size INTEGER NOT NULL,
        encrypted_size INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        storage_path TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveRecord(FileRecord record) async {
    await _db.db.insert(_tableFiles, {
      'file_id': record.fileId,
      'file_name': record.fileName,
      'mime_type': record.mimeType,
      'original_size': record.originalSize,
      'encrypted_size': record.encryptedSize,
      'created_at': record.createdAt.toIso8601String(),
      'storage_path': record.storagePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<FileRecord?> getRecord(String fileId) async {
    final rows = await _db.db.query(_tableFiles, where: 'file_id = ?', whereArgs: [fileId]);
    if (rows.isEmpty) return null;
    return FileRecord(
      fileId: rows.first['file_id'] as String,
      fileName: rows.first['file_name'] as String,
      mimeType: rows.first['mime_type'] as String,
      originalSize: rows.first['original_size'] as int,
      encryptedSize: rows.first['encrypted_size'] as int,
      createdAt: DateTime.parse(rows.first['created_at'] as String),
      storagePath: rows.first['storage_path'] as String,
    );
  }

  Future<List<FileRecord>> listRecords() async {
    final rows = await _db.db.query(_tableFiles, orderBy: 'created_at DESC');
    return rows.map((r) => FileRecord(
          fileId: r['file_id'] as String,
          fileName: r['file_name'] as String,
          mimeType: r['mime_type'] as String,
          originalSize: r['original_size'] as int,
          encryptedSize: r['encrypted_size'] as int,
          createdAt: DateTime.parse(r['created_at'] as String),
          storagePath: r['storage_path'] as String,
        )).toList();
  }

  Future<void> deleteRecord(String fileId) async {
    await _db.db.delete(_tableFiles, where: 'file_id = ?', whereArgs: [fileId]);
  }
}
