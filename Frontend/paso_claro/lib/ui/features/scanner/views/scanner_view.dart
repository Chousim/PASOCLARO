import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/models/pasoclaro_models.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pasoclaro_widgets.dart';

/// Stitch-faithful 390x844 multimodal document scanner & plain-language reader.
/// Strictly zero overlapping text over the document preview area.
class ScannerView extends StatefulWidget {
  const ScannerView({
    super.key,
    required this.appState,
    required this.onOpenChecklist,
  });

  final PasoClaroAppState appState;
  final VoidCallback onOpenChecklist;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _pickDocument(ImageSource source) async {
    String? pickedPath;
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      pickedPath = file.path;
    } catch (_) {
      // Graceful fallback to verified sample medical referral document.
      pickedPath = null;
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = true);
    await widget.appState.scanDocument(pickedPath);
    if (!mounted) return;
    setState(() => _isAnalyzing = false);
  }

  Future<void> _useSampleDocument() async {
    setState(() => _isAnalyzing = true);
    await widget.appState.scanDocument(null);
    if (!mounted) return;
    setState(() => _isAnalyzing = false);
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.purePaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elegir documento para leer',
                  style: AppTheme.heading(18, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toma una foto clara de tu hoja o selecciona una imagen guardada.',
                  style: AppTheme.body(14, color: AppColors.graphiteSecondary),
                ),
                const SizedBox(height: 16),
                _SourceOptionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Tomar foto con cámara',
                  subtitle: 'Enfoca el documento con buena luz',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickDocument(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                _SourceOptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Elegir de galería',
                  subtitle: 'Usa una foto que ya tengas en tu teléfono',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickDocument(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _SourceOptionTile(
                  icon: Icons.description_outlined,
                  title: 'Usar documento de ejemplo',
                  subtitle: 'Hoja de Referencia — Clínica Familiar',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _useSampleDocument();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final seniorMode = widget.appState.isSeniorMode;
        final scan = widget.appState.lastScan;

        return Scaffold(
          backgroundColor: AppColors.canvasAlabaster,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ScannerTopBar(
                  seniorMode: seniorMode,
                  onBack: () => Navigator.maybePop(context),
                  onPickAnother: _showPhotoSourceSheet,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DocumentPreviewFrame(
                          scan: scan,
                          isAnalyzing: _isAnalyzing,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OfflineStatusPill(
                                label: _isAnalyzing
                                    ? 'Leyendo documento...'
                                    : (scan.deadlineLabel == '[por verificar]' &&
                                            scan.folioCode == '[sin folio]')
                                        ? 'Lectura parcial — revisa los datos'
                                        : 'Documento leído con claridad',
                                highContrast: seniorMode,
                              ),
                              _CaptureActionPill(
                                onTap: _showPhotoSourceSheet,
                                seniorMode: seniorMode,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ScanExplanationCard(
                          scan: scan,
                          seniorMode: seniorMode,
                          onSpeak: () {
                            final spokenExplanation =
                                scan.plainExplanation.contains('\n\n')
                                    ? scan.plainExplanation.split('\n\n').last
                                    : scan.plainExplanation;
                            final alertText =
                                scan.missingRequirementAlert != null
                                    ? ' Aviso importante: ${scan.missingRequirementAlert}'
                                    : '';
                            widget.appState.speakSpanish(
                              '${scan.documentType}. $spokenExplanation Fecha límite: ${scan.deadlineLabel}. Folio: ${scan.folioCode}.$alertText',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.purePaper,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.whisperBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: PrimaryActionButton(
                        label: 'Crear mi lista paso a paso',
                        icon: Icons.checklist_rounded,
                        minHeight: seniorMode ? 60 : 54,
                        onPressed: widget.onOpenChecklist,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({
    required this.seniorMode,
    required this.onBack,
    required this.onPickAnother,
  });

  final bool seniorMode;
  final VoidCallback onBack;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.purePaper,
        border: Border(
          bottom: BorderSide(color: AppColors.whisperBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.charcoalInk,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Escáner de Documentos',
              style: AppTheme.heading(
                seniorMode ? 19 : 18,
                weight: FontWeight.w600,
                color: AppColors.charcoalInk,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPickAnother,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.agaveJade,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Otra foto',
              style: AppTheme.body(
                seniorMode ? 15.5 : 14,
                weight: FontWeight.w600,
                color: AppColors.agaveJade,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean document preview framed by 4 architectural corner brackets in Agave Jade.
/// Zero overlapping badges or buttons over the document image/paper area.
class _DocumentPreviewFrame extends StatelessWidget {
  const _DocumentPreviewFrame({
    required this.scan,
    required this.isAnalyzing,
  });

  final ScannedDocumentResult scan;
  final bool isAnalyzing;

  bool _hasLocalFile(String? path) {
    if (kIsWeb || path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRealPhoto = _hasLocalFile(scan.imagePath);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.whisperBorder),
      ),
      child: CustomPaint(
        foregroundPainter: const _CornerBracketsPainter(
          color: AppColors.agaveJade,
          strokeWidth: 3,
          bracketLength: 22,
          cornerRadius: 12,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: isAnalyzing
              ? const SizedBox(
                  height: 210,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.agaveJade,
                    ),
                  ),
                )
              : hasRealPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(scan.imagePath!),
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _PaperDocumentMockup(scan: scan),
        ),
      ),
    );
  }
}

class _PaperDocumentMockup extends StatelessWidget {
  const _PaperDocumentMockup({required this.scan});

  final ScannedDocumentResult scan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purePaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.whisperBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A18181B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                size: 16,
                color: AppColors.agaveJade,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SERVICIOS DE SALUD PÚBLICA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.mono(
                    10,
                    weight: FontWeight.w600,
                    color: AppColors.mutedMeta,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                scan.folioCode,
                style: AppTheme.mono(
                  10.5,
                  weight: FontWeight.w600,
                  color: AppColors.charcoalInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            scan.documentPreviewTitle,
            style: AppTheme.heading(
              15.5,
              weight: FontWeight.w600,
              color: AppColors.charcoalInk,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.whisperBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MockupField(
                  label: 'ESPECIALIDAD',
                  value: 'Oftalmología',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MockupField(
                  label: 'VIGENCIA',
                  value: scan.deadlineLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.softStone,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          FractionallySizedBox(
            widthFactor: 0.72,
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.softStone,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.strongBorder,
                  width: 1,
                ),
              ),
              child: Text(
                'SELLO DE ARCHIVO',
                style: AppTheme.mono(
                  9.5,
                  weight: FontWeight.w600,
                  color: AppColors.mutedMeta,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockupField extends StatelessWidget {
  const _MockupField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.mono(
            9.5,
            weight: FontWeight.w600,
            color: AppColors.mutedMeta,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body(
            13,
            weight: FontWeight.w600,
            color: AppColors.charcoalInk,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter({
    required this.color,
    required this.strokeWidth,
    required this.bracketLength,
    required this.cornerRadius,
  });

  final Color color;
  final double strokeWidth;
  final double bracketLength;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = cornerRadius;
    final l = bracketLength;
    final w = size.width;
    final h = size.height;

    // Top-left
    final tl = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0);
    canvas.drawPath(tl, paint);

    // Top-right
    final tr = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l);
    canvas.drawPath(tr, paint);

    // Bottom-left
    final bl = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(l, h);
    canvas.drawPath(bl, paint);

    // Bottom-right
    final br = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - l);
    canvas.drawPath(br, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        bracketLength != oldDelegate.bracketLength ||
        cornerRadius != oldDelegate.cornerRadius;
  }
}

class _CaptureActionPill extends StatelessWidget {
  const _CaptureActionPill({
    required this.onTap,
    required this.seniorMode,
  });

  final VoidCallback onTap;
  final bool seniorMode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.purePaper,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: seniorMode ? AppColors.charcoalInk : AppColors.strongBorder,
              width: seniorMode ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 15,
                color: AppColors.agaveJade,
              ),
              const SizedBox(width: 6),
              Text(
                'Tomar foto',
                style: AppTheme.body(
                  12.5,
                  weight: FontWeight.w600,
                  color: AppColors.charcoalInk,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanExplanationCard extends StatelessWidget {
  const _ScanExplanationCard({
    required this.scan,
    required this.seniorMode,
    required this.onSpeak,
  });

  final ScannedDocumentResult scan;
  final bool seniorMode;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      highContrast: seniorMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'EXPLICACIÓN EN PALABRAS CLARAS',
                  style: AppTheme.mono(
                    11,
                    weight: FontWeight.w600,
                    color: AppColors.agaveJade,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.agaveMist,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onSpeak,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.volume_up_outlined,
                      size: 18,
                      color: AppColors.agaveJade,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scan.documentType,
            style: AppTheme.heading(
              seniorMode ? 22 : 19,
              weight: FontWeight.w700,
              color: AppColors.charcoalInk,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scan.plainExplanation,
            style: AppTheme.body(
              seniorMode ? 18 : 15.5,
              color: AppColors.slateCharcoal,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softStone,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: seniorMode
                    ? AppColors.strongBorder
                    : AppColors.whisperBorder,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FECHA LÍMITE',
                          style: AppTheme.mono(
                            10.5,
                            weight: FontWeight.w600,
                            color: AppColors.mutedMeta,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan.deadlineLabel,
                          style: AppTheme.mono(
                            seniorMode ? 16 : 14,
                            weight: FontWeight.w700,
                            color: AppColors.charcoalInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppColors.whisperBorder,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FOLIO',
                          style: AppTheme.mono(
                            10.5,
                            weight: FontWeight.w600,
                            color: AppColors.mutedMeta,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan.folioCode,
                          style: AppTheme.mono(
                            seniorMode ? 16 : 14,
                            weight: FontWeight.w700,
                            color: AppColors.charcoalInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (scan.deadlineLabel == '[por verificar]' ||
              scan.folioCode == '[sin folio]') ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.graphiteSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Algunos datos no se distinguieron bien en la foto. Revísalos directamente en tu hoja o intenta con más luz.',
                    style: AppTheme.body(
                      seniorMode ? 14 : 12.5,
                      color: AppColors.graphiteSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (scan.missingRequirementAlert != null &&
              scan.missingRequirementAlert!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: const BoxDecoration(
                  color: AppColors.brickWash,
                  border: Border(
                    left: BorderSide(
                      color: AppColors.brickAlert,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: AppColors.brickAlert,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REQUISITO FALTANTE',
                            style: AppTheme.mono(
                              10.5,
                              weight: FontWeight.w700,
                              color: AppColors.brickAlert,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            scan.missingRequirementAlert!,
                            style: AppTheme.body(
                              seniorMode ? 16 : 14,
                              weight: FontWeight.w500,
                              color: AppColors.brickAlert,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceOptionTile extends StatelessWidget {
  const _SourceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.agaveMist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.agaveJade, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.heading(15.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.body(13, color: AppColors.graphiteSecondary),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.mutedMeta,
          ),
        ],
      ),
    );
  }
}
