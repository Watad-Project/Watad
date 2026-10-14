import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';

abstract interface class ClientProjectsRepository {
  Future<Result<void>> createProject(ClientNewProject project);
}
