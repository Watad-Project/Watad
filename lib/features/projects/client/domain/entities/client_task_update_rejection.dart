/// The client's rejection of a pending update (GRA-51): the reason they
/// picked, in the words they read it in, and the details they wrote. The
/// contractor reads both; their notification carries the reason.
class ClientTaskUpdateRejection {
  const ClientTaskUpdateRejection({
    required this.updateId,
    required this.reason,
    required this.details,
  });

  final String updateId;
  final String reason;
  final String details;
}
