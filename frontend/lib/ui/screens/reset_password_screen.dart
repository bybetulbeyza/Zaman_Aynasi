import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/pill_button.dart';

/// E-postadaki "şifre sıfırla" bağlantısından açılır: yeni şifre belirlenir.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    final toastCtx = nav.context;
    try {
      await AuthService.updatePassword(_pw.text);
      if (!mounted) return;
      nav.pop();
      if (toastCtx.mounted) {
        AppToast.show(toastCtx, toastCtx.t('reset_done'));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AuthService.friendlyError(e, context.isEn);
        });
      }
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    prefixIcon: const Icon(Icons.lock_outline, size: 20),
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
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('reset_title'),
                    style: AppTheme.displayLarge.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t('reset_sub'),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _pw,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(context.t('reset_new')).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? context.t('auth_err_password')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pw2,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: _dec(context.t('reset_again')),
                    validator: (v) =>
                        v != _pw.text ? context.t('reset_mismatch') : null,
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
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      _busy ? context.t('fb_sending') : context.t('acc_save'),
                      onPressed: _busy ? null : _save,
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
