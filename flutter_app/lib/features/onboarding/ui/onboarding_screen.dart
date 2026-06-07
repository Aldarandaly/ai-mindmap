import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/ui/login_screen.dart';
import '../../../shared/widgets/network_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Diagrams',
      subtitle: 'DiagramAI',
      description:
          'Transform your ideas into professional diagrams instantly using advanced AI. Just describe what you need in plain text.',
      gradient: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      features: ['ERD Diagrams', 'Class Diagrams', 'Mind Maps', 'And more...'],
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      title: 'Fast & Smart',
      subtitle: 'Generate in seconds',
      description:
          'No more manual drawing. Our AI understands your requirements and generates accurate diagrams in seconds.',
      gradient: [Color(0xFF0D9488), Color(0xFF0891B2)],
      features: [
        'Auto-detect diagram type',
        'Smart suggestions',
        'Multiple diagram types',
        'Export to PNG & PDF',
      ],
    ),
    _OnboardingPage(
      icon: Icons.folder_rounded,
      title: 'Organize & Export',
      subtitle: 'Your workspace',
      description:
          'Keep all your diagrams organized in projects. Export them in multiple formats and share with your team.',
      gradient: [Color(0xFFDB2777), Color(0xFF9333EA)],
      features: [
        'Project management',
        'Export PNG & PDF',
        'Share Mermaid code',
        'Unlimited projects',
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Pages ──
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),

          // ── Skip Button ──
          Positioned(
            top: 52,
            right: AppSizes.screenPadding,
            child: SafeArea(
              child: TextButton(
                onPressed: _goToLogin,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  0,
                  AppSizes.screenPadding,
                  AppSizes.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dots
                    Row(
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started Button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusRound,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.fontMd,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
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

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),

          // ── Icon ──
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: page.gradient[0].withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(page.icon, size: 56, color: Colors.white),
          ),

          SizedBox(height: AppSizes.xl),

          // ── Subtitle ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: page.gradient[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: page.gradient[0].withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              page.subtitle,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: page.gradient[0],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: AppSizes.md),

          // ── Title ──
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),

          SizedBox(height: AppSizes.md),

          // ── Description ──
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

          SizedBox(height: AppSizes.xl),

          // ── Features ──
          Container(
            padding: EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: page.features
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: page.gradient[0].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: page.gradient[0],
                            ),
                          ),
                          SizedBox(width: AppSizes.sm),
                          Text(
                            f,
                            style: TextStyle(
                              fontSize: AppSizes.fontSm,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final List<String> features;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.features,
  });
}
