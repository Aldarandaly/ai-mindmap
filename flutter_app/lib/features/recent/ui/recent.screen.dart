import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../diagrams/data/diagram_model.dart';
import '../../diagrams/data/diagram_repository.dart';
import '../../diagrams/ui/diagram_viewer_screen.dart';
import '../../diagrams/ui/widgets/diagram_card.dart';
import 'dart:developer';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  final _repo = DiagramRepository();
  List<Diagram> _diagrams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repo.getRecentDiagrams();
    debugger(); 

    if (result['success']) {
      setState(() {
        _diagrams = List<Diagram>.from(result['data']);
        _isLoading = false;
      });
    } else {
      debugger(); 
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.lg,
                AppSizes.screenPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: AppSizes.fontXxl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Last generated diagrams',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                  ? _buildError()
                  : _diagrams.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.md),
          Text(_error!, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: _loadRecent,
            child: const Text(
              'Try again',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
              Icons.history_rounded,
              size: 36,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'No recent diagrams',
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'Generated diagrams will appear here',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadRecent,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding,
          vertical: AppSizes.sm,
        ),
        itemCount: _diagrams.length,
        itemBuilder: (_, i) => DiagramCard(
          diagram: _diagrams[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DiagramViewerScreen(diagram: _diagrams[i]),
            ),
          ),
        ),
      ),
    );
  }
}
