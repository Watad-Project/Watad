/// A new ownership deed for a project whose deed was rejected.
class ClientReplaceDeedParams {
  const ClientReplaceDeedParams({
    required this.projectId,
    required this.filePath,
  });

  final String projectId;

  /// The file on the device: a PDF or a photo.
  final String filePath;
}
