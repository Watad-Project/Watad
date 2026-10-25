/// The tasks the client chose to pay, on one of their projects (GRA-50,
/// GRA-52).
class ClientPaymentSelection {
  const ClientPaymentSelection({
    required this.projectId,
    required this.taskIds,
  });

  final String projectId;
  final List<String> taskIds;
}
