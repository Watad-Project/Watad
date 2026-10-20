import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';

/// A project's title as the client reads it. The post-project flow saves the
/// first line of the description, or the project type's code (e.g.
/// `newHouse`) when there is none: that code reads as the type's name.
abstract final class ClientProjectTitle {
  static String of(BuildContext context, String title) {
    final type = ClientProjectType.values.asNameMap()[title];
    return type == null ? title : context.tr(type.titleKey);
  }
}
