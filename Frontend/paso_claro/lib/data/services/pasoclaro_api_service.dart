import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/pasoclaro_models.dart';
import 'api_config.dart';

/// FastAPI HTTP client prepared to connect to the teammate's Gemini backend.
/// Automatically falls back to verified offline responses when API_BASE_URL
/// is not configured or the device has no internet connection.
class PasoClaroApiService {
  PasoClaroApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ChatMessage?> sendAssistantQuery({
    required String prompt,
    required UserProfileType profile,
    required AppLanguage language,
    required TramiteCategory category,
    required List<String> completedDocs,
  }) async {
    if (!ApiConfig.isBackendConfigured) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/assistant/chat');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'perfil': profile.id,
              'idioma': language.code,
              'tramite': category.id,
              'docs_completados': completedDocs,
              'mensaje': prompt,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatMessage(
        id: 'api_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: (data['respuesta'] as String?) ?? '',
        timestampLabel: 'Ahora',
        officialTag: data['etiqueta_oficial'] as String?,
        followUpQuestion: data['pregunta_siguiente'] as String?,
        quickReplies: (data['respuestas_rapidas'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
    } catch (_) {
      return null;
    }
  }

  Future<ScannedDocumentResult?> analyzeDocumentImage({
    required String imagePath,
    required UserProfileType profile,
    required AppLanguage language,
  }) async {
    if (!ApiConfig.isBackendConfigured) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/scanner/analyze');
      final request = http.MultipartRequest('POST', uri)
        ..fields['perfil'] = profile.id
        ..fields['idioma'] = language.code
        ..files.add(await http.MultipartFile.fromPath('file', imagePath));

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) return null;

      final data = jsonDecode(body) as Map<String, dynamic>;
      return ScannedDocumentResult(
        documentType: (data['tipo_documento'] as String?) ?? 'Documento oficial',
        documentPreviewTitle:
            (data['titulo_corto'] as String?) ?? 'Documento analizado',
        plainExplanation: (data['explicacion'] as String?) ?? '',
        deadlineLabel: (data['fecha_limite'] as String?) ?? '[por verificar]',
        folioCode: (data['folio'] as String?) ?? '[sin folio]',
        missingRequirementAlert: data['alerta_faltante'] as String?,
        linkedGuideId: (data['guia_id'] as String?) ?? 'salud_cita_clinica',
        imagePath: imagePath,
      );
    } catch (_) {
      return null;
    }
  }
}
