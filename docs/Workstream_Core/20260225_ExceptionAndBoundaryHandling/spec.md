# Spec: Exception and Boundary Handling Improvements

## 1. Overview
This specification outlines the technical changes to improve the reliability, stability, and observability of the ZTD Password Manager.

## 2. Changes

### 2.1 Exception Handling Standardization
- **Rule**: No empty catch blocks.
- **Implementation**: All `catch` blocks must use `CrashReportService` for logging or re-throw after logging.
- **Specifics**:
  - `database_service.dart`: Log decryption failures.
  - `webdav_sync.dart`: Log network and file I/O errors with meaningful context.
  - `vault_service.dart`: Log decryption failures in `decryptCard`.

### 2.2 Database Atomicity (Transactions)
- **Problem**: Multi-step operations (Card + Event) are not atomic.
- **Solution**: Use `db.transaction()` for:
  - `VaultService.createCard` / `updateCard` / `deleteCard`
  - `DatabaseService.saveCard` (Card + Blind Indexes)
- **Interface Change**: `DatabaseService` will expose a `transaction` method.

### 2.3 Boundary Condition Improvements
- **Null Safety**: Replace force-unwraps (`!`) with explicit checks and descriptive error messages if they fail.
- **Collection Safety**: Add checks before accessing `.first` or specific indices.
- **I/O Safety**: Add timeouts to all WebDAV and File operations.

### 2.4 Cleanup of Mocked Stubs
- **Replace**: Replace custom `File` and `Uuid` stubs with proper packages or `dart:io`.

## 3. Architecture Influence
- **Database Layer**: Increased dependency on transactions.
- **Service Layer**: Tighter coupling with `CrashReportService` for better observability.
