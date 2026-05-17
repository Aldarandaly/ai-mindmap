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
  bool _isLoading = true;
  bool _notifyGeneration = true;
  bool _notifyCollaboration = true;
  bool _notifyInsights = false;
  String _selectedEngine = 'NLP Pro';

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {

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
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, AppSizes.lg, AppSizes.screenPadding, AppSizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('System Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppSizes.radiusRound)),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Account & Profile ──
                  _buildCard(
                    title: 'Account & Profile',
                    titleIcon: initials,
                    child: Column(
                      children: [
                        _buildTileItem(icon: Icons.edit_rounded, label: 'Edit Profile', onTap: _showEditProfile),
                        _buildTileItem(icon: Icons.lock_outline_rounded, label: 'Manage Password', trailing: const Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.textTertiary), onTap: () {}),
                        _buildTileItem(icon: Icons.link_rounded, label: 'Connected Accounts', onTap: () {}),
                        const SizedBox(height: AppSizes.sm),
                        _buildPremiumBanner(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── AI & Generation ──
                  _buildCard(
                    title: 'AI & Generation',
                    titleIcon: null,
                    titleIconWidget: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Generation Engine', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSizes.sm),
                        _buildSegmentedControl(),
                        const SizedBox(height: AppSizes.md),
                        _buildSwitchItem(label: 'Smart Enhancement', value: true, onChanged: (_) {}),
                        const SizedBox(height: AppSizes.md),
                        const Text('Analysis Depth', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSizes.xs),
                        _buildSlider(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── Projects & Workspace ──
                  _buildCard(
                    title: 'Projects & Workspace',
                    titleIcon: null,
                    titleIconWidget: const Icon(Icons.folder_rounded, size: 16, color: AppColors.primary),
                    child: Column(
                      children: [
                        _buildTileItem(icon: Icons.tune_rounded, label: 'Workspace Preferences', onTap: () {}),
                        _buildStorageItem(),
                        _buildTileItem(icon: Icons.share_rounded, label: 'Sharing Permissions', onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── Notifications ──
                  _buildCard(
                    title: 'Notifications',
                    titleIcon: null,
                    titleIconWidget: const Icon(Icons.notifications_rounded, size: 16, color: AppColors.primary),
                    child: Column(
                      children: [
                        _buildSwitchItem(label: 'Generation Complete', value: _notifyGeneration, onChanged: (v) => setState(() => _notifyGeneration = v), icon: Icons.check_circle_rounded),
                        _buildSwitchItem(label: 'Collaboration Updates', value: _notifyCollaboration, onChanged: (v) => setState(() => _notifyCollaboration = v), icon: Icons.people_rounded),
                        _buildSwitchItem(label: 'Insight Suggestions', value: _notifyInsights, onChanged: (v) => setState(() => _notifyInsights = v), icon: Icons.lightbulb_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── Export & Integrations ──
                  _buildCard(
                    title: 'Export & Integrations',
                    titleIcon: null,
                    titleIconWidget: const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Export Formats', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSizes.sm),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: ['PDF', 'Mermaid', 'JSON', 'PNG'].map((f) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(f, style: const TextStyle(fontSize: AppSizes.fontXs, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                        const SizedBox(height: AppSizes.md),
                        const Text('Integrations', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSizes.sm),
                        Row(
                          children: [
                            _buildIntegrationIcon(Icons.drive_file_rename_outline_rounded, Colors.blue, 'Drive'),
                            const SizedBox(width: AppSizes.md),
                            _buildIntegrationIcon(Icons.cloud_rounded, Colors.indigo, 'Dropbox'),
                            const SizedBox(width: AppSizes.md),
                            _buildIntegrationIcon(Icons.tag_rounded, Colors.purple, 'Slack'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── System ──
                  _buildCard(
                    title: 'System',
                    titleIcon: null,
                    titleIconWidget: const Icon(Icons.settings_rounded, size: 16, color: AppColors.primary),
                    child: Column(
                      children: [
                        _buildTileItem(icon: Icons.palette_rounded, label: 'Theme', trailing: const Text('Dark', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textTertiary)), onTap: () {}),
                        _buildTileItem(icon: Icons.language_rounded, label: 'Language', onTap: () {}),
                        _buildTileItem(icon: Icons.shield_outlined, label: 'Privacy Policy & Terms', onTap: () {}),
                        const SizedBox(height: AppSizes.sm),
                        // Delete Account
                        _buildDangerButton(icon: Icons.delete_rounded, label: 'Delete Account', onTap: _showDeleteDialog),
                        const SizedBox(height: AppSizes.xs),
                        // Sign Out
                        _buildSignOutButton(),
                        const SizedBox(height: AppSizes.sm),
                        // Support links
                        Row(
                          children: [
                            Expanded(child: _buildSupportLink(icon: Icons.language_rounded, label: 'mindmap.io')),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(child: _buildSupportLink(icon: Icons.email_outlined, label: 'support')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.xl),
                  const Center(
                    child: Text('System & Support', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textTertiary)),
                  ),
                  const SizedBox(height: AppSizes.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Builder ──────────────────────────────────────────

  Widget _buildCard({required String title, String? titleIcon, Widget? titleIconWidget, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
            child: Row(
              children: [
                if (titleIconWidget != null) ...[titleIconWidget, const SizedBox(width: 6)],
                if (titleIcon != null) ...[
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(titleIcon, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(title, style: const TextStyle(fontSize: AppSizes.fontMd, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(AppSizes.md), child: child),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.8), const Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
          const SizedBox(width: AppSizes.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DiagramAI Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: AppSizes.fontMd)),
                Text('Unlimited diagrams', style: TextStyle(color: Colors.white70, fontSize: AppSizes.fontSm)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm))),
            child: const Text('Manage', style: TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: AppColors.border)),
      child: Row(
        children: ['NLP Pro', 'Standard'].map((e) {
          final isSelected = _selectedEngine == e;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedEngine = e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Center(child: Text(e, style: TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(value: 0.4, onChanged: (_) {}),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Basic', style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.textTertiary)),
              Text('Deep', style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

  Widget _buildStorageItem() {
    final total = _projectsCount + _diagramsCount;
    final progress = (total / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

  Widget _buildProfileCard() {
    final initials =
        _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),

    );
  }

  // ── Stats Card ─────────────────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(

            Row(
              children: [
                const Icon(Icons.storage_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Storage Management', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.border, color: AppColors.primary, minHeight: 4),
            ),
            const SizedBox(height: 4),
            Text('$_projectsCount Projects / $_diagramsCount Diagrams', style: const TextStyle(fontSize: AppSizes.fontXs, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTileItem({required IconData icon, required String label, Widget? trailing, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSizes.sm),
            Expanded(child: Text(label, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textPrimary))),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({required String label, required bool value, required ValueChanged<bool> onChanged, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: AppSizes.sm)],
          Expanded(child: Text(label, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textPrimary))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ],
      ),
    );
  }

  Widget _buildIntegrationIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: AppSizes.fontXs, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildDangerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.error),
            const SizedBox(width: AppSizes.sm),
            Text(label, style: const TextStyle(fontSize: AppSizes.fontSm, color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Center(child: Text('Sign Out', style: TextStyle(fontSize: AppSizes.fontSm, color: Colors.white, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildSupportLink({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppSizes.radiusSm), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: AppSizes.fontXs, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSizes.screenPadding, AppSizes.md, AppSizes.screenPadding, MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSizes.lg),
            const Text('Edit Profile', style: TextStyle(fontSize: AppSizes.fontXl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: AppSizes.lg),
            TextField(controller: nameController, style: const TextStyle(color: AppColors.textPrimary), decoration: _fieldDecoration('Full name')),
            const SizedBox(height: AppSizes.md),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.textPrimary), decoration: _fieldDecoration('Email')),
            const SizedBox(height: AppSizes.xl),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))), child: const Text('Cancel'))),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _client.put('/user/profile', data: {'name': nameController.text.trim(), 'email': emailController.text.trim()});
                        setState(() { _name = nameController.text.trim(); _email = emailController.text.trim(); });
                        if (mounted) Navigator.pop(ctx);
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: const Text('Delete Account', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure? This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))), child: const Text('Delete')),
        ],
      ),
    );
  }
}