import 'dart:async';
import 'package:flutter/material.dart';
import '../../diagrams/data/diagram_model.dart';
import '../data/diagram_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../payment/ui/plans_screen.dart';
import '../../../core/network/api_client.dart';
import '../../diagrams/ui/diagram_viewer_screen.dart';

class _DiagramType {
  final String key;
  final String label;
  final IconData icon;
  final String description;

  const _DiagramType({
    required this.key,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class CreateDiagramScreen extends StatefulWidget {
  final int projectId;
  const CreateDiagramScreen({super.key, required this.projectId});

  @override
  State<CreateDiagramScreen> createState() => _CreateDiagramScreenState();
}

class _CreateDiagramScreenState extends State<CreateDiagramScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedType;
  String _userPlan = 'free';
  bool _isGenerating = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _descriptionLength = 0;
  static const int _maxDescriptionLength = 1000;

  final List<String> _freeDiagramTypes = ['erd', 'class', 'mindmap'];

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _errorSlideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _errorSlideAnimation;

  final _repo = DiagramRepository();

  final List<Map<String, dynamic>> _diagramTypes = [
    {
      'type': 'erd',
      'label': 'ERD',
      'desc': 'Entity Relationship Diagram',
      'icon': Icons.storage_rounded,
    },
    {
      'type': 'class',
      'label': 'Class',
      'desc': 'Class Diagram',
      'icon': Icons.code_rounded,
    },
    {
      'type': 'mindmap',
      'label': 'Mind Map',
      'desc': 'Mind Map Diagram',
      'icon': Icons.hub_rounded,
    },
    {
      'type': 'usecase',
      'label': 'Use Case',
      'desc': 'Use Case Diagram',
      'icon': Icons.person_rounded,
    },
    {
      'type': 'sequence',
      'label': 'Sequence',
      'desc': 'Sequence Diagram',
      'icon': Icons.swap_horiz_rounded,
    },
    {
      'type': 'activity',
      'label': 'Activity',
      'desc': 'Activity Diagram',
      'icon': Icons.alt_route_rounded,
    },
    {
      'type': 'context',
      'label': 'Context',
      'desc': 'Context Diagram',
      'icon': Icons.language_rounded,
    },
    {
      'type': 'state',
      'label': 'State',
      'desc': 'State Diagram',
      'icon': Icons.timeline_rounded,
    },
    {
      'type': 'dfd',
      'label': 'DFD',
      'desc': 'Data Flow Diagram',
      'icon': Icons.account_tree_rounded,
    },
    {
      'type': 'gantt',
      'label': 'Gantt',
      'desc': 'Gantt Chart',
      'icon': Icons.bar_chart_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _errorSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _errorSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _errorSlideController, curve: Curves.easeOut),
        );

    _descriptionController.addListener(
      () => setState(
        () => _descriptionLength = _descriptionController.text.length,
      ),
    );

    // ← load plan هنا برضو عشان أول مرة
    _loadUserPlan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ← بيتعمل كل مرة الـ screen يظهر تاني
    _loadUserPlan();
  }

  Future<void> _loadUserPlan() async {
    try {
      final response = await ApiClient().get('/plan/current');
      if (mounted) setState(() => _userPlan = response['plan'] ?? 'free');
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _errorSlideController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onBack() {
    if (_currentPage == 1)
      _goToPage(0);
    else
      Navigator.of(context).pop();
  }

  void _onNext() {
    if (_selectedType == null) {
      _showSnack('Please select a diagram type');
      return;
    }
    _goToPage(1);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Pro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This diagram type is only available on Pro and Enterprise plans.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlansScreen()),
                  );
                  _loadUserPlan(); // ← reload بعد ما يرجع
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: const Text(
                  'View Plans',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Maybe later',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter a diagram name');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnack('Please describe what you want to generate');
      return;
    }

    setState(() {
      _isGenerating = true;
      _hasError = false;
    });
    _progressController.forward(from: 0);

    try {
      final diagram = await _repo.generateDiagram(
        projectId: widget.projectId,
        name: _nameController.text.trim(),
        type: _selectedType!,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiagramViewerScreen(diagram: diagram),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _errorSlideController.forward(from: 0);
      _progressController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildStepIndicator(),
                Expanded(
                  child: _isGenerating
                      ? _buildGeneratingState()
                      : PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          children: [
                            _buildPage1TypeSelector(),
                            _buildPage2DescribeForm(),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (_hasError)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildErrorBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Align(
                key: ValueKey(_currentPage),
                alignment: Alignment.centerLeft,
                child: Text(
                  _currentPage == 0 ? 'Choose Type' : 'Describe Diagram',
                  style: AppTextStyles.headingMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        0,
        AppSizes.screenPadding,
        AppSizes.md,
      ),
      child: Row(
        children: [
          _buildStep(1, 'Type', true),
          _buildStepConnector(_currentPage >= 1),
          _buildStep(2, 'Describe', _currentPage >= 1),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.20),
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  Widget _buildPage1TypeSelector() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            itemCount: _diagramTypes.length,
            itemBuilder: (context, index) {
              final item = _diagramTypes[index];
              final isSelected = _selectedType == item['type'];
              return _buildTypeCard(item, isSelected);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(AppSizes.screenPadding),
          child: _buildGradientButton(
            label: 'Continue',
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: _onNext,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> item, bool isSelected) {
    final isFree = _userPlan == 'free';
    final isLocked = isFree && !_freeDiagramTypes.contains(item['type']);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showUpgradeDialog();
          return;
        }
        setState(() => _selectedType = item['type']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.white.withValues(alpha: 0.02)
              : isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isLocked
                ? Colors.white.withValues(alpha: 0.05)
                : isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.white.withValues(alpha: 0.04)
                    : isSelected
                    ? AppColors.primary.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: isLocked
                    ? AppColors.textTertiary.withValues(alpha: 0.4)
                    : isSelected
                    ? AppColors.primary
                    : AppColors.textTertiary,
                size: 22,
              ),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['label'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isLocked
                              ? AppColors.textTertiary.withValues(alpha: 0.4)
                              : isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFB800,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFFFFB800,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFFFB800),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    item['desc'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: isLocked
                          ? AppColors.textTertiary.withValues(alpha: 0.3)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: AppColors.textTertiary.withValues(alpha: 0.4),
              )
            else if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2DescribeForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideBox(),
          SizedBox(height: AppSizes.md),
          _buildExampleBox(),
          SizedBox(height: AppSizes.lg),
          _buildLabel('Diagram Name'),
          SizedBox(height: AppSizes.sm),
          _buildNameField(),
          SizedBox(height: AppSizes.lg),
          _buildLabel('Description'),
          SizedBox(height: AppSizes.sm),
          _buildDescriptionField(),
          SizedBox(height: AppSizes.xl),
          _buildGradientButton(
            label: 'Generate Diagram',
            leadingSymbol: '✦',
            onTap: _generate,
          ),
          SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Widget _buildGuideBox() {
    return Container(
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Be specific! The more detail you provide, the better the generated diagram.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleBox() {
    final examples = {
      'erd': (
        title: 'ERD Example',
        icon: Icons.storage_rounded,
        color: Color(0xFF0D9488),
        hints: [
          'List your main tables/entities',
          'Mention attributes & data types',
          'Describe relationships (one-to-many)',
          'Specify primary & foreign keys',
        ],
        example:
            'I have a school system with Teachers, Students, and Classes. Each teacher teaches multiple classes. Each student enrolls in many classes. Teachers have: id, name, email, subject.',
      ),
      'class': (
        title: 'Class Diagram Example',
        icon: Icons.code_rounded,
        color: Color(0xFF7C3AED),
        hints: [
          'List your main classes',
          'Mention attributes & methods',
          'Describe inheritance & associations',
          'Specify access modifiers',
        ],
        example:
            'E-commerce app with User, Product, Order, Payment classes. User can place multiple orders. Order contains multiple products. Payment belongs to one order.',
      ),
      'mindmap': (
        title: 'Mind Map Example',
        icon: Icons.hub_rounded,
        color: Color(0xFFDB2777),
        hints: [
          'Start with the main topic',
          'List main branches/categories',
          'Add sub-topics under each branch',
          'Keep it short — keywords only',
        ],
        example:
            'Software Engineering main topics: Design Patterns, Testing, Deployment, Databases, Security, and DevOps.',
      ),
      'usecase': (
        title: 'Use Case Example',
        icon: Icons.person_rounded,
        color: Color(0xFF0891B2),
        hints: [
          'List all actors (users/systems)',
          'Describe main use cases/features',
          'Mention actor-use case relationships',
          'Include include/extend relationships',
        ],
        example:
            'Library system: Librarian can add books, manage members. Member can search books, borrow and return books. System sends overdue notifications.',
      ),
      'sequence': (
        title: 'Sequence Diagram Example',
        icon: Icons.swap_horiz_rounded,
        color: Color(0xFF059669),
        hints: [
          'List all participants/systems',
          'Describe message sequence',
          'Mention sync/async calls',
          'Include responses & conditions',
        ],
        example:
            'User login flow: User sends credentials to Frontend, Frontend calls AuthService, AuthService checks Database, Database returns user, AuthService generates JWT, Frontend redirects user.',
      ),
      'activity': (
        title: 'Activity Diagram Example',
        icon: Icons.alt_route_rounded,
        color: Color(0xFFD97706),
        hints: [
          'Describe the process step by step',
          'Mention decision points (if/else)',
          'Include start and end points',
          'Describe any parallel activities',
        ],
        example:
            'Online order process: Customer browses products, adds to cart, proceeds to checkout. If logged in, shows payment. If not, prompt login first. After payment, confirm order and send email.',
      ),
      'context': (
        title: 'Context Diagram Example',
        icon: Icons.language_rounded,
        color: Color(0xFF6C63FF),
        hints: [
          'Describe the main system',
          'List all external entities',
          'Describe data flows in/out',
          'Mention external services used',
        ],
        example:
            'Hospital management system interacts with: Patients (register, book appointments), Doctors (view schedules, update records), Lab (send test requests, receive results), Insurance (billing).',
      ),
      'state': (
        title: 'State Diagram Example',
        icon: Icons.timeline_rounded,
        color: Color(0xFFEA580C),
        hints: [
          'List all possible states',
          'Describe transitions between states',
          'Mention triggers for each transition',
          'Include initial and final states',
        ],
        example:
            'Order lifecycle: Created → Confirmed (payment received) → Processing → Shipped → Delivered. Can also go to Cancelled from Created or Confirmed. Failed payment goes back to Created.',
      ),
      'dfd': (
        title: 'DFD Example',
        icon: Icons.account_tree_rounded,
        color: Color(0xFF16A34A),
        hints: [
          'List external entities (sources/sinks)',
          'Describe all processes',
          'Mention data stores (databases)',
          'Describe data flows between them',
        ],
        example:
            'Student submits assignment to the system. System validates and stores in Assignment DB. Teacher retrieves assignments, grades them, stores grades in Grade DB. System notifies student.',
      ),
      'gantt': (
        title: 'Gantt Chart Example',
        icon: Icons.bar_chart_rounded,
        color: Color(0xFFC026D3),
        hints: [
          'List all project phases/sections',
          'Describe tasks within each phase',
          'Mention task durations',
          'Describe task dependencies',
        ],
        example:
            'Mobile app project: Planning (2 weeks) → Design (3 weeks) → Backend development (6 weeks, starts after design) → Frontend development (6 weeks, parallel with backend) → Testing (2 weeks) → Launch.',
      ),
    };

    final data = examples[_selectedType];
    if (data == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedType),
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: data.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: data.color, size: 16),
                ),
                SizedBox(width: AppSizes.sm),
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w700,
                    color: data.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.sm),
            ...data.hints.map(
              (hint) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: data.color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSizes.sm),
            const Divider(color: AppColors.border),
            SizedBox(height: AppSizes.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example prompt:',
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () {
                          _descriptionController.text = data.example;
                          setState(
                            () => _descriptionLength = data.example.length,
                          );
                        },
                        child: Text(
                          data.example,
                          style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          _descriptionController.text = data.example;
                          setState(
                            () => _descriptionLength = data.example.length,
                          );
                        },
                        child: Text(
                          'Tap to use this example →',
                          style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: data.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'e.g. E-Commerce ERD',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        fillColor: Colors.white.withValues(alpha: 0.08),
        filled: true,
        prefixIcon: Icon(
          Icons.drive_file_rename_outline_rounded,
          color: AppColors.textTertiary,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          maxLength: _maxDescriptionLength,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Describe the diagram you want to generate in detail...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            fillColor: Colors.white.withValues(alpha: 0.08),
            filled: true,
            counterText: '',
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            contentPadding: EdgeInsets.all(AppSizes.md),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$_descriptionLength/$_maxDescriptionLength',
          style: AppTextStyles.caption.copyWith(
            color: _descriptionLength > (_maxDescriptionLength * 0.9)
                ? AppColors.warning
                : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
    String? leadingSymbol,
    IconData? trailingIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingSymbol != null) ...[
              Text(
                leadingSymbol,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(width: AppSizes.sm),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: AppSizes.sm),
              Icon(trailingIcon, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            SizedBox(height: AppSizes.xl),
            Text(
              'Generating your diagram...',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            Text(
              'This may take a few seconds',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSizes.xl),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (_, __) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return SlideTransition(
      position: _errorSlideAnimation,
      child: Container(
        margin: EdgeInsets.all(AppSizes.md),
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                _errorMessage,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _hasError = false),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
