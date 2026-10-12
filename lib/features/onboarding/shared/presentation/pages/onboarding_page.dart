import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_page_dots.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';
import 'package:watad/features/onboarding/shared/presentation/widgets/onboarding_slide.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    (
      animation: 'assets/animations/onboarding_all_in_one.json',
      titleKey: 'onboarding.slide_1_title',
      descriptionKey: 'onboarding.slide_1_description',
    ),
    (
      animation: 'assets/animations/onboarding_trusted_contracts.json',
      titleKey: 'onboarding.slide_2_title',
      descriptionKey: 'onboarding.slide_2_description',
    ),
    (
      animation: 'assets/animations/onboarding_staged_payments.json',
      titleKey: 'onboarding.slide_3_title',
      descriptionKey: 'onboarding.slide_3_description',
    ),
  ];

  final _controller = PageController();
  var _currentIndex = 0;

  bool get _isLastSlide => _currentIndex == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() =>
      context.read<OnboardingBloc>().add(const OnboardingFinished());

  void _next() {
    if (_isLastSlide) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Leaves the onboarding once it is marked as seen. goNamed, so Back can't
  /// return here.
  void _leave(BuildContext context) => context.goNamed(AuthRoutes.loginName);

  void _onStateChanged(BuildContext context, OnboardingState state) {
    switch (state) {
      case OnboardingSaveSuccess():
        _leave(context);
      case OnboardingSaveFailure(:final failure):
        // Don't keep the user here: at worst they see the onboarding again on
        // the next launch.
        context.showErrorSnackBar(context.tr(failure.messageKey));
        _leave(context);
      case OnboardingInitial() || OnboardingSaveInProgress():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final isSaving = state is OnboardingSaveInProgress;
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return OnboardingSlide(
                      animation: slide.animation,
                      title: context.tr(slide.titleKey),
                      description: context.tr(slide.descriptionKey),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppPageDots(
                        count: _slides.length,
                        currentIndex: _currentIndex,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: context.tr(
                          _isLastSlide
                              ? 'onboarding.get_started'
                              : 'onboarding.next',
                        ),
                        onPressed: isSaving ? null : _next,
                        isLoading: isSaving && _isLastSlide,
                      ),
                      // Hidden on the last slide, where the button above does
                      // the same. It keeps its space so the button stays put.
                      Visibility(
                        visible: !_isLastSlide,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: AppButton(
                          label: context.tr('onboarding.skip'),
                          onPressed: isSaving ? null : _finish,
                          variant: AppButtonVariant.link,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
