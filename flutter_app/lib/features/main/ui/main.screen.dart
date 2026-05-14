import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../projects/ui/projects_screen.dart';
import '../../recent/ui/recent.screen.dart';
import '../../settings/ui/setting.screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  VoidCallback? _showCreateModal;

  // ── Tab animation controllers ──────────────────────────────────────────────
  late final List<AnimationController> _tabControllers;
  late final List<Animation<double>> _tabAnimations;

  // ── FAB animation ──────────────────────────────────────────────────────────
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  late final Animation<double> _fabRotate;

  static const _navItems = [
    (icon: Icons.folder_rounded, label: 'Projects'),
    (icon: Icons.history_rounded, label: 'Recent'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();

    // Tab controllers
    _tabControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );
    _tabAnimations = _tabControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();
    _tabControllers[0].forward(); // initial selected tab

    // FAB
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _fabRotate = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _fabController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward();
    });
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _tabControllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _tabControllers[index].forward();
  }

  @override
  void dispose() {
    for (final c in _tabControllers) {
      c.dispose();
    }
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // content goes under nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ProjectsBody(
            onRegisterShowModal: (fn) => _showCreateModal = fn,
          ),
          const RecentScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (_, __) => Transform.scale(
        scale: _fabScale.value,
        child: Transform.rotate(
          angle: _fabRotate.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showCreateModal?.call();
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 68 + bottomPad,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left tabs (0, 1)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0, 1].map(_buildNavTab).toList(),
              ),
            ),
            // FAB spacer
            const SizedBox(width: 70),
            // Right tab (2)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [2].map(_buildNavTab).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _tabAnimations[index],
        builder: (_, __) {
          final t = _tabAnimations[index].value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.12),
                t,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient when selected
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isSelected
                        ? [AppColors.primary, AppColors.accent]
                        : [
                            AppColors.textTertiary.withValues(alpha: 0.5),
                            AppColors.textTertiary.withValues(alpha: 0.5),
                          ],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textTertiary.withValues(alpha: 0.5),
                    fontSize: AppSizes.fontXs,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}