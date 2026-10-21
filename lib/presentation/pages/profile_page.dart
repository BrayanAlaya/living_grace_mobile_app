import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/failures/profile_failure.dart';
import '../profile/profile_view_mapper.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/profile/profile_hero.dart';
import '../widgets/profile/profile_info_section.dart';

/// S — pinta el perfil. La carga llega ya resuelta.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.headerTitle,
    required this.isLoading,
    required this.onBack,
    required this.onRetry,
    this.failure,
    this.data,
    this.onEdit,
    this.onEditPhoto,
  });

  final String headerTitle;
  final bool isLoading;
  final ProfileFailure? failure;
  final ProfileViewData? data;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final profile = data;

    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset + 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHero(
              title: headerTitle,
              fullName: profile?.fullName,
              role: profile?.role,
              onBack: onBack,
              onEditPhoto: onEditPhoto,
            ),
            const SizedBox(height: 28),
            if (isLoading)
              const Center(
                child: AppLoadingIndicator(message: 'Cargando perfil...'),
              )
            else if (failure != null)
              _ProfileError(failure: failure!, onRetry: onRetry)
            else if (profile != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ProfileInfoSection(
                  title: 'Información Personal',
                  fields: profile.personal,
                  onEdit: onEdit,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ProfileInfoSection(
                  title: 'Información Adicional',
                  fields: profile.additional,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.failure, required this.onRetry});

  final ProfileFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            failure.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.link),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
