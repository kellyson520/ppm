<div align="center">
  <img src="assets/icons/icon.png" alt="ZTD Password Manager" width="120"/>
  <h1>🔐 ZTD Password Manager</h1>
  <p><strong>Zero-Trust Distributed Password Manager</strong></p>
  <p>AES-256-GCM cryptographically secured • Offline-first • CRDT synchronized</p>

  <!-- Badges -->
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter" alt="Flutter"/>
    <img src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart" alt="Dart"/>
    <img src="https://img.shields.io/badge/license-MIT-green" alt="License"/>
    <img src="https://img.shields.io/badge/security-AES--256--GCM-blueviolet" alt="Security"/>
    <img src="https://img.shields.io/badge/architecture-Clean%20Architecture-important" alt="Architecture"/>
    <img src="https://img.shields.io/badge/sync-CRDT-9cf" alt="Sync"/>
  </p>

  <p>
    <a href="#-features">Features</a> •
    <a href="#-architecture">Architecture</a> •
    <a href="#-quick-start">Quick Start</a> •
    <a href="#-security">Security</a> •
    <a href="#-development">Development</a>
  </p>
</div>

---

> **⚡ The password manager that doesn't trust anyone — not even itself.**
>
> Your secrets are encrypted with **AES-256-GCM** before they touch disk. Keys are locked in **hardware-backed TEE**. Sync is conflict-free via **CRDT**. Zero knowledge. Zero trust. Zero compromises.

---

## ✨ Features

### 🛡️ Military-Grade Security

| Layer | Protection |
|-------|-----------|
| **Cipher** | AES-256-GCM with authenticated encryption |
| **Key Derivation** | Argon2id — device-specific parameters, side-channel resistant |
| **Key Hierarchy** | Double envelope (KEK ↔ DEK) — rotate keys without re-encrypting everything |
| **Hardware** | Secure Enclave / StrongBox TEE integration |
| **Memory** | DoD 5220.22-M compliant secure wiping |
| **Search** | Blind index — search without exposing plaintext |

### 🌐 Distributed & Offline-First

- **Event Sourcing** — Immutable event log; every change is recorded forever
- **CRDT Merge** — Conflict-free replicated data types let you edit offline, merge seamlessly
- **HLC Timestamps** — Hybrid Logical Clocks for causal ordering across devices
- **WebDAV Sync** — Bring your own cloud (Nextcloud, ownCloud, any WebDAV server)
- **Snapshot Compaction** — Automatic state snapshots keep sync lean

### 📱 Cross-Platform

| Platform | Status |
|----------|--------|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| Linux | ✅ |
| macOS | ✅ |
| Windows | ✅ |

---

## 🏗️ Architecture

```
  ┌───────────────────────────────────────────────────────┐
  │                   🎨 UI Layer                         │
  │    Flutter Widgets · BLoC State Management            │
  │    Animations · Responsive Layout · Glassmorphism     │
  └───────────────────────┬───────────────────────────────┘
                          │ depends on
  ┌───────────────────────▼───────────────────────────────┐
  │                ⚙️ Application Layer                    │
  │    VaultService · SyncService · AuthService            │
  │    Orchestrates all business operations                │
  └───────────────────────┬───────────────────────────────┘
                          │ depends on
  ┌───────────────────────▼───────────────────────────────┐
  │                 🧠 Domain Layer                        │
  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
  │  │ Crypto Core  │ │ Event Store  │ │ CRDT Merger  │  │
  │  │ AES-GCM      │ │ Event Log    │ │ Conflict Res.│  │
  │  │ Argon2id     │ │ Snapshots    │ │ HLC Clock    │  │
  │  └──────────────┘ └──────────────┘ └──────────────┘  │
  └───────────────────────┬───────────────────────────────┘
                          │ depends on
  ┌───────────────────────▼───────────────────────────────┐
  │               🔌 Infrastructure Layer                  │
  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
  │  │ SQLCipher    │ │ WebDAV       │ │ TEE / HSM    │  │
  │  │ Encrypted DB │ │ Sync Gateway │ │ Key Storage  │  │
  │  └──────────────┘ └──────────────┘ └──────────────┘  │
  └───────────────────────────────────────────────────────┘
```

