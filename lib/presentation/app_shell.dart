import 'package:flutter/material.dart';

import '../domain/entities/register_data.dart';
import '../login/login_controller.dart';
import '../register/ministry/ministry_catalog.dart';
import '../register/register_controller.dart';
import '../register/register_validator.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/registration_loading_page.dart';
import 'pages/session_loading_page.dart';
import 'pages/splash_page.dart';

enum _AppView {
  splash,
  login,
  sessionLoading,
  register,
  registrationLoading,
  home,
}

/// Orquesta las pantallas de la app sobre el árbol de layouts.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.loginController,
    required this.registerController,
    required this.ministryCatalog,
    required this.registerValidator,
  });

  final LoginController loginController;
  final RegisterController registerController;
  final MinistryCatalog ministryCatalog;
  final RegisterValidator registerValidator;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppView _view = _AppView.splash;
  int _registerStep = 0;

  LoginController get _login => widget.loginController;
  RegisterController get _register => widget.registerController;

  void _goToLogin() {
    _register.clearFailure();
    setState(() => _view = _AppView.login);
  }

  void _goToRegister() {
    _login.clearFailure();
    _register.clearFailure();
    _registerStep = 0;
    setState(() => _view = _AppView.register);
  }

  Future<void> _handleLogin(String identifier, String password) async {
    setState(() => _view = _AppView.sessionLoading);

    final success = await _login.login(
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

  void _handleLogout() {
    _login.logout();
    setState(() => _view = _AppView.login);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _AppView.splash => SplashPage(onReady: _goToLogin),
      _AppView.sessionLoading => const SessionLoadingPage(),
      _AppView.registrationLoading => const RegistrationLoadingPage(),
      _AppView.home => HomePage(
          user: _login.user!,
          onLogout: _handleLogout,
        ),
      _AppView.register => RegisterPage(
          catalog: widget.ministryCatalog,
          validator: widget.registerValidator,
          initialStep: _registerStep,
          failure: _register.failure,
          onSubmit: _handleRegister,
          onLogin: _goToLogin,
        ),
      _AppView.login => LoginPage(
          failure: _login.failure,
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
