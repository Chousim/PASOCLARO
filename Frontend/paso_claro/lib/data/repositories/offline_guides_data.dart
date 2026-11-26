import '../../domain/models/pasoclaro_models.dart';

/// Verified offline anchor guides & validated Yucatec Maya / Nahuatl glossary
/// aligned with propuesta-conjunta.pdf (Reto 1 · Puentes de oportunidad).
abstract final class OfflineGuidesData {
  static const List<TramiteGuide> anchorGuides = [
    TramiteGuide(
      id: 'salud_cita_clinica',
      category: TramiteCategory.salud,
      title: 'Cita en Clínica Pública',
      summaryPlainSpanish:
          'Guía verificada para solicitar consulta por primera vez en tu Centro de Salud sin costo.',
      items: [
        BilingualChecklistItem(
          id: 'ine',
          titleSpanish: 'Identificación oficial (INE)',
          titleMaya: "U ju'unil k'ajóolal (INE)",
          titleNahuatl: 'Amoxtli tlen mitzixmati (INE)',
          descriptionSpanish: 'INE vigente, original y copia por ambos lados.',
          howToGetIfMissing:
              'Si no tienes INE vigente, puedes llevar pasaporte o constancia de identidad del municipio.',
          iconType: DocumentIconType.ine,
          isCompleted: true,
        ),
        BilingualChecklistItem(
          id: 'curp',
          titleSpanish: 'CURP impresa reciente',
          titleMaya: "U ts'íibil CURP",
          titleNahuatl: 'Mocurp tlen yankuik',
          descriptionSpanish: 'Tu CURP impresa reciente en formato oficial.',
          howToGetIfMissing:
              'Descárgala gratis en gob.mx/curp o pídela impresa en un módulo comunitario.',
          iconType: DocumentIconType.curp,
          isCompleted: true,
        ),
        BilingualChecklistItem(
          id: 'domicilio',
          titleSpanish: 'Comprobante de domicilio',
          titleMaya: "U ju'unil tu'ux kaja'anech",
          titleNahuatl: 'Amoxtli kampa tichanti',
          descriptionSpanish:
              'Recibo de luz o agua con menos de 3 meses de antigüedad.',
          howToGetIfMissing:
              'Te falta este papel · Pide una constancia gratuita de vecindad en tu comisaría o municipio.',
          iconType: DocumentIconType.domicilio,
          isCompleted: false,
        ),
      ],
      officialChannel: OfficialChannel(
        institutionName: 'Centro de Salud Urbano · Lun–Vie',
        schedule: 'Lunes a viernes, 08:00 a 15:00 h',
        phoneNumber: '800 004 4800',
        officialUrl: 'https://www.gob.mx/salud',
        freeServiceNote:
            'Atención gratuita sin intermediarios ni gestores.',
      ),
    ),
    TramiteGuide(
      id: 'beca_apoyo_social',
      category: TramiteCategory.tramites,
      title: 'Solicitud de Beca o Apoyo',
      summaryPlainSpanish:
          'Requisitos básicos verificados para tramitar tu beca educativa o apoyo social.',
      items: [
        BilingualChecklistItem(
          id: 'beca_constancia',
          titleSpanish: 'Constancia de estudios',
          titleMaya: "U ju'unil xook",
          titleNahuatl: 'Amoxtli tlen momachtia',
          descriptionSpanish:
              'Documento de tu escuela que confirma que estás inscrito en el periodo actual.',
          howToGetIfMissing:
              'Pídela sin costo en servicios escolares o dirección de tu plantel.',
          iconType: DocumentIconType.constancia,
          isCompleted: true,
        ),
        BilingualChecklistItem(
          id: 'beca_curp',
          titleSpanish: 'CURP certificada',
          titleMaya: "U ts'íibil CURP",
          titleNahuatl: 'Mocurp tlen yankuik',
          descriptionSpanish:
              'CURP actualizada con la leyenda de verificación del Registro Civil.',
          howToGetIfMissing:
              'Consíguela gratis en gob.mx/curp con tus datos de nacimiento.',
          iconType: DocumentIconType.curp,
          isCompleted: false,
        ),
        BilingualChecklistItem(
          id: 'beca_domicilio',
          titleSpanish: 'Comprobante de domicilio',
          titleMaya: "U ju'unil tu'ux kaja'anech",
          titleNahuatl: 'Amoxtli kampa tichanti',
          descriptionSpanish:
              'Recibo de luz, agua o constancia municipal reciente.',
          howToGetIfMissing:
              'Si no tienes recibo a tu nombre, lleva el del domicilio donde vives o una constancia municipal.',
          iconType: DocumentIconType.domicilio,
          isCompleted: false,
        ),
      ],
      officialChannel: OfficialChannel(
        institutionName: 'Coordinación Nacional de Becas · Lun–Vie',
        schedule: 'Lunes a viernes, 09:00 a 18:00 h',
        phoneNumber: '55 1162 0300',
        officialUrl: 'https://www.gob.mx/becasbenitojuarez',
        freeServiceNote:
            'Todos los trámites de becas y apoyos son 100 % gratuitos.',
      ),
    ),
  ];

