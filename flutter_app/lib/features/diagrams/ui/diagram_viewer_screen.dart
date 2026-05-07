import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/diagram_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';

class DiagramViewerScreen extends StatefulWidget {
  final Diagram diagram;

  const DiagramViewerScreen({super.key, required this.diagram});

  @override
  State<DiagramViewerScreen> createState() => _DiagramViewerScreenState();
}

class _DiagramViewerScreenState extends State<DiagramViewerScreen> {
  bool _showCode = false;

  void _copyCode() {
    final code = widget.diagram.diagramCode ?? '';
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.diagram.name.isNotEmpty ? widget.diagram.name : 'Untitled',
            style: AppTextStyles.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _typeLabel(widget.diagram.type),
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          color: AppColors.textSecondary,
          tooltip: 'Copy code',
          onPressed: widget.diagram.diagramCode != null ? _copyCode : null,
        ),
        IconButton(
          icon: Icon(
            _showCode ? Icons.visibility_rounded : Icons.code_rounded,
            size: 20,
          ),
          color: AppColors.textSecondary,
          tooltip: _showCode ? 'Hide code' : 'Show code',
          onPressed: () => setState(() => _showCode = !_showCode),
        ),
        const SizedBox(width: AppSizes.xs),
      ],
    );
  }

  Widget _buildBody() {
    if (widget.diagram.diagramCode == null || widget.diagram.diagramCode!.isEmpty) {
      return _buildNoCode();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Banner ──
          _buildStatusBanner(),
          const SizedBox(height: AppSizes.md),

          // ── Toggle ──
          Row(
            children: [
              _buildToggleChip('Preview', !_showCode),
              const SizedBox(width: AppSizes.sm),
              _buildToggleChip('Code', _showCode),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ── Content ──
          _showCode ? _buildCodeView() : _buildPreviewInfo(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isDone = widget.diagram.isDone;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            size: 16,
            color: isDone ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            isDone ? 'Diagram generated successfully' : 'Status: ${widget.diagram.status}',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: isDone ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Diagram Ready',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'WebView preview is available on mobile devices.\nTap "Code" to view the Mermaid code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showCode = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            icon: const Icon(Icons.code_rounded, size: 18),
            label: const Text('View Mermaid Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mermaid Code',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: _copyCode,
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSizes.sm),
          SelectableText(
            widget.diagram.diagramCode ?? '',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCode() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 36,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text('No diagram yet', style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'The diagram is still being generated.',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showCode = label == 'Code'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'class': return 'Class Diagram';
      case 'erd': return 'Entity Relationship Diagram';
      case 'mindmap': return 'Mind Map';
      case 'auto': return 'Auto Generated';
      default: return type;
    }
  }
}