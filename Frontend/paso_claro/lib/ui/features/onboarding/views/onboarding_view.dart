import 'package:flutter/material.dart';
import '../../../../domain/models/pasoclaro_models.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pasoclaro_widgets.dart';

/// 2-tap empathetic onboarding screen (390x844 mobile-first layout).
/// Never asks for personal names, accounts, or passwords.
class OnboardingView extends StatelessWidget {
  const OnboardingView({
    super.key,
    required this.appState,
    required this.onContinue,
    required this.onStartVoice,
  });

  final PasoClaroAppState appState;
  final VoidCallback onContinue;
  final VoidCallback onStartVoice;

  IconData _iconForProfile(UserProfileType type) {
    return switch (type) {
      UserProfileType.senior => Icons.text_fields_rounded,
      UserProfileType.bilingual => Icons.translate_outlined,
      UserProfileType.student => Icons.format_list_numbered_rounded,
      UserProfileType.offline => Icons.offline_pin_outlined,
    };
  }

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
                      'Elige tu idioma',
                      style: AppTheme.heading(20, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las guías en maya y náhuatl se muestran por escrito.',
                      style: AppTheme.body(
                        14,
                        color: AppColors.graphiteSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                        ? 'Guías escritas bilingües'
                                        : 'Texto y voz en español',
                                    style: AppTheme.body(
                                      13,
                                      color: AppColors.graphiteSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _SelectionCircle(
                              selected: appState.language == lang,
                            ),
                          ],
                        ),
                      ),
                      if (lang != AppLanguage.values.last)
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
            final hasSelection = appState.hasSelectedProfile;

            return MobileScreenPadding(
              top: 12,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const PasoClaroBrandMark(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _LanguagePillButton(
                          label: appState.language.label,
                          onTap: () => _showLanguagePicker(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ¿cómo prefieres usar PasoClaro?',
                            style: AppTheme.heading(
                              26,
                              weight: FontWeight.w700,
                              height: 1.18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Elige una opción para adaptar la app. Sin formularios ni registro.',
                            style: AppTheme.body(
                              15,
                              color: AppColors.graphiteSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (final type in UserProfileType.values) ...[
                            _ProfileOptionCard(
                              type: type,
                              icon: _iconForProfile(type),
                              selected: appState.selectedProfile == type,
                              onTap: () => appState.selectProfile(type),
                            ),
                            if (type == UserProfileType.bilingual &&
                                appState.selectedProfile ==
                                    UserProfileType.bilingual) ...[
                              const SizedBox(height: 10),
                              _InlineLanguageSelector(
                                currentLanguage: appState.language,
                                onSelect: appState.selectLanguage,
                              ),
                            ],
                            if (type != UserProfileType.values.last)
                              const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!hasSelection) ...[
                    Text(
                      'Selecciona una opción arriba para activar los botones',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        13,
                        weight: FontWeight.w500,
                        color: AppColors.graphiteSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  PrimaryActionButton(
                    label: 'Hablar con PasoClaro',
                    icon: Icons.mic_none_outlined,
                    onPressed: hasSelection ? onStartVoice : null,
                  ),
                  const SizedBox(height: 10),
                  SecondaryActionButton(
                    label: 'Continuar al inicio',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: hasSelection ? onContinue : null,
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

class _LanguagePillButton extends StatelessWidget {
  const _LanguagePillButton({
    required this.label,
    required this.onTap,
  });

  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.whisperBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate_outlined,
                size: 14,
                color: AppColors.agaveJade,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(
                    12,
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

/// Inline language selector revealed immediately when the user chooses
/// "Guías bilingües por escrito" on the welcome screen.
class _InlineLanguageSelector extends StatelessWidget {
  const _InlineLanguageSelector({
    required this.currentLanguage,
    required this.onSelect,
  });

  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whisperBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige tu lengua para las tarjetas bilingües (solo texto):',
            style: AppTheme.body(
              13,
              weight: FontWeight.w600,
              color: AppColors.charcoalInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lang in AppLanguage.values)
                ChoiceChip(
                  label: Text(
                    lang.label,
                    style: AppTheme.body(
                      13.5,
                      weight: FontWeight.w600,
                      color: currentLanguage == lang
                          ? AppColors.purePaper
                          : AppColors.charcoalInk,
                      height: 1.2,
                    ),
                  ),
                  selected: currentLanguage == lang,
                  selectedColor: AppColors.agaveJade,
                  backgroundColor: AppColors.purePaper,
                  side: BorderSide(
                    color: currentLanguage == lang
                        ? AppColors.agaveJade
                        : AppColors.strongBorder,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) => onSelect(lang),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileOptionCard extends StatelessWidget {
  const _ProfileOptionCard({
    required this.type,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final UserProfileType type;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      selected: selected,
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? AppColors.purePaper : AppColors.softStone,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? AppColors.agaveJade : AppColors.slateCharcoal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: AppTheme.heading(
                    16,
                    weight: FontWeight.w600,
                    color: AppColors.charcoalInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.subtitle,
                  style: AppTheme.body(
                    13.5,
                    color: AppColors.graphiteSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SelectionCircle(selected: selected),
        ],
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.agaveJade : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.agaveJade : AppColors.strongBorder,
          width: 1.8,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.purePaper,
            )
          : null,
    );
  }
}
