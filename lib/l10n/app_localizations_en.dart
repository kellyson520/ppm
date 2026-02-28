// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZTD Password Manager';

  @override
  String get failedToInitializeVault => 'Failed to initialize vault';

  @override
  String get retry => 'Retry';

  @override
  String get vaultLocked => 'Vault Locked';

  @override
  String get enterMasterPassword => 'Enter your master password to unlock';

  @override
  String get masterPassword => 'Master Password';

  @override
  String get unlock => 'Unlock';

  @override
  String get useBiometric => 'Use Biometric';

  @override
  String get biometricSoon => 'Biometric auth coming soon';

  @override
  String get tooManyAttempts => 'Too many failed attempts. Please wait.';

  @override
  String get incorrectPassword => 'Incorrect password.';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get passwordVault => 'Password Vault';

  @override
  String get authenticator => 'Authenticator';

  @override
  String get settings => 'Settings';

  @override
  String get lockVault => 'Lock Vault';

  @override
  String get syncStarted => 'Sync started';

  @override
  String get alreadyUpToDate => 'Already up to date';

  @override
  String get addPassword => 'Add Password';

  @override
  String get addAuth => 'Add Auth';

  @override
  String get searchPassword => 'Search Password...';

  @override
  String get searchAuthenticator => 'Search Authenticator...';

  @override
  String get passwords => 'Passwords';

  @override
  String get events => 'Events';

  @override
  String get noPasswords => 'No Passwords';

  @override
  String get noMatches => 'No matching items found';

  @override
  String get clickToAdd => 'Click the + button to add your first password';

  @override
  String get clickToAddAuth =>
      'Click the + button to add your first authenticator';

  @override
  String get passwordSaved => 'Password saved successfully';

  @override
  String get changeMasterPassword => 'Change Master Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get cancel => 'Cancel';

  @override
  String get change => 'Change';

  @override
  String get passwordsDoNotMatch => 'New passwords do not match';

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String get failedToChangePassword => 'Failed to change password';

  @override
  String get exportEmergencyKit => 'Export Emergency Kit';

  @override
  String get exportEmergencyKitDesc =>
      'This will export your encryption keys for emergency recovery. Store this securely!';

  @override
  String get export => 'Export';

  @override
  String get emergencyKitExported => 'Emergency kit exported';

  @override
  String get failedToExportEmergencyKit => 'Failed to export emergency kit';

  @override
  String get compactStorage => 'Compact Storage';

  @override
  String get compactStorageQuestion => 'Compact Storage?';

  @override
  String get compactStorageDesc =>
      'This will compress your event history and create a snapshot. This action cannot be undone.';

  @override
  String get compact => 'Compact';

  @override
  String get storageCompacted => 'Storage compacted successfully';

  @override
  String get comingSoon => 'This feature is coming soon 🚀';

  @override
  String get vaultStatistics => 'Vault Statistics';

  @override
  String get totalEvents => 'Total Events';

  @override
  String get pendingSync => 'Pending Sync';

  @override
  String get snapshots => 'Snapshots';

  @override
  String get security => 'Security';

  @override
  String get updateVaultPassword => 'Update your vault password';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get useFaceTouchID => 'Use Face ID / Touch ID';

  @override
  String get synchronization => 'Synchronization';

  @override
  String get webdavNodes => 'WebDAV Nodes';

  @override
  String get configureSyncDestinations => 'Configure sync destinations';

  @override
  String get manualSync => 'Manual Sync';

  @override
  String get syncNowWithNodes => 'Sync now with all nodes';

  @override
  String get storage => 'Storage';

  @override
  String get compressEventHistory => 'Compress event history';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get createEncryptedBackup => 'Create encrypted backup file';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get restoreFromBackup => 'Restore from backup file';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get documentation => 'Documentation';

  @override
  String get sourceCode => 'Source Code';

  @override
  String get lockVaultFull => 'Lock Vault';

  @override
  String get weak => 'Weak';

  @override
  String get medium => 'Medium';

  @override
  String get strong => 'Strong';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get welcomeToZTD => 'Welcome to ZTD';

  @override
  String get e2eEncryption => 'End-to-End Encryption';

  @override
  String get e2eEncryptionDesc => 'Your data is encrypted with AES-256-GCM';

  @override
  String get distributedSync => 'Distributed Sync';

  @override
  String get distributedSyncDesc => 'Sync across devices via WebDAV';

  @override
  String get offlineFirst => 'Offline First';

  @override
  String get offlineFirstDesc => 'Access your passwords anytime, anywhere';

  @override
  String get getStarted => 'Get Started';

  @override
  String get createMasterPassword => 'Create Master Password';

  @override
  String get masterPasswordDesc =>
      'This password will encrypt all your data. Make it strong and memorable.';

  @override
  String get atLeast8Chars => 'At least 8 characters';

  @override
  String get containsUpper => 'Contains uppercase letter';

  @override
  String get containsLower => 'Contains lowercase letter';

  @override
  String get containsNumber => 'Contains number';

  @override
  String get containsSpecial => 'Contains special character';

  @override
  String get back => 'Back';

  @override
  String get continueText => 'Continue';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get enterPasswordAgain => 'Enter your password again to confirm.';

  @override
  String get createVault => 'Create Vault';

  @override
  String get editPassword => 'Edit Password';

  @override
  String get save => 'Save';

  @override
  String get titleWithAsterisk => 'Title *';

  @override
  String get titleHint => 'e.g., Google, Netflix, Bank';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get usernameWithAsterisk => 'Username / Email *';

  @override
  String get usernameHint => 'your@email.com';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get passwordWithAsterisk => 'Password *';

  @override
  String get generatePassword => 'Generate Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShortShort => 'Password must be at least 6 characters';

  @override
  String get websiteURL => 'Website URL';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Additional information...';

  @override
  String get encryption => 'Encryption';

  @override
  String get codeCopied => 'Verification code copied';

  @override
  String get clickToDecrypt => '●● Click to Decrypt ●●';

  @override
  String get details => 'Details';

  @override
  String get noAuthenticators => 'No Authenticators';

  @override
  String get appCrashed => 'App Crashed';

  @override
  String get crashReport => 'Crash Report';

  @override
  String get errorInfo => 'Error Info';

  @override
  String get stackTrace => 'Stack Trace';

  @override
  String get noStackTrace => '(No stack trace info)';

  @override
  String get copyReport => 'Copy Report';

  @override
  String get closeApp => 'Close App';

  @override
  String get reportCopied => 'Crash report copied to clipboard';

  @override
  String get noWebDavNodes => 'No WebDAV nodes configured';

  @override
  String get addNode => 'Add Node';

  @override
  String get addWebDavNode => 'Add WebDAV Node';

  @override
  String get nodeName => 'Node Name';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get open => 'Open';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get title => 'Title';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get website => 'Website';

  @override
  String get metadata => 'Metadata';

  @override
  String get created => 'Created';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get deviceID => 'Device ID';

  @override
  String get deletePasswordQuestion => 'Delete Password?';

  @override
  String get deletePasswordDesc =>
      'This will move the password to trash. You can restore it later.';

  @override
  String get error => 'Error';

  @override
  String get failedToDecryptPassword => 'Failed to decrypt password';

  @override
  String get copiedToClipboard => 'copied to clipboard';

  @override
  String get copyPassword => 'Copy Password';

  @override
  String get authenticatorDetails => 'Authenticator Details';

  @override
  String get exportAsFile => 'Export as File';

  @override
  String get exportAsQrCode => 'Export as QR Code';

  @override
  String get code => 'Code';

  @override
  String get refreshInSeconds => 'seconds left';

  @override
  String get detailsLabel => 'Details';

  @override
  String get issuer => 'Issuer';

  @override
  String get account => 'Account';

  @override
  String get algorithm => 'Algorithm';

  @override
  String get digits => 'Digits';

  @override
  String get digitSpan => 'digits';

  @override
  String get refreshPeriod => 'Refresh Period';

  @override
  String get secondSpan => 'seconds';

  @override
  String get exportLabel => 'Export';

  @override
  String get exportText => 'Export Text';

  @override
  String get exportQrCodeButton => 'Export QR Code';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteThisAuthenticator => 'Delete This Authenticator';

  @override
  String get exportURI => 'Export URI';

  @override
  String get exportWarning =>
      '⚠️ This URI contains your secret key, keep it safe!';

  @override
  String get qrCodeExport => 'QR Code Export';

  @override
  String get qrWarning =>
      '⚠️ This QR code contains your secret key, do not leak it!';

  @override
  String get qrScanTip =>
      'Tip: Use another authenticator to scan this QR code.';

  @override
  String get copyURI => 'Copy URI';

  @override
  String get deleteAuthenticatorLabel => 'Delete Authenticator';

  @override
  String get deleteAuthenticatorConfirmPart1 =>
      'Are you sure you want to delete the authenticator for';

  @override
  String get deleteAuthenticatorConfirmPart2 => '?';

  @override
  String get deleteAuthenticatorWarning =>
      'Deleting this will be permanent! Make sure you have backed up the 2FA secret or disabled it in the respective service.';

  @override
  String get addAuthenticator => 'Add Authenticator';

  @override
  String get editAuthenticator => 'Edit Authenticator';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get uriImport => 'URI Import';

  @override
  String get qrScanImport => 'QR Scan';

  @override
  String get invalidURIMessage => 'Please enter a valid otpauth:// URI';

  @override
  String get uriParsedSuccessfully =>
      'URI parsed successfully, please confirm the details.';

  @override
  String get uriParseFailed => 'URI parse failed';

  @override
  String get qrParsedSuccessfully =>
      'QR code parsed successfully, please confirm the details.';

  @override
  String get qrParseFailed => 'QR code parse failed';

  @override
  String get encryptionKeysNotReady => 'Encryption keys are not ready';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get importedSuccessfullyPart1 => 'Successfully imported';

  @override
  String get importedSuccessfullyPart2 => 'authenticators';

  @override
  String get noValidURIFound => 'No valid otpauth:// URI found';

  @override
  String get issuerWithAsterisk => 'Issuer *';

  @override
  String get issuerHint => 'e.g. GitHub, Google, Binance';

  @override
  String get issuerRequired => 'Please enter the issuer name';

  @override
  String get accountWithAsterisk => 'Account *';

  @override
  String get accountRequired => 'Please enter account name';

  @override
  String get pleaseEnterContent => 'Please enter content';

  @override
  String get secretWithAsterisk => 'Secret *';

  @override
  String get secretRequired => 'Please enter the secret key';

  @override
  String get invalidSecretFormat => 'Invalid secret format (Base32 only)';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get hashAlgorithm => 'Hash Algorithm';

  @override
  String get verificationDigits => 'Verification Digits';

  @override
  String get importMethod => 'Import Method';

  @override
  String get uriImportDesc =>
      'Paste an otpauth:// URI or multiple URIs (one per line) for batch import.\nFormat: otpauth://totp/Label?secret=XXX&issuer=YYY';

  @override
  String get pasteFromClipboard => 'Paste from Clipboard';

  @override
  String get parseAndEdit => 'Parse & Edit';

  @override
  String get quickImport => 'Quick Import';

  @override
  String get scanQR => 'Scan QR Code';

  @override
  String get scanQRToSet => 'Scan 2FA QR Code';

  @override
  String get scanQRDesc =>
      'Scan the QR code provided by the service\nto quickly add an authenticator.';

  @override
  String get startScanning => 'Start Scanning';

  @override
  String get supportGoogleAuth => 'Support Google Authenticator format';

  @override
  String get supportTotpHotp => 'Support TOTP / HOTP protocol';

  @override
  String get autoRecognizeURI => 'Auto-recognize otpauth:// URI';

  @override
  String get placeQrInFrame => 'Place the 2FA QR code inside the frame';

  @override
  String get autoRecognizeQr => 'Auto-recognize otpauth:// QR code';

  @override
  String get turnOnFlash => 'Turn on Flash';

  @override
  String get turnOffFlash => 'Turn off Flash';

  @override
  String get switchCamera => 'Switch Camera';

  @override
  String get scanSuccessful => 'Scan Successful';

  @override
  String get passwordEntry => 'Password Entry';

  @override
  String get urlHint => 'URL (e.g. https://cloud.com/dav/)';

  @override
  String get attempts => 'attempts';
}
