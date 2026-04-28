import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routing/router.dart';
import '../../../shared/widgets/ss_primitives.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  int _birthYear = DateTime.now().year - 30;
  String _gender = 'prefer_not_to_say';
  bool _healthExpanded = false;
  final Set<String> _allergies = {};
  bool _pregnant = false;
  bool _loading = false;
  String? _error;

  static const _genders = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('non_binary', 'Non-binary'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  static const _allergyOptions = [
    'Peanuts', 'Tree nuts', 'Dairy', 'Gluten', 'Eggs',
    'Soy', 'Shellfish', 'Fish',
  ];

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final age = DateTime.now().year - _birthYear;
      final profileJson = <String, dynamic>{
        if (_allergies.isNotEmpty) 'allergies': _allergies.toList(),
        if (_pregnant) 'pregnant': true,
      };
      await ref.read(apiClientProvider).upsertMe({
        'name': name,
        'age': age,
        'gender': _gender,
        if (profileJson.isNotEmpty) 'profileJson': profileJson,
      });
      ref.read(profileCompleteProvider.notifier).state = true;
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _loading = false; _error = 'Failed to save. Please try again.'; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            SSTopBar(
              title: 'Your profile',
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Tell us a little about yourself.',
                      style: SSTypography.title.copyWith(
                        color: dark ? SSColors.inkDark : SSColors.ink,
                      ),
                    ),
                    Text(
                      'We use this to surface relevant flags — never shared.',
                      style: SSTypography.body.copyWith(
                        color: dark ? SSColors.mutedDark : SSColors.muted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _FieldLabel('NAME', dark: dark),
                    const SizedBox(height: 6),
                    _InsetInput(
                      controller: _nameController,
                      hint: 'Your name',
                      dark: dark,
                    ),

                    const SizedBox(height: 20),
                    _FieldLabel('BIRTH YEAR', dark: dark),
                    const SizedBox(height: 6),
                    _YearPicker(
                      year: _birthYear,
                      dark: dark,
                      onChanged: (y) => setState(() => _birthYear = y),
                    ),

                    const SizedBox(height: 20),
                    _FieldLabel('GENDER', dark: dark),
                    const SizedBox(height: 6),
                    SSCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: _genders.asMap().entries.map((e) {
                          final i = e.key;
                          final (value, label) = e.value;
                          final selected = _gender == value;
                          return GestureDetector(
                            onTap: () => setState(() => _gender = value),
                            child: Container(
                              decoration: BoxDecoration(
                                border: i < _genders.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: dark ? SSColors.lineDark : SSColors.line,
                                        ),
                                      )
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontFamily: SSTypography.bodyFamily,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: dark ? SSColors.inkDark : SSColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? (dark ? SSColors.forestDark : SSColors.forest)
                                            : (dark ? SSColors.lineDark : SSColors.line),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: selected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: dark
                                                    ? SSColors.forestDark
                                                    : SSColors.forest,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Health context accordion
                    GestureDetector(
                      onTap: () => setState(() => _healthExpanded = !_healthExpanded),
                      child: SSCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health context',
                                    style: TextStyle(
                                      fontFamily: SSTypography.bodyFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: dark ? SSColors.inkDark : SSColors.ink,
                                    ),
                                  ),
                                  Text(
                                    'Optional · allergies, pregnancy, conditions',
                                    style: TextStyle(
                                      fontFamily: SSTypography.bodyFamily,
                                      fontSize: 12.5,
                                      color: dark ? SSColors.mutedDark : SSColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _healthExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: dark ? SSColors.mutedDark : SSColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_healthExpanded) ...[
                      const SizedBox(height: 10),
                      SSCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALLERGIES',
                              style: SSTypography.mono.copyWith(
                                color: dark ? SSColors.mutedDark : SSColors.muted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allergyOptions.map((a) {
                                final on = _allergies.contains(a);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (on) _allergies.remove(a);
                                    else _allergies.add(a);
                                  }),
                                  child: SSChip(label: a, selected: on),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Currently pregnant',
                                    style: TextStyle(
                                      fontFamily: SSTypography.bodyFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: dark ? SSColors.inkDark : SSColors.ink,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _pregnant,
                                  onChanged: (v) => setState(() => _pregnant = v),
                                  activeColor: dark ? SSColors.forestDark : SSColors.forest,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          fontFamily: SSTypography.bodyFamily,
                          fontSize: 13,
                          color: dark ? SSColors.avoidDark : SSColors.avoid,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SSPrimaryButton(
                      label: _loading ? 'Saving…' : 'Continue',
                      onTap: _loading ? null : _save,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.dark});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: SSTypography.monoFamily,
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w500,
      color: dark ? SSColors.mutedDark : SSColors.muted,
    ),
  );
}

class _InsetInput extends StatelessWidget {
  const _InsetInput({
    required this.controller,
    required this.hint,
    required this.dark,
  });

  final TextEditingController controller;
  final String hint;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0E0F11) : const Color(0xFFF2ECDC),
        borderRadius: SSRadius.borderSm,
        border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withOpacity(0.5)
                : const Color(0xFF123C24).withOpacity(0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: SSTypography.bodyFamily,
          fontSize: 15,
          color: dark ? SSColors.inkDark : SSColors.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: SSTypography.bodyFamily,
            fontSize: 15,
            color: dark ? SSColors.mutedDark : SSColors.muted,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _YearPicker extends StatelessWidget {
  const _YearPicker({
    required this.year,
    required this.dark,
    required this.onChanged,
  });

  final int year;
  final bool dark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(100, (i) => currentYear - i);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0E0F11) : const Color(0xFFF2ECDC),
        borderRadius: SSRadius.borderSm,
        border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withOpacity(0.5)
                : const Color(0xFF123C24).withOpacity(0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          isExpanded: true,
          style: TextStyle(
            fontFamily: SSTypography.bodyFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: dark ? SSColors.inkDark : SSColors.ink,
          ),
          dropdownColor: dark ? SSColors.surfaceDark : SSColors.surface,
          items: years
              .map(
                (y) => DropdownMenuItem(
                  value: y,
                  child: Text('$y'),
                ),
              )
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}
