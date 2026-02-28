import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ZTD Password Manager'**
  String get appTitle;

  /// No description provided for @failedToInitializeVault.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize vault'**
  String get failedToInitializeVault;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @vaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault Locked'**
  String get vaultLocked;

  /// No description provided for @enterMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your master password to unlock'**
  String get enterMasterPassword;

  /// No description provided for @masterPassword.
  ///
  /// In en, this message translates to:
  /// **'Master Password'**
  String get masterPassword;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometric;

  /// No description provided for @biometricSoon.
  ///
  /// In en, this message translates to:
  /// **'Biometric auth coming soon'**
  String get biometricSoon;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please wait.'**
  String get tooManyAttempts;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get incorrectPassword;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @passwordVault.
  ///
  /// In en, this message translates to:
  /// **'Password Vault'**
  String get passwordVault;

  /// No description provided for @authenticator.
  ///
  /// In en, this message translates to:
  /// **'Authenticator'**
  String get authenticator;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @lockVault.
  ///
  /// In en, this message translates to:
  /// **'Lock Vault'**
  String get lockVault;

  /// No description provided for @syncStarted.
  ///
  /// In en, this message translates to:
  /// **'Sync started'**
  String get syncStarted;

  /// No description provided for @alreadyUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get alreadyUpToDate;

  /// No description provided for @addPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get addPassword;

  /// No description provided for @addAuth.
  ///
  /// In en, this message translates to:
  /// **'Add Auth'**
  String get addAuth;

  /// No description provided for @searchPassword.
  ///
  /// In en, this message translates to:
  /// **'Search Password...'**
  String get searchPassword;

  /// No description provided for @searchAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Search Authenticator...'**
  String get searchAuthenticator;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get passwords;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @noPasswords.
  ///
  /// In en, this message translates to:
  /// **'No Passwords'**
  String get noPasswords;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching items found'**
  String get noMatches;

  /// No description provided for @clickToAdd.
  ///
  /// In en, this message translates to:
  /// **'Click the + button to add your first password'**
  String get clickToAdd;

  /// No description provided for @clickToAddAuth.
  ///
  /// In en, this message translates to:
  /// **'Click the + button to add your first authenticator'**
  String get clickToAddAuth;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved successfully'**
  String get passwordSaved;

  /// No description provided for @changeMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get changeMasterPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @exportEmergencyKit.
  ///
  /// In en, this message translates to:
  /// **'Export Emergency Kit'**
  String get exportEmergencyKit;

  /// No description provided for @exportEmergencyKitDesc.
  ///
  /// In en, this message translates to:
  /// **'This will export your encryption keys for emergency recovery. Store this securely!'**
  String get exportEmergencyKitDesc;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @emergencyKitExported.
  ///
  /// In en, this message translates to:
  /// **'Emergency kit exported'**
  String get emergencyKitExported;

  /// No description provided for @failedToExportEmergencyKit.
  ///
  /// In en, this message translates to:
  /// **'Failed to export emergency kit'**
  String get failedToExportEmergencyKit;

  /// No description provided for @compactStorage.
  ///
  /// In en, this message translates to:
  /// **'Compact Storage'**
  String get compactStorage;

  /// No description provided for @compactStorageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Compact Storage?'**
  String get compactStorageQuestion;

  /// No description provided for @compactStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'This will compress your event history and create a snapshot. This action cannot be undone.'**
  String get compactStorageDesc;

  /// No description provided for @compact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @storageCompacted.
  ///
  /// In en, this message translates to:
  /// **'Storage compacted successfully'**
  String get storageCompacted;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon 🚀'**
  String get comingSoon;

  /// No description provided for @vaultStatistics.
  ///
  /// In en, this message translates to:
  /// **'Vault Statistics'**
  String get vaultStatistics;

  /// No description provided for @totalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total Events'**
  String get totalEvents;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get pendingSync;

  /// No description provided for @snapshots.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get snapshots;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @updateVaultPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your vault password'**
  String get updateVaultPassword;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @useFaceTouchID.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID / Touch ID'**
  String get useFaceTouchID;

  /// No description provided for @synchronization.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get synchronization;

  /// No description provided for @webdavNodes.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Nodes'**
  String get webdavNodes;

  /// No description provided for @configureSyncDestinations.
  ///
  /// In en, this message translates to:
  /// **'Configure sync destinations'**
  String get configureSyncDestinations;

  /// No description provided for @manualSync.
  ///
  /// In en, this message translates to:
  /// **'Manual Sync'**
  String get manualSync;

  /// No description provided for @syncNowWithNodes.
  ///
  /// In en, this message translates to:
  /// **'Sync now with all nodes'**
  String get syncNowWithNodes;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @compressEventHistory.
  ///
  /// In en, this message translates to:
  /// **'Compress event history'**
  String get compressEventHistory;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @createEncryptedBackup.
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup file'**
  String get createEncryptedBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup file'**
  String get restoreFromBackup;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// No description provided for @lockVaultFull.
  ///
  /// In en, this message translates to:
  /// **'Lock Vault'**
  String get lockVaultFull;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @welcomeToZTD.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ZTD'**
  String get welcomeToZTD;

  /// No description provided for @e2eEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption'**
  String get e2eEncryption;

  /// No description provided for @e2eEncryptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted with AES-256-GCM'**
  String get e2eEncryptionDesc;

  /// No description provided for @distributedSync.
  ///
  /// In en, this message translates to:
  /// **'Distributed Sync'**
  String get distributedSync;

  /// No description provided for @distributedSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync across devices via WebDAV'**
  String get distributedSyncDesc;

  /// No description provided for @offlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Offline First'**
  String get offlineFirst;

  /// No description provided for @offlineFirstDesc.
  ///
  /// In en, this message translates to:
  /// **'Access your passwords anytime, anywhere'**
  String get offlineFirstDesc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @createMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Master Password'**
  String get createMasterPassword;

  /// No description provided for @masterPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'This password will encrypt all your data. Make it strong and memorable.'**
  String get masterPasswordDesc;

  /// No description provided for @atLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Chars;

  /// No description provided for @containsUpper.
  ///
  /// In en, this message translates to:
  /// **'Contains uppercase letter'**
  String get containsUpper;

  /// No description provided for @containsLower.
  ///
  /// In en, this message translates to:
  /// **'Contains lowercase letter'**
  String get containsLower;

  /// No description provided for @containsNumber.
  ///
  /// In en, this message translates to:
  /// **'Contains number'**
  String get containsNumber;

  /// No description provided for @containsSpecial.
  ///
  /// In en, this message translates to:
  /// **'Contains special character'**
  String get containsSpecial;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @enterPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again to confirm.'**
  String get enterPasswordAgain;

  /// No description provided for @createVault.
  ///
  /// In en, this message translates to:
  /// **'Create Vault'**
  String get createVault;

  /// No description provided for @editPassword.
  ///
  /// In en, this message translates to:
  /// **'Edit Password'**
  String get editPassword;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @titleWithAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleWithAsterisk;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Google, Netflix, Bank'**
  String get titleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @usernameWithAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Username / Email *'**
  String get usernameWithAsterisk;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @passwordWithAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get passwordWithAsterisk;

  /// No description provided for @generatePassword.
  ///
  /// In en, this message translates to:
  /// **'Generate Password'**
  String get generatePassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShortShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShortShort;

  /// No description provided for @websiteURL.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get websiteURL;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional information...'**
  String get notesHint;

  /// No description provided for @encryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryption;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Verification code copied'**
  String get codeCopied;

  /// No description provided for @clickToDecrypt.
  ///
  /// In en, this message translates to:
  /// **'●● Click to Decrypt ●●'**
  String get clickToDecrypt;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @noAuthenticators.
  ///
  /// In en, this message translates to:
  /// **'No Authenticators'**
  String get noAuthenticators;

  /// No description provided for @appCrashed.
  ///
  /// In en, this message translates to:
  /// **'App Crashed'**
  String get appCrashed;

  /// No description provided for @crashReport.
  ///
  /// In en, this message translates to:
  /// **'Crash Report'**
  String get crashReport;

  /// No description provided for @errorInfo.
  ///
  /// In en, this message translates to:
  /// **'Error Info'**
  String get errorInfo;

  /// No description provided for @stackTrace.
  ///
  /// In en, this message translates to:
  /// **'Stack Trace'**
  String get stackTrace;

  /// No description provided for @noStackTrace.
  ///
  /// In en, this message translates to:
  /// **'(No stack trace info)'**
  String get noStackTrace;

  /// No description provided for @copyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy Report'**
  String get copyReport;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeApp;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Crash report copied to clipboard'**
  String get reportCopied;

  /// No description provided for @noWebDavNodes.
  ///
  /// In en, this message translates to:
  /// **'No WebDAV nodes configured'**
  String get noWebDavNodes;

  /// No description provided for @addNode.
  ///
  /// In en, this message translates to:
  /// **'Add Node'**
  String get addNode;

  /// No description provided for @addWebDavNode.
  ///
  /// In en, this message translates to:
  /// **'Add WebDAV Node'**
  String get addWebDavNode;

  /// No description provided for @nodeName.
  ///
  /// In en, this message translates to:
  /// **'Node Name'**
  String get nodeName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @deviceID.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceID;

  /// No description provided for @deletePasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Password?'**
  String get deletePasswordQuestion;

  /// No description provided for @deletePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'This will move the password to trash. You can restore it later.'**
  String get deletePasswordDesc;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @failedToDecryptPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to decrypt password'**
  String get failedToDecryptPassword;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyPassword.
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get copyPassword;

  /// No description provided for @authenticatorDetails.
  ///
  /// In en, this message translates to:
  /// **'Authenticator Details'**
  String get authenticatorDetails;

  /// No description provided for @exportAsFile.
  ///
  /// In en, this message translates to:
  /// **'Export as File'**
  String get exportAsFile;

  /// No description provided for @exportAsQrCode.
  ///
  /// In en, this message translates to:
  /// **'Export as QR Code'**
  String get exportAsQrCode;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @refreshInSeconds.
  ///
  /// In en, this message translates to:
  /// **'seconds left'**
  String get refreshInSeconds;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @issuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @algorithm.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get algorithm;

  /// No description provided for @digits.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get digits;

  /// No description provided for @digitSpan.
  ///
  /// In en, this message translates to:
  /// **'digits'**
  String get digitSpan;

  /// No description provided for @refreshPeriod.
  ///
  /// In en, this message translates to:
  /// **'Refresh Period'**
  String get refreshPeriod;

  /// No description provided for @secondSpan.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondSpan;

  /// No description provided for @exportLabel.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportLabel;

  /// No description provided for @exportText.
  ///
  /// In en, this message translates to:
  /// **'Export Text'**
  String get exportText;

  /// No description provided for @exportQrCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Export QR Code'**
  String get exportQrCodeButton;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteThisAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Delete This Authenticator'**
  String get deleteThisAuthenticator;

  /// No description provided for @exportURI.
  ///
  /// In en, this message translates to:
  /// **'Export URI'**
  String get exportURI;

  /// No description provided for @exportWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This URI contains your secret key, keep it safe!'**
  String get exportWarning;

  /// No description provided for @qrCodeExport.
  ///
  /// In en, this message translates to:
  /// **'QR Code Export'**
  String get qrCodeExport;

  /// No description provided for @qrWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This QR code contains your secret key, do not leak it!'**
  String get qrWarning;

  /// No description provided for @qrScanTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Use another authenticator to scan this QR code.'**
  String get qrScanTip;

  /// No description provided for @copyURI.
  ///
  /// In en, this message translates to:
  /// **'Copy URI'**
  String get copyURI;

  /// No description provided for @deleteAuthenticatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Authenticator'**
  String get deleteAuthenticatorLabel;

  /// No description provided for @deleteAuthenticatorConfirmPart1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the authenticator for'**
  String get deleteAuthenticatorConfirmPart1;

  /// No description provided for @deleteAuthenticatorConfirmPart2.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get deleteAuthenticatorConfirmPart2;

  /// No description provided for @deleteAuthenticatorWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting this will be permanent! Make sure you have backed up the 2FA secret or disabled it in the respective service.'**
  String get deleteAuthenticatorWarning;

  /// No description provided for @addAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Add Authenticator'**
  String get addAuthenticator;

  /// No description provided for @editAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Edit Authenticator'**
  String get editAuthenticator;

  /// No description provided for @manualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual Input'**
  String get manualInput;

  /// No description provided for @uriImport.
  ///
  /// In en, this message translates to:
  /// **'URI Import'**
  String get uriImport;

  /// No description provided for @qrScanImport.
  ///
  /// In en, this message translates to:
  /// **'QR Scan'**
  String get qrScanImport;

  /// No description provided for @invalidURIMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid otpauth:// URI'**
  String get invalidURIMessage;

  /// No description provided for @uriParsedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'URI parsed successfully, please confirm the details.'**
  String get uriParsedSuccessfully;

  /// No description provided for @uriParseFailed.
  ///
  /// In en, this message translates to:
  /// **'URI parse failed'**
  String get uriParseFailed;

  /// No description provided for @qrParsedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'QR code parsed successfully, please confirm the details.'**
  String get qrParsedSuccessfully;

  /// No description provided for @qrParseFailed.
  ///
  /// In en, this message translates to:
  /// **'QR code parse failed'**
  String get qrParseFailed;

  /// No description provided for @encryptionKeysNotReady.
  ///
  /// In en, this message translates to:
  /// **'Encryption keys are not ready'**
  String get encryptionKeysNotReady;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @importedSuccessfullyPart1.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported'**
  String get importedSuccessfullyPart1;

  /// No description provided for @importedSuccessfullyPart2.
  ///
  /// In en, this message translates to:
  /// **'authenticators'**
  String get importedSuccessfullyPart2;

  /// No description provided for @noValidURIFound.
  ///
  /// In en, this message translates to:
  /// **'No valid otpauth:// URI found'**
  String get noValidURIFound;

  /// No description provided for @issuerWithAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Issuer *'**
  String get issuerWithAsterisk;

  /// No description provided for @issuerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GitHub, Google, Binance'**
  String get issuerHint;

  /// No description provided for @issuerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the issuer name'**
  String get issuerRequired;

  /// No description provided for @accountWithAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Account *'**
  String get accountWithAsterisk;

  /// No description provided for @accountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter account name'**
  String get accountRequired;

  /// No description provided for @pleaseEnterContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter content'**
  String get pleaseEnterContent;

  /// No description provided for @secretWithAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Secret *'**
  String get secretWithAsterisk;

  /// No description provided for @secretRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the secret key'**
  String get secretRequired;

  /// No description provided for @invalidSecretFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid secret format (Base32 only)'**
  String get invalidSecretFormat;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// No description provided for @hashAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Hash Algorithm'**
  String get hashAlgorithm;

  /// No description provided for @verificationDigits.
  ///
  /// In en, this message translates to:
  /// **'Verification Digits'**
  String get verificationDigits;

  /// No description provided for @importMethod.
  ///
  /// In en, this message translates to:
  /// **'Import Method'**
  String get importMethod;

  /// No description provided for @uriImportDesc.
  ///
  /// In en, this message translates to:
  /// **'Paste an otpauth:// URI or multiple URIs (one per line) for batch import.\nFormat: otpauth://totp/Label?secret=XXX&issuer=YYY'**
  String get uriImportDesc;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @parseAndEdit.
  ///
  /// In en, this message translates to:
  /// **'Parse & Edit'**
  String get parseAndEdit;

  /// No description provided for @quickImport.
  ///
  /// In en, this message translates to:
  /// **'Quick Import'**
  String get quickImport;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQR;

  /// No description provided for @scanQRToSet.
  ///
  /// In en, this message translates to:
  /// **'Scan 2FA QR Code'**
  String get scanQRToSet;

  /// No description provided for @scanQRDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code provided by the service\nto quickly add an authenticator.'**
  String get scanQRDesc;

  /// No description provided for @startScanning.
  ///
  /// In en, this message translates to:
  /// **'Start Scanning'**
  String get startScanning;

  /// No description provided for @supportGoogleAuth.
  ///
  /// In en, this message translates to:
  /// **'Support Google Authenticator format'**
  String get supportGoogleAuth;

  /// No description provided for @supportTotpHotp.
  ///
  /// In en, this message translates to:
  /// **'Support TOTP / HOTP protocol'**
  String get supportTotpHotp;

  /// No description provided for @autoRecognizeURI.
  ///
  /// In en, this message translates to:
  /// **'Auto-recognize otpauth:// URI'**
  String get autoRecognizeURI;

  /// No description provided for @placeQrInFrame.
  ///
  /// In en, this message translates to:
  /// **'Place the 2FA QR code inside the frame'**
  String get placeQrInFrame;

  /// No description provided for @autoRecognizeQr.
  ///
  /// In en, this message translates to:
  /// **'Auto-recognize otpauth:// QR code'**
  String get autoRecognizeQr;

  /// No description provided for @turnOnFlash.
  ///
  /// In en, this message translates to:
  /// **'Turn on Flash'**
  String get turnOnFlash;

  /// No description provided for @turnOffFlash.
  ///
  /// In en, this message translates to:
  /// **'Turn off Flash'**
  String get turnOffFlash;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @scanSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Scan Successful'**
  String get scanSuccessful;

  /// No description provided for @passwordEntry.
  ///
  /// In en, this message translates to:
  /// **'Password Entry'**
  String get passwordEntry;

  /// No description provided for @urlHint.
  ///
  /// In en, this message translates to:
  /// **'URL (e.g. https://cloud.com/dav/)'**
  String get urlHint;

  /// No description provided for @attempts.
  ///
  /// In en, this message translates to:
  /// **'attempts'**
  String get attempts;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
