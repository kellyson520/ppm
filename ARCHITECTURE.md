# ZTD Password Manager - Architecture Overview

## System Architecture

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐   │
│  │ SplashScreen │ │ LockScreen   │ │ VaultScreen          │   │
│  └──────────────┘ └──────────────┘ └──────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐   │
│  │ SetupScreen  │ │ AddPassword  │ │ SettingsScreen       │   │
│  └──────────────┘ └──────────────┘ └──────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                    Application Layer                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ VaultService                                             │  │
│  │  - Business logic coordination                           │  │
│  │  - Session management                                    │  │
│  │  - CRUD operations                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      Domain Layer                                │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐   │
│  │ CryptoService│ │ CrdtMerger   │ │ EventStore           │   │
│  │  - AES-GCM   │ │  - LWW merge │ │  - Event sourcing    │   │
│  │  - Argon2id  │ │  - Conflict  │ │  - Snapshots         │   │
│  │  - HKDF      │ │    resolution│ │  - Compaction        │   │
│  └──────────────┘ └──────────────┘ └──────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐   │
│  │ KeyManager   │ │ HLC          │ │ WebDavSyncManager    │   │
│  │  - KEK/DEK   │ │  - Clock     │ │  - Multi-node sync   │   │
│  │  - TEE store │ │  - Ordering  │ │  - Conflict handling │   │
│  └──────────────┘ └──────────────┘ └──────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                   Infrastructure Layer                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐   │
│  │ SQLCipher    │ │ flutter_secure│ │ webdav_client       │   │
│  │  - Encrypted │ │ _storage     │ │  - WebDAV protocol   │   │
│  │    database  │ │  - TEE/Key   │ │  - HTTP operations   │   │
│  │  - Blind     │ │    storage   │ │                      │   │
│  │    indexes   │ │  - Biometric │ │                      │   │
│  └──────────────┘ └──────────────┘ └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Cryptographic Services (`core/crypto/`)

#### CryptoService
- **AES-256-GCM**: Symmetric encryption for data
- **Argon2id**: Password-based key derivation
- **HKDF-SHA256**: Key stretching and derivation
- **HMAC-SHA256**: Message authentication
- **Constant-time operations**: Side-channel resistance

#### KeyManager
- **Double envelope encryption**: KEK encrypts DEK
- **TEE integration**: Hardware-backed key storage
- **Key rotation**: DEK rotation without data re-encryption
- **Emergency kit**: Export/import for recovery

### 2. Hybrid Logical Clock (`core/models/hlc.dart`)

```dart
class HLC {
  final int physicalTime;     // NTP-synced timestamp
  final int logicalCounter;   // For concurrent events
  final String deviceId;      // Tie-breaker
}
```

**Features:**
- Causal ordering of events
- Deterministic conflict resolution
- No central coordination required

### 3. CRDT Merger (`core/crdt/crdt_merger.dart`)

**Semantics:**
- **Add-Wins Set**: Card creation (duplicates tolerated)
- **LWW-Register**: Card updates (last write wins)
- **Tombstone**: Card deletion (permanent marker)

**Conflict Resolution:**
1. Compare HLC timestamps
2. If equal, use device ID for tie-breaking
3. Preserve losing event as history

### 4. Event Store (`core/events/event_store.dart`)

**Event Structure:**
```dart
class PasswordEvent {
  final HLC hlc;              // Timestamp
  final String eventId;       // UUID v4
  final EventType type;       // CREATE/UPDATE/DELETE
  final String cardId;        // Target card
  final EncryptedPayload payload;  // Encrypted data
  final String? prevEventHash;     // Chain validation
}
```

**Features:**
- Append-only log
- Event chain validation
- Snapshot compaction
- Sync state tracking

### 5. Database Service (`core/storage/database_service.dart`)

**Tables:**
- `password_cards`: Encrypted card storage
- `blind_index_entries`: Searchable indexes
- `password_events`: Event log
- `snapshots`: Compaction checkpoints

**Features:**
- SQLCipher encryption
- Blind index search
- Full-text search (decrypted)

### 6. WebDAV Sync (`core/sync/webdav_sync.dart`)

**Multi-Node Architecture:**
```
Local Device
    │
    ├──► Primary Node (Real-time, Full sync)
    │
    ├──► Secondary Node 1 (Delayed, Snapshots only)
    │
    └──► Secondary Node 2 (LAN, Full sync)
```

**Sync Protocol:**
1. Check remote manifest
2. Calculate diff
3. Download missing events
4. Merge using CRDT
5. Upload local events
6. Update manifest

## Data Flow

### Creating a Password

```
User Input
    │
    ▼
[Encrypt Payload] ──► AES-256-GCM(DEK)
    │
    ▼
[Generate Blind Indexes] ──► HMAC-SHA256(searchKey, tokens)
    │
    ▼
[Create Event] ──► PasswordEvent(CREATE)
    │
    ▼
[Save to Database] ──► SQLCipher
    │
    ▼
[Mark Unsynced] ──► Sync queue
```

### Synchronization

```
Local Events ──► WebDAV Upload ──► Remote Storage
    │                              │
    │                              ▼
    │                         Remote Events
    │                              │
    ▼                              ▼
[CRDT Merge] ◄───────────────────┘
    │
    ▼
[Apply to Local DB]
    │
    ▼
[Update State]
```

## Security Model

### Threat Mitigations

| Threat | Mitigation |
|--------|------------|
| Physical Access | TEE key storage, memory wiping |
| Network Sniffing | E2E encryption, no plaintext |
| Brute Force | Argon2id with device params |
| Side-Channel | Constant-time algorithms |
| Data Loss | Multi-node backup |
| Key Compromise | DEK rotation capability |

### Key Hierarchy

```
Master Password
    │
    ▼
[Argon2id] ──► Salt + Device Fingerprint
    │
    ▼
KEK (256-bit) ──► Stored in TEE
    │
    ▼
DEK (256-bit random) ──► KEK-encrypted, session-only
    │
    ▼
Data Encryption ──► AES-256-GCM
```

## Performance Considerations

### Optimizations

1. **Blind Indexes**: O(1) search without decryption
2. **Event Compaction**: Reduces storage over time
3. **Incremental Sync**: Only sync changed events
4. **Memory Caching**: Hot data in memory
5. **Lazy Loading**: Decrypt on demand

### Benchmarks

| Operation | Target |
|-----------|--------|
| Cold Start | < 2s |
| Search | < 100ms |
| Encrypt 1KB | < 100ms |
| Sync (100 events) | < 5s |

## Testing Strategy

### Unit Tests
- Cryptographic operations
- HLC ordering
- CRDT merging
- Event chain validation

### Integration Tests
- Database operations
- Sync protocol
- Key management

### Security Tests
- Memory dumping
- Timing analysis
- Fuzzing inputs

## Deployment

### Platforms
- iOS 14+
- Android 10+
- macOS 12+
- Windows 10+
- Linux

### Build Commands
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Desktop
flutter build macos
flutter build windows
flutter build linux
```

## Future Enhancements

1. **Biometric Auth**: Face ID / Touch ID / Fingerprint
2. **TOTP Generation**: Built-in 2FA code generation
3. **Password Sharing**: Secure sharing via public keys
4. **Digital Legacy**: Emergency access for trusted contacts
5. **Browser Extension**: Auto-fill for web browsers
6. **Audit Log**: Detailed access history
