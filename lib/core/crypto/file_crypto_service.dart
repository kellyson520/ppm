import 'dart:typed_data';
import 'crypto_service.dart';
import 'crypto_facade.dart';

/// ZTDF (Zero-Trust Data File) 信封格式 — 流式分块 AES-256-GCM 文件加密引擎
///
/// 二进制布局：
/// ```
/// [Header 70 bytes]
///   magic:       "ZTDF" (4 B)
///   version:     uint8  (1 B = 1)
///   flags:       uint8  (1 B, reserved)
///   kdfSalt:     [32]B  (HKDF salt)
///   metaIv:      [12]B  (metadata AES-GCM nonce)
///   metaLen:     uint32 LE (4 B)
///   chunkSize:   uint32 LE (4 B)
///   originalSize: uint64 LE (8 B)
/// [Encrypted Metadata]
///   fileName:    UTF-8 (prefixed with uint16 LE length)
///   mimeType:    UTF-8 (prefixed with uint16 LE length)
/// [Chunks]
///   [chunkIv: 12B][chunkLen: uint32 LE][ciphertext+authTag: chunkLen bytes]
/// ```
///
/// 密钥派生: fileKey = HKDF-SHA256(ikm: sessionDEK, salt: kdfSalt, info: "ztd-file-v1")
class FileCryptoService {
  final CryptoFacade _facade;

  FileCryptoService({CryptoFacade? facade})
      : _facade = facade ?? CryptoFacade();

  static const _magic = 'ZTDF';
  static const _version = 1;

  /// 加密 [plaintext] 为 ZTDF 信封字节。返回 envelope bytes。
  Uint8List encrypt({
    required Uint8List sessionDEK,
    required String fileName,
    required Uint8List plaintext,
    String mimeType = 'application/octet-stream',
    int chunkSize = 65536,
  }) {
    // 1. Derive per-file key
    final kdfSalt = _facade.generateRandomBytes(32);
    final fileKey = _facade.hkdfSha256(sessionDEK,
        salt: kdfSalt,
        info: Uint8List.fromList('ztd-file-v1'.codeUnits),
        length: 32);

    // 2. Encrypt metadata
    final metaBytes = _encodeMetadata(fileName, mimeType, plaintext.length);
    final encryptedMeta = _facade.encryptAESGCM(metaBytes, fileKey);
    final metaIv = encryptedMeta.nonce;
    final metaCipher = Uint8List.fromList([
      ...encryptedMeta.ciphertext,
      ...encryptedMeta.authTag,
    ]);

    // 3. Encrypt chunks
    final chunks = <Uint8List>[];
    for (var offset = 0; offset < plaintext.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, plaintext.length);
      final chunk = plaintext.sublist(offset, end);
      final enc = _facade.encryptAESGCM(chunk, fileKey);
      final chunkData = _encodeChunk(enc.nonce, Uint8List.fromList([
        ...enc.ciphertext,
        ...enc.authTag,
      ]));
      chunks.add(chunkData);
    }

