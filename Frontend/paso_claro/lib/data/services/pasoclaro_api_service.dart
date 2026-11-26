import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../domain/models/pasoclaro_models.dart';
import 'api_config.dart';

/// FastAPI HTTP client aligned 1:1 with FRONTEND_INTEGRATION.md:
/// - GET /health (5s timeout)
/// - GET /api/guides (5s timeout)
/// - POST /api/assistant/chat (12s timeout)
/// - POST /api/scanner/analyze (20s timeout, multipart/form-data, max 10 MB)
///
/// Automatically falls back gracefully when API_BASE_URL is not configured
/// or when the device is offline.
class PasoClaroApiService {
  PasoClaroApiService({http.Client? client}) : _client = client ?? http.Client();

  static const int maxUploadBytes = 10 * 1024 * 1024; // 10 MB
  static const Set<String> _allowedExts = {'jpg', 'jpeg', 'png', 'webp'};

  final http.Client _client;

  Future<bool> checkHealth() async {
    if (!ApiConfig.isBackendConfigured) return false;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Fetches the 4 verified official guides + 15-term bilingual glossary
  /// from GET /api/guides and maps them into [TramiteGuide] domain models.
  Future<List<TramiteGuide>?> fetchGuides() async {
    if (!ApiConfig.isBackendConfigured) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/guides');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final payload =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final rawGuides = payload['guides'] as List<dynamic>? ?? const [];
      final rawGlossary = payload['glossary'] as List<dynamic>? ?? const [];

      final glossaryMaps = rawGlossary
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      final guides = <TramiteGuide>[];
      for (final raw in rawGuides.whereType<Map<String, dynamic>>()) {
        final id = (raw['id'] as String?) ?? '';
        if (id.isEmpty) continue;
        final category = TramiteCategory.fromId(raw['tramite'] as String?);
        final title = (raw['titulo'] as String?) ?? category.title;
        final requisitos = (raw['requisitos'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        final pasos = (raw['pasos'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        final canal =
            (raw['canal_oficial'] as Map<String, dynamic>?) ?? const {};

        final items = <BilingualChecklistItem>[];
        for (var i = 0; i < requisitos.length; i++) {
          final reqText = requisitos[i];
          final match = _findGlossaryMatch(reqText, glossaryMaps);
          final lower = reqText.toLowerCase();
          final iconType = _inferIconType(lower);

          items.add(
            BilingualChecklistItem(
              id: '${id}_req_$i',
              titleSpanish:
                  (match?['termino_es'] as String?) ?? _shortTitle(reqText),
              titleMaya: (match?['yua'] as String?) ?? _shortTitle(reqText),
              titleNahuatl: (match?['nah'] as String?) ?? _shortTitle(reqText),
              descriptionSpanish: reqText,
              descriptionMaya: _mayaDescriptionFor(iconType),
              descriptionNahuatl: _nahuatlDescriptionFor(iconType),
              howToGetIfMissing: (match?['explicacion_sencilla'] as String?) ??
                  'Consulta en tu módulo oficial cercano cómo tramitar este documento sin costo.',
              howToGetMaya: _mayaHowToGetFor(iconType),
              howToGetNahuatl: _nahuatlHowToGetFor(iconType),
              iconType: iconType,
              isCompleted: false,
            ),
          );
        }

        guides.add(
          TramiteGuide(
            id: id,
            category: category,
            title: title,
            summaryPlainSpanish: pasos.isNotEmpty
                ? pasos.first
                : 'Guía oficial verificada disponible sin internet.',
            items: items,
            officialChannel: OfficialChannel(
              institutionName:
                  (canal['institucion'] as String?) ?? 'Atención oficial',
              schedule: (canal['horario'] as String?) ?? 'Lun–Vie',
              phoneNumber: (canal['telefono'] as String?) ?? '800 004 4800',
              officialUrl:
                  (canal['url'] as String?) ?? 'https://www.gob.mx',
              freeServiceNote: (canal['nota'] as String?) ??
                  'Atención gratuita sin intermediarios.',
            ),
            savedOffline: true,
          ),
        );
      }

      return guides.isEmpty ? null : guides;
    } catch (_) {
      return null;
    }
  }

  Future<ChatMessage?> sendAssistantQuery({
    required String prompt,
    required UserProfileType profile,
    required AppLanguage language,
    required TramiteCategory category,
    required List<String> completedDocs,
  }) async {
    if (!ApiConfig.isBackendConfigured) return null;
    final cleanMessage = prompt.trim();
    if (cleanMessage.isEmpty) return null;

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
              'mensaje': cleanMessage,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
      final file = File(imagePath);
      if (!await file.exists()) return null;
      final length = await file.length();
      if (length == 0 || length > maxUploadBytes) return null;

      final rawExt = imagePath.split('.').last.toLowerCase();
      final safeExt = _allowedExts.contains(rawExt) ? rawExt : 'jpg';
      final subtype = switch (safeExt) {
        'png' => 'png',
        'webp' => 'webp',
        _ => 'jpeg',
      };
      final safeFilename = 'documento.$safeExt';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/scanner/analyze');
      final request = http.MultipartRequest('POST', uri)
        ..fields['perfil'] = profile.id
        ..fields['idioma'] = language.code
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imagePath,
            filename: safeFilename,
            contentType: MediaType('image', subtype),
          ),
        );

      final streamed =
          await request.send().timeout(const Duration(seconds: 20));
      final bytes = await streamed.stream.toBytes();
      if (streamed.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final rawAlert = data['alerta_faltante'] as String?;

      return ScannedDocumentResult(
        documentType: (data['tipo_documento'] as String?) ?? 'Documento oficial',
        documentPreviewTitle:
            (data['titulo_corto'] as String?) ?? 'Documento analizado',
        plainExplanation: (data['explicacion'] as String?) ?? '',
        deadlineLabel: (data['fecha_limite'] as String?) ?? '[por verificar]',
        folioCode: (data['folio'] as String?) ?? '[sin folio]',
        missingRequirementAlert:
            (rawAlert != null && rawAlert.trim().isNotEmpty) ? rawAlert : null,
        linkedGuideId: (data['guia_id'] as String?) ?? 'salud_cita_clinica',
        imagePath: imagePath,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _findGlossaryMatch(
    String requirement,
    List<Map<String, dynamic>> glossary,
  ) {
    final lower = requirement.toLowerCase();
    for (final entry in glossary) {
      final term = (entry['termino_es'] as String? ?? '').toLowerCase();
      if (term.isEmpty) continue;
      if (lower.contains('ine') && term.contains('ine')) return entry;
      if (lower.contains('curp') && term.contains('curp')) return entry;
      if (lower.contains('domicilio') && term.contains('domicilio')) {
        return entry;
      }
      if (lower.contains('constancia') && term.contains('constancia')) {
        return entry;
      }
      if (lower.contains('receta') && term.contains('receta')) return entry;
      if (lower.contains('acta') && term.contains('acta')) return entry;
      if (lower.contains('solicitud') && term.contains('solicitud')) {
        return entry;
      }
      if (lower.contains(term)) return entry;
    }
    return null;
  }

  String _shortTitle(String text) {
    final parenIdx = text.indexOf('(');
    final base = parenIdx > 0 ? text.substring(0, parenIdx).trim() : text.trim();
    return base.length > 42 ? '${base.substring(0, 42).trim()}…' : base;
  }

  DocumentIconType _inferIconType(String lower) {
    if (lower.contains('ine') || lower.contains('identificaci')) {
      return DocumentIconType.ine;
    }
    if (lower.contains('curp')) return DocumentIconType.curp;
    if (lower.contains('domicilio') || lower.contains('vecindad')) {
      return DocumentIconType.domicilio;
    }
    if (lower.contains('receta') || lower.contains('médic') || lower.contains('salud')) {
      return DocumentIconType.receta;
    }
    if (lower.contains('constancia') || lower.contains('estudios') || lower.contains('beca')) {
      return DocumentIconType.constancia;
    }
    return DocumentIconType.acta;
  }

  String _mayaDescriptionFor(DocumentIconType type) {
    return switch (type) {
      DocumentIconType.ine =>
        "INE ma'alob u k'iinil, u yáaxil yéetel u kóopia.",
      DocumentIconType.curp =>
        "A CURP túumben ts'íibta'an ti' ju'un (gob.mx/curp).",
      DocumentIconType.domicilio =>
        "U ju'unil sáasil, ja' wa u ju'unil a kaajal túumben.",
      DocumentIconType.constancia =>
        "U ju'unil a najil xook ku ye'esik táan a xook bejla'e'.",
      DocumentIconType.receta =>
        "U ju'unil ts'aak ts'íibta'an tumen le ts'ak yajo'.",
      DocumentIconType.acta =>
        "Ju'un k'a'abéet utia'al a beetik le meyaja'.",
    };
  }

  String _nahuatlDescriptionFor(DocumentIconType type) {
    return switch (type) {
      DocumentIconType.ine =>
        'INE tlen kuali, achto amoxtli iuan ikopia.',
      DocumentIconType.curp =>
        'Mocurp tlen yankuik tlatlali ipan amatl (gob.mx/curp).',
      DocumentIconType.domicilio =>
        'Amatl tlen tlauili, atl noso amatl tlen moaltepe.',
      DocumentIconType.constancia =>
        'Amatl tlen mokalmachtiloyan tlen kinextia timomachtia axkan.',
      DocumentIconType.receta =>
        'Amatl tlen tepajtijketl kichijki para mopaj.',
      DocumentIconType.acta =>
        'Amoxtli tlen moneki para tikchiuas inin tekitl.',
    };
  }

  String _mayaHowToGetFor(DocumentIconType type) {
    return switch (type) {
      DocumentIconType.ine =>
        "Wa mina'an a INE, bis a pasaporte wa u ju'unil a kaajal.",
      DocumentIconType.curp =>
        "K'áate' x-ma' bo'ol ti' gob.mx/curp wa ti' a kaajal.",
      DocumentIconType.domicilio =>
        "K'áat junp'éel ju'un x-ma' bo'ol ti' a comisaría.",
      DocumentIconType.constancia =>
        "K'áate' x-ma' bo'ol ti' u kúuchil a najil xook.",
      DocumentIconType.receta =>
        "K'áate' ti' a ts'ak yaj tu kúuchil toj óolal.",
      DocumentIconType.acta =>
        "K'áat áantaj x-ma' bo'ol ti' u kúuchil le meyaja'.",
    };
  }

  String _nahuatlHowToGetFor(DocumentIconType type) {
    return switch (type) {
      DocumentIconType.ine =>
        'Tla amo tikpia INE, xikuika mopasaporte noso amatl tlen moaltepe.',
      DocumentIconType.curp =>
        'Xiktemo amo motlaxtlaua ipan gob.mx/curp.',
      DocumentIconType.domicilio =>
        'Xiktlajtlani amatl amo motlaxtlaua ipan moaltepe.',
      DocumentIconType.constancia =>
        'Xiktlajtlani amo motlaxtlaua ipan mokalmachtiloyan.',
      DocumentIconType.receta =>
        'Xiktlajtlani mopaj amatl ipan mopajtikali.',
      DocumentIconType.acta =>
        'Xiktlajtlani tlapaleuilistli amo motlaxtlaua ipan altepekali.',
    };
  }
}
