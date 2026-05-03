import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/auth_repository.dart';        // ← جديد
import '../data/auth_service.dart';           // ← جديد
import '../../projects/ui/projects_screen.dart'; // ← جديد
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  final result = await _authRepository.login(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );

  setState(() => _isLoading = false);

  if (result['success']) {
    await AuthService.saveToken(result['data']['token']);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectsScreen()),
      );
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.xxl),

                // ── Logo ──
                _buildLogo(),

                const SizedBox(height: AppSizes.xl),

                // ── Title ──
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: AppSizes.fontXxl,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSizes.xl),

                // ── Fields ──
                AppTextField(
                  label: 'Email',
                  hint: 'email@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.md),

                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Password is required';
                    if (val.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.sm),

                // ── Forgot Password ──
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: AppSizes.fontSm,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.md),

                // ── Login Button ──
                AppButton(
                  label: 'Sign in',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSizes.lg),

                // ── Divider ──
                _buildDivider(),

                const SizedBox(height: AppSizes.lg),

                // ── Google Button ──
                _buildGoogleButton(),

                const SizedBox(height: AppSizes.xl),

                // ── Register Link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontMd,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text(
                        'Create one',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppSizes.fontMd,
                          fontWeight: FontWeight.w600,
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
    );
  }

  // ── Helpers ──

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: const Center(
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: Text(
            'or',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: AppSizes.fontSm,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightSm,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // استبدل بصورة Google لو عندك
            const Icon(
              Icons.g_mobiledata,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.sm),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
