import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_status_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update_rejection.dart';

abstract interface class ClientProjectsRepository {
  Future<Result<void>> createProject(ClientNewProject project);
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses();
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  });

  /// The client's projects, newest first.
  Future<Result<List<ClientProject>>> getMyProjects();

  Future<Result<ClientProject>> getProject(String projectId);

  /// The offers on a project, cheapest first.
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId);

  /// Accepts the offer: the other pending offers are rejected and the
  /// project starts with this contractor.
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params);

  /// Uploads a new ownership deed for a project whose deed was rejected:
  /// it goes back to review.
  Future<Result<void>> replaceDeed(ClientReplaceDeedParams params);

  /// The tasks of one of the client's projects, by start date (tasks
  /// without one last), then by when the contractor added them.
  Future<Result<List<ClientProjectTask>>> getProjectTasks(String projectId);

  /// One task of the client's projects.
  Future<Result<ClientProjectTask>> getProjectTask(String taskId);

  /// The client's answer to a task the contractor proposed.
  Future<Result<void>> setTaskStatus(ClientTaskStatusParams params);

  /// One update the contractor sent on a task, with its photos and the
  /// contractor.
  Future<Result<ClientTaskUpdate>> getTaskUpdate(String updateId);

  /// Accepts a pending update: the task is approved, and a task with an
  /// amount gets its payment stage.
  Future<Result<void>> acceptTaskUpdate(String updateId);

  /// Rejects a pending update with a reason and details: the task goes back
  /// to the contractor.
  Future<Result<void>> rejectTaskUpdate(ClientTaskUpdateRejection rejection);
}
