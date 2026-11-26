import 'package:flutter/material.dart';
import '../../../../domain/models/pasoclaro_models.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pasoclaro_widgets.dart';

/// Main Home Hub displaying the asymmetric 4 Caminos, offline status pill,
/// quick document scanner strip, and voice-first CTA.
class HomeHubView extends StatelessWidget {
  const HomeHubView({
    super.key,
    required this.appState,
    required this.onSelectCategory,
    required this.onOpenScanner,
    required this.onOpenVoiceAssistant,
    required this.onOpenSavedLists,
    required this.onOpenSettings,
  });

  final PasoClaroAppState appState;
  final ValueChanged<TramiteCategory> onSelectCategory;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenVoiceAssistant;
  final VoidCallback onOpenSavedLists;
  final VoidCallback onOpenSettings;

  Future<void> _showLanguagePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.purePaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: ListenableBuilder(
              listenable: appState,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Idioma de tus guías',
                      style: AppTheme.heading(20, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las guías en maya yucateco y náhuatl se muestran por escrito junto al español.',
                      style: AppTheme.body(
                        14,
                        color: AppColors.graphiteSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final lang in AppLanguage.values) ...[
                      PasoClaroCard(
                        selected: appState.language == lang,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        borderRadius: 16,
                        onTap: () {
                          appState.selectLanguage(lang);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.label,
                                    style: AppTheme.heading(
                                      16,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang.isIndigenousTextOnly
                                        ? 'Tarjetas bilingües solo por escrito'
                                        : 'Español sencillo con voz disponible',
                                    style: AppTheme.body(
                                      13,
                                      color: AppColors.graphiteSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (appState.language == lang)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.agaveJade,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasAlabaster,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final isBilingual = appState.language.isIndigenousTextOnly ||
                appState.profile == UserProfileType.bilingual;

            return MobileScreenPadding(
              top: 14,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buen día',
                              style: AppTheme.heading(
                                26,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InkWell(
                                  onTap: onOpenSavedLists,
                                  borderRadius: BorderRadius.circular(999),
                                  child: OfflineStatusPill(
                                    label: isBilingual
                                        ? 'Mis listas bilingües (${appState.savedGuidesCount}) ›'
                                        : 'Mis listas (${appState.savedGuidesCount}) ›',
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showLanguagePicker(context),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.purePaper,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.whisperBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.translate_outlined,
                                          size: 13,
                                          color: AppColors.agaveJade,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          appState.language.label,
                                          style: AppTheme.mono(
                                            11.5,
                                            weight: FontWeight.w600,
                                            color: AppColors.charcoalInk,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 15,
                                          color: AppColors.graphiteSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.purePaper,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onOpenSettings,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.strongBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 18,
                                  color: AppColors.charcoalInk,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Menú',
                                  style: AppTheme.heading(
                                    13.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.charcoalInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '¿En qué te ayudamos hoy?',
                            style: AppTheme.heading(
                              19,
                              weight: FontWeight.w600,
                              color: AppColors.charcoalInk,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ProminentPathCard(
                            category: TramiteCategory.salud,
                            onTap: () =>
                                onSelectCategory(TramiteCategory.salud),
                          ),
                          const SizedBox(height: 12),
                          _ProminentPathCard(
                            category: TramiteCategory.tramites,
                            onTap: () =>
                                onSelectCategory(TramiteCategory.tramites),
                          ),
                          const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _CompactPathCard(
                                    category: TramiteCategory.educacion,
                                    onTap: () => onSelectCategory(
                                      TramiteCategory.educacion,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CompactPathCard(
                                    category: TramiteCategory.empleo,
                                    onTap: () => onSelectCategory(
                                      TramiteCategory.empleo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.agaveMist,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.agaveJade,
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: onOpenScanner,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.agaveJade,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.document_scanner_outlined,
                                          size: 22,
                                          color: AppColors.purePaper,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Escanear un papel o receta',
                                              style: AppTheme.heading(
                                                16,
                                                weight: FontWeight.w700,
                                                color: AppColors.agaveDeep,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Toma foto y te lo explicamos claro',
                                              style: AppTheme.body(
                                                13,
                                                color: AppColors.slateCharcoal,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 22,
                                        color: AppColors.agaveJade,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryActionButton(
                    label: 'Preguntar con voz',
                    icon: Icons.mic_outlined,
                    onPressed: onOpenVoiceAssistant,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProminentPathCard extends StatelessWidget {
  const _ProminentPathCard({
    required this.category,
    required this.onTap,
  });

  final TramiteCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.agaveMist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              category.icon,
              size: 24,
              color: AppColors.agaveJade,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: AppTheme.heading(
                    18,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category.subtitle,
                  style: AppTheme.body(
                    14,
                    color: AppColors.graphiteSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.mutedMeta,
          ),
        ],
      ),
    );
  }
}

class _CompactPathCard extends StatelessWidget {
  const _CompactPathCard({
    required this.category,
    required this.onTap,
  });

  final TramiteCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.agaveMist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.icon,
              size: 22,
              color: AppColors.agaveJade,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.title,
            style: AppTheme.heading(
              16,
              weight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.subtitle,
            style: AppTheme.body(
              13,
              color: AppColors.graphiteSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
