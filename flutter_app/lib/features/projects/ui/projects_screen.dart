import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../diagrams/ui/project_detail_screen.dart';
import '../data/project_repository.dart';
import '../data/projects_model.dart';
import 'widgets/create_project_modal.dart';

String _initials = '';
final _apiClient = ApiClient();

class ProjectsBody extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterShowModal;

  const ProjectsBody({super.key, this.onRegisterShowModal});

  @override
  State<ProjectsBody> createState() => _ProjectsBodyState();
}

class _ProjectsBodyState extends State<ProjectsBody> {
  final _repo = ProjectRepository();
  final _searchController = TextEditingController();

  List<ProjectModel> _projects = [];
  List<ProjectModel> _filtered = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    widget.onRegisterShowModal?.call(_showCreateModal);

    _init();
    _searchController.addListener(_onSearch);
  }

  Future<void> _init() async {
    await _loadProjects();
    await _loadInitials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();

    setState(() {
      _filtered = q.isEmpty
          ? _projects
          : _projects.where((p) {
              return p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q);
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
        _projects = List<ProjectModel>.from(result['data']);
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
        _initials = name[0].toUpperCase();
      });
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF171717),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: CreateProjectModal(
            onCreated: (project) {
              setState(() {
                _projects.insert(0, project);
                _filtered = _projects;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFF111111),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Projects",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_projects.length} projects",
                          style: TextStyle(
                            color: Colors.white.withOpacity(.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B4DFF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(.06)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search projects...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(.35)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withOpacity(.4),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// LIST
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5B4DFF),
                      ),
                    )
                  : _error != null
                  ? _buildError()
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadProjects,
                      color: const Color(0xFF5B4DFF),
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: MediaQuery.of(context).padding.bottom + 120,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final project = _filtered[i];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProjectDetailScreen(project: project),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          project.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              .55,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Updated recently",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(.3),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF5B4DFF,
                                      ).withOpacity(.15),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      "${project.diagramsCount} diagram${project.diagramsCount == 1 ? '' : 's'}",
                                      style: const TextStyle(
                                        color: Color(0xFF8C7BFF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        _error ?? "Something went wrong",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 60,
            color: Colors.white.withOpacity(.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "No projects yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first project",
            style: TextStyle(color: Colors.white.withOpacity(.5)),
          ),
        ],
      ),
    );
  }
}
