import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';
import 'package:watad/features/evidence/shared/presentation/widgets/evidence_labels.dart';

/// The project evidence PDF (GRA-72): the project from the database, its
/// record on the blockchain with «مطابق» or «غير مطابق» on every row, and
/// Watad's signature, in the app's language with Gregorian dates.
///
/// Every text is translated when the document is built ([document]), while
/// the page is on screen; [save] then only lays it out.
class EvidencePdf {
  EvidencePdf._(
    this.evidence,
    this.assets,
    this.isArabic,
    this._tr,
    this._money,
  );

  /// The PDF of [evidence] in the language of [context], with the fonts
  /// and logo of [assets] (`EvidencePdfAssets.load()`). Call it, then
  /// [document], while [context] is mounted.
  factory EvidencePdf.of(
    BuildContext context,
    ProjectEvidence evidence,
    EvidencePdfAssets assets,
  ) => EvidencePdf._(
    evidence,
    assets,
    context.isArabic,
    (key, [args = const []]) => context.tr(key, args: args),
    (money) => AppMoneyText.format(context, money),
  );

  final ProjectEvidence evidence;
  final bool isArabic;
  final EvidencePdfAssets assets;
  final String Function(String key, [List<String> args]) _tr;
  final String Function(Money money) _money;

  static final PdfColor _primary = PdfColor.fromInt(
    AppColors.primary.toARGB32(),
  );
  static final PdfColor _ink = PdfColor.fromInt(AppColors.ink.toARGB32());
  static final PdfColor _body = PdfColor.fromInt(AppColors.textBody.toARGB32());
  static final PdfColor _border = PdfColor.fromInt(
    AppColors.borderStrong.toARGB32(),
  );
  static final PdfColor _muted = PdfColor.fromInt(
    AppColors.surfaceMuted.toARGB32(),
  );
  static final PdfColor _success = PdfColor.fromInt(
    AppColors.success.toARGB32(),
  );
  static final PdfColor _error = PdfColor.fromInt(AppColors.error.toARGB32());

  /// e.g. `watad-evidence-1a2b3c4d.pdf`.
  String get fileName =>
      'watad-evidence-${evidence.exportId.split('-').first}.pdf';

  /// What the QR code holds: the export id and the fingerprint, to check
  /// the file against `v_project_evidence_exports`.
  String get qrData =>
      'watad-evidence:${evidence.exportId}:${evidence.fingerprint}';

  String get _none => _tr('evidence.none');

