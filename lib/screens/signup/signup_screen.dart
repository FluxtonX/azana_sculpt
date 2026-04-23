import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../widgets/animated_auth_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _termsAccepted = false;
  final String _selectedRole = 'client'; // Default to client

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms of Service and Privacy Policy',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential?.user != null) {
        // Create initial user profile in Firestore
        final newUser = UserModel(
          uid: userCredential!.user!.uid,
          email: _emailController.text.trim(),
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          createdAt: DateTime.now(),
        );
        await DatabaseService().saveUserProfile(newUser);

        if (mounted) {
          if (_selectedRole == 'coach') {
            Navigator.pushReplacementNamed(context, '/coach');
          } else {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Image ──────────────────────────────────────
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Background image
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent, // TOP bilkul clear
                      Colors.transparent, // mid bhi clear
                      Colors.white, // fade start
                    ],
                    stops: [0.0, 0.7, 1.0], // fade sirf last 30% me
                  ).createShader(rect),
                  blendMode: BlendMode.dstOut,
                  child: Image.asset(
                    'assets/images/signin.png',
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Logo icon sitting at the bottom of hero
                Positioned(
                  bottom: 0,
                  child: Column(
                    children: [
                      // Title
                      const Text(
                        'Create your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                    ],
                  ),
                ),
              ],
            ),

            // ── Form Area ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 6),
                  // Subtitle
                  const Text(
                    'Join KOR and start your fitness journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ── Full Name Field ──────────────────────────────────────
                  _buildInputField(
                    controller: _nameController,
                    hint: 'Full name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  // ── Email Field ─────────────────────────────────────────
                  _buildInputField(
                    controller: _emailController,
                    hint: 'Email address',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // ── Phone Field ─────────────────────────────────────────
                  _buildInputField(
                    controller: _phoneController,
                    hint: 'Phone number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // ── Create Password Field ────────────────────────────────
                  _buildInputField(
                    controller: _passwordController,
                    hint: 'Create password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                  ),
                  const SizedBox(height: 14),

                  // ── Confirm Password Field ───────────────────────────────
                  _buildInputField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                  ),
                  const SizedBox(height: 18),

                  // ── Terms Checkbox ───────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _termsAccepted = !_termsAccepted;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _termsAccepted
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _termsAccepted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "I agree to KOR's ",
                                    style: TextStyle(
                                      color: AppTheme.primary.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: TextStyle(
                                      color: AppTheme.primary.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Create Account Button ────────────────────────────────
                  AnimatedAuthButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onTap: _handleSignup,
                  ),
                  const SizedBox(height: 26),

                  // ── Sign In Link ─────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: AppTheme.textMedium.withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: AppTheme.textDark,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(prefixIcon, color: AppTheme.textLight, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 56,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
