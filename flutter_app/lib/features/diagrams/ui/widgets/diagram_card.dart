import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/diagram_model.dart';

class DiagramCard extends StatelessWidget {
  final Diagram diagram;
  final VoidCallback onTap;

  const DiagramCard({super.key, required this.diagram, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(diagram.type);
    final typeIcon = _typeIcon(diagram.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          diagram.name.isNotEmpty ? diagram.name : 'Untitled',
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TypeBadge(type: diagram.type, color: typeColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusDot(status: diagram.status),
                      const SizedBox(width: 4),
                      Text(
                        '${_statusLabel(diagram.status)} · ${diagram.createdAtLabel}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'erd':
        return AppColors.diagramErd;
      case 'class':
        return AppColors.diagramClass;
      case 'mindmap':
        return AppColors.diagramMindmap;
      default:
        return AppColors.diagramAuto;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'erd':
        return Icons.table_chart_rounded;
      case 'class':
        return Icons.code_rounded;
      case 'mindmap':
        return Icons.account_tree_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Generated';
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'done':
        color = AppColors.success;
        break;
      case 'failed':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
