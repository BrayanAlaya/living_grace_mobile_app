import 'package:flutter/material.dart';

import '../domain/entities/register_data.dart';
import '../register/ministry/ministry_catalog.dart';
import '../register/register_controller.dart';
import '../register/register_validator.dart';
import '../rehearsals/rehearsal_api.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/rehearsal_form_controller.dart';
import 'pages/admin_panel_page.dart';
import 'pages/create_rehearsal_page.dart';
import 'pages/home_page.dart';
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
  settings,
  profile,
  admin,
  scheduleRehearsal,
}

/// Orquesta las pantallas de la app sobre el árbol de layouts.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authController,
    required this.profileController,
    required this.rehearsalFormController,
    required this.registerController,
    required this.ministryCatalog,
    required this.registerValidator,
    required this.rehearsalApi,
  });

  final AuthController authController;
  final ProfileController profileController;
  final RehearsalFormController rehearsalFormController;
  final RegisterController registerController;
  final MinistryCatalog ministryCatalog;
  final RegisterValidator registerValidator;
  final RehearsalApi rehearsalApi;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppView _view = _AppView.splash;
  int _registerStep = 0;

  AuthController get _auth => widget.authController;
  ProfileController get _profile => widget.profileController;
  RegisterController get _register => widget.registerController;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onProfileChanged);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileController == _profile) return;
    oldWidget.profileController.removeListener(_onProfileChanged);
    _profile.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
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
  }

  void _goToHome() {
    setState(() => _view = _AppView.home);
  }

  void _goToSettings() {
    setState(() => _view = _AppView.settings);
  }

  void _goToProfile() {
    setState(() => _view = _AppView.profile);
    _profile.load();
  }

  bool get _isAdmin => _auth.user?.role.isAdmin ?? false;

  void _goToAdmin() {
    if (!_isAdmin) return;
    setState(() => _view = _AppView.admin);
    if (_profile.status == ProfileStatus.idle) {
      _profile.load();
    }
  }

  String _greetingName() {
    final firstName = _profile.profile?.firstName.trim() ?? '';
    if (firstName.isNotEmpty) return firstName;
    final displayName = _auth.user?.displayName.trim() ?? '';
    if (displayName.isEmpty) return '';
    return displayName.split(RegExp(r'\s+')).first;
  }

  String? _sessionUsername() {
    final id = _auth.user?.id ?? '';
    if (id.isEmpty || id.contains('@')) return null;
    return id;
  }

  void _onSettingsItem(String id) {
    if (id == SettingsItemId.profile) {
      _goToProfile();
      return;
    }
    if (id == SettingsItemId.adminPanel) {
      _goToAdmin();
      return;
    }
    _showSnack('Próximamente');
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
    _showSnack('Próximamente');
  }

  void _onPanelDestinationSelected(String destinationId) {
    if (destinationId == PanelMenuDestinations.home.id) {
      _goToHome();
      return;
    }
    if (destinationId == PanelMenuDestinations.settings.id) {
      _goToSettings();
    }
  }

  Future<void> _handleLogin(String identifier, String password) async {
    setState(() => _view = _AppView.sessionLoading);

    final success = await _auth.login(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _view = success ? _AppView.home : _AppView.login;
    });
  }

  Future<void> _handleRegister(RegisterData data) async {
    final validation = widget.registerValidator.validate(data);
    if (validation != null) {
      _register.showFailure(validation);
      setState(() {});
      return;
    }

    setState(() => _view = _AppView.registrationLoading);

    final success = await _register.register(data);

    if (!mounted) return;

    setState(() {
      _registerStep = success ? 0 : 1;
      _view = success ? _AppView.login : _AppView.register;
    });

    if (success) {
      _register.reset();
      _showSnack('Cuenta creada. Ahora inicia sesión.');
    }
  }

  Future<void> _handleLogout() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() => _view = _AppView.login);
  }

  Widget _settingsPage() {
    final user = _auth.user!;
    return SettingsPage(
      displayName: user.displayName,
      sections: SettingsCatalog.forRole(user.role),
      onBack: _goToHome,
      onLogout: _handleLogout,
      onEditPhoto: () => _showSnack('Foto de perfil próximamente'),
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
        catalog: widget.ministryCatalog,
        validator: widget.registerValidator,
        initialStep: _registerStep,
        failure: _register.failure,
        onSubmit: _handleRegister,
        onLogin: _goToLogin,
      ),
      _AppView.home => HomePage(
          user: _auth.user!,
          onOpenSettings: _goToSettings,
          onDestinationSelected: _onPanelDestinationSelected,
          rehearsalApi: widget.rehearsalApi,
        ),
      _AppView.settings => SettingsPage(
          user: _auth.user!,
          onLogout: _handleLogout,
          onOpenSettings: _goToSettings,
          onDestinationSelected: _onPanelDestinationSelected,
        ),
      _AppView.login => LoginPage(
        failure: _auth.failure,
        onSubmit: _handleLogin,
        onForgotPassword: () =>
            _showSnack('Recuperación de contraseña próximamente'),
        onResetPassword: () =>
            _showSnack('Restablecer contraseña próximamente'),
        onRegister: _goToRegister,
      ),
    };
  }
}