    // 4. Assemble
    final metaEncoded = Uint8List.fromList([...metaIv, ...metaCipher]);
    final header = _buildHeader(kdfSalt, metaIv, metaEncoded.length, chunkSize, plaintext.length);
    final builder = BytesBuilder();
    builder.add(header);
    builder.add(metaEncoded);
    for (final c in chunks) {
      builder.add(c);
    }
    return builder.toBytes();
  }

  /// Decrypt ZTDF [envelope] bytes. Returns [DecryptedFile].
  DecryptedFile decrypt({
    required Uint8List sessionDEK,
    required Uint8List envelope,
  }) {
    if (envelope.length < 70) {
      throw FormatException('File too small to be ZTDF');
    }

    // 1. Parse header
    final magic = String.fromCharCodes(envelope.sublist(0, 4));
    if (magic != _magic) throw FormatException('Not a ZTDF file (bad magic)');

    final version = envelope[4];
    if (version != _version) throw FormatException('Unsupported ZTDF version: $version');

    // flags = envelope[5]
    final kdfSalt = envelope.sublist(6, 38);
    final metaIv = envelope.sublist(38, 50);
    final metaLen = _read32LE(envelope, 50);
    final chunkSize = _read32LE(envelope, 54);
    final originalSize = _read64LE(envelope, 58);
    const headerEnd = 66;

    // 2. Derive file key
    final fileKey = _facade.hkdfSha256(sessionDEK,
        salt: kdfSalt,
        info: Uint8List.fromList('ztd-file-v1'.codeUnits),
        length: 32);

    // 3. Decrypt metadata
    final metaStart = headerEnd;
    final metaEnd = metaStart + metaLen;
    if (envelope.length < metaEnd) throw FormatException('ZTDF truncated at metadata');
    final metaEncoded = envelope.sublist(metaStart, metaEnd);
    final metaEncNonce = metaEncoded.sublist(0, 12);
    final metaEncData = metaEncoded.sublist(12);
    final metaAuthTag = metaEncData.sublist(metaEncData.length - 16);
    final metaCipher = metaEncData.sublist(0, metaEncData.length - 16);
    final metaBytes = _facade.decryptAESGCM(
      EncryptedBox(nonce: metaEncNonce, ciphertext: metaCipher, authTag: metaAuthTag),
      fileKey,
    );
    final meta = _decodeMetadata(metaBytes);

    // 4. Decrypt chunks
    final plaintext = BytesBuilder();
    var pos = metaEnd;
    while (pos + 16 <= envelope.length) {
      final chunkIv = envelope.sublist(pos, pos + 12);
      final chunkDataLen = _read32LE(envelope, pos + 12);
      final chunkEnd = pos + 16 + chunkDataLen;
      if (chunkEnd > envelope.length) throw FormatException('ZTDF chunk truncated at $pos');
      final chunkData = envelope.sublist(pos + 16, chunkEnd);
      final chunkAuthTag = chunkData.sublist(chunkData.length - 16);
      final chunkCipher = chunkData.sublist(0, chunkData.length - 16);
      final chunk = _facade.decryptAESGCM(
        EncryptedBox(nonce: chunkIv, ciphertext: chunkCipher, authTag: chunkAuthTag),
        fileKey,
      );
      plaintext.add(chunk);
      pos = chunkEnd;
    }

    final result = plaintext.toBytes();
    if (result.length != originalSize) {
      throw FormatException(
        'Size mismatch: expected $originalSize, got ${result.length}',
      );
    }

    return DecryptedFile(
      fileName: meta.fileName,
      mimeType: meta.mimeType,
      bytes: result,
    );
  }

  // ── Helpers ─────────────────────────────────────────────

  Uint8List _buildHeader(
    Uint8List salt, Uint8List metaIv, int metaLen, int chunkSize, int originalSize) {
    final buf = BytesBuilder();
    buf.add(_magic.codeUnits);
    buf.add(Uint8List.fromList([_version, 0])); // version + flags
    buf.add(salt); // 32
    buf.add(metaIv); // 12
    buf.add(_uint32LE(metaLen)); // 4
    buf.add(_uint32LE(chunkSize)); // 4
    buf.add(_uint64LE(originalSize)); // 8
    return buf.toBytes(); // = 4+2+32+12+4+4+8 = 66
  }

  Uint8List _encodeMetadata(String fileName, String mimeType, int originalSize) {
    final nameBytes = fileName.codeUnits;
    final mimeBytes = mimeType.codeUnits;
    final buf = BytesBuilder();
    buf.add(_uint16LE(nameBytes.length));
    buf.add(Uint8List.fromList(nameBytes));
    buf.add(_uint16LE(mimeBytes.length));
    buf.add(Uint8List.fromList(mimeBytes));
    return buf.toBytes();
  }

  _Meta _decodeMetadata(Uint8List bytes) {
    var pos = 0;
    final nameLen = _read16LE(bytes, pos); pos += 2;
    final fileName = String.fromCharCodes(bytes.sublist(pos, pos + nameLen)); pos += nameLen;
    final mimeLen = _read16LE(bytes, pos); pos += 2;
    final mimeType = String.fromCharCodes(bytes.sublist(pos, pos + mimeLen));
    return _Meta(fileName: fileName, mimeType: mimeType);
  }

  Uint8List _encodeChunk(Uint8List iv, Uint8List chunkData) {
    final buf = BytesBuilder();
    buf.add(iv);
    buf.add(_uint32LE(chunkData.length));
    buf.add(chunkData);
    return buf.toBytes();
  }

  Uint8List _uint16LE(int v) {
    final b = Uint8List(2);
    b.buffer.asByteData().setUint16(0, v, Endian.little);
    return b;
  }

  Uint8List _uint32LE(int v) {
    final b = Uint8List(4);
    b.buffer.asByteData().setUint32(0, v, Endian.little);
    return b;
  }

  Uint8List _uint64LE(int v) {
    final b = Uint8List(8);
    b.buffer.asByteData().setUint64(0, v, Endian.little);
    return b;
  }

  int _read16LE(Uint8List d, int o) => d.buffer.asByteData().getUint16(o, Endian.little);
  int _read32LE(Uint8List d, int o) => d.buffer.asByteData().getUint32(o, Endian.little);
  int _read64LE(Uint8List d, int o) => d.buffer.asByteData().getUint64(o, Endian.little);
}

class _Meta {
  final String fileName;
  final String mimeType;
  const _Meta({required this.fileName, required this.mimeType});
}

/// 解密后的文件内容
class DecryptedFile {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  const DecryptedFile({required this.fileName, required this.mimeType, required this.bytes});
}
