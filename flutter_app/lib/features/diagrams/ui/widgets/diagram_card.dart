import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/diagram_model.dart';

class DiagramCard extends StatefulWidget {
  final Diagram diagram;
  final VoidCallback onTap;
  final int index;

  const DiagramCard({
    super.key,
    required this.diagram,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<DiagramCard> createState() => _DiagramCardState();
}

class _DiagramCardState extends State<DiagramCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 55),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(
      Duration(milliseconds: widget.index * 55),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(widget.diagram.type);
    final typeColor2 = _typeColor2(widget.diagram.type);
    final typeIcon = _typeIcon(widget.diagram.type);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              splashColor: typeColor.withValues(alpha: 0.07),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    // Gradient type icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [typeColor, typeColor2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(typeIcon, color: Colors.white, size: 24),
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
                                  widget.diagram.name.isNotEmpty
                                      ? widget.diagram.name
                                      : 'Untitled',
                                  style: AppTextStyles.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _TypeBadge(
                                type: widget.diagram.type,
                                color: typeColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _StatusDot(status: widget.diagram.status),
                              const SizedBox(width: 5),
                              Text(
                                '${_statusLabel(widget.diagram.status)} · ${widget.diagram.createdAtLabel}',
                                style: AppTextStyles.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSizes.sm),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm + 2),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'erd':      return const Color(0xFF6C63FF);
      case 'class':    return const Color(0xFF00D4FF);
      case 'mindmap':  return const Color(0xFFFF6584);
      case 'usecase':  return const Color(0xFF43E97B);
      case 'sequence': return const Color(0xFFF7971E);
      case 'activity': return const Color(0xFF9B59B6);
      case 'context':  return const Color(0xFF00B4D8);
      case 'state':    return const Color(0xFFFF9A9E);
      case 'dfd':      return const Color(0xFF56CCF2);
      case 'gantt':    return const Color(0xFFF2994A);
      default:         return AppColors.primary;
    }
  }

  Color _typeColor2(String type) {
    switch (type) {
      case 'erd':      return const Color(0xFF00D4FF);
      case 'class':    return const Color(0xFF6C63FF);
      case 'mindmap':  return const Color(0xFFFFA07A);
      case 'usecase':  return const Color(0xFF38F9D7);
      case 'sequence': return const Color(0xFFFFD200);
      case 'activity': return const Color(0xFF6C63FF);
      case 'context':  return const Color(0xFF0077B6);
      case 'state':    return const Color(0xFFFDA085);
      case 'dfd':      return const Color(0xFF2F80ED);
      case 'gantt':    return const Color(0xFFEB5757);
      default:         return AppColors.accent;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'erd':      return Icons.storage_rounded;
      case 'class':    return Icons.code_rounded;
      case 'mindmap':  return Icons.hub_rounded;
      case 'usecase':  return Icons.person_rounded;
      case 'sequence': return Icons.swap_horiz_rounded;
      case 'activity': return Icons.alt_route_rounded;
      case 'context':  return Icons.language_rounded;
      case 'state':    return Icons.timeline_rounded;
      case 'dfd':      return Icons.account_tree_rounded;
      case 'gantt':    return Icons.bar_chart_rounded;
      default:         return Icons.auto_awesome_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'done':       return 'Generated';
      case 'processing': return 'Processing';
      case 'pending':    return 'Pending';
      case 'failed':     return 'Failed';
      default:           return status;
    }
  }
}

// Type Badge
class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Status Dot
class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'done'   => AppColors.success,
      'failed' => AppColors.error,
      _        => AppColors.warning,
    };
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}