// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ZTD 密码管理器';

  @override
  String get failedToInitializeVault => '初始化保管库失败';

  @override
  String get retry => '重试';

  @override
  String get vaultLocked => '保险箱已锁定';

  @override
  String get enterMasterPassword => '请输入主密码解锁';

  @override
  String get masterPassword => '主密码';

  @override
  String get unlock => '解锁';

  @override
  String get useBiometric => '使用生物识别';

  @override
  String get biometricSoon => '生物识别功能即将推出';

  @override
  String get tooManyAttempts => '尝试次数过多，请稍候。';

  @override
  String get incorrectPassword => '密码错误。';

  @override
  String get anErrorOccurred => '发生错误';

  @override
  String get passwordVault => '密码保险箱';

  @override
  String get authenticator => '身份验证器';

  @override
  String get settings => '设置';

  @override
  String get lockVault => '锁定保险箱';

  @override
  String get syncStarted => '同步已开始';

  @override
  String get alreadyUpToDate => '已是最新状态';

  @override
  String get addPassword => '添加密码';

  @override
  String get addAuth => '添加验证';

  @override
  String get searchPassword => '搜索密码...';

  @override
  String get searchAuthenticator => '搜索验证器...';

  @override
  String get passwords => '密码';

  @override
  String get events => '事件';

  @override
  String get noPasswords => '暂无密码';

  @override
  String get noMatches => '未找到匹配项';

  @override
  String get clickToAdd => '点击右下角 + 按钮添加第一个密码';

  @override
  String get clickToAddAuth => '点击右下角 + 按钮添加第一个验证器';

  @override
  String get passwordSaved => '密码保存成功';

  @override
  String get changeMasterPassword => '更改主密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get cancel => '取消';

  @override
  String get change => '更改';

  @override
  String get passwordsDoNotMatch => '新密码不匹配';

  @override
  String get passwordChanged => '密码已成功更改';

  @override
  String get failedToChangePassword => '更改密码失败';

  @override
  String get exportEmergencyKit => '导出紧急恢复包';

  @override
  String get exportEmergencyKitDesc => '这将导出您的加密密钥用于紧急恢复。请妥善保管！';

  @override
  String get export => '导出';

  @override
  String get emergencyKitExported => '紧急恢复包已导出';

  @override
  String get failedToExportEmergencyKit => '导出紧急恢复包失败';

  @override
  String get compactStorage => '压缩存储';

  @override
  String get compactStorageQuestion => '是否压缩存储？';

  @override
  String get compactStorageDesc => '这将压缩您的事件历史记录并创建快照。此操作无法撤销。';

  @override
  String get compact => '压缩';

  @override
  String get storageCompacted => '存储压缩成功';

  @override
  String get comingSoon => '此功能即将推出，敬请期待 🚀';

  @override
  String get vaultStatistics => '保险箱统计';

  @override
  String get totalEvents => '总事件数';

  @override
  String get pendingSync => '待同步';

  @override
  String get snapshots => '快照';

  @override
  String get security => '安全';

  @override
  String get updateVaultPassword => '更新您的保险箱密码';

  @override
  String get biometricAuth => '生物识别身份验证';

  @override
  String get useFaceTouchID => '使用面容 ID / 指纹 ID';

  @override
  String get synchronization => '同步';

  @override
  String get webdavNodes => 'WebDAV 节点';

  @override
  String get configureSyncDestinations => '配置同步目标';

  @override
  String get manualSync => '手动同步';

  @override
  String get syncNowWithNodes => '立即与所有节点同步';

  @override
  String get storage => '存储';

  @override
  String get compressEventHistory => '压缩事件历史记录';

  @override
  String get exportBackup => '导出备份';

  @override
  String get createEncryptedBackup => '创建加密备份文件';

  @override
  String get importBackup => '导入备份';

  @override
  String get restoreFromBackup => '从备份文件恢复';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get documentation => '文档';

  @override
  String get sourceCode => '源代码';

  @override
  String get lockVaultFull => '锁定保险箱';

  @override
  String get weak => '弱';

  @override
  String get medium => '中';

  @override
  String get strong => '强';

  @override
  String get passwordTooShort => '密码长度必须至少为 8 个字符';

  @override
  String get unknownError => '未知错误';

  @override
  String get welcomeToZTD => '欢迎使用 ZTD';

  @override
  String get e2eEncryption => '端到端加密';

  @override
  String get e2eEncryptionDesc => '您的数据使用 AES-256-GCM 加密';

  @override
  String get distributedSync => '分布式同步';

  @override
  String get distributedSyncDesc => '通过 WebDAV 在设备之间同步';

  @override
  String get offlineFirst => '离线优先';

  @override
  String get offlineFirstDesc => '随时随地访问您的密码';

  @override
  String get getStarted => '开始使用';

  @override
  String get createMasterPassword => '创建主密码';

  @override
  String get masterPasswordDesc => '此密码将加密您的所有数据。请确保它既强大又好记。';

  @override
  String get atLeast8Chars => '至少 8 个字符';

  @override
  String get containsUpper => '包含大写字母';

  @override
  String get containsLower => '包含小写字母';

  @override
  String get containsNumber => '包含数字';

  @override
  String get containsSpecial => '包含特殊字符';

  @override
  String get back => '上一步';

  @override
  String get continueText => '继续';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get enterPasswordAgain => '再次输入您的密码以确认。';

  @override
  String get createVault => '创建保险箱';

  @override
  String get editPassword => '编辑密码';

  @override
  String get save => '保存';

  @override
  String get titleWithAsterisk => '标题 *';

  @override
  String get titleHint => '例如：谷歌、网易云、银行';

  @override
  String get titleRequired => '请输入标题';

  @override
  String get usernameWithAsterisk => '用户名 / 邮箱 *';

  @override
  String get usernameHint => 'your@email.com';

  @override
  String get usernameRequired => '请输入用户名';

  @override
  String get passwordWithAsterisk => '密码 *';

  @override
  String get generatePassword => '生成密码';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get passwordTooShortShort => '密码长度必须至少为 6 个字符';

  @override
  String get websiteURL => '网站 URL';

  @override
  String get notes => '备注';

  @override
  String get notesHint => '附加信息...';

  @override
  String get encryption => '加密';

  @override
  String get codeCopied => '验证码已复制';

  @override
  String get clickToDecrypt => '●● 点击解密 ●●';

  @override
  String get details => '详情';

  @override
  String get noAuthenticators => '暂无验证器';

  @override
  String get appCrashed => '应用崩溃';

  @override
  String get crashReport => '崩溃报告';

  @override
  String get errorInfo => '错误信息';

  @override
  String get stackTrace => '堆栈轨迹';

  @override
  String get noStackTrace => '（无堆栈信息）';

  @override
  String get copyReport => '复制报告';

  @override
  String get closeApp => '关闭应用';

  @override
  String get reportCopied => '崩溃报告已复制到剪贴板';

  @override
  String get noWebDavNodes => '未配置 WebDAV 节点';

  @override
  String get addNode => '添加节点';

  @override
  String get addWebDavNode => '添加 WebDAV 节点';

  @override
  String get nodeName => '节点名称';

  @override
  String get username => '用户名';

  @override
  String get password => 'Password';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get copy => '复制';

  @override
  String get open => '打开';

  @override
  String get hide => '隐藏';

  @override
  String get show => '显示';

  @override
  String get title => '标题';

  @override
  String get usernameLabel => '用户名';

  @override
  String get passwordLabel => '密码';

  @override
  String get website => '网站';

  @override
  String get metadata => '元数据';

  @override
  String get created => '创建于';

  @override
  String get lastUpdated => '最后更新';

  @override
  String get deviceID => '设备 ID';

  @override
  String get deletePasswordQuestion => '删除密码？';

  @override
  String get deletePasswordDesc => '这将把密码移至回收站。您可以稍后恢复它。';

  @override
  String get error => '错误';

  @override
  String get failedToDecryptPassword => '解密密码失败';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get copyPassword => '复制密码';

  @override
  String get authenticatorDetails => '验证器详情';

  @override
  String get exportAsFile => '导出为文件';

  @override
  String get exportAsQrCode => '导出为二维码';

  @override
  String get code => '验证码';

  @override
  String get refreshInSeconds => '秒后刷新';

  @override
  String get detailsLabel => '详细信息';

  @override
  String get issuer => '发行方';

  @override
  String get account => '账号';

  @override
  String get algorithm => '算法';

  @override
  String get digits => '位数';

  @override
  String get digitSpan => '位';

  @override
  String get refreshPeriod => '刷新周期';

  @override
  String get secondSpan => '秒';

  @override
  String get exportLabel => '导出';

  @override
  String get exportText => '导出文本';

  @override
  String get exportQrCodeButton => '导出二维码';

  @override
  String get dangerZone => '危险操作';

  @override
  String get deleteThisAuthenticator => '删除此验证器';

  @override
  String get exportURI => '导出 URI';

  @override
  String get exportWarning => '⚠️ 此 URI 包含您的密钥，请妥善保管！';

  @override
  String get qrCodeExport => '二维码导出';

  @override
  String get qrWarning => '⚠️ 此二维码包含您的密钥，请勿泄露！';

  @override
  String get qrScanTip => '提示：可使用其他验证器扫描此二维码导入。';

  @override
  String get copyURI => '复制 URI';

  @override
  String get deleteAuthenticatorLabel => '删除验证器';

  @override
  String get deleteAuthenticatorConfirmPart1 => '您确定要删除';

  @override
  String get deleteAuthenticatorConfirmPart2 => '的验证器吗？';

  @override
  String get deleteAuthenticatorWarning =>
      '删除后将无法恢复！请确保您已备份 2FA 密钥或在对应服务中禁用了它。';

  @override
  String get addAuthenticator => '添加验证器';

  @override
  String get editAuthenticator => '编辑验证器';

  @override
  String get manualInput => '手动输入';

  @override
  String get uriImport => 'URI 导入';

  @override
  String get qrScanImport => '扫码导入';

  @override
  String get invalidURIMessage => '请输入有效的 otpauth:// URI';

  @override
  String get uriParsedSuccessfully => 'URI 解析成功，请确认详情。';

  @override
  String get uriParseFailed => 'URI 解析失败';

  @override
  String get qrParsedSuccessfully => '二维码解析成功，请确认详情。';

  @override
  String get qrParseFailed => '二维码解析失败';

  @override
  String get encryptionKeysNotReady => '加密密钥未就绪';

  @override
  String get saveFailed => '保存失败';

  @override
  String get importedSuccessfullyPart1 => '成功导入';

  @override
  String get importedSuccessfullyPart2 => '个验证器';

  @override
  String get noValidURIFound => '未找到有效的 otpauth:// URI';

  @override
  String get issuerWithAsterisk => '发行方 *';

  @override
  String get issuerHint => '例如：GitHub, Google, Binance';

  @override
  String get issuerRequired => '请输入发行方名称';

  @override
  String get accountWithAsterisk => '账号 *';

  @override
  String get accountRequired => '请输入账号名称';

  @override
  String get pleaseEnterContent => '请输入内容';

  @override
  String get secretWithAsterisk => '密钥 *';

  @override
  String get secretRequired => '请输入密钥';

  @override
  String get invalidSecretFormat => '密钥格式无效（仅支持 Base32 字符）';

  @override
  String get advancedOptions => '高级选项';

  @override
  String get hashAlgorithm => '哈希算法';

  @override
  String get verificationDigits => '验证码位数';

  @override
  String get importMethod => '导入方式';

  @override
  String get uriImportDesc =>
      '粘贴 otpauth:// URI 或多个 URI（每行一个）进行批量导入。\n格式：otpauth://totp/Label?secret=XXX&issuer=YYY';

  @override
  String get pasteFromClipboard => '从剪贴板粘贴';

  @override
  String get parseAndEdit => '解析并编辑';

  @override
  String get quickImport => '快速导入';

  @override
  String get scanQR => '扫描二维码';

  @override
  String get scanQRToSet => '扫描 2FA 二维码';

  @override
  String get scanQRDesc => '扫描服务提供的二维码\n以快速添加验证器。';

  @override
  String get startScanning => '开始扫描';

  @override
  String get supportGoogleAuth => '支持 Google Authenticator 格式';

  @override
  String get supportTotpHotp => '支持 TOTP / HOTP 协议';

  @override
  String get autoRecognizeURI => '自动识别 otpauth:// URI';

  @override
  String get placeQrInFrame => '将 2FA 二维码放入框内';

  @override
  String get autoRecognizeQr => '自动识别 otpauth:// 二维码';

  @override
  String get turnOnFlash => '开启闪光灯';

  @override
  String get turnOffFlash => '关闭闪光灯';

  @override
  String get switchCamera => '切换摄像头';

  @override
  String get scanSuccessful => '扫描成功';

  @override
  String get passwordEntry => '密码条目';

  @override
  String get urlHint => 'URL (例如 https://cloud.com/dav/)';

  @override
  String get attempts => '次尝试';
}
