import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_repository.dart';
import '../data/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) strength++;
    return strength;
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.accent;
      case 4:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authRepository.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
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
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final strength = _getPasswordStrength(password);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back Button ──
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: AppSizes.iconSm,
                  ),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSizes.lg),

                // ── Title ──
                const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: AppSizes.fontXxl,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                const Text(
                  'Start building diagrams in minutes',
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSizes.xl),

                // ── Fields ──
                AppTextField(
                  label: 'Full name',
                  hint: 'Jane Doe',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Name is required';
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.md),

                AppTextField(
                  label: 'Email',
                  hint: 'jane@example.com',
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

                // ── Password + Strength ──
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

                if (password.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: List.generate(4, (i) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < strength
                                ? _strengthColor(strength)
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _strengthLabel(strength),
                    style: TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: _strengthColor(strength),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.xl),

                // ── Register Button ──
                AppButton(
                  label: 'Create account',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSizes.lg),

                // ── Terms ──
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.textTertiary,
                      ),
                      children: [
                        TextSpan(text: 'By signing up, you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.lg),

                // ── Login Link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontMd,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign in',
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
}
