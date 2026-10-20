part of 'client_project_deed_bloc.dart';

sealed class ClientProjectDeedEvent {
  const ClientProjectDeedEvent();
}

/// Load the project, when the page opens and on «حاول مرة أخرى».
final class ClientProjectDeedFetched extends ClientProjectDeedEvent {
  const ClientProjectDeedFetched(this.projectId);

  final String projectId;
}

/// The client picked the new deed's file.
final class ClientProjectDeedPicked extends ClientProjectDeedEvent {
  const ClientProjectDeedPicked({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;
}

/// «إرسال الصك»: upload it and send it back to review.
final class ClientProjectDeedSubmitted extends ClientProjectDeedEvent {
  const ClientProjectDeedSubmitted();
}
