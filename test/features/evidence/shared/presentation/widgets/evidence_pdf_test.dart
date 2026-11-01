import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/evidence/shared/presentation/widgets/evidence_pdf.dart';

import '../../../../../helpers/fake_evidence_repository.dart';
import '../../../../../helpers/pump_component.dart';

/// The fonts and logo, read from disk: the asset bundle never finishes
/// under a widget test's fake clock.
EvidencePdfAssets _assets() {
  ByteData read(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());
  return EvidencePdfAssets(
    regular: pw.Font.ttf(read(EvidencePdfAssets.regularFont)),
    bold: pw.Font.ttf(read(EvidencePdfAssets.boldFont)),
    logo: pw.MemoryImage(File(AppLogo.lightAsset).readAsBytesSync()),
  );
}

Future<EvidencePdf> _pdf(WidgetTester tester, Locale locale) async {
  late BuildContext context;
  await pumpLocalizedApp(
    tester,
    Builder(
      builder: (inner) {
        context = inner;
        return const SizedBox.shrink();
      },
    ),
    locale: locale,
  );
  return EvidencePdf.of(context, fakeProjectEvidence, _assets());
}

void main() {
  for (final locale in AppLocalization.supportedLocales) {
    testWidgets('builds a PDF in ${locale.languageCode}', (tester) async {
      final pdf = await _pdf(tester, locale);
      final document = pdf.document();
      final bytes = await tester.runAsync(document.save);

      expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(10000));
    });
  }

  testWidgets('names the file and the QR code after the export', (
    tester,
  ) async {
    final pdf = await _pdf(tester, AppLocalization.arabic);

    expect(pdf.fileName, 'watad-evidence-6f1c2d3e.pdf');
    expect(
      pdf.qrData,
      'watad-evidence:${fakeProjectEvidence.exportId}:'
      '${fakeProjectEvidence.fingerprint}',
    );
  });

  test('e-mails are partly hidden', () {
    expect(EvidencePdf.maskEmail('amer@gmail.com'), 'a***@gmail.com');
    expect(EvidencePdf.maskEmail('broken'), '***');
  });
}
