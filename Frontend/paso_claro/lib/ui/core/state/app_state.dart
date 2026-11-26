import 'package:flutter/foundation.dart';
import '../../../data/repositories/offline_guides_data.dart';
import '../../../data/repositories/pasoclaro_repository.dart';
import '../../../data/services/voice_service.dart';
import '../../../domain/models/pasoclaro_models.dart';

/// Root ChangeNotifier coordinating profile adaptation, language, offline
/// guides, checklist ticks, and Spanish voice playback.
class PasoClaroAppState extends ChangeNotifier {
  PasoClaroAppState({
    required PasoClaroRepository repository,
    required VoiceService voiceService,
  })  : _repository = repository,
        _voiceService = voiceService,
        _guides = List<TramiteGuide>.from(OfflineGuidesData.anchorGuides);

  final PasoClaroRepository _repository;
  final VoiceService _voiceService;

  UserProfileType? _selectedProfile;
  AppLanguage _language = AppLanguage.spanish;
  bool _slowVoice = true;
  bool _initialized = false;
  bool _backendOnline = false;
  List<TramiteGuide> _guides;
  String _activeGuideId = 'salud_cita_clinica';
  ScannedDocumentResult _lastScan = OfflineGuidesData.sampleMedicalReferral();

  UserProfileType? get selectedProfile => _selectedProfile;
  bool get hasSelectedProfile => _selectedProfile != null;
  UserProfileType get profile => _selectedProfile ?? UserProfileType.student;
  AppLanguage get language => _language;
  bool get slowVoice => _slowVoice;
  bool get isSeniorMode => _selectedProfile == UserProfileType.senior;
  bool get initialized => _initialized;
  bool get isBackendOnline => _backendOnline;
  List<TramiteGuide> get guides => List.unmodifiable(_guides);
  int get savedGuidesCount => _guides.length;
  ScannedDocumentResult get lastScan => _lastScan;
  VoiceService get voiceService => _voiceService;
  PasoClaroRepository get repository => _repository;

  TramiteGuide get activeGuide => _guides.firstWhere(
        (g) => g.id == _activeGuideId,
        orElse: () => _guides.first,
      );

  Future<void> initialize() async {
    _selectedProfile = await _repository.getProfile();
    _language = await _repository.getLanguage();
    _slowVoice = await _repository.getSlowVoice();
    _backendOnline = await _repository.checkBackendHealth();
    _guides = await _repository.loadGuides();
    _initialized = true;
    notifyListeners();
  }

  Future<void> selectProfile(UserProfileType profile) async {
    _selectedProfile = profile;
    if (profile == UserProfileType.senior) {
      _slowVoice = true;
    } else if (profile == UserProfileType.bilingual &&
        _language == AppLanguage.spanish) {
      _language = AppLanguage.yucatecMaya;
    }
    notifyListeners();
    await _repository.saveProfile(profile);
    await _repository.saveLanguage(_language);
    await _repository.saveSlowVoice(_slowVoice);
  }

  Future<void> selectLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    await _repository.saveLanguage(language);
  }

  Future<void> toggleSlowVoice() async {
    _slowVoice = !_slowVoice;
    notifyListeners();
    await _repository.saveSlowVoice(_slowVoice);
  }

  void setActiveGuide(String guideId) {
    _activeGuideId = guideId;
    notifyListeners();
  }

  void selectGuideForCategory(TramiteCategory category) {
    final match = _guides.where((g) => g.category == category);
    _activeGuideId = match.isNotEmpty ? match.first.id : _guides.first.id;
    notifyListeners();
  }

  Future<void> toggleChecklistItem(String guideId, String itemId) async {
    final index = _guides.indexWhere((g) => g.id == guideId);
    if (index == -1) return;

    final guide = _guides[index];
    final updatedItems = guide.items
        .map(
          (item) => item.id == itemId
              ? item.copyWith(isCompleted: !item.isCompleted)
              : item,
        )
        .toList();

    final updatedGuide = TramiteGuide(
      id: guide.id,
      category: guide.category,
      title: guide.title,
      summaryPlainSpanish: guide.summaryPlainSpanish,
      items: updatedItems,
      officialChannel: guide.officialChannel,
      savedOffline: guide.savedOffline,
    );

    _guides = List<TramiteGuide>.from(_guides)..[index] = updatedGuide;
    notifyListeners();
    await _repository.saveGuideChecklist(updatedGuide);
  }

  Future<ScannedDocumentResult> scanDocument(String? imagePath) async {
    _lastScan = await _repository.analyzeDocument(
      imagePath: imagePath,
      profile: profile,
      language: _language,
    );
    _activeGuideId = _lastScan.linkedGuideId;
    notifyListeners();
    return _lastScan;
  }

  Future<void> speakSpanish(String text) {
    return _voiceService.speakSpanish(text, slow: _slowVoice);
  }

  Future<void> stopSpeaking() => _voiceService.stopSpeaking();
}
