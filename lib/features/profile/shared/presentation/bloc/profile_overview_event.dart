part of 'profile_overview_bloc.dart';

sealed class ProfileOverviewEvent {
  const ProfileOverviewEvent();
}

/// The tab opened, the user pulled to refresh or tapped retry, or came back
/// from a screen that may have changed the profile.
final class ProfileOverviewFetched extends ProfileOverviewEvent {
  const ProfileOverviewFetched();
}
