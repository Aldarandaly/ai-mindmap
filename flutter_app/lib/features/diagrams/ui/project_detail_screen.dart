import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../projects/data/projects_model.dart';
import '../data/diagram_model.dart';
import '../data/diagram_repository.dart';
import 'widgets/diagram_card.dart';
import 'create_diagram_screen.dart';
import 'diagram_viewer_screen.dart';
import '../../chat/ui/chat_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _repo = DiagramRepository();

  List<Diagram> _diagrams = [];
  List<Diagram> _filtered = [];

  bool _isLoading = true;
  String? _error;

  String _selectedType = 'all';

  final _types = [
    'all',
    'erd',
    'class',
    'mindmap',
    'usecase',
    'activity',
    'sequence',
    'context',
    'state',
    'dfd',
    'gantt',
  ];

  @override
  void initState() {
    super.initState();
    _loadDiagrams();
  }

  Future<void> _loadDiagrams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repo.getDiagrams(widget.project.id);

    if (result['success']) {
      setState(() {
        _diagrams = List<Diagram>.from(result['data']);

        _filterDiagrams();

        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  void _filterDiagrams() {
    setState(() {
      _filtered = _selectedType == 'all'
          ? _diagrams
          : _diagrams.where((d) => d.type == _selectedType).toList();
    });
  }

  void _onTypeSelected(String type) {
    _selectedType = type;
    _filterDiagrams();
  }

  void _goToCreateDiagram() async {
    final result = await Navigator.push<Diagram>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDiagramScreen(
          projectId: widget.project.id,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _diagrams.insert(0, result);
        _filterDiagrams();
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagramViewerScreen(diagram: result),
          ),
        );
      }
    }
  }

  // OPEN AI CHAT
  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.md,
                AppSizes.screenPadding,
                0,
              ),

              child: Row(
                children: [
                  // BACK BUTTON
                  IconButton(
                    onPressed: () => Navigator.pop(context),

                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: AppSizes.iconSm,
                      color: AppColors.textPrimary,
                    ),

                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(width: AppSizes.sm),

                  // PROJECT INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          widget.project.name,

                          style: AppTextStyles.h3,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          '${_diagrams.length} diagram${_diagrams.length == 1 ? '' : 's'}'
                          ' · ${widget.project.updatedAtLabel}',

                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // FILTER CHIPS
            SizedBox(
              height: 36,

              child: ListView(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                ),

                children: _types.map((type) {
                  final isSelected = _selectedType == type;

                  final label = type == 'all'
                      ? 'All'
                      : type == 'mindmap'
                      ? 'Mind Map'
                      : type.toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),

                    child: GestureDetector(
                      onTap: () => _onTypeSelected(type),

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,

                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusRound,
                          ),

                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),

                        child: Text(
                          label,

                          style: TextStyle(
                            fontSize: AppSizes.fontSm,

                            fontWeight: FontWeight.w500,

                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // BODY
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                  ? _buildError()
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
            ),
          ],
        ),
      ),

      // FLOATING BUTTONS
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          // AI CHAT BUTTON
          FloatingActionButton.extended(
            heroTag: "chat",

            backgroundColor: Colors.deepPurple,

            onPressed: _openChat,

            icon: const Icon(Icons.auto_awesome, color: Colors.white),

            label: const Text(
              "AI Chat",

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // NEW DIAGRAM BUTTON
          FloatingActionButton.extended(
            heroTag: "diagram",

            onPressed: _goToCreateDiagram,

            backgroundColor: AppColors.primary,

            icon: const Icon(Icons.add, color: Colors.white),

            label: const Text(
              'New Diagram',

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOADING
  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),

      itemCount: 3,

      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),

        height: 80,

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
    );
  }

  // ERROR
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.textTertiary,
          ),

          const SizedBox(height: AppSizes.md),

          Text(_error!, style: AppTextStyles.bodyMedium),

          const SizedBox(height: AppSizes.md),

          TextButton(
            onPressed: _loadDiagrams,

            child: const Text(
              'Try again',

              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // EMPTY
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: const [
          Icon(
            Icons.auto_awesome_rounded,
            size: 60,
            color: AppColors.textTertiary,
          ),

          SizedBox(height: AppSizes.lg),

          Text(
            'No diagrams yet',

            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: AppSizes.xs),

          Text(
            'Generate your first diagram',

            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // LIST
  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadDiagrams,

      color: AppColors.primary,

      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding,
          vertical: AppSizes.sm,
        ),

        itemCount: _filtered.length,

        itemBuilder: (_, i) => DiagramCard(
          diagram: _filtered[i],

          onTap: () {
            Navigator.push(
              context,

              MaterialPageRoute(
                builder: (_) => DiagramViewerScreen(diagram: _filtered[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}
