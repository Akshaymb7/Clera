import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';

enum _FeedbackType { bug, feature, general }

extension _FeedbackTypeX on _FeedbackType {
  String get label => switch (this) {
    _FeedbackType.bug     => '🐛  Bug report',
    _FeedbackType.feature => '💡  Feature request',
    _FeedbackType.general => '💬  General',
  };
  String get apiValue => switch (this) {
    _FeedbackType.bug     => 'bug',
    _FeedbackType.feature => 'feature',
    _FeedbackType.general => 'general',
  };
}

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  _FeedbackType _type = _FeedbackType.general;
  int _rating = 0;
  final _controller = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).sendFeedback(
        comment: text,
        type: _type.apiValue,
        rating: _rating > 0 ? _rating : null,
      );
      setState(() { _sent = true; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send — please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            SSTopBar(
              title: 'Send feedback',
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: _sent ? _SuccessView(dark: dark, brand: brand) : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SSSectionLabel('Type'),
                    const SizedBox(height: 10),
                    SSCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: _FeedbackType.values.map((t) {
                          final last = t == _FeedbackType.general;
                          return GestureDetector(
                            onTap: () => setState(() => _type = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: last ? null : Border(
                                  bottom: BorderSide(color: dark ? SSColors.lineDark : SSColors.line),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.label,
                                      style: TextStyle(
                                        fontFamily: SSTypography.bodyFamily,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: dark ? SSColors.inkDark : SSColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (_type == t)
                                    Icon(Icons.check_circle_rounded, size: 18, color: brand),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 22),
                    const SSSectionLabel('Rating (optional)'),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 32,
                              color: filled ? const Color(0xFFD6A443) : (dark ? SSColors.lineDark : SSColors.line),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 22),
                    const SSSectionLabel('Message'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      maxLines: 6,
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 15,
                        color: dark ? SSColors.inkDark : SSColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: _type == _FeedbackType.bug
                            ? 'Describe what happened and what you expected…'
                            : _type == _FeedbackType.feature
                                ? 'What would you like Clera to do?'
                                : 'Tell us what you think…',
                        hintStyle: TextStyle(color: dark ? SSColors.mutedDark : SSColors.muted),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _loading
                        ? Center(child: CircularProgressIndicator(color: brand))
                        : SSPrimaryButton(
                            label: 'Send feedback',
                            onTap: _submit,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.dark, required this.brand});
  final bool dark;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: brand.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 36, color: brand),
            ),
            const SizedBox(height: 20),
            Text(
              'Thanks for the feedback!',
              style: SSTypography.headline.copyWith(color: dark ? SSColors.inkDark : SSColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We read every message and use it to improve Clera.',
              style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SSGhostButton(label: 'Back to Settings', onTap: () => context.pop()),
          ],
        ),
      ),
    );
  }
}
