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
  // Page controller
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State
  String? _selectedType;
  bool _isGenerating = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _generatingProgress = 0.0;
  int _descriptionLength = 0;
  static const int _maxDescriptionLength = 1000;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _errorSlideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _errorSlideAnimation;

  // Diagram types
  final List<Map<String, dynamic>> _diagramTypes = [
    {'type': 'erd',      'label': 'ERD',        'description': 'Entity Relationship',  'icon': Icons.account_tree_outlined},
    {'type': 'class',    'label': 'Class',       'description': 'Class Diagram',        'icon': Icons.class_outlined},
    {'type': 'mindmap',  'label': 'Mind Map',    'description': 'Mind Map Diagram',     'icon': Icons.hub_outlined},
    {'type': 'usecase',  'label': 'Use Case',    'description': 'Use Case Diagram',     'icon': Icons.person_outlined},
    {'type': 'activity', 'label': 'Activity',    'description': 'Activity Diagram',     'icon': Icons.directions_run_outlined},
    {'type': 'sequence', 'label': 'Sequence',    'description': 'Sequence Diagram',     'icon': Icons.swap_horiz_outlined},
    {'type': 'context',  'label': 'Context',     'description': 'Context Diagram',      'icon': Icons.crop_square_outlined},
    {'type': 'state',    'label': 'State',       'description': 'State Diagram',        'icon': Icons.toggle_on_outlined},
    {'type': 'dfd',      'label': 'DFD',         'description': 'Data Flow Diagram',    'icon': Icons.data_usage_outlined},
    {'type': 'gantt',    'label': 'Gantt Chart', 'description': 'Project Timeline',     'icon': Icons.bar_chart_outlined},
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    );
    _progressController.addListener(() {
      if (mounted) setState(() => _generatingProgress = _progressController.value);
    });

    _errorSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _errorSlideAnimation = CurvedAnimation(
      parent: _errorSlideController,
      curve: Curves.easeOut,
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

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
  }

  void _onNext() {
    if (_selectedType == null) {
      _showSnack('Please select a diagram type first');
      return;
    }
    _goToPage(1);
  }

  void _onBack() {
    if (_currentPage == 1) {
      _goToPage(0);
    } else {
      Navigator.pop(context);
    }
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
    // ← generateDiagram بدل createDiagram
    final diagram = await DiagramRepository().generateDiagram(
      projectId: widget.projectId,
      name: _nameController.text.trim(),
      type: _selectedType!,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    _progressController.stop();
    setState(() => _isGenerating = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DiagramViewerScreen(diagram: diagram),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    _progressController.stop();
    setState(() {
      _isGenerating = false;
      _hasError = true;
      _errorMessage = e.toString();
    });
    _errorSlideController.forward(from: 0);
  }
}

  void _dismissError() {
    _errorSlideController.reverse().then((_) {
      if (mounted) setState(() => _hasError = false);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                          onPageChanged: (i) => setState(() => _currentPage = i),
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
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
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
                ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
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
                ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: Text(
            'What kind of diagram do you need?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.sm,
              mainAxisSpacing: AppSizes.sm,
              childAspectRatio: 2.5,
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = item['type']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 17,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['label'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item['description'] as String,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── Page 2: Describe Form ────────────────────────────────────────────────

  Widget _buildPage2DescribeForm() {
    final selectedTypeData = _selectedType != null
        ? _diagramTypes.firstWhere((t) => t['type'] == _selectedType)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected type chip — tap to go back and change
          if (selectedTypeData != null) ...[
            GestureDetector(
              onTap: () => _goToPage(0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm + 2,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(selectedTypeData['icon'] as IconData,
                        color: AppColors.primaryLight, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      selectedTypeData['label'] as String,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_rounded,
                        color: AppColors.primaryLight.withValues(alpha: 0.6), size: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
          ],

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
        color: AppColors.textSecondary,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: AppSizes.sm),
              Text(
                'Tips for better results',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ...[
            'Be specific about entities, relationships, and attributes',
            'Mention the number of nodes or steps if relevant',
            'Include domain context (e.g. e-commerce, hospital system)',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Text(
              'Example: "An e-commerce system with Users, Products, Orders and Reviews. Users can place multiple orders and write reviews."',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
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
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        fillColor: Colors.white.withValues(alpha: 0.08),
        filled: true,
        prefixIcon: Icon(Icons.drive_file_rename_outline_rounded,
            color: AppColors.textTertiary, size: 20),
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
            horizontal: AppSizes.md, vertical: AppSizes.md),
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
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Describe the diagram you want to generate in detail...',
            hintStyle:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
            fillColor: Colors.white.withValues(alpha: 0.08),
            filled: true,
            counterText: '',
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
              Text(leadingSymbol,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
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
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        strokeWidth: 3,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              'Generating your diagram...',
              style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'This may take a few seconds',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSizes.xl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  child: LinearProgressIndicator(
                    value: _generatingProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_generatingProgress * 100).toInt()}%',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_errorSlideAnimation),
    child: Container(
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Failed to generate diagram. Please try again.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          // ── Retry button ──────────────────────
          GestureDetector(
            onTap: () {
              _dismissError();
              _generate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // ── Close button ──────────────────────
          GestureDetector(
            onTap: _dismissError,
            child: Icon(Icons.close_rounded,
                color: AppColors.error.withValues(alpha: 0.7), size: 18),
          ),
        ],
      ),
    ),
  );
}
}