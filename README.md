# ZTD Password Manager

Zero-Trust Distributed Password Manager - A secure, offline-first password manager with WebDAV synchronization.

## Features

### Security
- **End-to-End Encryption**: AES-256-GCM encryption for all data
- **Argon2id KDF**: Modern key derivation function with device-specific parameters
- **Double Envelope Encryption**: KEK/DEK separation for key rotation support
- **TEE Integration**: Hardware-backed key storage (Secure Enclave / StrongBox)
- **Constant-Time Operations**: Side-channel attack resistance
- **Secure Memory**: Automatic sensitive data wiping with DoD 5220.22-M compliance

### Distributed Architecture
- **Event Sourcing**: Immutable event log for data consistency
- **CRDT Merge**: Conflict-free replicated data types for offline-first operation
- **HLC Timestamps**: Hybrid Logical Clocks for causal ordering
- **WebDAV Sync**: Multi-node backup with priority-based synchronization
- **Snapshots**: Automatic compaction and state snapshots

### Offline-First
- **Local-First Design**: Full functionality without network
- **SQLite + SQLCipher**: Encrypted local database
- **Blind Index Search**: Privacy-preserving search capability
- **Automatic Sync**: Background synchronization when online

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (Flutter UI)                            │
├─────────────────────────────────────────────────────────────┤
│  Application Layer (Vault Service)                          │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer                                               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │ Crypto Svc   │ │ Event Svc    │ │ CRDT Merger      │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure Layer                                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │ SQLCipher    │ │ WebDAV       │ │ TEE/HSM          │   │
│  └──────────────┘ └──────────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites
- Flutter SDK >= 3.16.0
- Dart SDK >= 3.0.0
- Android SDK (for Android builds)
- Xcode (for iOS builds)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ztd-password-manager.git
cd ztd-password-manager
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

### WebDAV Sync
Configure WebDAV nodes in Settings > Synchronization:

1. **Primary Node** (Real-time sync)
   - URL: `https://your-webdav-server.com`
   - Username: Your username
   - Password: Your password

2. **Secondary Nodes** (Backup)
   - Configure additional nodes for redundancy
   - Supports: Nextcloud, ownCloud,坚果云, etc.

### Security Settings

- **Biometric Auth**: Enable Face ID / Touch ID in Settings > Security
- **Auto-Lock**: Set automatic vault lock timeout
- **Password Requirements**: Configure minimum password strength

## Development

### Project Structure
```
lib/
├── core/
│   ├── crypto/          # Cryptographic services
│   ├── crdt/            # CRDT merge logic
│   ├── events/          # Event sourcing
│   ├── hlc/             # Hybrid Logical Clock
│   ├── models/          # Data models
│   ├── security/        # Security utilities
│   ├── storage/         # Database layer
│   └── sync/            # WebDAV synchronization
├── services/
│   └── vault_service.dart   # Main business logic
├── ui/
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable widgets
│   └── viewmodels/      # State management
└── main.dart
```

### Running Tests

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage
```

## Security Considerations

### Threat Model

| Threat | Mitigation |
|--------|------------|
| Physical Device Access | TEE-backed key storage, memory wiping |
| Network Eavesdropping | End-to-end encryption, no plaintext over network |
| Brute Force | Argon2id with device-specific parameters |
| Side-Channel Attacks | Constant-time algorithms |
| Data Loss | Multi-node WebDAV backup |

### Key Management

- **KEK (Key Encryption Key)**: Derived from master password, stored in TEE
- **DEK (Data Encryption Key)**: Random 256-bit key, encrypted by KEK
- **Search Key**: Separate key for blind index generation

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [PointyCastle](https://github.com/bcgit/pc-dart) for Dart cryptography
- [SQLCipher](https://www.zetetic.net/sqlcipher/) for encrypted database
- [WebDAV](https://github.com/flymzero/webdav_client) for synchronization

## Disclaimer

This is a proof-of-concept implementation. For production use, additional security audits and testing are recommended. Always backup your data and keep your master password secure.
