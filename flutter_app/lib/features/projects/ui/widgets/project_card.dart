import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/projects_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  final VoidCallback onTap;

  final int index;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.index = 0,
  });

  static const _gradients = [
    [Color(0xFF6C63FF), Color(0xFF9B59B6)],
    [Color(0xFF3B82F6), Color(0xFF6C63FF)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFF10B981), Color(0xFF06B6D4)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient =
        _gradients[index % _gradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [
            // ───────────────────────────────────
            // Folder Icon
            // ───────────────────────────────────

            Container(
              width: 52,
              height: 52,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius:
                    BorderRadius.circular(16),

                boxShadow: [
                  BoxShadow(
                    color: gradient[0]
                        .withValues(alpha: 0.28),

                    blurRadius: 10,

                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: const Icon(
                Icons.folder_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // ───────────────────────────────────
            // Project Info
            // ───────────────────────────────────

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      _DiagramsBadge(
                        count: project.diagramsCount,
                        color: gradient[0],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  if ((project.description ?? '')
                      .isNotEmpty) ...[
                    Text(
                      project.description ?? '',

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: 0.60),

                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 3),
                  ],

                  Text(
                    project.updatedAtLabel,

                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.42),

                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ───────────────────────────────────
            // Arrow
            // ───────────────────────────────────

            Container(
              width: 28,
              height: 28,

              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.05),

                borderRadius:
                    BorderRadius.circular(8),
              ),

              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color:
                    Colors.white.withValues(alpha: 0.55),
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Badge
// ─────────────────────────────────────────────────────

class _DiagramsBadge extends StatelessWidget {
  final int count;

  final Color color;

  const _DiagramsBadge({
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),

      child: Text(
        '$count',

        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}