import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../auth/ui/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final _client = ApiClient();
  String _name = '';
  String _email = '';
  int _projectsCount = 0;
  int _diagramsCount = 0;
  String _memberSince = '';
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

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
    // ── Confirm dialog ─────────────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius:
                BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 26),
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontXl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontMd),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.redAccent,
                              AppColors.error,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Logout',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
    );

    if (confirmed != true) return;

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
    super.build(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, Color(0xFF1A0535)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.lg),
                    // ── Title ──
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // ── Profile Card ──
                    _isLoading
                        ? _buildLoadingCard()
                        : _buildProfileCard(),
                    const SizedBox(height: AppSizes.md),

                    // ── Stats Card ──
                    if (!_isLoading) _buildStatsCard(),
                    const SizedBox(height: AppSizes.lg),

                    // ── Account Info ──
                    if (!_isLoading) ...[
                      _buildSectionLabel('Account'),
                      const SizedBox(height: AppSizes.sm),
                      _buildAccountInfo(),
                      const SizedBox(height: AppSizes.lg),
                    ],

                    // ── About ──
                    _buildSectionLabel('About'),
                    const SizedBox(height: AppSizes.sm),
                    _buildAboutSection(),
                    const SizedBox(height: AppSizes.xxl),
                  ],
                ),
              ),
            ),

            // ── Logout fixed at bottom ──────────────────────────────────────
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────────
  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: _glassDecoration(),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    )),
                const SizedBox(height: 8),
                Container(
                    height: 11,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    final initials =
        _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: _glassDecoration(),
      child: Row(
        children: [
          // ← gradient avatar بدل flat color
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusMd),
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
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
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
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontSm,
                  ),
                ),
              ],
            ),
          ),
          // ← glass edit button
          GestureDetector(
            onTap: _showEditProfile,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusSm + 2),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Card ─────────────────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      decoration: _glassDecoration(),
      child: IntrinsicHeight(
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
            VerticalDivider(
              width: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
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
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Column(
        children: [
          // ← gradient icon
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [color, AppColors.accent],
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Icon(icon, size: AppSizes.iconMd, color: Colors.white),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSm,
            ),
          ),
        ],
      ),
    );
  }

  // ── Account Info ───────────────────────────────────────────────────────────
  Widget _buildAccountInfo() {
    return _SettingsCard(
      items: [
        _SettingsRow(
          icon: Icons.calendar_today_rounded,
          label: 'Member since',
          value: _memberSince,
        ),
        _SettingsRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _email,
        ),
      ],
    );
  }

  // ── About Section ──────────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return _SettingsCard(
      items: [
        _SettingsRow(
          icon: Icons.info_outline_rounded,
          label: 'App version',
          value: '1.0.0',
        ),
        _SettingsRow(
          icon: Icons.auto_awesome_rounded,
          label: 'Powered by',
          value: 'Groq AI',
          valueColor: AppColors.accent,
        ),
        _SettingsRow(
          icon: Icons.draw_rounded,
          label: 'Diagrams by',
          value: 'Mermaid.js',
          valueColor: AppColors.primary,
        ),
      ],
    );
  }

  // ── Logout Button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        // ← SafeArea padding aware
        AppSizes.md,
      ),
      child: GestureDetector(
        onTap: _logout,
        child: Container(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            // ← radiusRound بدل radiusMd
            borderRadius:
                BorderRadius.circular(AppSizes.radiusRound),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded,
                  size: AppSizes.iconSm + 2,
                  color: AppColors.error),
              const SizedBox(width: AppSizes.sm),
              const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Profile Modal ─────────────────────────────────────────────────────
  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.md,
            AppSizes.screenPadding,
            MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1624),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28)),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppSizes.fontXl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Name
              _buildModalField(
                  ctrl: nameCtrl, label: 'Full name', hint: 'Your name'),
              const SizedBox(height: AppSizes.md),

              // Email
              _buildModalField(
                ctrl: emailCtrl,
                label: 'Email',
                hint: 'Your email',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              setModal(() => isLoading = true);
                              try {
                                await _client.put(
                                  '/user/profile',
                                  data: {
                                    'name': nameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                  },
                                );
                                setState(() {
                                  _name = nameCtrl.text.trim();
                                  _email = emailCtrl.text.trim();
                                });
                                if (mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Profile updated!'),
                                      backgroundColor:
                                          AppColors.success,
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppSizes.radiusMd),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModal(() => isLoading = false);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.accent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusRound),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildModalField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hint,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Glass decoration helper ────────────────────────────────────────────────
  BoxDecoration _glassDecoration() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      );
}

// ── Settings Card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<_SettingsRow> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Settings Row ──────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      child: Row(
        children: [
          // ← glass icon container
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusSm + 2),
            ),
            child: Icon(icon,
                size: AppSizes.iconSm + 1,
                color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textSecondary,
              fontSize: AppSizes.fontSm,
              fontWeight: valueColor != null
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}