import 'dart:async';
import 'package:flutter/material.dart';
import '../../diagrams/data/diagram_model.dart';
import '../data/diagram_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../projects/data/projects_model.dart';

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
      description: 'Picks the best type automatically',
    ),
    _DiagramType(
      key: 'class',
      label: 'Class',
      icon: Icons.account_tree_rounded,
      description: 'Class Diagram for OOP',
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
      description: 'Visual mind map for ideas',
    ),
    _DiagramType(
      key: 'usecase',
      label: 'Use Case',
      icon: Icons.person_rounded,
      description: 'System use cases',
    ),
    _DiagramType(
      key: 'activity',
      label: 'Activity',
      icon: Icons.alt_route_rounded,
      description: 'Activity flow diagram',
    ),
    _DiagramType(
      key: 'sequence',
      label: 'Sequence',
      icon: Icons.swap_horiz_rounded,
      description: 'Sequence of interactions',
    ),
    _DiagramType(
      key: 'context',
      label: 'Context',
      icon: Icons.bubble_chart_rounded,
      description: 'System context diagram',
    ),
    _DiagramType(
      key: 'state',
      label: 'State',
      icon: Icons.stacked_line_chart_rounded,
      description: 'State machine diagram',
    ),
    _DiagramType(
      key: 'dfd',
      label: 'DFD',
      icon: Icons.share_rounded,
      description: 'Data flow diagram',
    ),
    _DiagramType(
      key: 'gantt',
      label: 'Gantt',
      icon: Icons.bar_chart_rounded,
      description: 'Project timeline chart',
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
        _errorMessage =
            'Failed to send request. Check your connection and try again.';
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
          _errorMessage = 'Generation took too long. Please try again.';
        });
        return;
      }
      try {
        final diagram = await DiagramRepository().getDiagram(
          _pendingDiagramId!,
        );
        if (diagram.status == 'done' ||
            diagram.status == 'completed' ||
            diagram.isDone) {
          _stopPolling();
          if (mounted) Navigator.of(context).pop(diagram);
        } else if (diagram.status == 'failed' || diagram.isFailed) {
          _stopPolling();
          setState(() {
            _isGenerating = false;
            _errorMessage = 'Failed to generate diagram. Please try again.';
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

  // ── Hints ──────────────────────────────────────────────────

  List<String> _getHints(String type) {
    switch (type) {
      case 'erd':
        return [
          'List all your main entities (tables)',
          'Mention the attributes of each entity',
          'Describe relationships (one-to-many, many-to-many)',
          'Specify primary and foreign keys if known',
        ];
      case 'class':
        return [
          'List the main classes in your system',
          'Mention attributes and methods for each class',
          'Describe relationships (inheritance, association)',
          'Specify access modifiers if needed (public, private)',
        ];
      case 'mindmap':
        return [
          'Start with the main topic or idea',
          'List the main branches or categories',
          'Add sub-topics under each branch',
          'Keep it concise — keywords work best',
        ];
      case 'auto':
        return [
          'Describe your system or idea naturally',
          'Mention entities, classes, or concepts',
          'The AI will pick the best diagram type',
          'More details = better diagram',
        ];
      case 'usecase':
        return [
          'List the actors (users or systems)',
          'Describe the main use cases or actions',
          'Mention relationships between actors and use cases',
          'Include any include or extend relationships',
        ];
      case 'activity':
        return [
          'Describe the flow of activities step by step',
          'Mention decision points (if/else)',
          'Include start and end points',
          'Describe parallel activities if any',
        ];
      case 'sequence':
        return [
          'List the participants (objects or systems)',
          'Describe the sequence of messages between them',
          'Mention the order of interactions',
          'Include return messages if needed',
        ];
      case 'context':
        return [
          'Describe the main system',
          'List external entities that interact with it',
          'Describe data flows between system and entities',
        ];
      case 'state':
        return [
          'List all possible states',
          'Describe transitions between states',
          'Mention triggers or events for each transition',
          'Include initial and final states',
        ];
      case 'dfd':
        return [
          'List processes in your system',
          'Describe data stores (databases)',
          'Mention external entities',
          'Describe data flows between them',
        ];
      case 'gantt':
        return [
          'List all tasks or phases',
          'Mention duration for each task',
          'Describe dependencies between tasks',
          'Include start date or project timeline',
        ];
      default:
        return [];
    }
  }

  String _getExample(String type) {
    switch (type) {
      case 'erd':
        return 'I have a school system with Teachers, Students, and Classes. Each teacher teaches multiple classes. Each student enrolls in many classes. Teachers have name, email, and subject.';
      case 'class':
        return 'I have an e-commerce app with User, Product, Order, and Payment classes. User can place multiple orders. Each order contains multiple products.';
      case 'mindmap':
        return 'Software Engineering main topics: Design Patterns, Testing, Deployment, Databases, and Security.';
      case 'auto':
        return 'I want to build a hospital management system with doctors, patients, appointments, and medical records.';
      case 'usecase':
        return 'A library system where Librarian can add books, manage members. Member can search books, borrow and return books.';
      case 'activity':
        return 'User login flow: start, enter credentials, validate, if valid go to dashboard, if invalid show error and retry.';
      case 'sequence':
        return 'User sends login request to AuthService, AuthService checks Database, Database returns result, AuthService returns token to User.';
      case 'context':
        return 'Online store system interacts with Customer, Payment Gateway, Supplier, and Shipping Service.';
      case 'state':
        return 'Order states: Created, Confirmed, Shipped, Delivered, Cancelled. Order moves from Created to Confirmed when payment is received.';
      case 'dfd':
        return 'Student submits assignment to System, System stores in Database, Teacher retrieves from Database, System sends notification to Student.';
      case 'gantt':
        return 'Project has 4 phases: Planning (2 weeks), Design (3 weeks), Development (8 weeks), Testing (2 weeks). Design starts after Planning.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: _isGenerating ? _buildGeneratingState() : _buildForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
      ),
      title: Text('New Diagram', style: AppTextStyles.h3),
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

            Text('Diagram Type', style: AppTextStyles.labelSmall),
            const SizedBox(height: AppSizes.sm),
            _buildTypeSelector(),
            const SizedBox(height: AppSizes.sm),

            // ── Hints ──
            _buildHints(),
            const SizedBox(height: AppSizes.lg),

            Text('Diagram Name', style: AppTextStyles.labelSmall),
            const SizedBox(height: AppSizes.xs),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                hint: 'e.g. User Authentication System',
                icon: Icons.label_outline_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter a diagram name'
                  : null,
            ),
            const SizedBox(height: AppSizes.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Description', style: AppTextStyles.labelSmall),
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
                    'Describe the system or idea you want to turn into a diagram...',
                icon: Icons.notes_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter a description'
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
                        style: const TextStyle(
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

  Widget _buildHints() {
    final hints = _getHints(_selectedType);
    if (hints.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'What to include in your description:',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ...hints.map(
            (hint) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      hint,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Example:',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getExample(_selectedType),
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                'Generating${'.' * _dotsAnimation.value}',
                style: AppTextStyles.h3,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'AI is analyzing your text and building the diagram\nThis may take up to 30 seconds',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(height: 1.6),
            ),
            const SizedBox(height: AppSizes.sm),
            AnimatedBuilder(
              animation: _dotsController,
              builder: (_, __) => Text(
                'Attempt $_pollingCount / $_maxPollingAttempts',
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
              child: const Text('Cancel'),
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
