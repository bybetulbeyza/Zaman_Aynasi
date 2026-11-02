import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import 'app_toast.dart';
import 'pill_button.dart';

/// Geri bildirim formu: tür seç, mesaj yaz, isteğe bağlı e-posta bırak. Supabase'deki
/// `feedback_messages` tablosuna yalnızca eklenir. Bir eser sayfasından açılırsa eser otomatik eklenir.
class FeedbackSheet {
  static DateTime? _last;

  static Future<void> show(
    BuildContext context, {
    String? placeId,
    String? placeName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCanvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FeedbackForm(
        outerContext: context,
        placeId: placeId,
        placeName: placeName,
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  final BuildContext outerContext;
  final String? placeId;
  final String? placeName;
  const _FeedbackForm({
    required this.outerContext,
    this.placeId,
    this.placeName,
  });

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  static const _cats = ['bug', 'idea', 'content', 'thanks'];
  String _cat = 'idea';
  final _msg = TextEditingController();
  final _contact = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msg.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (text.length < 3 || _sending) return;
    final last = FeedbackSheet._last;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 20)) {
      AppToast.show(
        context,
        context.t('fb_wait'),
        icon: Icons.hourglass_top_rounded,
      );
      return;
    }
    setState(() => _sending = true);
    final outer = widget.outerContext;
    final ok = await _insert(text);
    if (!mounted) return;
    if (ok) {
      FeedbackSheet._last = DateTime.now();
      Navigator.pop(context);
      if (outer.mounted) AppToast.show(outer, outer.t('fb_sent'));
    } else {
      setState(() => _sending = false);
      AppToast.show(
        context,
        context.t('fb_failed'),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<bool> _insert(String text) async {
    try {
      final contact = _contact.text.trim();
      await Supabase.instance.client.from('feedback_messages').insert({
        'category': _cat,
        'message': text,
        'contact': contact.isEmpty ? null : contact,
        'place_id': widget.placeId,
        'device_id': Analytics.instance.deviceId,
        'lang': context.isEn ? 'en' : 'tr',
      });
      return true;
    } catch (e) {
      debugPrint('feedback: $e');
      return false;
    }
  }

  static const _icons = {
    'bug': Icons.bug_report_outlined,
    'idea': Icons.lightbulb_outline_rounded,
    'content': Icons.edit_note_rounded,
    'thanks': Icons.favorite_border_rounded,
  };

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: c, width: w),
  );

  InputDecoration _decoration(String hint, {Widget? prefix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    counterText: '',
    prefixIcon: prefix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: _border(AppColors.chipBorder),
    enabledBorder: _border(AppColors.chipBorder),
    focusedBorder: _border(AppColors.primaryTeal, 1.6),
  );

  Widget _category(String c) {
    final on = _cat == c;
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        label: context.t('fb_$c'),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _cat = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: on ? AppColors.primaryTealLight : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? AppColors.primaryTeal : AppColors.chipBorder,
                width: on ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icons[c],
                  size: 22,
                  color: on ? AppColors.primaryTeal : AppColors.textMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('fb_$c'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.15,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    color: on ? AppColors.primaryTealDark : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final canSend = _msg.text.trim().length >= 3 && !_sending;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 10, 22, 18 + inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('feedback_row'),
                      style: AppTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: context.t('acc_cancel'),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              Text(
                widget.placeName != null
                    ? context
                          .t('fb_about_place')
                          .replaceAll('{name}', widget.placeName!)
                    : context.t('fb_sub'),
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < _cats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _category(_cats[i]),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _msg,
                minLines: 4,
                maxLines: 6,
                maxLength: 600,
                cursorColor: AppColors.primaryTeal,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(context.t('fb_hint_$_cat')),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4, bottom: 10),
                  child: Text(
                    '${_msg.text.length}/600',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                maxLength: 120,
                cursorColor: AppColors.primaryTeal,
                decoration: _decoration(
                  context.t('fb_contact'),
                  prefix: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  _sending ? context.t('fb_sending') : context.t('fb_send'),
                  onPressed: canSend ? _send : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
