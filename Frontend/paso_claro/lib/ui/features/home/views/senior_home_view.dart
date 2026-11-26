import 'package:flutter/material.dart';
import '../../../../domain/models/pasoclaro_models.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pasoclaro_widgets.dart';

/// Single-column High-Contrast Senior Mode home screen.
/// Uses solid 2px #18181B borders, extra-large typography (20px-28px),
/// and a priority top voice button.
class SeniorHomeView extends StatelessWidget {
  const SeniorHomeView({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasAlabaster,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: MobileScreenPadding(
                top: 14,
                bottom: 24,
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
                              const PasoClaroBrandMark(fontSize: 22),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.agaveMist,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.agaveDeep,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'MODO LETRA GRANDE',
                                  style: AppTheme.mono(
                                    11.5,
                                    weight: FontWeight.w700,
                                    color: AppColors.agaveDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: AppColors.purePaper,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: onOpenSettings,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.charcoalInk,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                    color: AppColors.charcoalInk,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Menú',
                                    style: AppTheme.heading(
                                      16,
                                      weight: FontWeight.w700,
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
                    const SizedBox(height: 22),
                    Text(
                      'Buenos días',
                      style: AppTheme.heading(
                        28,
                        weight: FontWeight.w700,
                        color: AppColors.charcoalInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¿Qué trámite o consulta necesita hoy?',
                      style: AppTheme.body(
                        20,
                        weight: FontWeight.w500,
                        color: AppColors.charcoalInk,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryActionButton(
                      label: 'Toca aquí para hablar',
                      subtitle: 'Te escuchamos y te leemos despacio',
                      icon: Icons.mic_outlined,
                      backgroundColor: AppColors.agaveDeep,
                      minHeight: 80,
                      onPressed: onOpenVoiceAssistant,
                    ),
                    const SizedBox(height: 20),
                    _SeniorActionCard(
                      title: 'Salud y citas médicas',
                      icon: Icons.local_hospital_outlined,
                      onTap: () => onSelectCategory(TramiteCategory.salud),
                    ),
                    const SizedBox(height: 16),
                    _SeniorActionCard(
                      title: 'Trámites y apoyos',
                      icon: Icons.description_outlined,
                      onTap: () => onSelectCategory(TramiteCategory.tramites),
                    ),
                    const SizedBox(height: 16),
                    _SeniorActionCard(
                      title: 'Leer un papel con foto',
                      icon: Icons.photo_camera_outlined,
                      onTap: onOpenScanner,
                    ),
                    const SizedBox(height: 16),
                    _SeniorActionCard(
                      title: 'Mis listas guardadas',
                      icon: Icons.bookmark_outline_rounded,
                      trailingPill: const OfflineStatusPill(
                        label: 'SIN INTERNET',
                        highContrast: true,
                      ),
                      onTap: onOpenSavedLists,
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.softStone,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.charcoalInk,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.phone_in_talk_outlined,
                              size: 24,
                              color: AppColors.agaveDeep,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Si prefiere ayuda telefónica directa gratuita: 800 004 4800',
                              style: AppTheme.mono(
                                15,
                                weight: FontWeight.w600,
                                color: AppColors.charcoalInk,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SeniorActionCard extends StatelessWidget {
  const _SeniorActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.trailingPill,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailingPill;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      highContrast: true,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.agaveMist,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.agaveDeep,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 26,
                color: AppColors.agaveDeep,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTheme.heading(
                      21,
                      weight: FontWeight.w700,
                      color: AppColors.charcoalInk,
                      height: 1.2,
                    ),
                  ),
                  if (trailingPill != null) ...[
                    const SizedBox(height: 8),
                    trailingPill!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 24,
              color: AppColors.charcoalInk,
            ),
          ],
        ),
      ),
    );
  }
}
