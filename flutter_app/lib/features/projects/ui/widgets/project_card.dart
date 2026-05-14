import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/projects_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
  super.key,
  required this.project,      
  required this.onTap,
});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // ── Folder icon ──────────────────────────────
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ── Project info ─────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + diagrams count badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DiagramsBadge(count: project.diagramsCount),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  if ((project.description ?? '').isNotEmpty) ...[
                    Text(
                      project.description ?? '',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Updated at
                  Text(
                    project.updatedAtLabel,
                    style: AppTextStyles.labelSmall,
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
}

// ── Small badge: "4 diagrams" ────────────────────────────────
class _DiagramsBadge extends StatelessWidget {
  final int count;
  const _DiagramsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$count diagram${count == 1 ? '' : 's'}',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
