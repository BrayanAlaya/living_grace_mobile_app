import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/session_loading_page.dart';
import 'pages/splash_page.dart';

enum _AppView { splash, login, sessionLoading, home }

/// Orquesta las pantallas de la app sobre el árbol de layouts.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppView _view = _AppView.splash;

  AuthController get _auth => widget.authController;

  void _goToLogin() {
    setState(() => _view = _AppView.login);
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
      _AppView.home => HomePage(
          user: _auth.user!,
          onLogout: _handleLogout,
        ),
      _AppView.login => LoginPage(
          failure: _auth.failure,
          onSubmit: _handleLogin,
          onForgotPassword: () =>
              _showSnack('Recuperación de contraseña próximamente'),
          onResetPassword: () =>
              _showSnack('Restablecer contraseña próximamente'),
          onRegister: () => _showSnack('Registro próximamente'),
        ),
    };
  }
}
