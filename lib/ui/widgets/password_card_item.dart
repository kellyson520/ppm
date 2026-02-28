import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../l10n/app_localizations.dart';
import 'bouncing_widget.dart';

class PasswordCardItem extends StatelessWidget {
  final PasswordCard card;
  final PasswordPayload? payload;
  final VoidCallback onTap;

  const PasswordCardItem({
    super.key,
    required this.card,
    this.payload,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingWidget(
      onTap: onTap,
      scaleFactor: 0.96, // 点击微弱阻尼收缩
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          // 彻底抛弃 Card 实底，只靠 1px 微量透白分割线和底层留白
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06), // 毛细边缘
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 图标底板：去除老式的渐变强光，改为苹果高级深色+极微光
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12), // iOS 连续圆角风
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.lock,
                color: Color(0xFF6C63FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // 内容排版
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCardTitle(context),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600, // SemiBold
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payload?.username ??
                        'ID: ${card.cardId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // 弱化的向右箭头（可选移除，保留提供暗示）
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getCardTitle(BuildContext context) {
    if (payload != null && payload!.title.isNotEmpty) {
      return payload!.title;
    }
    final l10n = AppLocalizations.of(context)!;
    return l10n.passwordEntry;
  }
}
