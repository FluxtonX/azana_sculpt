import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_auth_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent! Check your email.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your email address and we will send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // ── Email Field ──────────────────────────────────────────
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 18, right: 10),
                      child: Icon(Icons.mail_outline_rounded, color: AppTheme.textLight, size: 20),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 50, minHeight: 56),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // ── Send Link Button ───────────────────────────────────────
              AnimatedAuthButton(
                text: 'Send Reset Link',
                isLoading: _isLoading,
                onTap: _handleResetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