  static ScannedDocumentResult sampleMedicalReferral({String? imagePath}) {
    return ScannedDocumentResult(
      documentType: 'Hoja de referencia a especialidad',
      documentPreviewTitle: 'Hoja de Referencia — Clínica Familiar',
      plainExplanation:
          'Tu médico te envía al hospital general para consulta de oftalmología. Agenda antes de la fecha límite.',
      deadlineLabel: '15 DIC 2026',
      folioCode: 'REF-4082',
      missingRequirementAlert:
          'Falta un sello de vigencia en el módulo de archivo antes de ir al hospital.',
      linkedGuideId: 'salud_cita_clinica',
      imagePath: imagePath,
    );
  }

  static List<ChatMessage> initialConversation(TramiteCategory category) {
    return switch (category) {
      TramiteCategory.salud => const [
          ChatMessage(
            id: 'salud_welcome',
            isUser: false,
            text:
                'Hola, soy tu asistente de salud. Escribe o dicta tu duda en español sencillo, o toca una pregunta para empezar.',
            timestampLabel: 'Ahora',
            officialTag: 'Asistente · Salud',
            quickReplies: [
              '¿Qué papeles necesito para sacar cita?',
              '¿Qué hago si me falta un documento?',
            ],
          ),
        ],
      TramiteCategory.tramites => const [
          ChatMessage(
            id: 'tramites_welcome',
            isUser: false,
            text:
                'Hola, te ayudo con trámites y apoyos sociales en palabras claras. Pregúntame lo que necesites o elige una opción.',
            timestampLabel: 'Ahora',
            officialTag: 'Asistente · Trámites',
            quickReplies: [
              '¿Qué necesito para pedir un apoyo?',
              '¿Cómo consigo mi CURP o comprobante?',
            ],
          ),
        ],
      TramiteCategory.educacion => const [
          ChatMessage(
            id: 'edu_welcome',
            isUser: false,
            text:
                'Hola, te explico becas y trámites escolares sin tecnicismos. Pregúntame con confianza o elige una duda común.',
            timestampLabel: 'Ahora',
            officialTag: 'Asistente · Becas',
            quickReplies: [
              '¿Qué es una constancia de estudios?',
              '¿Qué papeles piden para una beca?',
            ],
          ),
        ],
      TramiteCategory.empleo => const [
          ChatMessage(
            id: 'empleo_welcome',
            isUser: false,
            text:
                'Hola, te ayudo a entender vacantes, requisitos laborales y apoyos gratuitos de empleo. ¿En qué te ayudo hoy?',
            timestampLabel: 'Ahora',
            officialTag: 'Asistente · Empleo',
            quickReplies: [
              '¿Qué documentos piden para buscar trabajo?',
              '¿Dónde encuentro bolsa de trabajo gratuita?',
            ],
          ),
        ],
    };
  }
}
