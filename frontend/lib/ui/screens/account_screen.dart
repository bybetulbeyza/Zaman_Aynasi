import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/pill_button.dart';

/// Giriş yapmış kullanıcının hesap sayfası: ad düzenleme, hesap bilgileri ve en altta çıkış.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _name = TextEditingController(
    text: AuthService.displayName,
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim().isNotEmpty &&
      _name.text.trim() != AuthService.displayName;

  Future<void> _save() async {
    if (!_dirty || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AuthService.updateName(_name.text);
      if (!mounted) return;
      AppToast.show(context, context.t('acc_saved'));
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        context.t('acc_save_failed'),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(ctx.t('acc_signout_q')),
        content: Text(ctx.t('acc_signout_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('acc_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ciniBordeaux,
            ),
            child: Text(ctx.t('auth_signout')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = Navigator.of(context);
    final toastContext = messenger.context;
    await AuthService.signOut();
    if (!mounted) return;
    messenger.pop();
    if (toastContext.mounted) {
      AppToast.show(
        toastContext,
        toastContext.t('acc_signed_out'),
        icon: Icons.logout_rounded,
      );
    }
  }

  String _date(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.displayName;
    final avatar = AuthService.avatarUrl;
    final google = AuthService.provider == 'google';
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Row(
                      children: [
                        const AppBackButton(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.t('acc_title'),
                            style: AppTheme.displayLarge.copyWith(fontSize: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primaryTeal,
                        backgroundImage: avatar != null
                            ? NetworkImage(avatar)
                            : null,
                        onBackgroundImageError: avatar != null
                            ? (_, _) {}
                            : null,
                        child: avatar == null
                            ? Text(
                                name.isEmpty ? '?' : name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _label(context.t('acc_name')),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      onChanged: (_) => setState(() {}),
                      decoration: _field(),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: PillButton(
                        context.t('acc_save'),
                        onPressed: _dirty && !_saving ? _save : null,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _info(
                      context.t('acc_email'),
                      AuthService.user?.email ?? '—',
                    ),
                    _info(
                      context.t('acc_method'),
                      google
                          ? context.t('acc_method_google')
                          : context.t('acc_method_email'),
                    ),
                    _info(context.t('acc_since'), _date(AuthService.createdAt)),
                  ],
                ),
              ),
              // Çıkış en altta
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmSignOut,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(context.t('auth_signout')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ciniBordeaux,
                      side: const BorderSide(color: AppColors.ciniBordeaux),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    ),
  );

  InputDecoration _field() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: AppColors.chipBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: AppColors.chipBorder),
    ),
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.chipBorder),
  );

  Widget _info(String label, String value) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    decoration: _card(),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}
