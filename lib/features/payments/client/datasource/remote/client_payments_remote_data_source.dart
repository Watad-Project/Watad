import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/payments/client/datasource/models/client_bank_details_model.dart';
import 'package:watad/features/payments/client/datasource/models/client_payment_task_model.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt_type.dart';

abstract interface class ClientPaymentsRemoteDataSource {
  /// The tasks of a project with their payment stages (`v_project_tasks`,
  /// `my_role = 'owner'`), by start date (tasks without one last), then by
  /// when they were added.
  Future<List<ClientPaymentTaskModel>> getTasks(String projectId);

  /// The same, for the tasks with [taskIds] only.
  Future<List<ClientPaymentTaskModel>> getTasksByIds(
    String projectId,
    List<String> taskIds,
  );

  /// The bank account of the project's contractor
  /// (`v_contractor_bank_details` for `v_my_projects.taker_id`), or null
  /// when they haven't added it.
  Future<ClientBankDetailsModel?> getBankDetails(String projectId);

  /// Uploads [receipt] to `bank-transfer-receipts/<paymentId>/<new name>`,
  /// then submits it (`submit_bank_transfer`); returns the transfer's id.
  Future<String> submitBankTransfer(String paymentId, ClientReceipt receipt);
}

class ClientPaymentsRemoteDataSourceImpl
    implements ClientPaymentsRemoteDataSource {
  const ClientPaymentsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _taskColumns =
      'id, title, amount, status, payment_id, payment_status';

  @override
  Future<List<ClientPaymentTaskModel>> getTasks(String projectId) async {
    final rows = await _client
        .from('v_project_tasks')
        .select(_taskColumns)
        .eq('project_id', projectId)
        .eq('my_role', 'owner')
        // Postgrest sorts descending unless asked; empty start dates last.
        .order('start_date', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(ClientPaymentTaskModel.fromJson).toList();
  }

  @override
  Future<List<ClientPaymentTaskModel>> getTasksByIds(
    String projectId,
    List<String> taskIds,
  ) async {
    final rows = await _client
        .from('v_project_tasks')
        .select(_taskColumns)
        .eq('project_id', projectId)
        .eq('my_role', 'owner')
        .inFilter('id', taskIds)
        .order('start_date', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(ClientPaymentTaskModel.fromJson).toList();
  }

  @override
  Future<ClientBankDetailsModel?> getBankDetails(String projectId) async {
    final project = await _client
        .from('v_my_projects')
        .select('taker_id')
        .eq('id', projectId)
        .eq('my_role', 'owner')
        .single();
    final takerId = project['taker_id'] as String?;
    if (takerId == null) return null;
    final row = await _client
        .from('v_contractor_bank_details')
        .select('beneficiary_name, bank_name, iban')
        .eq('contractor_id', takerId)
        .maybeSingle();
    return row == null ? null : ClientBankDetailsModel.fromJson(row);
  }

  @override
  Future<String> submitBankTransfer(
    String paymentId,
    ClientReceipt receipt,
  ) async {
    final type = receipt.type;
    if (type == null) {
      throw ArgumentError.value(receipt.name, 'receipt', 'not a PDF/JPEG/PNG');
    }
    // A new name for every upload: the bucket never replaces a file, and the
    // picked file's name may hold spaces or Arabic letters, which the path
    // rule of `bank_transfers.storage_path` refuses.
    final path =
        '$paymentId/receipt_${DateTime.now().microsecondsSinceEpoch}'
        '.${_extensionOf(type)}';
    await _client.storage
        .from('bank-transfer-receipts')
        .uploadBinary(
          path,
          receipt.bytes,
          fileOptions: FileOptions(contentType: _contentTypeOf(type)),
        );
    return _client.rpc<String>(
      'submit_bank_transfer',
      params: {'p_payment_id': paymentId, 'p_storage_path': path},
    );
  }

  static String _extensionOf(ClientReceiptType type) => switch (type) {
    ClientReceiptType.pdf => 'pdf',
    ClientReceiptType.jpeg => 'jpg',
    ClientReceiptType.png => 'png',
  };

  static String _contentTypeOf(ClientReceiptType type) => switch (type) {
    ClientReceiptType.pdf => 'application/pdf',
    ClientReceiptType.jpeg => 'image/jpeg',
    ClientReceiptType.png => 'image/png',
  };
}
