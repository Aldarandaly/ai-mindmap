import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/network_background.dart';
import '../../diagrams/ui/project_detail_screen.dart';
import '../data/project_repository.dart';
import '../data/projects_model.dart';
import 'widgets/create_project_modal.dart';

String _initials = '';
final _apiClient = ApiClient();

// ── Gradient pairs for project cards ─────────────────────────────────────────
const _gradients = [
  [Color(0xFF6C63FF), Color(0xFF9B59B6)],
  [Color(0xFF00D4FF), Color(0xFF6C63FF)],
  [Color(0xFF9B59B6), Color(0xFF00D4FF)],
  [Color(0xFF6C63FF), Color(0xFF00D4FF)],
  [Color(0xFF00D4FF), Color(0xFF9B59B6)],
];

class ProjectsBody extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterShowModal;
  const ProjectsBody({super.key, this.onRegisterShowModal});

  @override
  State<ProjectsBody> createState() => _ProjectsBodyState();
}

class _ProjectsBodyState extends State<ProjectsBody>
    with AutomaticKeepAliveClientMixin {
  final _repo = ProjectRepository();
  final _searchController = TextEditingController();
  List<Project> _projects = [];
  List<Project> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onRegisterShowModal?.call(_showCreateModal);
    _init();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadProjects();
    await _loadInitials();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _projects
          : _projects
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  (p.description ?? '').toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _repo.getProjects();
    if (result['success']) {
      setState(() {
        _projects = List<Project>.from(result['data']);
        _filtered = _projects;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitials() async {
    final name = await _apiClient.getUserName();
    if (name != null && name.isNotEmpty) {
      setState(() => _initials = name[0].toUpperCase());
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          top: AppSizes.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
        ),
        decoration: BoxDecoration(
          // ← glass dark surface
          color: const Color(0xFF0E1624),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: CreateProjectModal(
          onCreated: (project) {
            setState(() {
              _projects.insert(0, project);
              _filtered = _projects;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NetworkBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSizes.md),
            _buildSearchBar(),
            const SizedBox(height: AppSizes.sm),
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Projects',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : '${_projects.length} project${_projects.length == 1 ? '' : 's'}',
                    key: ValueKey(
                        _isLoading ? 'loading' : _projects.length),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials.isEmpty ? '?' : _initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding),
      child: Container(
        height: AppSizes.inputHeight,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontMd),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search projects...',
            hintStyle: AppTextStyles.hint,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm + 4,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textTertiary,
                        size: AppSizes.iconSm),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch();
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Shimmer loading ────────────────────────────────────────────────────────
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
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontMd,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _GradientButton(
              label: 'Try again',
              onTap: _loadProjects,
              colors: [AppColors.error, Colors.redAccent],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.folder_open_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'No projects yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'Create your first project to get started',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontMd,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          _GradientButton(
            label: '+ New Project',
            onTap: _showCreateModal,
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _ProjectCard(
          project: _filtered[i],
          index: i,
          gradientColors:
              _gradients[i % _gradients.length],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProjectDetailScreen(project: _filtered[i]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────
class _ProjectCard extends StatefulWidget {
  final Project project;
  final int index;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.index,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: 350 + widget.index * 60),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(
      Duration(milliseconds: widget.index * 55),
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
    final p = widget.project;
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
              splashColor:
                  AppColors.primary.withValues(alpha: 0.08),
              highlightColor:
                  AppColors.primary.withValues(alpha: 0.04),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color:
                      Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(
                      AppSizes.radiusXl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    // ── Folder icon ──────────────────────────
                    Container(
                      width: 50,
                      height: 50,
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
                      child: const Icon(
                        Icons.folder_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm + 4),

                    // ── Info ─────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppSizes.fontLg,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((p.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                p.description ?? '',
                                maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppSizes.fontSm,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                p.updatedAtLabel,
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
                    const SizedBox(width: AppSizes.sm),

                    // ── Diagrams badge ───────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c1, c2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusRound),
                      ),
                      child: Text(
                        '${p.diagramsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w700,
                        ),
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
      builder: (context, index) => Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(AppSizes.radiusXl),
          gradient: LinearGradient(
            begin:
                Alignment(-1.5 + _ctrl.value * 3.5, 0),
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

// ── Gradient Button ───────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.colors = const [AppColors.primary, AppColors.accent],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius:
              BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontMd,
          ),
        ),
      ),
    );
  }
}