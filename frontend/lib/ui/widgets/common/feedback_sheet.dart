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

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 22, 18 + inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('feedback_row'), style: AppTheme.titleLarge),
              const SizedBox(height: 6),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _cats)
                    ChoiceChip(
                      label: Text(context.t('fb_$c')),
                      selected: _cat == c,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryTealLight,
                      side: BorderSide(
                        color: _cat == c
                            ? AppColors.primaryTeal
                            : AppColors.primaryTeal.withValues(alpha: 0.25),
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _cat == c
                            ? AppColors.primaryTealDark
                            : AppColors.textDark,
                      ),
                      onSelected: (_) => setState(() => _cat = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _msg,
                minLines: 4,
                maxLines: 6,
                maxLength: 600,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.t('fb_hint'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                maxLength: 120,
                decoration: InputDecoration(
                  hintText: context.t('fb_contact'),
                  counterText: '',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  _sending ? context.t('fb_sending') : context.t('fb_send'),
                  onPressed: _msg.text.trim().length < 3 || _sending
                      ? null
                      : _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
