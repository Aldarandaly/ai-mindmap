import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/auth_repository.dart';
import '../../../shared/widgets/network_background.dart';
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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    
    super.dispose();
  }

  int _getPasswordStrength(String password) {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) s++;
    return s;
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return AppColors.accent;
      case 4: return AppColors.success;
      default: return Colors.white24;
    }
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 1: return 'Weak password';
      case 2: return 'Fair password';
      case 3: return 'Good password';
      case 4: return 'Strong password';
      default: return '';
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
    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created!'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final strength = _getPasswordStrength(password);

    return Scaffold(
      body: NetworkBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back button ───────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Logo ─────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── App name ──────────────────────────
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mind',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: 'Map',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Sign In to your account',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Full name ─────────────────────────
                  _buildLabel('Full name'),
                  const SizedBox(height: 8),
                  _buildGlassField(
                    controller: _nameController,
                    hint: 'Jane Doe',
                    icon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Email ─────────────────────────────
                  _buildLabel('Email'),
                  const SizedBox(height: 8),
                  _buildGlassField(
                    controller: _emailController,
                    hint: 'jane@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  _buildGlassField(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textTertiary, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),

                  // ── Password strength ─────────────────
                  if (password.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(4, (i) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < strength ? _strengthColor(strength) : Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _strengthLabel(strength),
                      style: TextStyle(
                        fontSize: 11,
                        color: _strengthColor(strength),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Create account button ─────────────
                  _buildGradientButton(
                    label: 'Create account',
                    onPressed: _isLoading ? null : _register,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 20),

                  // ── Terms ─────────────────────────────
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                        children: const [
                          TextSpan(text: 'By signing up, you agree to our '),
                          TextSpan(text: 'Terms', style: TextStyle(color: AppColors.accent)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Login link ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}