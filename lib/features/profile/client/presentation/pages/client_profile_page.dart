import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_overview_body.dart';

/// «حسابي»: the client's account tab (GRA-59). Who they are, and the way
/// to everything about their account.
class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.tr('profile.client.title')),
      body: const ProfileOverviewBody(),
    );
  }
}
