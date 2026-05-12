import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../auth/ui/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _client = ApiClient();
  String _name = '';
  String _email = '';
  int _projectsCount = 0;
  int _diagramsCount = 0;
  String _memberSince = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _client.get('/user');
      setState(() {
        _name = response['name'] ?? '';
        _email = response['email'] ?? '';
        _projectsCount = response['projects_count'] ?? 0;
        _diagramsCount = response['diagrams_count'] ?? 0;
        final createdAt = response['created_at'];
        if (createdAt != null) {
          final date = DateTime.tryParse(createdAt);
          if (date != null) {
            _memberSince = '${date.day}/${date.month}/${date.year}';
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    try {
      await _client.post('/logout');
    } catch (_) {}
    await _client.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.sm),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: AppSizes.fontXxl,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // ── Profile ──
                    _isLoading ? _buildLoadingCard() : _buildProfileCard(),
                    const SizedBox(height: AppSizes.md),

                    // ── Stats ──
                    if (!_isLoading) _buildStatsCard(),
                    const SizedBox(height: AppSizes.md),

                    // ── Account Info ──
                    if (!_isLoading) _buildAccountInfo(),
                    const SizedBox(height: AppSizes.md),

                    // ── About ──
                    _buildAboutSection(),
                  ],
                ),
              ),
            ),

            // ── Logout ──
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 120, color: AppColors.border),
                const SizedBox(height: 8),
                Container(height: 12, width: 180, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            onPressed: _showEditProfile,
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat(
              icon: Icons.folder_rounded,
              label: 'Projects',
              value: '$_projectsCount',
              color: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 60, color: AppColors.border),
          Expanded(
            child: _buildStat(
              icon: Icons.auto_awesome_rounded,
              label: 'Diagrams',
              value: '$_diagramsCount',
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Member since',
            value: _memberSince,
          ),
          const Divider(color: AppColors.border, height: 1),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _email,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: AppSizes.sm),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.info_outline_rounded,
            label: 'App version',
            value: '1.0.0',
          ),
          const Divider(color: AppColors.border, height: 1),
          _buildInfoRow(
            icon: Icons.auto_awesome_rounded,
            label: 'Powered by',
            value: 'Groq AI',
          ),
          const Divider(color: AppColors.border, height: 1),
          _buildInfoRow(
            icon: Icons.draw_rounded,
            label: 'Diagrams by',
            value: 'Mermaid.js',
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(icon, color: color, size: AppSizes.iconMd),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppSizes.fontXxl,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontSm,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          foregroundColor: AppColors.error,
          elevation: 0,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.md,
            AppSizes.screenPadding,
            MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: AppSizes.fontXl,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Name field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Full name',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.background,
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Email field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Your email',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.background,
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setModalState(() => isLoading = true);
                              try {
                                await _client.put(
                                  '/user/profile',
                                  data: {
                                    'name': nameController.text.trim(),
                                    'email': emailController.text.trim(),
                                  },
                                );
                                setState(() {
                                  _name = nameController.text.trim();
                                  _email = emailController.text.trim();
                                });
                                if (mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Profile updated successfully',
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusMd,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
