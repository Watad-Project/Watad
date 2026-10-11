part of 'splash_bloc.dart';

sealed class SplashState {
  const SplashState();
}

final class SplashInitial extends SplashState {
  const SplashInitial();
}

final class SplashLoadInProgress extends SplashState {
  const SplashLoadInProgress();
}

final class SplashLoadSuccess extends SplashState {
  const SplashLoadSuccess(this.destination);

  final SplashDestination destination;
}

final class SplashLoadFailure extends SplashState {
  const SplashLoadFailure(this.failure);

  final Failure failure;
}
