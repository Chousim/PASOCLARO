import 'package:flutter/material.dart';
import 'data/repositories/pasoclaro_repository.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/pasoclaro_api_service.dart';
import 'data/services/voice_service.dart';
import 'domain/models/pasoclaro_models.dart';
import 'ui/core/state/app_state.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/assistant/views/assistant_view.dart';
import 'ui/features/checklist/views/bilingual_checklist_view.dart';
import 'ui/features/home/views/home_hub_view.dart';
import 'ui/features/home/views/senior_home_view.dart';
import 'ui/features/onboarding/views/onboarding_view.dart';
import 'ui/features/scanner/views/scanner_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = PasoClaroAppState(
    repository: PasoClaroRepository(
      storage: LocalStorageService(),
      api: PasoClaroApiService(),
    ),
    voiceService: VoiceService(),
  )..initialize();

  runApp(PasoClaroApp(appState: appState));
}

class PasoClaroApp extends StatelessWidget {
  const PasoClaroApp({super.key, required this.appState});

  final PasoClaroAppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'PasoClaro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(seniorMode: appState.isSeniorMode),
          home: _OnboardingEntry(appState: appState),
        );
      },
    );
  }
}

class _OnboardingEntry extends StatelessWidget {
  const _OnboardingEntry({required this.appState});

  final PasoClaroAppState appState;

  void _openHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _AdaptiveHomeShell(appState: appState),
      ),
    );
  }

  void _openVoiceDirectly(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _AdaptiveHomeShell(
          appState: appState,
          openVoiceOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingView(
      appState: appState,
      onContinue: () => _openHome(context),
      onStartVoice: () => _openVoiceDirectly(context),
    );
  }
}

class _AdaptiveHomeShell extends StatefulWidget {
  const _AdaptiveHomeShell({
    required this.appState,
    this.openVoiceOnStart = false,
  });

  final PasoClaroAppState appState;
  final bool openVoiceOnStart;

  @override
  State<_AdaptiveHomeShell> createState() => _AdaptiveHomeShellState();
}

class _AdaptiveHomeShellState extends State<_AdaptiveHomeShell> {
  @override
  void initState() {
    super.initState();
    if (widget.openVoiceOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAssistant(TramiteCategory.salud, autoStartVoice: true);
      });
    }
  }

  void _openAssistant(
    TramiteCategory category, {
    bool autoStartVoice = false,
  }) {
    widget.appState.selectGuideForCategory(category);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssistantView(
          appState: widget.appState,
          category: category,
          autoStartVoice: autoStartVoice,
          onOpenScanner: _openScanner,
          onOpenChecklist: _openChecklist,
        ),
      ),
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScannerView(
          appState: widget.appState,
          onOpenChecklist: _openChecklist,
        ),
      ),
    );
  }

  void _openChecklist() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilingualChecklistView(appState: widget.appState),
      ),
    );
  }

  void _openOnboardingSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingView(
          appState: widget.appState,
          onContinue: () => Navigator.of(context).pop(),
          onStartVoice: () {
            Navigator.of(context).pop();
            _openAssistant(TramiteCategory.salud, autoStartVoice: true);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        if (widget.appState.isSeniorMode) {
          return SeniorHomeView(
            appState: widget.appState,
            onSelectCategory: _openAssistant,
            onOpenScanner: _openScanner,
            onOpenVoiceAssistant: () =>
                _openAssistant(TramiteCategory.salud, autoStartVoice: true),
            onOpenSavedLists: _openChecklist,
            onOpenSettings: _openOnboardingSettings,
          );
        }
        return HomeHubView(
          appState: widget.appState,
          onSelectCategory: _openAssistant,
          onOpenScanner: _openScanner,
          onOpenVoiceAssistant: () =>
              _openAssistant(TramiteCategory.salud, autoStartVoice: true),
          onOpenSavedLists: _openChecklist,
          onOpenSettings: _openOnboardingSettings,
        );
      },
    );
  }
}
