import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/entities/register_data.dart';
import '../domain/failures/auth_failure.dart';
import '../register/ministry/ministry_catalog.dart';
import '../register/register_controller.dart';
import '../register/register_validator.dart';
import '../attendance/admin_attendance_page.dart';
import '../attendance/attendance_panel_page.dart';
import '../attendance/attendance_qr_api.dart';
import '../attendance/generate_qr_page.dart';
import '../core/layouts/home_layout.dart';
import '../dashboard/dashboard_api.dart';
import '../notifications/app_notification.dart';
import '../notifications/notification_controller.dart';
import '../rehearsals/rehearsal_api.dart';
import '../rehearsals/rehearsal_detail_page.dart';
import '../rehearsals/rehearsals_page.dart';
import 'admin/admin_catalog.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/rehearsal_form_controller.dart';
import 'pages/admin_panel_page.dart';
import 'pages/change_password_page.dart';
import 'pages/create_rehearsal_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/home_page.dart';
import 'pages/ministry_members_page.dart';
import 'pages/notifications_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/register_page.dart';
import 'pages/registration_loading_page.dart';
import 'pages/session_loading_page.dart';
import 'pages/settings_page.dart';
import 'settings/settings_catalog.dart';
import 'pages/splash_page.dart';
import 'profile/profile_view_mapper.dart';
import 'settings/settings_menu.dart';
import 'widgets/panel_drawer.dart';

enum _AppView {
  splash,
  login,
  sessionLoading,
  register,
  registrationLoading,
  home,
  rehearsals,
  attendances,
  settings,
  profile,
  admin,
  scheduleRehearsal,
  generateQr,
  adminAttendance,
  ministryMembers,
  changePassword,
  forgotPassword,
}

