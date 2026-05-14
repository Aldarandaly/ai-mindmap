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

  ];

  @override
  void initState() {
    super.initState();

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


    }
    _goToPage(1);
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


  }
}


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


            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── Page 2: Describe Form ────────────────────────────────────────────────


                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

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

                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

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

                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            Text(
              'Generating your diagram...',
              style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.sm),

            ),
          ],
        ),
      ),
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {

      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [

