import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../diagrams/ui/project_detail_screen.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/data/projects_model.dart';
import 'widgets/create_project_modal.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/state/user_notifier.dart';
import 'dart:ui';

String _initials = '';
String _userName = "";

final _apiClient = ApiClient();

const List<List<Color>> _gradients = [
  [Color(0xFF6C63FF), Color(0xFF9B59B6)],
  [Color(0xFF3B82F6), Color(0xFF6C63FF)],
  [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  [Color(0xFF10B981), Color(0xFF06B6D4)],
];

class ProjectsBody extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterShowModal;

  const ProjectsBody({super.key, this.onRegisterShowModal});

  @override
  State<ProjectsBody> createState() => _ProjectsBodyState();
}

class _ProjectsBodyState extends State<ProjectsBody>
    with AutomaticKeepAliveClientMixin {
  final _repo = ProjectRepository();
  final _searchController = TextEditingController();

  List<Project> _projects = [];
  List<Project> _filtered = [];

  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    widget.onRegisterShowModal?.call(_showCreateModal);
    _init();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadProjects();
    await _loadInitials();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();

    setState(() {
      _filtered = q.isEmpty
          ? _projects
          : _projects.where((p) {
              return p.name.toLowerCase().contains(q) ||
                  (p.description ?? '').toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repo.getProjects();

    if (result['success']) {
      setState(() {
        _projects = List<Project>.from(result['data']);
        _filtered = _projects;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitials() async {
    final name = await _apiClient.getUserName();

    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
        _initials = name[0].toUpperCase();
      });
    }
  }

  void _showCreateModal() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: CreateProjectModal(
          onCreated: (project) {
            setState(() {
              _projects.insert(0, project);
              _filtered = _projects;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildSearch(),
          const SizedBox(height: 14),

          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _error != null
                ? _buildError()
                : _filtered.isEmpty
                ? _buildEmpty()
                : _buildProjects(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── HEADER
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        AppSizes.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                if (!_isLoading && _error == null)
                  Text(
                    'This is your workshop',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          _buildAvatar(),
        ],
      ),
    );
  }

  // ───────────────────────── SEARCH
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search projects...',
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── AVATAR
  Widget _buildAvatar() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6FFF), Color(0xFF36D1FF)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: ValueListenableBuilder<String>(
          valueListenable: UserNotifier.userName,
          builder: (context, value, _) {
            final firstName = value.trim().split(' ').first;

            return Text(
              firstName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────────────── PROJECTS LIST
  Widget _buildProjects() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 90),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          return Dismissible(
            key: Key(_filtered[i].id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1828),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Delete Project',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to delete "${_filtered[i].name}"?',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) async {
              final project = _filtered[i];
              setState(() {
                _projects.removeWhere((p) => p.id == project.id);
                _filtered = _projects;
              });
              try {
                await _repo.deleteProject(project.id);
              } catch (_) {
                setState(() {
                  _projects.insert(0, project);
                  _filtered = _projects;
                });
              }
            },
            child: _ProjectCard(
              project: _filtered[i],
              gradient: _gradients[i % _gradients.length],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(project: _filtered[i]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError() => Center(child: Text(_error ?? 'Error'));

  Widget _buildEmpty() => const Center(child: Text('No Projects'));
}

// ───────────────────────── PROJECT CARD
class _ProjectCard extends StatelessWidget {
  final Project project;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.gradient,
    required this.onTap,
  });

  String _timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final difference = DateTime.now().difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.10),

                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1.2,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ICON
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _timeAgo(project.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ARROW
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFBFA2FF).withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          '${project.diagramsCount} diagrams',
                          style: const TextStyle(
                            color: Color(0xFFD8C8FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
