import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/state/user_notifier.dart';
import '../../projects/ui/projects_screen.dart';
import '../../recent/ui/recent_screen.dart';
import '../../settings/ui/setting.screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  VoidCallback? _showCreateModal;

  final _apiClient = ApiClient();

  late final List<AnimationController> _tabControllers;
  late final List<Animation<double>> _tabAnimations;

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

    _initUser();

    _tabControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
      ),
    );

    _tabAnimations = _tabControllers
        .map((c) => CurvedAnimation(
              parent: c,
              curve: Curves.easeOutCubic,
            ))
        .toList();

    _tabControllers[0].forward();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fabScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fabRotate = Tween<double>(begin: -0.15, end: 0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fabController.forward();
    });
  }

  // ───────────────────────── LOAD USER
  Future<void> _initUser() async {
  try {
    final user = await _apiClient.get('/user');

    if (user != null) {
      UserNotifier.userName.value = user['name'] ?? '';
    }
  } catch (_) {}
}

  @override
  void dispose() {
    for (final c in _tabControllers) {
      c.dispose();
    }
    _fabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.selectionClick();

    _tabControllers[_currentIndex].reverse();

    setState(() {
      _currentIndex = index;
    });

    _tabControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProjectsBody(
        onRegisterShowModal: (cb) {
          _showCreateModal = cb;
        },
      ),
      const RecentScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,

      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // ───────── FAB
      floatingActionButton: _currentIndex == 0
          ? ScaleTransition(
              scale: _fabScale,
              child: RotationTransition(
                turns: _fabRotate,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showCreateModal?.call();
                  },
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7C6FFF),
                          Color(0xFF9B59B6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            )
          : null,

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────── BOTTOM NAV
  Widget _buildBottomNav() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A).withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          _navItems.length,
          (i) => Expanded(child: _buildNavTab(i)),
        ),
      ),
    );
  }

  // ───────── NAV TAB
  Widget _buildNavTab(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF8B7FFF)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF8B7FFF)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}