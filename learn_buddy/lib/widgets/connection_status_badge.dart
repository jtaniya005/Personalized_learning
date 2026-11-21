import 'package:flutter/material.dart';
import '../controllers/voice_assistant_controller.dart';
import '../theme/voice_app_theme.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final ServerStatus status;
  final String statusMessage;
  final VoidCallback? onTap;

  const ConnectionStatusBadge({
    super.key,
    required this.status,
    required this.statusMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    String label;

    switch (status) {
      case ServerStatus.online:
        indicatorColor = VoiceAppColors.statusOnline;
        label = 'Online';
        break;
      case ServerStatus.offline:
        indicatorColor = VoiceAppColors.statusOffline;
        label = 'Offline';
        break;
      case ServerStatus.checking:
        indicatorColor = VoiceAppColors.statusWarning;
        label = 'Connecting...';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: indicatorColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: indicatorColor.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
                boxShadow: [
                  BoxShadow(
                    color: indicatorColor.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: indicatorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
