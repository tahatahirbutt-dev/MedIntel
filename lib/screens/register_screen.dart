import 'package:flutter/material.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/services/auth_service.dart';
import 'package:med_intel/screens/login_screen.dart';
import 'package:med_intel/screens/main_navigation.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/widgets/google_sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack(
        l10n.registerAcceptTerms,
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.register(
        _emailCtrl.text,
        _passCtrl.text,
        _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      _showSnack(l10n.registerAccountCreated);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
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
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            slivers: [
              // ── Compact App Bar ──────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E40AF), Color(0xFF0EA47D)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              l10n.registerCreateAccount,
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.registerSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Form ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: l10n.registerFullName,
                          hint: l10n.registerFullNameHint,
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.registerNameRequired
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: l10n.registerEmailLabel,
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return l10n.registerEmailRequired;
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                            ).hasMatch(v.trim()))
                              return l10n.registerEmailInvalid;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: l10n.commonPassword,
                          controller: _passCtrl,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePass,
                          suffix: _visibilityBtn(
                            _obscurePass,
                            () => setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return l10n.registerPasswordRequired;
                            if (v.length < 6) return l10n.registerPasswordMinLength;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: l10n.registerConfirmPassword,
                          controller: _confirmCtrl,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirm,
                          suffix: _visibilityBtn(
                            _obscureConfirm,
                            () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return l10n.registerConfirmPasswordRequired;
                            if (v != _passCtrl.text)
                              return l10n.registerPasswordMismatch;
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Terms checkbox
                        Container(
                          decoration: BoxDecoration(
                            color: _agreedToTerms
                                ? AppColors.primaryLight
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _agreedToTerms
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.border,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _agreedToTerms,
                            onChanged: (v) =>
                                setState(() => _agreedToTerms = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(text: l10n.registerAgreeToThe),
                                  TextSpan(
                                    text: l10n.registerTermsConditions,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primary,
                                    ),
                                  ),
                                  TextSpan(text: l10n.registerAnd),
                                  TextSpan(
                                    text: l10n.registerPrivacyPolicy,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        AppPrimaryButton(
                          label: l10n.registerCreateAccount,
                          onPressed: _isLoading ? null : _register,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),

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
                              : _registerWithGoogle,
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyMedium,
                              children: [
                                TextSpan(
                                  text: l10n.registerAlreadyHaveAccount,
                                ),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(
                                      l10n.loginSignIn,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _visibilityBtn(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(
      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      size: 20,
      color: AppColors.textMuted,
    ),
    onPressed: onTap,
  );
}
