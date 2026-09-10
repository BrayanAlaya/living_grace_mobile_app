import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'controllers/register_controller.dart';
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
    required this.authController,
    required this.registerController,
  });

  final AuthController authController;
  final RegisterController registerController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppView _view = _AppView.splash;

  AuthController get _auth => widget.authController;
  RegisterController get _register => widget.registerController;

  void _goToLogin() {
    _register.clearFailure();
    setState(() => _view = _AppView.login);
  }

  void _goToRegister() {
    _auth.clearFailure();
    _register.clearFailure();
    setState(() => _view = _AppView.register);
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

  Future<void> _handleRegister(
    String displayName,
    String identifier,
    String password,
    String confirmPassword,
  ) async {
    setState(() => _view = _AppView.registrationLoading);

    final success = await _register.register(
      displayName: displayName,
      identifier: identifier,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    setState(() {
      _view = success ? _AppView.login : _AppView.register;
    });

    if (success) {
      _register.reset();
      _showSnack('Cuenta creada. Ahora inicia sesión.');
    }
  }

  void _handleLogout() {
    _auth.logout();
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
          user: _auth.user!,
          onLogout: _handleLogout,
        ),
      _AppView.register => RegisterPage(
          failure: _register.failure,
          onSubmit: _handleRegister,
          onLogin: _goToLogin,
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
