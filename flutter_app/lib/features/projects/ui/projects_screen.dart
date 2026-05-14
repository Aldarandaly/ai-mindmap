import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/network_background.dart';
import '../../diagrams/ui/project_detail_screen.dart';
import '../data/project_repository.dart';
import '../data/projects_model.dart';
import 'widgets/create_project_modal.dart';

String _initials = '';
final _apiClient = ApiClient();

// ── Gradient pairs for project cards ─────────────────────────────────────────
const _gradients = [
  [Color(0xFF6C63FF), Color(0xFF9B59B6)],
  [Color(0xFF00D4FF), Color(0xFF6C63FF)],
  [Color(0xFF9B59B6), Color(0xFF00D4FF)],
  [Color(0xFF6C63FF), Color(0xFF00D4FF)],
  [Color(0xFF00D4FF), Color(0xFF9B59B6)],
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

    });
  }

  Future<void> _loadProjects() async {

    } else {
      setState(() { _error = result['message']; _isLoading = false; });
    }
  }

  Future<void> _loadInitials() async {
    final name = await _apiClient.getUserName();
    if (name != null && name.isNotEmpty) {
      setState(() => _initials = name[0].toUpperCase());
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(

          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

            ),
          ],
        ),
      ),
    );
  }


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

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials.isEmpty ? '?' : _initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textTertiary,
                        size: AppSizes.iconSm),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch();
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Shimmer loading ────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding),
      itemCount: 4,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() {

  }

  // ── Empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

}