import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/pattern_background.dart';
import 'main_screen.dart';

/// Uygulama girişi: e-posta/şifre, Google veya misafir olarak devam.
/// [popOnDone] true ise (profilden açıldığında) başarılı girişte sadece kapanır.
class AuthScreen extends StatefulWidget {
  final bool popOnDone;
  const AuthScreen({super.key, this.popOnDone = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // Google dönüşü gibi dışarıdan açılan oturumları yakalar
    _sub = AuthService.changes.listen((s) {
      if (s.session != null) {
        AuthService.syncProfile();
        _done();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _finished = false;
  void _done() {
    if (!mounted || _finished) return;
    _finished = true;
    if (widget.popOnDone) {
      Navigator.of(context).pop();
    } else {
      _guest();
    }
  }

  void _guest() {
    if (widget.popOnDone) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final en = context.isEn;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        final ok = await AuthService.signUp(
          _email.text,
          _password.text,
          _name.text,
        );
        if (!ok && mounted) {
          setState(() {
            _register = false;
            _error = context.t('auth_confirm_mail');
          });
        }
      } else {
        await AuthService.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e, en));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    final en = context.isEn;
    setState(() => _error = null);
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e, en));
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.chipBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.chipBorder),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.popOnDone)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48),
                      const LangToggle(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(child: AppLogo(size: 96)),
                  const SizedBox(height: 18),
                  Text(
                    _register
                        ? context.t('auth_register')
                        : context.t('auth_login'),
                    textAlign: TextAlign.center,
                    style: AppTheme.displayLarge.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('auth_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        context.t('auth_name'),
                        Icons.person_outline,
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? context.t('auth_err_name')
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: _dec(
                      context.t('auth_email'),
                      Icons.mail_outline,
                    ),
                    validator: (v) =>
                        RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(v?.trim() ?? '')
                        ? null
                        : context.t('auth_err_email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration:
                        _dec(
                          context.t('auth_password'),
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                    validator: (v) => (v == null || v.length < 6)
                        ? context.t('auth_err_password')
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.ciniBordeaux,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _register
                                ? context.t('auth_register')
                                : context.t('auth_login'),
                          ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          context.t('auth_or'),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _google,
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    label: Text(context.t('auth_google')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: AppColors.chipBorder),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() {
                      _register = !_register;
                      _error = null;
                    }),
                    child: Text(
                      _register
                          ? context.t('auth_have_account')
                          : context.t('auth_no_account'),
                    ),
                  ),
                  if (!widget.popOnDone)
                    TextButton(
                      onPressed: _guest,
                      child: Text(
                        context.t('auth_guest'),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
