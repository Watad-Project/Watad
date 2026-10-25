import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';

class ClientProjectTaskModel extends ClientProjectTask {
  const ClientProjectTaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    super.amount,
    super.paymentStatus,
    super.startDate,
    super.finishDate,
    super.lastUpdateId,
  });

  /// Maps the `v_project_tasks` columns selected in
  /// ClientProjectsRemoteDataSourceImpl.
  factory ClientProjectTaskModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] as num?;
    final paymentStatus = json['payment_status'] as String?;
    final startDate = json['start_date'] as String?;
    final finishDate = json['finish_date'] as String?;
    return ClientProjectTaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: TaskStatus.fromJson(json['status'] as String),
      amount: amount == null ? null : Money.fromJson(amount),
      paymentStatus: paymentStatus == null
          ? null
          : PaymentStatus.fromJson(paymentStatus),
      startDate: startDate == null ? null : _day(startDate),
      finishDate: finishDate == null ? null : _day(finishDate),
      lastUpdateId: json['last_update_id'] as String?,
    );
  }

  /// A `date` column, e.g. `2026-10-12`: a Riyadh calendar day, kept at UTC
  /// midnight so that no time zone moves it to another day.
  static DateTime _day(String value) {
    final day = DateTime.parse(value);
    return DateTime.utc(day.year, day.month, day.day);
  }
}
