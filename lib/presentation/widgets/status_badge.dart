import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'published':
      case 'completed':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'প্রকাশিত';
        break;
      case 'draft':
        bg = AppColors.border;
        text = AppColors.textSecondary;
        label = 'ড্রাফট';
        break;
      case 'scheduled':
      case 'pending':
      case 'queued':
        bg = AppColors.infoLight;
        text = AppColors.info;
        label = 'শিডিউলড';
        break;
      case 'failed':
        bg = AppColors.dangerLight;
        text = AppColors.danger;
        label = 'ব্যর্থ';
        break;
      default:
        bg = AppColors.border;
        text = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