/// Orquesta las pantallas de la app sobre el árbol de layouts.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authController,
    required this.profileController,
    required this.rehearsalFormController,
    required this.registerController,
    required this.registerValidator,
    required this.rehearsalApi,
    this.dashboardApi,
    this.notifications,
  });

  final AuthController authController;
  final ProfileController profileController;
  final RehearsalFormController rehearsalFormController;
  final RegisterController registerController;
  final RegisterValidator registerValidator;
  final RehearsalApi rehearsalApi;
  final DashboardApi? dashboardApi;
  final NotificationController? notifications;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppView _view = _AppView.splash;
  int _registerStep = 0;
  int _homeEpoch = 0;

  AuthController get _auth => widget.authController;
  ProfileController get _profile => widget.profileController;
  RegisterController get _register => widget.registerController;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onProfileChanged);
    _register.addListener(_onRegisterChanged);
    widget.notifications?.addListener(_onNotificationsChanged);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileController != _profile) {
      oldWidget.profileController.removeListener(_onProfileChanged);
      _profile.addListener(_onProfileChanged);
    }
    if (oldWidget.registerController != _register) {
      oldWidget.registerController.removeListener(_onRegisterChanged);
      _register.addListener(_onRegisterChanged);
    }
    if (oldWidget.notifications != widget.notifications) {
      oldWidget.notifications?.removeListener(_onNotificationsChanged);
      widget.notifications?.addListener(_onNotificationsChanged);
    }
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    _register.removeListener(_onRegisterChanged);
    widget.notifications?.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _onRegisterChanged() {
    if (mounted) setState(() {});
  }

  void _onNotificationsChanged() {
    if (!mounted) return;
    setState(() {});
    final incoming = widget.notifications?.takeIncoming();
    if (incoming != null) {
      _showSnack(incoming.title);
    }
  }

  void _goToLogin() {
    _register.clearFailure();
    setState(() => _view = _AppView.login);
  }

  void _goToRegister() {
    _auth.clearFailure();
    _register.clearFailure();
    _registerStep = 0;
    setState(() => _view = _AppView.register);
    _register.loadMinistries();
  }

  void _goToHome() {
    setState(() {
      _homeEpoch++;
      _view = _AppView.home;
    });
  }

  void _goToRehearsals() {
    setState(() => _view = _AppView.rehearsals);
  }

  void _goToAttendances() {
    setState(() => _view = _AppView.attendances);
  }

  void _goToSettings() {
    setState(() => _view = _AppView.settings);
    if (_profile.profile == null) _profile.load();
  }

  void _goToProfile() {
    setState(() => _view = _AppView.profile);
    _profile.load();
  }

  bool get _isAdmin => _profile.profile?.isGlobalAdmin == true;

  void _goToAdmin() {
    if (!_isAdmin) return;
    setState(() => _view = _AppView.admin);
    if (_profile.status == ProfileStatus.idle) {
      _profile.load();
    }
  }

  String _greetingName() => _profile.profile?.firstName.trim() ?? '';

  String _profileFullName() => _profile.profile?.fullName.trim() ?? '';

  void _onSettingsItem(String id) {
    if (id == SettingsItemId.profile) {
      _goToProfile();
      return;
    }
    if (id == SettingsItemId.adminPanel) {
      _goToAdmin();
      return;
    }
    if (id == SettingsItemId.password) {
      setState(() => _view = _AppView.changePassword);
      return;
    }
    if (id == SettingsItemId.notifications) {
      _openNotificationsPage();
      return;
    }
    _showSnack('Próximamente');
  }

  void _openNotificationsPage() {
    final notifications = widget.notifications;
    if (notifications == null) {
      _showSnack('Próximamente');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
          controller: notifications,
          onBack: () => Navigator.of(context).pop(),
          onOpen: _openNotification,
        ),
      ),
    );
  }

  Future<void> _openNotification(AppNotification item) async {
    if (item.isRehearsal && item.resourceId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RehearsalDetailPage(
            api: widget.rehearsalApi,
            rehearsalId: item.resourceId!,
            formController: widget.rehearsalFormController,
            canManage: _isAdmin,
            attendanceApi: AttendanceQrApi(rehearsalApi: widget.rehearsalApi),
          ),
        ),
      );
      return;
    }
    if (item.isMembershipPending) {
      if (!_isAdmin) {
        _showSnack('No tienes acceso a los miembros del ministerio.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MinistryMembersPage(
            onBack: () => Navigator.of(context).pop(),
            repository: widget.rehearsalFormController.repository,
            onResetPassword: (userId) => _auth.resetPassword(userId),
          ),
        ),
      );
      return;
    }
    if (item.isMembershipApproved) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      _goToHome();
    }
  }

  void _goToForgotPassword() {
    _auth.clearFailure();
    setState(() => _view = _AppView.forgotPassword);
  }

  Future<AuthFailure?> _handleRecoverPassword({
    required String identifier,
    required String temporaryPassword,
    required String newPassword,
  }) async {
    final loggedIn = await _auth.login(
      identifier: identifier,
      password: temporaryPassword,
    );
    if (!loggedIn) return _auth.failure;

    final error = await _auth.changePassword(
      currentPassword: temporaryPassword,
      newPassword: newPassword,
    );
    if (error != null) return error;

    await _finishPasswordChange();
    return null;
  }

  void _backToAdmin() {
    if (!_isAdmin) {
      _goToSettings();
      return;
    }
    setState(() => _view = _AppView.admin);
  }

  void _onAdminItem(String id) {
    if (!_isAdmin) return;
    if (id == AdminItemId.scheduleRehearsals) {
      setState(() => _view = _AppView.scheduleRehearsal);
      return;
    }
    if (id == AdminItemId.qrCode) {
      setState(() => _view = _AppView.generateQr);
      return;
    }
    if (id == AdminItemId.attendance) {
      setState(() => _view = _AppView.adminAttendance);
      return;
    }
    if (id == AdminItemId.members) {
      setState(() => _view = _AppView.ministryMembers);
      return;
    }
    _showSnack('Próximamente');
  }

  void _onPanelDestinationSelected(String destinationId) {
    if (destinationId == PanelMenuDestinations.home.id) {
      _goToHome();
      return;
    }
    if (destinationId == PanelMenuDestinations.rehearsals.id) {
      _goToRehearsals();
      return;
    }
    if (destinationId == PanelMenuDestinations.attendances.id) {
      _goToAttendances();
      return;
    }
    if (destinationId == PanelMenuDestinations.settings.id) {
      _goToSettings();
    }
  }

  Widget _panel({required String destinationId, required Widget child}) {
    return HomeLayout(
      currentDestinationId: destinationId,
      onDestinationSelected: _onPanelDestinationSelected,
      onProfilePressed: _goToSettings,
      notifications: widget.notifications,
      onNotificationOpen: _openNotification,
      child: child,
    );
  }

  Future<void> _handleLogin(String identifier, String password) async {
    setState(() => _view = _AppView.sessionLoading);

    final success = await _auth.login(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;

    if (success) await _profile.load();
    if (!mounted) return;
    setState(() {
      if (!success) {
        _view = _AppView.login;
      } else if (_auth.user?.mustChangePassword == true) {
        _view = _AppView.changePassword;
      } else {
        _view = _AppView.home;
      }
    });
    if (success) {
      final notifications = widget.notifications;
      if (notifications != null) unawaited(notifications.start());
    }
  }

  Future<void> _handleRegister(RegisterData data) async {
    final validation = widget.registerValidator.validate(data);
    if (validation != null) {
      _register.showFailure(validation);
      setState(() {});
      return;
    }

    final success = await _register.register(data);

    if (!mounted) return;

    if (!success) return;

    _register.reset();
    setState(() {
      _registerStep = 0;
      _view = _AppView.login;
    });

    _showSnack('Cuenta creada. Ahora inicia sesión.');
  }

  Future<void> _handleLogout() async {
    await widget.notifications?.stop();
    await _auth.logout();
    _profile.clear();
    if (!mounted) return;
    setState(() => _view = _AppView.login);
  }

  Future<void> _finishPasswordChange() async {
    await _handleLogout();
    if (!mounted) return;
    _showSnack('Contraseña actualizada. Inicia sesión con tu nueva clave.');
  }

  Widget _settingsPage() {
    return SettingsPage(
      displayName: _profileFullName(),
      sections: SettingsCatalog.forAdmin(_isAdmin),
      onBack: _goToHome,
      onLogout: _handleLogout,
      onItemSelected: _onSettingsItem,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _AppView.splash => SplashPage(onReady: _goToLogin),
      _AppView.sessionLoading => const SessionLoadingPage(),
      _AppView.registrationLoading => const RegistrationLoadingPage(),
      _AppView.register => RegisterPage(
        catalog: MinistryCatalog(_register.ministries),
        validator: widget.registerValidator,
        initialStep: _registerStep,
        submitting: _register.status == RegisterStatus.submitting,
        failure: _register.failure,
        loadingMinistries: _register.loadingMinistries,
        ministriesFailure: _register.ministriesFailure,
        onRetryMinistries: _register.loadMinistries,
        onSubmit: _handleRegister,
        onLogin: _goToLogin,
      ),
      _AppView.home => HomePage(
        key: ValueKey(_homeEpoch),
        name: _greetingName(),
        loadingName:
            _profile.status == ProfileStatus.loading &&
            _profile.profile == null,
        onOpenSettings: _goToSettings,
        onDestinationSelected: _onPanelDestinationSelected,
        rehearsalApi: widget.rehearsalApi,
        dashboardApi: widget.dashboardApi,
        rehearsalFormController: widget.rehearsalFormController,
        canManageRehearsals: _isAdmin,
        notifications: widget.notifications,
        onNotificationOpen: _openNotification,
      ),
      _AppView.rehearsals => _panel(
        destinationId: PanelMenuDestinations.rehearsals.id,
        child: RehearsalsPage(
          api: widget.rehearsalApi,
          formController: widget.rehearsalFormController,
          canManage: _isAdmin,
          embedded: true,
        ),
      ),
      _AppView.attendances => _panel(
        destinationId: PanelMenuDestinations.attendances.id,
        child: _isAdmin
            ? AdminAttendancePage(
                onBack: _goToHome,
                rehearsalApi: widget.rehearsalApi,
                showHeader: false,
              )
            : AttendancePanelPage(api: widget.dashboardApi),
      ),
      _AppView.settings => _settingsPage(),
      _AppView.profile => ProfilePage(
        headerTitle: _auth.user!.displayName,
        isLoading:
            _profile.status != ProfileStatus.ready &&
            _profile.status != ProfileStatus.failure,
        failure: _profile.status == ProfileStatus.failure
            ? _profile.failure
            : null,
        data: _profile.profile == null
            ? null
            : ProfileViewMapper.map(_profile.profile!),
        onBack: _goToSettings,
        onRetry: _profile.load,
        onEdit: () => _showSnack('Edición de perfil próximamente'),
      ),
      _AppView.admin =>
        _isAdmin
            ? AdminPanelPage(
                greetingName: _greetingName(),
                onBack: _goToSettings,
                onItemSelected: _onAdminItem,
              )
            : _settingsPage(),
      _AppView.scheduleRehearsal =>
        _isAdmin
            ? CreateRehearsalPage(
                controller: widget.rehearsalFormController,
                onBack: _backToAdmin,
                onCreated: () {
                  _backToAdmin();
                  _showSnack('Ensayo programado.');
                },
              )
            : _settingsPage(),
      _AppView.generateQr =>
        _isAdmin
            ? GenerateQrPage(
                onBack: _backToAdmin,
                qrApi: AttendanceQrApi(rehearsalApi: widget.rehearsalApi),
              )
            : _settingsPage(),
      _AppView.adminAttendance =>
        _isAdmin
            ? AdminAttendancePage(
                onBack: _backToAdmin,
                rehearsalApi: widget.rehearsalApi,
              )
            : _settingsPage(),
      _AppView.ministryMembers =>
        _isAdmin
            ? MinistryMembersPage(
                onBack: _backToAdmin,
                repository: widget.rehearsalFormController.repository,
                onResetPassword: (userId) => _auth.resetPassword(userId),
              )
            : _settingsPage(),
      _AppView.changePassword => ChangePasswordPage(
        forced: _auth.user?.mustChangePassword == true,
        onBack: _goToSettings,
        onSubmit: ({required currentPassword, required newPassword}) async {
          final error = await _auth.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
          if (error == null && mounted) {
            await _finishPasswordChange();
          }
          return error;
        },
      ),
      _AppView.forgotPassword => ForgotPasswordPage(
        failure: _auth.failure,
        onBack: _goToLogin,
        onSubmit: _handleRecoverPassword,
      ),
      _AppView.login => LoginPage(
        failure: _auth.failure,
        onSubmit: _handleLogin,
        onForgotPassword: _goToForgotPassword,
        onResetPassword: _goToForgotPassword,
        onRegister: _goToRegister,
      ),
    };
  }
}