  pw.TextDirection get _direction =>
      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// The whole document, translated now.
  pw.Document document() {
    final content = <pw.Widget>[
      _header(),
      _section(_tr('evidence.pdf_project_section')),
      _projectDetails(),
      _section(_tr('evidence.pdf_tasks_section')),
      _tasks(),
      _section(_tr('evidence.pdf_payments_section')),
      _payments(),
      ..._chain(),
      _section(_tr('evidence.pdf_signature_section')),
      _signature(),
    ];
    final pageOf = _tr('evidence.pdf_page', ['{page}', '{pages}']);
    final footerId = _tr('evidence.pdf_export_id_line', [evidence.exportId]);
    final document = pw.Document(
      title: _tr('evidence.pdf_title'),
      author: _tr('evidence.pdf_author'),
      creator: _tr('evidence.pdf_author'),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        textDirection: _direction,
        theme: pw.ThemeData.withFont(
          base: assets.regular,
          bold: assets.bold,
        ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: 10, color: _ink)),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _words(footerId, pw.TextStyle(fontSize: 7, color: _body)),
              _words(
                pageOf
                    .replaceAll('{page}', _number(context.pageNumber))
                    .replaceAll('{pages}', _number(context.pagesCount)),
                pw.TextStyle(fontSize: 8, color: _body),
              ),
            ],
          ),
        ),
        build: (context) => content,
      ),
    );
    return document;
  }

  /// The file's bytes.
  Future<Uint8List> save() => document().save();

  pw.Widget _header() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(assets.logo, height: 54),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _tr('evidence.pdf_title'),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 4),
                _line(
                  _tr('evidence.pdf_export_id'),
                  evidence.exportId,
                  ltr: true,
                ),
                _line(
                  _tr('evidence.pdf_exported_at'),
                  _time(evidence.exportedAt),
                ),
                _line(
                  _tr('evidence.pdf_exported_by'),
                  _tr(EvidenceLabels.roleKey(evidence.exportedByRole)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _line(String label, String value, {bool ltr = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(color: _body, fontSize: 9)),
          pw.Flexible(child: _text(value, ltr: ltr, fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _section(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _primary,
        ),
      ),
    );
  }

  pw.Widget _projectDetails() {
    final project = evidence.project;
    final place = [
      project.city,
      if (project.district case final district? when district.isNotEmpty)
        district,
    ].join(_tr('evidence.pdf_separator'));
    final rows = <(String, String, bool)>[
      (_tr('evidence.pdf_project_title'), project.title, false),
      (
        _tr('evidence.pdf_status'),
        _tr(EvidenceLabels.projectStatusKey(project.status)),
        false,
      ),
      (_tr('evidence.pdf_place'), place, false),
      (_tr('evidence.pdf_description'), _orNone(project.description), false),
      (_tr('evidence.pdf_client'), _orNone(evidence.clientName), false),
      (
        _tr('evidence.pdf_contractor'),
        _orNone(evidence.contractorCompany),
        false,
      ),
      (
        _tr('evidence.pdf_cr_number'),
        _orNone(evidence.contractorCrNumber),
        true,
      ),
      (_tr('evidence.pdf_agreed_price'), _money(evidence.agreedPrice), false),
      (_tr('evidence.pdf_created_at'), _day(project.createdAt), false),
      (_tr('evidence.pdf_started_at'), _dayOrNone(project.startedAt), false),
      (_tr('evidence.pdf_finished_at'), _dayOrNone(project.completedAt), false),
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(5)},
      children: [
        for (final (label, value, ltr) in rows)
          pw.TableRow(
            children: [
              _cell(label, background: _muted, bold: true),
              _cell(value, ltr: ltr),
            ],
          ),
      ],
    );
  }

  pw.Widget _tasks() {
    if (evidence.tasks.isEmpty) return _empty(_tr('evidence.pdf_no_tasks'));
    return _table(
      headers: [
        _tr('evidence.pdf_number'),
        _tr('evidence.pdf_task'),
        _tr('evidence.pdf_start'),
        _tr('evidence.pdf_finish'),
        _tr('evidence.pdf_status'),
        _tr('evidence.pdf_amount'),
        _tr('evidence.pdf_last_decision'),
      ],
      widths: const [0.6, 3.4, 1.5, 1.5, 1.4, 1.6, 1.4],
      rows: [
        for (final (index, task) in evidence.tasks.indexed)
          [
            _cell(_number(index + 1)),
            _cell(
              task.description.isEmpty || task.description == task.title
                  ? task.title
                  : [task.title, task.description].join('\n'),
            ),
            _cell(_dayOrNone(task.startDate)),
            _cell(_dayOrNone(task.finishDate)),
            _cell(_tr(EvidenceLabels.taskStatusKey(task.status))),
            _cell(task.amount == null ? _none : _money(task.amount!)),
            _cell(_tr(EvidenceLabels.decisionKey(task.lastDecision))),
          ],
      ],
    );
  }

  pw.Widget _payments() {
    if (evidence.payments.isEmpty) {
      return _empty(_tr('evidence.pdf_no_payments'));
    }
    return _table(
      headers: [
        _tr('evidence.pdf_stage'),
        _tr('evidence.pdf_amount'),
        _tr('evidence.pdf_method'),
        _tr('evidence.pdf_paid_at'),
        _tr('evidence.pdf_status'),
        _tr('evidence.pdf_receipt'),
      ],
      widths: const [0.8, 1.8, 1.6, 1.6, 1.4, 1.6],
      rows: [
        for (final payment in evidence.payments)
          [
            _cell(_number(payment.stageNumber)),
            _cell(_money(payment.amount)),
            _cell(_tr(EvidenceLabels.methodKey(payment.method))),
            _cell(_dayOrNone(payment.paidAt)),
            _cell(_tr(EvidenceLabels.paymentStatusKey(payment.status))),
            _cell(
              payment.method == 'bank_transfer'
                  ? _tr(EvidenceLabels.receiptKey(payment.bankTransferStatus))
                  : _none,
            ),
          ],
      ],
    );
  }

  List<pw.Widget> _chain() {
    final matches = evidence.matches;
    return [
      // In a row, so the title and its box never break across two pages.
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _section(_tr('evidence.pdf_chain_section')),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: matches ? _success : _error),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _tr(
                          matches
                              ? 'evidence.pdf_chain_matches'
                              : 'evidence.pdf_chain_differs',
                        ),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: matches ? _success : _error,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      _words(
                        _tr('evidence.pdf_last_sync', [
                          evidence.lastSyncedAt == null
                              ? _none
                              : _time(evidence.lastSyncedAt!),
                        ]),
                        pw.TextStyle(fontSize: 9, color: _body),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      _table(
        headers: [
          _tr('evidence.pdf_field'),
          _tr('evidence.pdf_on_chain'),
          _tr('evidence.pdf_in_database'),
          _tr('evidence.pdf_result'),
        ],
        widths: const [1.6, 3, 3, 1.3],
        rows: [
          for (final field in evidence.chainFields)
            [
              _cell(_tr(EvidenceLabels.fieldKey(field.field))),
              _cell(_fieldValue(field.field, field.chain), ltr: _isLtr(field)),
              _cell(
                _fieldValue(field.field, field.database),
                ltr: _isLtr(field),
              ),
              _result(field.matches),
            ],
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text(
        _tr('evidence.pdf_milestones'),
        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      if (evidence.chainMilestones.isEmpty)
        _empty(_tr('evidence.pdf_no_milestones'))
      else
        _table(
          headers: [
            _tr('evidence.pdf_number'),
            _tr('evidence.pdf_description'),
            _tr('evidence.pdf_status'),
            _tr('evidence.pdf_result'),
          ],
          widths: const [0.6, 5, 1.6, 1.3],
          rows: [
            for (final milestone in evidence.chainMilestones)
              [
                _cell(_number(milestone.index + 1)),
                _cell(_orNone(milestone.description)),
                _cell(_tr(EvidenceLabels.milestoneStatusKey(milestone.status))),
                _result(milestone.matches),
              ],
          ],
        ),
      pw.SizedBox(height: 10),
      pw.Text(
        _tr('evidence.pdf_chain_payments'),
        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      if (evidence.chainPayments.isEmpty)
        _empty(_tr('evidence.pdf_no_chain_payments'))
      else
        _table(
          headers: [
            _tr('evidence.pdf_payment_id'),
            _tr('evidence.pdf_amount'),
            _tr('evidence.pdf_date'),
            _tr('evidence.pdf_note'),
            _tr('evidence.pdf_result'),
          ],
          widths: const [1.6, 1.8, 1.5, 2.6, 1.3],
          rows: [
            for (final payment in evidence.chainPayments)
              [
                _cell(payment.id.split('-').first, ltr: true),
                _cell(payment.amount == null ? _none : _money(payment.amount!)),
                _cell(payment.date ?? _none, ltr: true),
                _cell(
                  !payment.isOnChain
                      ? _tr('evidence.pdf_not_on_chain_yet')
                      : !payment.isInDatabase
                      ? _tr('evidence.pdf_not_paid_anymore')
                      : '',
                ),
                _result(payment.matches),
              ],
          ],
        ),
    ];
  }

  pw.Widget _signature() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _code(_tr('evidence.pdf_fingerprint'), evidence.fingerprint),
              _code(_tr('evidence.pdf_signature'), evidence.signature),
              _code(_tr('evidence.pdf_key_id'), evidence.keyId),
              if (evidence.publicKey.isNotEmpty)
                _code(_tr('evidence.pdf_public_key'), evidence.publicKey),
              pw.SizedBox(height: 8),
              pw.Text(
                _tr('evidence.pdf_statement'),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              pw.Text(
                _tr('evidence.pdf_how_to_check'),
                style: pw.TextStyle(fontSize: 8, color: _body),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: qrData,
          width: 96,
          height: 96,
          drawText: false,
        ),
      ],
    );
  }

  pw.Widget _code(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _body)),
          _text(value, ltr: true, fontSize: 8),
        ],
      ),
    );
  }

  /// A table whose header row repeats on every page it spans.
  pw.Widget _table({
    required List<String> headers,
    required List<double> widths,
    required List<List<pw.Widget>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        for (final (index, width) in widths.indexed)
          index: pw.FlexColumnWidth(width),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _muted),
          children: [for (final header in headers) _cell(header, bold: true)],
        ),
        for (final row in rows) pw.TableRow(children: row),
      ],
    );
  }

  pw.Widget _cell(
    String value, {
    bool bold = false,
    bool ltr = false,
    PdfColor? background,
  }) {
    return pw.Container(
      color: background,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: _text(value, ltr: ltr, fontSize: 9, bold: bold),
    );
  }

  /// «مطابق» in green or «غير مطابق» in red.
  pw.Widget _result(bool matches) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        _tr(matches ? 'evidence.matches' : 'evidence.differs'),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: matches ? _success : _error,
        ),
      ),
    );
  }

  pw.Widget _empty(String message) =>
      pw.Text(message, style: pw.TextStyle(color: _body, fontSize: 9));

  /// Ids, hashes and e-mails read left to right, also in Arabic.
  pw.Widget _text(
    String value, {
    required bool ltr,
    double fontSize = 10,
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : null,
    );
    if (!ltr) return _words(value, style);
    return pw.Text(
      value,
      textDirection: pw.TextDirection.ltr,
      // In an Arabic page, left-to-right text still sits at the start.
      textAlign: isArabic ? pw.TextAlign.end : null,
      style: style,
    );
  }

  /// [value] on the page. Arabic text is set right to left, also in an
  /// English page (a project's title, a name), where it sits at the start.
  /// The pdf package moves the space before a number in Arabic text to
  /// after it (a date reads «نوفمبر٢٠٢٦»), so Arabic text with digits is
  /// laid out word by word, each word its own Text.
  pw.Widget _words(String value, pw.TextStyle style) {
    if (!isArabic && !_arabicLetter.hasMatch(value)) {
      return pw.Text(value, style: style);
    }
    // In an English page, the end of a right-to-left line is its left.
    final align = isArabic ? null : pw.TextAlign.end;
    if (!_digit.hasMatch(value)) {
      return pw.Text(
        value,
        style: style,
        textDirection: pw.TextDirection.rtl,
        textAlign: align,
      );
    }
    final space = (style.fontSize ?? 10) * 0.28;
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: isArabic
            ? pw.CrossAxisAlignment.start
            : pw.CrossAxisAlignment.end,
        children: [
          for (final line in value.split('\n'))
            pw.Wrap(
              spacing: space,
              alignment: isArabic
                  ? pw.WrapAlignment.start
                  : pw.WrapAlignment.end,
              children: [
                for (final word in line.split(' '))
                  if (word.isNotEmpty)
                    pw.Text(
                      word,
                      style: style,
                      // An id or a time alone reads left to right.
                      textDirection: _arabicLetter.hasMatch(word)
                          ? null
                          : pw.TextDirection.ltr,
                    ),
              ],
            ),
        ],
      ),
    );
  }

  /// Western and Arabic-Indic digits.
  static final RegExp _digit = RegExp('[0-9\u0660-\u0669]');

  /// Arabic letters (not digits).
  static final RegExp _arabicLetter = RegExp('[\u0620-\u064A]');

  /// Ids, e-mails and the currency code read left to right; names and the
  /// price in SAR follow the page.
  bool _isLtr(EvidenceFieldCheck field) => switch (field.field) {
    'owner' || 'contractor' || 'agreedPrice' => false,
    _ => true,
  };

  /// A field's value as shown: e-mails partly hidden, the price in SAR.
  String _fieldValue(String field, String? value) {
    if (value == null || value.isEmpty) return _none;
    return switch (field) {
      'ownerEmail' || 'contractorEmail' => maskEmail(value),
      'agreedPrice' => switch (num.tryParse(value)) {
        final sar? => _money(Money.fromJson(sar)),
        null => value,
      },
      _ => value,
    };
  }

  /// `amer@gmail.com` → `a***@gmail.com`: enough to recognise it, without
  /// handing the full address to whoever gets the file.
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return '***';
    return '${email[0]}***${email.substring(at)}';
  }

  String _orNone(String? value) =>
      value == null || value.trim().isEmpty ? _none : value;

  String get _locale => isArabic
      ? AppLocalization.arabic.languageCode
      : AppLocalization.english.languageCode;

  String _number(int value) => NumberFormat.decimalPattern(
    isArabic ? 'ar_EG' : AppLocalization.english.languageCode,
  ).format(value);

  /// A moment, on the phone's clock: «١ نوفمبر ٢٠٢٦ ١١:٠٥ ص».
  String _time(DateTime time) =>
      DateFormat.yMMMd(_locale).add_jm().format(time.toLocal());

  /// A calendar day: «١ نوفمبر ٢٠٢٦». Task days are Riyadh days, stored as
  /// UTC midnight, so they're read as they are.
  String _day(DateTime day) => DateFormat.yMMMd(
    _locale,
  ).format(day.isUtc && day.hour == 0 && day.minute == 0 ? day : day.toLocal());

  String _dayOrNone(DateTime? day) => day == null ? _none : _day(day);
}

/// The Amiri font and the Watad logo, embedded in every evidence PDF.
class EvidencePdfAssets {
  const EvidencePdfAssets({
    required this.regular,
    required this.bold,
    required this.logo,
  });

  static const String regularFont = 'assets/fonts/Amiri-Regular.ttf';
  static const String boldFont = 'assets/fonts/Amiri-Bold.ttf';

  final pw.Font regular;
  final pw.Font bold;
  final pw.ImageProvider logo;

  static Future<EvidencePdfAssets> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    return EvidencePdfAssets(
      regular: pw.Font.ttf(await assets.load(regularFont)),
      bold: pw.Font.ttf(await assets.load(boldFont)),
      logo: pw.MemoryImage(
        (await assets.load(AppLogo.lightAsset)).buffer.asUint8List(),
      ),
    );
  }
}
