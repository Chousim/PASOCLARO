import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shared mobile-first layout container enforcing DESIGN.md rules:
/// - Mandatory 16px horizontal side margins
/// - Clean vertical safe area with zero horizontal overflow
class MobileScreenPadding extends StatelessWidget {
  const MobileScreenPadding({
    super.key,
    required this.child,
    this.top = 12,
    this.bottom = 20,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
      child: child,
    );
  }
}

/// Clean geometric PasoClaro brand mark (bridge icon + wordmark).
class PasoClaroBrandMark extends StatelessWidget {
  const PasoClaroBrandMark({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.agaveMist,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.route_outlined,
            color: AppColors.agaveJade,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'PasoClaro',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTheme.heading(fontSize, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Compact offline readiness pill using JetBrains Mono.
class OfflineStatusPill extends StatelessWidget {
  const OfflineStatusPill({
    super.key,
    required this.label,
    this.highContrast = false,
  });

  final String label;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.agaveMist,
        borderRadius: BorderRadius.circular(999),
        border: highContrast
            ? Border.all(color: AppColors.agaveDeep, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.agaveJade,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTheme.mono(
                11.5,
                weight: FontWeight.w600,
                color: AppColors.agaveDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary tactile CTA button (flat, no neon glow, minimum 54px height).
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.subtitle,
    this.backgroundColor = AppColors.agaveJade,
    this.minHeight = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? subtitle;
  final Color backgroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bgColor = enabled ? backgroundColor : AppColors.softStone;
    final fgColor = enabled ? AppColors.purePaper : AppColors.mutedMeta;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: enabled
                ? null
                : Border.all(color: AppColors.whisperBorder, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fgColor, size: 22),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: subtitle != null
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTheme.heading(
                        subtitle != null ? 20 : 16,
                        weight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTheme.body(
                          14,
                          color: fgColor.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// High-visibility secondary tactile button with crisp Agave Jade outline
/// and clear muted disabled state when [onPressed] is null.
class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minHeight = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bgColor = enabled ? AppColors.purePaper : AppColors.softStone;
    final borderColor =
        enabled ? AppColors.agaveJade : AppColors.whisperBorder;
    final fgColor = enabled ? AppColors.agaveJade : AppColors.mutedMeta;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: enabled ? 1.8 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.heading(
                    16,
                    weight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: fgColor, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Surface card with Whisper Border & diffused ambient shadow.
class PasoClaroCard extends StatelessWidget {
  const PasoClaroCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.selected = false,
    this.highContrast = false,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool selected;
  final bool highContrast;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (selected ? AppColors.agaveMist : AppColors.purePaper);
    final borderColor = selected
        ? AppColors.agaveJade
        : (highContrast ? AppColors.charcoalInk : AppColors.whisperBorder);
    final borderWidth = (selected || highContrast) ? 2.0 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: selected || highContrast
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D18181B),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
