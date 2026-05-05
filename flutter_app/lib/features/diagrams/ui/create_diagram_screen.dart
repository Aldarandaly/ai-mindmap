import 'dart:async';
import 'package:flutter/material.dart';
import '../../diagrams/data/diagram_model.dart';
import '../data/diagram_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../projects/ui/projects_model.dart';

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
// ─── Screen ───────────────────────────────────────────────────────────────────

class CreateDiagramScreen extends StatefulWidget {
  final ProjectModel project;

  const CreateDiagramScreen({super.key, required this.project});

  @override
  State<CreateDiagramScreen> createState() => _CreateDiagramScreenState();
}

class _CreateDiagramScreenState extends State<CreateDiagramScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'auto';
  bool _isGenerating = false;
  int _descLength = 0;
  String? _errorMessage;

  Timer? _pollingTimer;
  int? _pendingDiagramId;
  int _pollingCount = 0;
  static const int _maxPollingAttempts = 40;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _dotsController;
  late Animation<int> _dotsAnimation;

  final List<_DiagramType> _types = const [
    _DiagramType(
      key: 'auto',
      label: 'Auto',
      icon: Icons.auto_awesome_rounded,
      description: 'بيختار النوع الأنسب تلقائياً',
    ),
    _DiagramType(
      key: 'class',
      label: 'Class',
      icon: Icons.account_tree_rounded,
      description: 'Class Diagram للـ OOP',
    ),
    _DiagramType(
      key: 'erd',
      label: 'ERD',
      icon: Icons.table_chart_rounded,
      description: 'Entity Relationship Diagram',
    ),
    _DiagramType(
      key: 'mindmap',
      label: 'Mind Map',
      icon: Icons.hub_rounded,
      description: 'خريطة ذهنية للأفكار',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotsAnimation = IntTween(begin: 0, end: 3).animate(_dotsController);

    _descController.addListener(
      () => setState(() => _descLength = _descController.text.length),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _pollingCount = 0;
    });

    try {
      final diagram = await DiagramRepository().generateDiagram(
        projectId: widget.project.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
      );
      _pendingDiagramId = diagram.id;
      _startPolling();
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'فشل إرسال الطلب. تأكد من الاتصال وحاول تاني.';
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_pendingDiagramId == null) return;
      _pollingCount++;

      if (_pollingCount > _maxPollingAttempts) {
        _stopPolling();
        setState(() {
          _isGenerating = false;
          _errorMessage = 'استغرق التوليد وقتاً طويلاً. حاول مرة تانية.';
        });
        return;
      }

      try {
        final diagram = await DiagramRepository().getDiagram(
          _pendingDiagramId!,
        );
        if (diagram.isDone) {
          _stopPolling();
          if (mounted) Navigator.of(context).pop(diagram);
        } else if (diagram.isFailed) {
          _stopPolling();
          setState(() {
            _isGenerating = false;
            _errorMessage = 'فشل توليد الـ diagram. حاول مرة تانية.';
          });
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _pendingDiagramId = null;
  }

  void _cancelGeneration() {
    _stopPolling();
    setState(() {
      _isGenerating = false;
      _errorMessage = null;
      _pollingCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isGenerating ? _buildGeneratingState() : _buildForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
      ),
      title: Text('Diagram جديد', style: AppTextStyles.h3),
      centerTitle: true,
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: AppSizes.md),
            ],

            Text('نوع الـ Diagram', style: AppTextStyles.labelSmall),
            const SizedBox(height: AppSizes.sm),
            _buildTypeSelector(),
            const SizedBox(height: AppSizes.lg),

            Text('اسم الـ Diagram', style: AppTextStyles.labelSmall),
            const SizedBox(height: AppSizes.xs),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                hint: 'مثلاً: User Authentication System',
                icon: Icons.label_outline_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'اكتب اسم للـ diagram'
                  : null,
            ),
            const SizedBox(height: AppSizes.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الوصف', style: AppTextStyles.labelSmall),
                Text(
                  '$_descLength / 1000',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _descLength > 900
                        ? Colors.redAccent
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
              maxLines: 6,
              maxLength: 1000,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => const SizedBox.shrink(),
              decoration: _inputDecoration(
                hint:
                    'اوصف الـ system أو الفكرة اللي عايز تحولها لـ diagram...',
                icon: Icons.notes_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'اكتب وصف للـ diagram'
                  : null,
            ),
            const SizedBox(height: AppSizes.xl),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 20),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Generate Diagram',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.sm,
      mainAxisSpacing: AppSizes.sm,
      childAspectRatio: 2.4,
      children: _types.map((t) {
        final isSelected = _selectedType == t.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = t.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            child: Row(
              children: [
                Icon(
                  t.icon,
                  size: AppSizes.iconSm,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontSm,
                        ),
                      ),
                      Text(
                        t.description,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: AppSizes.fontXs,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            AnimatedBuilder(
              animation: _dotsAnimation,
              builder: (_, __) => Text(
                'جاري التوليد${'.' * _dotsAnimation.value}',
                style: AppTextStyles.h3,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            Text(
              'الـ AI بيحلل النص ويولد الـ diagram\nده ممكن ياخد لحد 30 ثانية',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(height: 1.6),
            ),
            const SizedBox(height: AppSizes.sm),

            AnimatedBuilder(
              animation: _dotsController,
              builder: (_, __) => Text(
                'محاولة $_pollingCount / $_maxPollingAttempts',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: AppSizes.fontXs,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xxl),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surface,
                color: AppColors.primary,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            TextButton(
              onPressed: _cancelGeneration,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
              ),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: AppSizes.iconSm,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: AppSizes.fontSm,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.textTertiary,
        size: AppSizes.iconSm,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
