import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/pasoclaro_models.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pasoclaro_widgets.dart';

/// Bilingual Offline Checklist screen (Stitch-faithful 390x844 mobile layout).
///
/// Linguistic rule: Indigenous language cards (Yucatec Maya & Nahuatl) are
/// strictly TEXT-ONLY with zero audio/TTS buttons for linguistic accuracy.
class BilingualChecklistView extends StatelessWidget {
  const BilingualChecklistView({super.key, required this.appState});

  final PasoClaroAppState appState;

  String _languagePillLabel(AppLanguage language) {
    return switch (language) {
      AppLanguage.yucatecMaya => 'Maya Yucateco + Español',
      AppLanguage.nahuatl => 'Náhuatl + Español',
      AppLanguage.spanish => 'Español sencillo',
    };
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _showSnackBar(
          context,
          'Teléfono oficial: $phoneNumber (disponible sin internet).',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Teléfono oficial: $phoneNumber (disponible sin internet).',
        );
      }
    }
  }

  Future<void> _launchOfficialUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar(
        context,
        'No se pudo abrir el enlace oficial. Consulta el teléfono guardado.',
      );
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showSnackBar(
          context,
          'Sin conexión para abrir el sitio oficial. El horario y teléfono siguen disponibles aquí.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Sin conexión para abrir el sitio oficial. El horario y teléfono siguen disponibles aquí.',
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTheme.body(14, color: AppColors.purePaper),
          ),
          backgroundColor: AppColors.charcoalInk,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _showLanguagePicker(BuildContext context, bool isSenior) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.purePaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Idioma de la lista',
                  style: AppTheme.heading(isSenior ? 22 : 19),
                ),
                const SizedBox(height: 4),
                Text(
                  'Las guías en lengua indígena se muestran únicamente por escrito junto al español.',
                  style: AppTheme.body(
                    isSenior ? 16 : 14,
                    color: AppColors.graphiteSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                for (final lang in AppLanguage.values) ...[
                  _LanguageOptionTile(
                    title: _languagePillLabel(lang),
                    subtitle: lang.isIndigenousTextOnly
                        ? 'Solo texto escrito bilingüe'
                        : 'Explicación directa en español claro',
                    selected: appState.language == lang,
                    isSenior: isSenior,
                    onTap: () {
                      appState.selectLanguage(lang);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGuidePicker(BuildContext context, bool isSenior) {
    final guides = appState.guides;
    final activeId = appState.activeGuide.id;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.purePaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Guías guardadas sin internet',
                  style: AppTheme.heading(isSenior ? 22 : 19),
                ),
                const SizedBox(height: 12),
                for (final guide in guides) ...[
                  PasoClaroCard(
                    selected: guide.id == activeId,
                    highContrast: isSenior,
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    onTap: () {
                      appState.setActiveGuide(guide.id);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.agaveMist,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            guide.category.icon,
                            color: AppColors.agaveJade,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide.title,
                                style: AppTheme.heading(
                                  isSenior ? 18 : 16,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${guide.completedCount} de ${guide.items.length} listos',
                                style: AppTheme.mono(
                                  isSenior ? 12.5 : 11.5,
                                  color: AppColors.graphiteSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (guide.id == activeId)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.agaveJade,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final guide = appState.activeGuide;
        final isSenior = appState.isSeniorMode;
        final language = appState.language;
        final progress = guide.items.isEmpty
            ? 0.0
            : guide.completedCount / guide.items.length;

        return Scaffold(
          backgroundColor: AppColors.canvasAlabaster,
          body: SafeArea(
            child: SingleChildScrollView(
              child: MobileScreenPadding(
                top: 12,
                bottom: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopHeader(
                      title: guide.title,
                      isSenior: isSenior,
                      hasMultipleGuides: appState.guides.length > 1,
                      onBack: () => Navigator.maybePop(context),
                      onSwitchGuide: () => _showGuidePicker(context, isSenior),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _LanguageSwitcherPill(
                          label: _languagePillLabel(language),
                          isSenior: isSenior,
                          onTap: () => _showLanguagePicker(context, isSenior),
                        ),
                        OfflineStatusPill(
                          label: 'Guardado sin internet',
                          highContrast: isSenior,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ProgressRow(
                      progress: progress,
                      completedCount: guide.completedCount,
                      totalCount: guide.items.length,
                      isSenior: isSenior,
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < guide.items.length; i++) ...[
                      _BilingualChecklistCard(
                        item: guide.items[i],
                        language: language,
                        isSenior: isSenior,
                        onToggle: () => appState.toggleChecklistItem(
                          guide.id,
                          guide.items[i].id,
                        ),
                      ),
                      if (i < guide.items.length - 1)
                        const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    _OfficialChannelCard(
                      channel: guide.officialChannel,
                      isSenior: isSenior,
                      onCallPhone: () => _launchPhone(
                        context,
                        guide.officialChannel.phoneNumber,
                      ),
                      onOpenOfficialUrl: () => _launchOfficialUrl(
                        context,
                        guide.officialChannel.officialUrl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.isSenior,
    required this.hasMultipleGuides,
    required this.onBack,
    required this.onSwitchGuide,
  });

  final String title;
  final bool isSenior;
  final bool hasMultipleGuides;
  final VoidCallback onBack;
  final VoidCallback onSwitchGuide;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: AppColors.purePaper,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSenior
                      ? AppColors.charcoalInk
                      : AppColors.whisperBorder,
                  width: isSenior ? 2 : 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.charcoalInk,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.heading(
              isSenior ? 24 : 22,
              weight: FontWeight.w700,
              color: AppColors.charcoalInk,
            ),
          ),
        ),
        if (hasMultipleGuides) ...[
          const SizedBox(width: 8),
          Material(
            color: AppColors.softStone,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onSwitchGuide,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSenior
                        ? AppColors.charcoalInk
                        : AppColors.whisperBorder,
                    width: isSenior ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cambiar',
                      style: AppTheme.body(
                        isSenior ? 14 : 12.5,
                        weight: FontWeight.w600,
                        color: AppColors.charcoalInk,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.slateCharcoal,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LanguageSwitcherPill extends StatelessWidget {
  const _LanguageSwitcherPill({
    required this.label,
    required this.isSenior,
    required this.onTap,
  });

  final String label;
  final bool isSenior;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.purePaper,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSenior ? AppColors.charcoalInk : AppColors.strongBorder,
              width: isSenior ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate_rounded,
                size: 15,
                color: AppColors.agaveJade,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(
                    isSenior ? 14 : 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.charcoalInk,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.graphiteSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.isSenior,
  });

  final double progress;
  final int completedCount;
  final int totalCount;
  final bool isSenior;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: isSenior ? 8 : 6,
              backgroundColor: AppColors.whisperBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSenior ? AppColors.agaveDeep : AppColors.agaveJade,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$completedCount de $totalCount listos',
          style: AppTheme.mono(
            isSenior ? 13 : 12,
            weight: FontWeight.w600,
            color: AppColors.graphiteSecondary,
          ),
        ),
      ],
    );
  }
}

class _BilingualChecklistCard extends StatelessWidget {
  const _BilingualChecklistCard({
    required this.item,
    required this.language,
    required this.isSenior,
    required this.onToggle,
  });

  final BilingualChecklistItem item;
  final AppLanguage language;
  final bool isSenior;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSenior ? AppColors.charcoalInk : AppColors.whisperBorder;
    final borderWidth = isSenior ? 2.0 : 1.0;
    final checkColor = isSenior ? AppColors.agaveDeep : AppColors.agaveJade;
    final primaryTitle = item.titleForLanguage(language);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.purePaper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isSenior
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D18181B),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 - borderWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top band: Pure Paper, full-row 56px+ interactive tap target.
            // Strictly text-only — no audio/TTS controls on bilingual cards.
            Semantics(
              checked: item.isCompleted,
              button: true,
              label: primaryTitle,
              child: Material(
                color: AppColors.purePaper,
                child: InkWell(
                  onTap: onToggle,
                  child: Container(
                    constraints: BoxConstraints(minHeight: isSenior ? 64 : 56),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.agaveMist,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.iconType.icon,
                            color: AppColors.agaveJade,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            primaryTitle,
                            style: AppTheme.heading(
                              isSenior ? 20 : 17,
                              weight: FontWeight.w600,
                              color: AppColors.charcoalInk,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: item.isCompleted
                                ? checkColor
                                : AppColors.purePaper,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: item.isCompleted
                                  ? checkColor
                                  : (isSenior
                                      ? AppColors.charcoalInk
                                      : AppColors.strongBorder),
                              width: 2,
                            ),
                          ),
                          child: item.isCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.purePaper,
                                  size: 18,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom band: Soft Stone plain Spanish explanation + Gap Detector.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.softStone,
                border: Border(
                  top: BorderSide(color: AppColors.whisperBorder, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.descriptionSpanish,
                    style: AppTheme.body(
                      isSenior ? 17 : 14.5,
                      color: AppColors.slateCharcoal,
                      height: 1.45,
                    ),
                  ),
                  if (!item.isCompleted) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.brickWash,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.brickAlert,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.brickAlert,
                            size: isSenior ? 20 : 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.howToGetIfMissing,
                              style: AppTheme.body(
                                isSenior ? 16 : 13.5,
                                weight: FontWeight.w500,
                                color: AppColors.brickAlert,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialChannelCard extends StatelessWidget {
  const _OfficialChannelCard({
    required this.channel,
    required this.isSenior,
    required this.onCallPhone,
    required this.onOpenOfficialUrl,
  });

  final OfficialChannel channel;
  final bool isSenior;
  final VoidCallback onCallPhone;
  final VoidCallback onOpenOfficialUrl;

  @override
  Widget build(BuildContext context) {
    final accent = isSenior ? AppColors.agaveDeep : AppColors.agaveJade;
    return PasoClaroCard(
      highContrast: isSenior,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CANAL OFICIAL VERIFICADO',
                  style: AppTheme.mono(
                    isSenior ? 12.5 : 11.5,
                    weight: FontWeight.w600,
                    color: accent,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            channel.institutionName,
            style: AppTheme.heading(
              isSenior ? 20 : 17,
              weight: FontWeight.w600,
              color: AppColors.charcoalInk,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppColors.graphiteSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel.schedule,
                  style: AppTheme.body(
                    isSenior ? 16 : 14,
                    color: AppColors.slateCharcoal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel.freeServiceNote,
                  style: AppTheme.body(
                    isSenior ? 16 : 14,
                    weight: FontWeight.w500,
                    color: AppColors.agaveDeep,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.softStone,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onCallPhone,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSenior
                        ? AppColors.charcoalInk
                        : AppColors.whisperBorder,
                    width: isSenior ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 19,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        channel.phoneNumber,
                        style: AppTheme.mono(
                          isSenior ? 17 : 15,
                          weight: FontWeight.w600,
                          color: AppColors.charcoalInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Llamar',
                      style: AppTheme.body(
                        isSenior ? 15 : 13.5,
                        weight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryActionButton(
            label: 'Ver ubicación y horario oficial',
            icon: Icons.location_on_outlined,
            backgroundColor: accent,
            minHeight: isSenior ? 60 : 54,
            onPressed: onOpenOfficialUrl,
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isSenior,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool isSenior;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      selected: selected,
      highContrast: isSenior,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.heading(
                    isSenior ? 18 : 16,
                    weight: FontWeight.w600,
                    color: AppColors.charcoalInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.body(
                    isSenior ? 15 : 13.5,
                    color: AppColors.graphiteSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.agaveJade,
              size: 22,
            ),
        ],
      ),
    );
  }
}
