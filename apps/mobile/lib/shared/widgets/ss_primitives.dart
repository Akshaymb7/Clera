import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'score_ring.dart';

// ─── SSCard ───────────────────────────────────────────────────────────────────

class SSCard extends StatelessWidget {
  const SSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = SSRadius.borderLg,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? SSColors.surfaceDark : SSColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: dark ? SSColors.lineDark : SSColors.line,
        ),
        boxShadow: dark
            ? null
            : elevated
            ? [
                BoxShadow(
                  color: const Color(0xFF12130F).withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF12130F).withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ─── SSChip ───────────────────────────────────────────────────────────────────

class SSChip extends StatelessWidget {
  const SSChip({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? (dark ? SSColors.forestDark : SSColors.forest)
        : (dark ? SSColors.surfaceDark : SSColors.surface);
    final fg = selected
        ? Colors.white
        : (dark ? SSColors.ink2Dark : SSColors.ink2);
    final border = selected
        ? (dark ? SSColors.forestDark : SSColors.forest)
        : (dark ? SSColors.lineDark : SSColors.line);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SSRadius.borderFull,
        border: Border.all(color: border),
        boxShadow:
            (!selected && !dark)
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: SSTypography.bodyFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── SSPrimaryButton ─────────────────────────────────────────────────────────

class SSPrimaryButton extends StatelessWidget {
  const SSPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.fullWidth = true,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;
    final brandDarker = dark
        ? const Color(0xFF5A9A6E)
        : const Color(0xFF152B1E);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [brand, brandDarker],
          ),
          borderRadius: SSRadius.borderMd,
          boxShadow: dark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: brand.withOpacity(0.33),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              label,
              style: const TextStyle(
                fontFamily: SSTypography.bodyFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SSGhostButton ────────────────────────────────────────────────────────────

class SSGhostButton extends StatelessWidget {
  const SSGhostButton({super.key, required this.label, this.onTap, this.fullWidth = true});

  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: SSRadius.borderMd,
          border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: SSTypography.bodyFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: dark ? SSColors.inkDark : SSColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─── SSIconButton ─────────────────────────────────────────────────────────────

class SSIconBtn extends StatelessWidget {
  const SSIconBtn({super.key, required this.icon, this.onTap, this.size = 36});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: dark ? SSColors.surfaceDark : SSColors.surface,
          borderRadius: SSRadius.borderSm,
          border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF12130F).withOpacity(0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Icon(icon, size: 18, color: dark ? SSColors.inkDark : SSColors.ink),
      ),
    );
  }
}

// ─── SSTopBar ─────────────────────────────────────────────────────────────────

class SSTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SSTopBar({
    super.key,
    this.title,
    this.leading,
    this.trailing,
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: leading ?? const SizedBox.shrink(),
          ),
          Expanded(
            child: Center(
              child: title != null
                  ? Text(
                      title!,
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: dark ? SSColors.inkDark : SSColors.ink,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SSSectionLabel ───────────────────────────────────────────────────────────

class SSSectionLabel extends StatelessWidget {
  const SSSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: SSTypography.monoFamily,
        fontSize: 10.5,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w500,
        color: dark ? SSColors.mutedDark : SSColors.muted,
      ),
    );
  }
}

// ─── SSMainScaffold (with bottom tab bar) ─────────────────────────────────────

enum SSTab { scan, history, profile }

class SSMainScaffold extends StatelessWidget {
  const SSMainScaffold({
    super.key,
    required this.body,
    required this.currentTab,
    required this.onTabTap,
  });

  final Widget body;
  final SSTab currentTab;
  final ValueChanged<SSTab> onTabTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: body,
      bottomNavigationBar: _SSTabBar(
        current: currentTab,
        onTap: onTabTap,
        dark: dark,
      ),
    );
  }
}

class _SSTabBar extends StatelessWidget {
  const _SSTabBar({
    required this.current,
    required this.onTap,
    required this.dark,
  });

  final SSTab current;
  final ValueChanged<SSTab> onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xD90B0B0E)
              : const Color(0xD9FFFFFF),
          border: Border(
            top: BorderSide(
              color: dark ? SSColors.lineDark : SSColors.line,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: SSTab.values.map((tab) {
              final on = tab == current;
              final brand = dark ? SSColors.forestDark : SSColors.forest;
              final color = on ? brand : (dark ? SSColors.mutedDark : SSColors.muted);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(tab),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_tabIcon(tab), size: 22, color: color),
                      const SizedBox(height: 4),
                      Text(
                        _tabLabel(tab),
                        style: TextStyle(
                          fontFamily: SSTypography.bodyFamily,
                          fontSize: 10.5,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.3,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static IconData _tabIcon(SSTab t) => switch (t) {
    SSTab.scan => Icons.camera_alt_outlined,
    SSTab.history => Icons.history,
    SSTab.profile => Icons.person_outline,
  };

  static String _tabLabel(SSTab t) => switch (t) {
    SSTab.scan => 'Scan',
    SSTab.history => 'History',
    SSTab.profile => 'Profile',
  };
}

// ─── RiskCard ─────────────────────────────────────────────────────────────────

class RiskCard extends StatelessWidget {
  const RiskCard({
    super.key,
    required this.band,
    required this.name,
    required this.hint,
    this.onTap,
  });

  final ScoreBand band;
  final String name;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final softColor = band.softColor(dark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? SSColors.surfaceDark : SSColors.surface,
          borderRadius: SSRadius.borderMd,
          border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF12130F).withOpacity(0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: SSRadius.borderXs,
                ),
                child: Center(
                  child: BandIcon(band: band, size: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: dark ? SSColors.inkDark : SSColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hint,
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 12.5,
                        color: dark ? SSColors.mutedDark : SSColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: dark ? SSColors.mutedDark : SSColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PersonalizationFlag ──────────────────────────────────────────────────────

class PersonalizationFlag extends StatelessWidget {
  const PersonalizationFlag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = dark ? SSColors.accentDark : SSColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: dark
            ? SSColors.accent.withOpacity(0.15)
            : const Color(0xFFFBE9DF),
        borderRadius: SSRadius.borderFull,
        border: Border.all(
          color: dark
              ? SSColors.accent.withOpacity(0.3)
              : const Color(0xFFF3D0BC),
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: SSColors.accent.withOpacity(0.08),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 12, color: accentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: SSTypography.bodyFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ScoreChip (for history rows) ────────────────────────────────────────────

class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final band = bandFromScore(score);
    final color = band.color(dark);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.44),
          colors: [
            color.withOpacity(0.87),
            color,
            Color.lerp(color, Colors.black, 0.15)!,
          ],
          stops: const [0, 0.6, 1],
        ),
        borderRadius: SSRadius.borderSm,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.27),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            fontFamily: SSTypography.displayFamily,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.4,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

