import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/network_background.dart';
import '../../projects/data/projects_model.dart';
import '../data/diagram_model.dart';
import '../data/diagram_repository.dart';
import 'create_diagram_screen.dart';
import 'diagram_viewer_screen.dart';
import '../../chat/ui/chat_screen.dart';

// ── Gradient pairs per type ───────────────────────────────────────────────────
const _typeGradients = {
  'erd':     [Color(0xFF00D4FF), Color(0xFF6C63FF)],
  'class':   [Color(0xFF10B981), Color(0xFF00D4FF)],
  'mindmap': [Color(0xFF9B59B6), Color(0xFF6C63FF)],
  'default': [Color(0xFF6C63FF), Color(0xFF9B59B6)],
};

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});
  final ProjectModel project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
class _ProjectDetailScreenState
    extends State<ProjectDetailScreen> {
  final _repo = DiagramRepository();
  List<Diagram> _diagrams = [];
  List<Diagram> _filtered = [];

  bool _isLoading = true;
  String? _error;

  String _selectedType = 'all';

  final _types = [
    'all',
    'erd',
    'class',
    'mindmap',
    'usecase',
    'activity',
    'sequence',
    'context',
    'state',
    'dfd',
    'gantt',
  ];

  // ← FAB animation
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
    );
    _loadDiagrams();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDiagrams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _repo.getDiagrams(widget.project.id);

    final result =
        await _repo.getDiagrams(widget.project.id);

    if (result['success']) {
      setState(() {
        _diagrams =
            List<Diagram>.from(result['data']);

        _filterDiagrams();

        _isLoading = false;
      });
      // ← FAB animates in after load
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _fabCtrl.forward();
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  void _filterDiagrams() {
    setState(() {
      _filtered = _selectedType == 'all'
          ? _diagrams
          : _diagrams
              .where(
                (d) => d.type == _selectedType,
              )
              .toList();
    });
  }

  void _goToCreateDiagram() async {
    final result = await Navigator.push<Diagram>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDiagramScreen(projectId: widget.project.id),
        builder: (_) => CreateDiagramScreen(
          project: widget.project,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _diagrams.insert(0, result);
        _filterDiagrams();
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DiagramViewerScreen(diagram: result),
          ),
        );
      }
    }
  }

  List<Color> _typeGradient(String type) =>
      _typeGradients[type] ?? _typeGradients['default']!;

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

  String _typeLabel(String type) {
    switch (type) {
      case 'erd':
        return 'ERD';
      case 'class':
        return 'Class';
      case 'mindmap':
        return 'Mind Map';
      default:
        return type.toUpperCase();
    }
  // OPEN AI CHAT
  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        0,
      ),
      child: Row(
        children: [
          // ← glass back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: AppSizes.iconSm,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontXl,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_diagrams.length} diagram${_diagrams.length == 1 ? '' : 's'}'
                  '${widget.project.updatedAtLabel.isNotEmpty ? ' · ${widget.project.updatedAtLabel}' : ''}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppSizes.fontXs + 1,
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                0,
              ),

              child: Row(
                children: [

                  // BACK BUTTON
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),

                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: AppSizes.iconSm,
                      color: AppColors.textPrimary,
                    ),

                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(
                    width: AppSizes.sm,
                  ),

                  // PROJECT INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          widget.project.name,

                          style: AppTextStyles.h3,

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,
                        ),

                        Text(
                          '${_diagrams.length} diagram${_diagrams.length == 1 ? '' : 's'}'
                          ' · ${widget.project.updatedAtLabel}',

                          style:
                              AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding),
        itemCount: _types.length,
        itemBuilder: (_, i) {
          final type = _types[i];
          final isSelected = _selectedType == type;
          final label = type == 'all'
              ? 'All'
              : type == 'mindmap'
                  ? 'Mind Map'
                  : type.toUpperCase();
          final colors = _typeGradient(type);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _selectedType = type;
              _filterDiagrams();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: AppSizes.sm),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: colors)
                    : null,
                color: isSelected
                    ? null
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusRound),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors[0].withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textTertiary,
                ),
              ),
            ),
          );
        },
            const SizedBox(
              height: AppSizes.md,
            ),

            // FILTER CHIPS
            SizedBox(
              height: 36,

              child: ListView(
                scrollDirection: Axis.horizontal,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      AppSizes.screenPadding,
                ),

                children: _types.map((type) {
                  final isSelected =
                      _selectedType == type;

                  final label = type == 'all'
                      ? 'All'
                      : type == 'mindmap'
                          ? 'Mind Map'
                          : type.toUpperCase();

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),

                    child: GestureDetector(
                      onTap: () =>
                          _onTypeSelected(type),

                      child: AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 200,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,

                          borderRadius:
                              BorderRadius.circular(
                            AppSizes.radiusRound,
                          ),

                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),

                        child: Text(
                          label,

                          style: TextStyle(
                            fontSize:
                                AppSizes.fontSm,

                            fontWeight:
                                FontWeight.w500,

                            color: isSelected
                                ? Colors.white
                                : AppColors
                                    .textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(
              height: AppSizes.md,
            ),

            // BODY
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _filtered.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabScale,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _goToCreateDiagram();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'New diagram',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding),
      itemCount: 4,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
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
      // FLOATING BUTTONS
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.end,

        children: [

          // AI CHAT BUTTON
          FloatingActionButton.extended(
            heroTag: "chat",

            backgroundColor:
                Colors.deepPurple,

            onPressed: _openChat,

            icon: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
            ),

            label: const Text(
              "AI Chat",

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // NEW DIAGRAM BUTTON
          FloatingActionButton.extended(
            heroTag: "diagram",

            onPressed: _goToCreateDiagram,

            backgroundColor:
                AppColors.primary,

            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),

            label: const Text(
              'New Diagram',

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOADING
  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
      ),

      itemCount: 3,

      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),

        height: 80,

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(
            AppSizes.cardRadius,
          ),
        ),
      ),
    );
  }

  // ERROR
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

          const SizedBox(
            height: AppSizes.md,
          ),

          Text(
            _error!,
            style: AppTextStyles.bodyMedium,
          ),

          const SizedBox(
            height: AppSizes.md,
          ),

          TextButton(
            onPressed: _loadDiagrams,

            child: const Text(
              'Try again',

              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontMd,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            GestureDetector(
              onTap: _loadDiagrams,
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
                      color: AppColors.primary.withValues(alpha: 0.4),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────
  // EMPTY
  Widget _buildEmpty() {
    return Center(
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
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: AppColors.primary,
            ),

        children: const [
          Icon(
            Icons.auto_awesome_rounded,
            size: 60,
            color: AppColors.textTertiary,
          ),

          SizedBox(
            height: AppSizes.lg,
          ),

          Text(
            'No diagrams yet',

            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(
            height: AppSizes.xs,
          ),

          Text(
            'Generate your first diagram',

            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontMd,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          GestureDetector(
            onTap: _goToCreateDiagram,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusRound),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                '+ New diagram',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  // LIST
  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadDiagrams,

      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,

      child: ListView.builder(
        padding: EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),

        itemCount: _filtered.length,
        itemBuilder: (_, i) => _DiagramCard(
          diagram: _filtered[i],
          index: i,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DiagramViewerScreen(diagram: _filtered[i]),
            ),
          ),
          gradientColors: _typeGradient(_filtered[i].type),
          typeIcon: _typeIcon(_filtered[i].type),
          typeLabel: _typeLabel(_filtered[i].type),
        ),
      ),
    );
  }
}

// ── Diagram Card ──────────────────────────────────────────────────────────────
class _DiagramCard extends StatefulWidget {
  final Diagram diagram;
  final int index;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final IconData typeIcon;
  final String typeLabel;

  const _DiagramCard({
    required this.diagram,
    required this.index,
    required this.onTap,
    required this.gradientColors,
    required this.typeIcon,
    required this.typeLabel,
  });

  @override
  State<_DiagramCard> createState() => _DiagramCardState();
}

class _DiagramCardState extends State<_DiagramCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(
      Duration(milliseconds: widget.index * 60),
      () { if (mounted) _ctrl.forward(); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diagram;
    final c1 = widget.gradientColors[0];
    final c2 = widget.gradientColors[1];

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusXl),
              splashColor: c1.withValues(alpha: 0.08),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(
                      AppSizes.radiusXl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    // ← gradient icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c1, c2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: c1.withValues(alpha: 0.40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.typeIcon,
                        color: Colors.white,
                        size: AppSizes.iconMd,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm + 4),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name.isNotEmpty ? d.name : 'Untitled',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppSizes.fontMd + 1,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                d.createdAtLabel,
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ← gradient type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                              c1.withValues(alpha: 0.25),
                              c2.withValues(alpha: 0.25),
                            ]),
                        borderRadius: BorderRadius.circular(
                            AppSizes.radiusRound),
                        border: Border.all(
                          color: c1.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        widget.typeLabel,
                        style: TextStyle(
                          color: c1,
                          fontSize: AppSizes.fontXs + 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

        itemBuilder: (_, i) => DiagramCard(
          diagram: _filtered[i],

          onTap: () {
            Navigator.push(
              context,

              MaterialPageRoute(
                builder: (_) =>
                    DiagramViewerScreen(
                  diagram: _filtered[i],
                ),
              ),
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(AppSizes.radiusXl),
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