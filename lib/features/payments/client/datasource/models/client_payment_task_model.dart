import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';

class ClientPaymentTaskModel extends ClientPaymentTask {
  const ClientPaymentTaskModel({
    required super.id,
    required super.title,
    required super.status,
    super.amount,
    super.paymentId,
    super.paymentStatus,
  });

  /// Maps the `v_project_tasks` columns selected in
  /// ClientPaymentsRemoteDataSourceImpl.
  factory ClientPaymentTaskModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] as num?;
    final paymentStatus = json['payment_status'] as String?;
    return ClientPaymentTaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: TaskStatus.fromJson(json['status'] as String),
      amount: amount == null ? null : Money.fromJson(amount),
      paymentId: json['payment_id'] as String?,
      paymentStatus: paymentStatus == null
          ? null
          : PaymentStatus.fromJson(paymentStatus),
    );
  }
}
