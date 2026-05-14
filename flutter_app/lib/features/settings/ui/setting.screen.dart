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
  bool _notifyGeneration = true;
  bool _notifyUpdates = false;

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
          if (date != null) _memberSince = '${date.day}/${date.month}/${date.year}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    try { await _client.post('/logout'); } catch (_) {}
    await _client.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(AppSizes.screenPadding, AppSizes.md, AppSizes.screenPadding, MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSizes.lg),
              const Text('Edit Profile', style: TextStyle(fontSize: AppSizes.fontXl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: AppSizes.lg),
              _modalField('Full name', nameController),
              const SizedBox(height: AppSizes.md),
              _modalField('Email', emailController, keyboard: TextInputType.emailAddress),
              const SizedBox(height: AppSizes.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))), child: const Text('Cancel'))),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        setModalState(() => isLoading = true);
                        try {
                          await _client.put('/user/profile', data: {'name': nameController.text.trim(), 'email': emailController.text.trim()});
                          setState(() { _name = nameController.text.trim(); _email = emailController.text.trim(); });
                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setModalState(() => isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
                      child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _modalField(String label, TextEditingController controller, {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: AppSizes.xs),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    const Text('Settings', style: TextStyle(fontSize: AppSizes.fontXxl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSizes.xl),
                    _buildSectionTitle('Account & Profile', Icons.person_rounded),
                    const SizedBox(height: AppSizes.sm),
                    _isLoading ? _buildLoadingCard() : _buildProfileCard(),
                    const SizedBox(height: AppSizes.xs),
                    _buildActionTile(icon: Icons.edit_rounded, label: 'Edit Profile', onTap: _showEditProfile),
                    _buildActionTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () {}),
                    const SizedBox(height: AppSizes.lg),
                    _buildSectionTitle('Projects & Workspace', Icons.folder_rounded),
                    const SizedBox(height: AppSizes.sm),
                    if (!_isLoading) _buildStatsCard(),
                    const SizedBox(height: AppSizes.lg),
                    _buildSectionTitle('Notifications', Icons.notifications_rounded),
                    const SizedBox(height: AppSizes.sm),
                    _buildToggleTile(icon: Icons.auto_awesome_rounded, label: 'Generation Complete', subtitle: 'Notify when diagram is ready', value: _notifyGeneration, onChanged: (v) => setState(() => _notifyGeneration = v)),
                    _buildToggleTile(icon: Icons.update_rounded, label: 'App Updates', subtitle: 'Notify about new features', value: _notifyUpdates, onChanged: (v) => setState(() => _notifyUpdates = v)),
                    const SizedBox(height: AppSizes.lg),
                    _buildSectionTitle('Export & Integrations', Icons.download_rounded),
                    const SizedBox(height: AppSizes.sm),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Export Formats', style: TextStyle(fontSize: AppSizes.fontMd, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: ['PNG', 'PDF', 'Mermaid Code'].map((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                              child: Text(f, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.primary, fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    _buildSectionTitle('System', Icons.settings_rounded),
                    const SizedBox(height: AppSizes.sm),
                    _buildInfoRow(icon: Icons.info_outline_rounded, label: 'App version', value: '1.0.0'),
                    _buildInfoRow(icon: Icons.auto_awesome_rounded, label: 'Powered by', value: 'Groq AI'),
                    _buildInfoRow(icon: Icons.draw_rounded, label: 'Diagrams by', value: 'Mermaid.js'),
                    _buildInfoRow(icon: Icons.calendar_today_rounded, label: 'Member since', value: _memberSince),
                    const SizedBox(height: AppSizes.md),
                    _buildSectionTitle('Danger Zone', Icons.warning_rounded, color: AppColors.error),
                    const SizedBox(height: AppSizes.sm),
                    _buildDangerTile(icon: Icons.delete_forever_rounded, label: 'Delete Account', onTap: _showDeleteAccountDialog),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.1), foregroundColor: AppColors.error, elevation: 0, side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: const Text('Delete Account', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 16, color: color ?? AppColors.primary),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: AppSizes.fontMd, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
    ]);
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.cardRadius), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppSizes.radiusRound))),
        const SizedBox(width: AppSizes.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 14, width: 120, color: AppColors.border),
          const SizedBox(height: 8),
          Container(height: 12, width: 180, color: AppColors.border),
        ])),
      ]),
    );
  }

  Widget _buildProfileCard() {
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.cardRadius), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppSizes.radiusRound)), child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)))),
        const SizedBox(width: AppSizes.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_name, style: const TextStyle(fontSize: AppSizes.fontLg, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(_email, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.cardRadius), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Expanded(child: _buildStat(icon: Icons.folder_rounded, label: 'Projects', value: '$_projectsCount', color: AppColors.primary)),
        Container(width: 1, height: 60, color: AppColors.border),
        Expanded(child: _buildStat(icon: Icons.auto_awesome_rounded, label: 'Diagrams', value: '$_diagramsCount', color: AppColors.accent)),
      ]),
    );
  }

  Widget _buildStat({required IconData icon, required String label, required String value, required Color color}) {
    return Column(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusMd)), child: Icon(icon, color: color, size: AppSizes.iconMd)),
      const SizedBox(height: AppSizes.sm),
      Text(value, style: const TextStyle(fontSize: AppSizes.fontXxl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusMd), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Icon(icon, size: 18, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: AppSizes.fontMd, color: AppColors.textPrimary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusMd), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Icon(icon, size: 18, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: AppSizes.fontMd, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textTertiary)),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),
    );
  }

  Widget _buildDangerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(AppSizes.radiusMd), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
      child: ListTile(
        leading: Icon(icon, size: 18, color: AppColors.error),
        title: Text(label, style: const TextStyle(fontSize: AppSizes.fontMd, color: AppColors.error, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.error),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.cardRadius), border: Border.all(color: AppColors.border)),
      child: child,
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusMd), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSizes.sm),
        Text(label, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}