import 'package:flutter/material.dart';

/// User accessibility & context profile chosen in the 2-tap onboarding.
/// PasoClaro never asks for personal names, accounts, or passwords.
enum UserProfileType {
  senior('senior', 'Letra grande y voz pausada', 'Ideal para adultos mayores'),
  bilingual(
    'bilingual',
    'Guías bilingües por escrito',
    'Maya yucateco, náhuatl u otro idioma',
  ),
  student(
    'student',
    'Explicaciones paso a paso',
    'Sin tecnicismos para trámites y becas',
  ),
  offline(
    'offline',
    'Modo sin internet',
    'Guarda tus listas en el teléfono',
  );

  const UserProfileType(this.id, this.title, this.subtitle);

  final String id;
  final String title;
  final String subtitle;

  static UserProfileType fromId(String? id) {
    return UserProfileType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => UserProfileType.student,
    );
  }
}

/// Supported display languages.
/// Indigenous languages (Yucatec Maya & Nahuatl) are strictly TEXT-ONLY
/// (no forced Spanish TTS audio) for linguistic respect and accuracy.
enum AppLanguage {
  spanish('es', 'Español', false),
  yucatecMaya('yua', 'Maya Yucateco', true),
  nahuatl('nah', 'Náhuatl', true);

  const AppLanguage(this.code, this.label, this.isIndigenousTextOnly);

  final String code;
  final String label;
  final bool isIndigenousTextOnly;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppLanguage.spanish,
    );
  }
}

/// The 4 clear paths of PasoClaro.
enum TramiteCategory {
  salud(
    'salud',
    'Salud',
    'Asistente de Salud',
    'Citas, clínicas y recetas',
    Icons.local_hospital_outlined,
  ),
  tramites(
    'tramites',
    'Trámites y Apoyos',
    'Asistente de Trámites',
    'INE, CURP, actas y programas',
    Icons.description_outlined,
  ),
  educacion(
    'educacion',
    'Educación y Becas',
    'Asistente de Becas',
    'Becas y certificados',
    Icons.school_outlined,
  ),
  empleo(
    'empleo',
    'Empleo',
    'Asistente de Empleo',
    'Bolsa de trabajo y derechos',
    Icons.work_outline,
  );

  const TramiteCategory(
    this.id,
    this.title,
    this.assistantTitle,
    this.subtitle,
    this.icon,
  );

  final String id;
  final String title;
  final String assistantTitle;
  final String subtitle;
  final IconData icon;

  static TramiteCategory fromId(String? id) {
    return TramiteCategory.values.firstWhere(
      (e) => e.id == id,
      orElse: () => TramiteCategory.salud,
    );
  }
}

/// Visual icon type for universal document recognition.
enum DocumentIconType {
  ine(Icons.badge_outlined),
  curp(Icons.assignment_ind_outlined),
  domicilio(Icons.home_outlined),
  receta(Icons.medical_information_outlined),
  constancia(Icons.school_outlined),
  acta(Icons.article_outlined);

  const DocumentIconType(this.icon);
  final IconData icon;
}

/// A single bilingual checklist requirement with Gap Detector guidance.
class BilingualChecklistItem {
  const BilingualChecklistItem({
    required this.id,
    required this.titleSpanish,
    required this.titleMaya,
    required this.titleNahuatl,
    required this.descriptionSpanish,
    required this.howToGetIfMissing,
    required this.iconType,
    this.isCompleted = false,
  });

  final String id;
  final String titleSpanish;
  final String titleMaya;
  final String titleNahuatl;
  final String descriptionSpanish;
  final String howToGetIfMissing;
  final DocumentIconType iconType;
  final bool isCompleted;

  String titleForLanguage(AppLanguage language) {
    return switch (language) {
      AppLanguage.yucatecMaya => titleMaya,
      AppLanguage.nahuatl => titleNahuatl,
      AppLanguage.spanish => titleSpanish,
    };
  }

  BilingualChecklistItem copyWith({bool? isCompleted}) {
    return BilingualChecklistItem(
      id: id,
      titleSpanish: titleSpanish,
      titleMaya: titleMaya,
      titleNahuatl: titleNahuatl,
      descriptionSpanish: descriptionSpanish,
      howToGetIfMissing: howToGetIfMissing,
      iconType: iconType,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Verified official government or public institution contact.
class OfficialChannel {
  const OfficialChannel({
    required this.institutionName,
    required this.schedule,
    required this.phoneNumber,
    required this.officialUrl,
    required this.freeServiceNote,
  });

  final String institutionName;
  final String schedule;
  final String phoneNumber;
  final String officialUrl;
  final String freeServiceNote;
}

/// Complete offline-capable procedure guide.
class TramiteGuide {
  const TramiteGuide({
    required this.id,
    required this.category,
    required this.title,
    required this.summaryPlainSpanish,
    required this.items,
    required this.officialChannel,
    this.savedOffline = true,
  });

  final String id;
  final TramiteCategory category;
  final String title;
  final String summaryPlainSpanish;
  final List<BilingualChecklistItem> items;
  final OfficialChannel officialChannel;
  final bool savedOffline;

  int get completedCount => items.where((item) => item.isCompleted).length;
  int get missingCount => items.length - completedCount;
}

/// A single turn in the guided voice-and-chat assistant.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestampLabel,
    this.wasVoice = false,
    this.officialTag,
    this.bulletRequirements = const [],
    this.followUpQuestion,
    this.quickReplies = const [],
    this.audioDurationLabel,
  });

  final String id;
  final bool isUser;
  final String text;
  final String timestampLabel;
  final bool wasVoice;
  final String? officialTag;
  final List<ChatRequirementBullet> bulletRequirements;
  final String? followUpQuestion;
  final List<String> quickReplies;
  final String? audioDurationLabel;
}

class ChatRequirementBullet {
  const ChatRequirementBullet({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

/// Structured result produced by the multimodal document scanner.
class ScannedDocumentResult {
  const ScannedDocumentResult({
    required this.documentType,
    required this.documentPreviewTitle,
    required this.plainExplanation,
    required this.deadlineLabel,
    required this.folioCode,
    required this.missingRequirementAlert,
    required this.linkedGuideId,
    this.imagePath,
  });

  final String documentType;
  final String documentPreviewTitle;
  final String plainExplanation;
  final String deadlineLabel;
  final String folioCode;
  final String? missingRequirementAlert;
  final String linkedGuideId;
  final String? imagePath;
}
