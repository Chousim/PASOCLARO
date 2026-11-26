import '../../domain/models/pasoclaro_models.dart';
import '../services/local_storage_service.dart';
import '../services/pasoclaro_api_service.dart';
import 'offline_guides_data.dart';

/// Single source of truth combining offline-first local storage with FastAPI.
class PasoClaroRepository {
  PasoClaroRepository({
    required LocalStorageService storage,
    required PasoClaroApiService api,
  })  : _storage = storage,
        _api = api;

  final LocalStorageService _storage;
  final PasoClaroApiService _api;

  Future<UserProfileType?> getProfile() => _storage.loadProfile();
  Future<void> saveProfile(UserProfileType profile) =>
      _storage.saveProfile(profile);

  Future<AppLanguage> getLanguage() => _storage.loadLanguage();
  Future<void> saveLanguage(AppLanguage language) =>
      _storage.saveLanguage(language);

  Future<bool> getSlowVoice() => _storage.loadSlowVoice();
  Future<void> saveSlowVoice(bool enabled) => _storage.saveSlowVoice(enabled);

  Future<List<TramiteGuide>> loadGuides() async {
    final result = <TramiteGuide>[];
    for (final baseGuide in OfflineGuidesData.anchorGuides) {
      final savedIds = await _storage.loadCompletedItemIds(baseGuide.id);
      if (savedIds.isEmpty) {
        result.add(baseGuide);
      } else {
        final updatedItems = baseGuide.items
            .map((item) => item.copyWith(isCompleted: savedIds.contains(item.id)))
            .toList();
        result.add(
          TramiteGuide(
            id: baseGuide.id,
            category: baseGuide.category,
            title: baseGuide.title,
            summaryPlainSpanish: baseGuide.summaryPlainSpanish,
            items: updatedItems,
            officialChannel: baseGuide.officialChannel,
            savedOffline: baseGuide.savedOffline,
          ),
        );
      }
    }
    return result;
  }

  Future<void> saveGuideChecklist(TramiteGuide guide) async {
    final completedIds = guide.items
        .where((item) => item.isCompleted)
        .map((item) => item.id)
        .toSet();
    await _storage.saveCompletedItemIds(guide.id, completedIds);
  }

  Future<ChatMessage> askAssistant({
    required String prompt,
    required UserProfileType profile,
    required AppLanguage language,
    required TramiteCategory category,
    required List<String> completedDocs,
  }) async {
    final remote = await _api.sendAssistantQuery(
      prompt: prompt,
      profile: profile,
      language: language,
      category: category,
      completedDocs: completedDocs,
    );
    if (remote != null && remote.text.isNotEmpty) return remote;

    final lower = prompt.toLowerCase();
    if (lower.contains('falta')) {
      return const ChatMessage(
        id: 'offline_missing',
        isUser: false,
        text:
            'No te preocupes. Si te falta tu comprobante de domicilio, puedes pedir una constancia gratuita de vecindad en tu comisaría o municipio. Ya marqué ese aviso en tu lista sin internet.',
        timestampLabel: 'Ahora',
        officialTag: 'Modo sin internet',
        audioDurationLabel: 'Escuchar respuesta (0:14)',
        followUpQuestion: '¿Abrimos tu lista bilingüe paso a paso?',
        quickReplies: ['Abrir mi lista paso a paso'],
      );
    }

    return const ChatMessage(
      id: 'offline_ready',
      isUser: false,
      text:
          'Excelente. Ya preparé tu lista interactiva guardada en el teléfono para que la revises en la fila sin gastar datos, junto con el teléfono oficial de atención.',
      timestampLabel: 'Ahora',
      officialTag: 'Modo sin internet',
      audioDurationLabel: 'Escuchar respuesta (0:12)',
      followUpQuestion: '¿Quieres revisar tu checklist ahora?',
      quickReplies: ['Abrir mi lista paso a paso'],
    );
  }

  Future<ScannedDocumentResult> analyzeDocument({
    required String? imagePath,
    required UserProfileType profile,
    required AppLanguage language,
  }) async {
    if (imagePath != null) {
      final remote = await _api.analyzeDocumentImage(
        imagePath: imagePath,
        profile: profile,
        language: language,
      );
      if (remote != null) return remote;
    }
    return OfflineGuidesData.sampleMedicalReferral(imagePath: imagePath);
  }
}
