import 'dart:typed_data';

/// An evidence photo selected by the contractor for a task progress update
/// (GRA-42), uploaded to the private `task-evidence` storage bucket before
/// calling `submit_task_update`.
class ContractorTaskEvidencePhoto {
  const ContractorTaskEvidencePhoto({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}
