import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../diagrams/data/diagram_model.dart';
import '../../diagrams/data/diagram_repository.dart';
import '../../diagrams/ui/diagram_viewer_screen.dart';
import '../../diagrams/ui/widgets/diagram_card.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = DiagramRepository();
  List<Diagram> _diagrams = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
    if (result['success']) {
      setState(() {
        _diagrams = List<Diagram>.from(result['data']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last generated diagrams',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: AppSizes.fontSm,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding),
      itemCount: 5,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return RefreshIndicator(
      onRefresh: _loadRecent,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusXl),
                      ),
                      child: const Icon(Icons.wifi_off_rounded,
                          size: 34, color: AppColors.error),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontMd),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    GestureDetector(
                      onTap: _loadRecent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Try again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontMd,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _loadRecent,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusXl),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.history_rounded,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const Text(
                    'No recent diagrams',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  const Text(
                    'Generated diagrams will appear here',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadRecent,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        itemCount: _diagrams.length,
        itemBuilder: (_, i) => DiagramCard(
          diagram: _diagrams[i],
          index: i,
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

// ── Shimmer Card ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3.5, 0),
            end: Alignment(-0.5 + _ctrl.value * 3.5, 0),
            colors: [
              AppColors.shimmerBase,
              AppColors.shimmerHighlight,
              AppColors.shimmerBase,
            ],
          ),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
    );
  }
}