**Layering rules:** UI → BLoC → Repository → Data Source. Never skip a layer. Never import infrastructure into UI.

---

## 🚀 Quick Start

### Prerequisites

```bash
# Flutter SDK >= 3.27.0
flutter --version

# Dart SDK >= 3.0.0
dart --version
```

### Run It

```bash
git clone https://github.com/kellyson520/ppm.git
cd ppm
flutter pub get
flutter run
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android AppBundle
flutter build appbundle --release

# Web
flutter build web
```

---

## 🛡️ Security

### Threat Model

| Threat | Mitigation |
|--------|-----------|
| 📱 Physical device access | TEE-backed key storage + memory wiping |
| 🌐 Network eavesdropping | End-to-end encryption, zero plaintext on wire |
| 🔨 Brute force | Argon2id with device-specific parameters |
| ⚡ Side-channel attacks | Constant-time algorithms |
| 💥 Data loss | Multi-node WebDAV backup + CRDT recovery |

### Key Hierarchy

```
  Master Password
       ↓ (Argon2id)
  KEK (Key Encryption Key) ─── stored in TEE
       ↓ (AES-256-GCM)
  DEK (Data Encryption Key) ─── encrypts all vault data
       ↓
  Encrypted Vault Items
```

---

## 🧪 Development

### Project Structure

```
lib/
├── blocs/           # BLoC state management
│   ├── auth/
│   ├── password/
│   ├── sync/
│   └── vault/
├── core/            # Pure domain logic
│   ├── crdt/        # Conflict resolution
│   ├── crypto/      # AES-GCM, Argon2id, key management
│   ├── models/      # Domain entities
│   ├── security/    # Secure buffer, constant-time utils
│   ├── storage/     # SQLCipher database
│   └── sync/        # WebDAV sync engine
├── services/        # Application orchestration
├── ui/              # Flutter screens & widgets
│   ├── screens/
│   └── widgets/
└── main.dart
```

### Before You Commit

```bash
flutter analyze          # 0 errors, 0 warnings
dart format --line-length 100 .   # formatting compliance
flutter test             # all tests green
```

### CI/CD

Every push triggers automated checks via **GitHub Actions**:
- ✅ `dart format` compliance (line-length 100)
- ✅ `flutter analyze` static analysis
- ✅ `flutter test` full test suite
- ✅ Android APK + AppBundle build
- ✅ Web build
- ✅ GitHub Release on tags

---

## 📄 License

MIT — see [LICENSE](LICENSE)

---

<p align="center">
  <strong>Zero Trust. Zero Knowledge. Zero Compromises.</strong><br>
  <sub>Built with ❤️ for people who take their secrets seriously.</sub>
</p>

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

## Development Standards

Before contributing, please read and follow our project standards:

| Document | Description |
|----------|-------------|
| [STANDARDS.md](STANDARDS.md) | 编码规范、Dart/Flutter 规范、架构规范、安全规范 |
| [GIT_WORKFLOW.md](GIT_WORKFLOW.md) | Git 分支策略、提交规范、PR 流程、版本发布 |
| [CI_CD.md](CI_CD.md) | CI/CD 配置、质量门禁、构建产物、故障排查 |

### Quick Check Before Commit

- [ ] `flutter analyze` passes (no errors or warnings)
- [ ] `flutter test` passes (all tests green)
- [ ] Code follows naming conventions
- [ ] No hardcoded secrets
- [ ] Public APIs have documentation comments
- [ ] Commit message follows the convention

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

1. Read the [Development Standards](STANDARDS.md) documentation
2. Fork the repository
3. Create your feature branch (`git checkout -b feature/amazing-feature`)
4. Follow [Git Workflow](GIT_WORKFLOW.md) for commit conventions
5. Ensure `flutter analyze` and `flutter test` pass locally
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request following the [PR process](GIT_WORKFLOW.md#4-pull-request-流程)
8. Wait for code review and address feedback

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [PointyCastle](https://github.com/bcgit/pc-dart) for Dart cryptography
- [SQLCipher](https://www.zetetic.net/sqlcipher/) for encrypted database
- [WebDAV](https://github.com/flymzero/webdav_client) for synchronization

## Disclaimer

This is a proof-of-concept implementation. For production use, additional security audits and testing are recommended. Always backup your data and keep your master password secure.
