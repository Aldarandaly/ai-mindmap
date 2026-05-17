import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/project_repository.dart';
import '../../data/projects_model.dart';

class CreateProjectModal extends StatefulWidget {
  final void Function(Project) onCreated;

  const CreateProjectModal({
    super.key,
    required this.onCreated,
  });

  @override
  State<CreateProjectModal> createState() =>
      _CreateProjectModalState();
}

class _CreateProjectModalState
    extends State<CreateProjectModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _descController = TextEditingController();

  final _repo = ProjectRepository();

  bool _isLoading = false;

  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;

  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();

    _descController.dispose();

    _animationController.dispose();

    super.dispose();
  }

  // ──────────────────────────────────────────────────
  // Create Project
  // ──────────────────────────────────────────────────

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _repo.createProject(
      _nameController.text.trim(),
    );

    if (result['success']) {
      if (mounted) {
        Navigator.pop(context);

        widget.onCreated(result['data']);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ──────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(12),

            padding: const EdgeInsets.fromLTRB(
              22,
              18,
              22,
              26,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFF181822),

              borderRadius: BorderRadius.circular(32),

              border: Border.all(
                color:
                    Colors.white.withValues(alpha: 0.08),
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Form(
              key: _formKey,

              child: Column(
                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // ── Handle ────────────────────
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.12),

                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Header ────────────────────
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(0xFF7C6FFF),
                              Color(0xFF36D1FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Project',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),

                            SizedBox(height: 2),

                            Text(
                              'Start a new workspace',
                              style: TextStyle(
                                color: AppColors
                                    .textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Name ──────────────────────
                  _buildLabel('Project name'),

                  const SizedBox(height: 10),

                  _buildInput(
                    controller: _nameController,
                    hint: 'My App UI',
                    icon:
                        Icons.drive_file_rename_outline_rounded,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Project name required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ── Description ───────────────
                  _buildLabel('Description'),

                  const SizedBox(height: 10),

                  _buildInput(
                    controller: _descController,
                    hint:
                        'Optional description...',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 28),

                  // ── Buttons ───────────────────
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.06),

                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),

                              border: Border.all(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Create
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              _isLoading ? null : _create,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  Color(0xFF7C6FFF),
                                  Color(0xFF36D1FF),
                                ],
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 18,
                                  offset:
                                      const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        Icon(
                                          Icons
                                              .add_rounded,
                                          color:
                                              Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(
                                            width: 8),
                                        Text(
                                          'Create',
                                          style:
                                              TextStyle(
                                            color: Colors
                                                .white,
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
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

  // ──────────────────────────────────────────────────
  // Label
  // ──────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Input
  // ──────────────────────────────────────────────────

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,

      validator: validator,

      maxLines: maxLines,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
        ),

        prefixIcon: maxLines == 1
            ? Icon(
                icon,
                color: Colors.white
                    .withValues(alpha: 0.6),
              )
            : null,

        filled: true,

        fillColor:
            Colors.white.withValues(alpha: 0.05),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
                Colors.white.withValues(alpha: 0.08),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
                Colors.white.withValues(alpha: 0.08),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF8B7FFF),
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.4,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}