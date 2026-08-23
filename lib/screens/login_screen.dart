import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/services/auth_service.dart';
import 'package:med_intel/screens/register_screen.dart';
import 'package:med_intel/screens/forgot_password_screen.dart';
import 'package:med_intel/screens/main_navigation.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePass = true;

  late final AnimationController _headerAnim;
  late final AnimationController _formAnim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _formAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _formAnim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formAnim, curve: Curves.easeOutCubic));
    _formAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _formAnim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted || user == null) return; // null = user cancelled the flow
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Animated Header ─────────────────
          _AnimatedHeader(controller: _headerAnim, l10n: l10n),

          // ── Form Area ───────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.loginWelcomeBack, style: AppTextStyles.displaySmall),
                        const SizedBox(height: 6),
                        Text(
                          l10n.loginSubtitle,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 28),

                        AppTextField(
                          label: l10n.loginEmailLabel,
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return l10n.loginEmailRequired;
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                            ).hasMatch(v.trim()))
                              return l10n.loginEmailInvalid;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          label: l10n.commonPassword,
                          controller: _passCtrl,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePass,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? l10n.loginPasswordRequired
                              : null,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              l10n.loginForgotPassword,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        AppPrimaryButton(
                          label: l10n.loginSignIn,
                          onPressed: _isLoading ? null : _login,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 28),

                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(l10n.commonOr, style: AppTextStyles.bodySmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),

                        GoogleSignInButton(
                          label: l10n.loginContinueWithGoogle,
                          isLoading: _isGoogleLoading,
                          onPressed: (_isLoading || _isGoogleLoading)
                              ? null
                              : _loginWithGoogle,
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyMedium,
                              children: [
                                TextSpan(text: l10n.loginNoAccount),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.commonSignUp,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary,
                                      ),
                                    ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Header Widget ──────────────────────
class _AnimatedHeader extends StatelessWidget {
  final AnimationController controller;
  final AppLocalizations l10n;
  const _AnimatedHeader({required this.controller, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final t = controller.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(t * 2 * math.pi),
                      math.sin(t * 2 * math.pi),
                    ),
                    end: Alignment(
                      -math.cos(t * 2 * math.pi),
                      -math.sin(t * 2 * math.pi),
                    ),
                    colors: const [
                      Color(0xFF1E40AF),
                      Color(0xFF2563EB),
                      Color(0xFF0EA47D),
                    ],
                  ),
                ),
              );
            },
          ),

          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),

          // Logo + title centered
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MedIntel logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.5),
                      child: Image.asset(
                        'assets/images/logo_mark.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Med Intel',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.loginTagline,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
