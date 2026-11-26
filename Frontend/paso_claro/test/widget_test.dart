import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paso_claro/data/repositories/pasoclaro_repository.dart';
import 'package:paso_claro/data/services/local_storage_service.dart';
import 'package:paso_claro/data/services/pasoclaro_api_service.dart';
import 'package:paso_claro/data/services/voice_service.dart';
import 'package:paso_claro/domain/models/pasoclaro_models.dart';
import 'package:paso_claro/main.dart';
import 'package:paso_claro/ui/core/state/app_state.dart';
import 'package:paso_claro/ui/features/assistant/views/assistant_view.dart';
import 'package:paso_claro/ui/features/checklist/views/bilingual_checklist_view.dart';
import 'package:paso_claro/ui/features/home/views/home_hub_view.dart';
import 'package:paso_claro/ui/features/scanner/views/scanner_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  PasoClaroAppState buildTestState() {
    return PasoClaroAppState(
      repository: PasoClaroRepository(
        storage: LocalStorageService(),
        api: PasoClaroApiService(),
      ),
      voiceService: VoiceService(),
    );
  }

  testWidgets(
      'Onboarding starts unselected with disabled buttons, reveals bilingual picker, and navigates to Senior Home',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = buildTestState();
    await tester.pumpWidget(PasoClaroApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.text('PasoClaro'), findsOneWidget);
    expect(find.text('Hablar con PasoClaro'), findsOneWidget);
    expect(find.text('Continuar al inicio'), findsOneWidget);
    expect(appState.hasSelectedProfile, isFalse);

    // Tapping disabled button must NOT navigate yet
    await tester.tap(find.text('Continuar al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, ¿cómo prefieres usar PasoClaro?'), findsOneWidget);

    // Tapping bilingual option reveals inline Maya Yucateco & Náhuatl chips
    await tester.tap(find.text('Guías bilingües por escrito'));
    await tester.pumpAndSettle();
    expect(find.text('Maya Yucateco'), findsAtLeastNWidgets(1));
    expect(find.text('Náhuatl'), findsOneWidget);

    // Selecting Senior profile enables buttons and navigates to Senior Home
    await tester.tap(find.text('Letra grande y voz pausada'));
    await tester.pumpAndSettle();
    expect(appState.hasSelectedProfile, isTrue);

    await tester.tap(find.text('Continuar al inicio'));
    await tester.pumpAndSettle();

    expect(find.text('Buenos días'), findsOneWidget);
    expect(find.text('Toca aquí para hablar'), findsOneWidget);
  });

  testWidgets('Bilingual checklist renders Maya + Spanish text-only and toggles item',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = buildTestState();
    await appState.selectProfile(UserProfileType.bilingual);
    await appState.selectLanguage(AppLanguage.yucatecMaya);

    await tester.pumpWidget(
      MaterialApp(
        home: BilingualChecklistView(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("U ju'unil k'ajóolal (INE)"), findsOneWidget);
    expect(find.text("2 ti' 3 ts'o'oka'an"), findsOneWidget);
    expect(find.text('Il u kúuchil web'), findsOneWidget);
    // Linguistic rule: strictly NO audio/TTS speaker icon on indigenous cards
    expect(find.byIcon(Icons.volume_up_outlined), findsNothing);
    expect(find.byIcon(Icons.volume_up), findsNothing);
  });

  testWidgets('HomeHub, Assistant, and Scanner render cleanly on 390x844',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = buildTestState();
    await appState.selectProfile(UserProfileType.student);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeHubView(
          appState: appState,
          onSelectCategory: (_) {},
          onOpenScanner: () {},
          onOpenVoiceAssistant: () {},
          onOpenSavedLists: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buen día'), findsOneWidget);
    expect(find.text('Salud'), findsOneWidget);
    expect(find.text('Trámites y Apoyos'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: AssistantView(
          appState: appState,
          category: TramiteCategory.salud,
          onOpenScanner: () {},
          onOpenChecklist: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Asistente de Salud'), findsOneWidget);
    expect(find.text('Voz lenta: Sí'), findsOneWidget);
    // No user avatar icon in Assistant header
    expect(find.byIcon(Icons.person), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: ScannerView(
          appState: appState,
          onOpenChecklist: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Escáner de Documentos'), findsOneWidget);
    expect(find.text('15 DIC 2026'), findsAtLeastNWidgets(1));
    expect(find.text('REF-4082'), findsAtLeastNWidgets(1));
  });
}
