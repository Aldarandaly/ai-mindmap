import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../data/diagram_repository.dart';
import 'diagram_viewer_screen.dart';

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
  bool _isGenerating = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _generatingProgress = 0.0;
  int _descriptionLength = 0;
  static const int _maxDescriptionLength = 1000;

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

    _descriptionController.addListener(() {
      setState(() => _descriptionLength = _descriptionController.text.length);
    });
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
    if (_currentPage == 1) {
      _goToPage(0);
    } else {
      Navigator.of(context).pop();
    }
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

  // ─── Generate ─────────────────────────────────────────────────────────────

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
      _generatingProgress = 0.0;
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

  // ─── Build ────────────────────────────────────────────────────────────────

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

  // ─── AppBar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
          const SizedBox(width: AppSizes.md),
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

  // ─── Step Indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
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

  // ─── Page 1: Type Selector ────────────────────────────────────────────────

  Widget _buildPage1TypeSelector() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            itemCount: _diagramTypes.length,
            itemBuilder: (context, index) {
              final item = _diagramTypes[index];
              final isSelected = _selectedType == item['type'];
              return _buildTypeCard(item, isSelected);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedType = item['type']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected
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
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['label'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item['desc'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
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

  // ─── Page 2: Describe Form ────────────────────────────────────────────────

  Widget _buildPage2DescribeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideBox(),
          const SizedBox(height: AppSizes.lg),

          _buildLabel('Diagram Name'),
          const SizedBox(height: AppSizes.sm),
          _buildNameField(),
          const SizedBox(height: AppSizes.lg),

          _buildLabel('Description'),
          const SizedBox(height: AppSizes.sm),
          _buildDescriptionField(),
          const SizedBox(height: AppSizes.xl),

          _buildGradientButton(
            label: 'Generate Diagram',
            leadingSymbol: '✦',
            onTap: _generate,
          ),
          const SizedBox(height: AppSizes.xl),
        ],
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

  Widget _buildGuideBox() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
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
          const SizedBox(width: AppSizes.sm),
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
        contentPadding: const EdgeInsets.symmetric(
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
            contentPadding: const EdgeInsets.all(AppSizes.md),
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

  // ─── Shared Gradient Button ───────────────────────────────────────────────

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
              const SizedBox(width: AppSizes.sm),
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
              const SizedBox(width: AppSizes.sm),
              Icon(trailingIcon, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Generating State ─────────────────────────────────────────────────────

  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
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
            const SizedBox(height: AppSizes.xl),
            Text(
              'Generating your diagram...',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'This may take a few seconds',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
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
                  const SizedBox(height: AppSizes.sm),
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

  // ─── Error Banner ─────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return SlideTransition(
      position: _errorSlideAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.md),
        padding: const EdgeInsets.all(AppSizes.md),
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
            const SizedBox(width: AppSizes.sm),
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
