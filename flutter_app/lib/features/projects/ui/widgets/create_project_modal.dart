import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/project_repository.dart';
import '../projects_model.dart';

class CreateProjectModal extends StatefulWidget {
  final void Function(ProjectModel) onCreated;

  const CreateProjectModal({super.key, required this.onCreated});

  @override
  State<CreateProjectModal> createState() => _CreateProjectModalState();
}

class _CreateProjectModalState extends State<CreateProjectModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _repo = ProjectRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

 void _create() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  final result = await _repo.createProject(_nameController.text.trim());

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
        ),
      );
    }
  }

  if (mounted) setState(() => _isLoading = false);
}

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.lg + bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            const Text(
              'New project',
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Name field
            AppTextField(
              label: 'Project name',
              hint: 'My App Database',
              controller: _nameController,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Description field
            AppTextField(
              label: 'Description',
              hint: 'Optional notes...',
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.xl),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: AppButton(
                    label: 'Create',
                    onPressed: _create,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
