import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/layouts/auth_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/failures/auth_failure.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// S — Single Responsibility: solo pinta el formulario de login.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onSubmit,
    this.failure,
    this.onForgotPassword,
    this.onRegister,
    this.onResetPassword,
  });

  final Future<void> Function(String identifier, String password) onSubmit;
  final AuthFailure? failure;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegister;
  final VoidCallback? onResetPassword;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _resetRecognizer;
  late final TapGestureRecognizer _registerRecognizer;

  @override
  void initState() {
    super.initState();
    _resetRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onResetPassword?.call();
    _registerRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onRegister?.call();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _resetRecognizer.dispose();
    _registerRecognizer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await widget.onSubmit(
      _identifierController.text,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          if (widget.failure != null) ...[
            _LoginErrorBanner(
              failure: widget.failure!,
              resetRecognizer: _resetRecognizer,
            ),
            const SizedBox(height: 16),
          ],
          AppTextField(
            label: 'E-mail o Usuario',
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Contraseña',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Iniciar Sesión',
            onPressed: _submit,
          ),
          const Spacer(flex: 3),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Aún no tienes una cuenta? ',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.footerText,
                ),
                children: [
                  TextSpan(
                    text: 'Regístrate',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: _registerRecognizer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({
    required this.failure,
    required this.resetRecognizer,
  });

  final AuthFailure failure;
  final TapGestureRecognizer resetRecognizer;

  @override
  Widget build(BuildContext context) {
    if (failure is InvalidCredentialsFailure) {
      return Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: AppColors.error,
          ),
          children: [
            const TextSpan(
              text:
                  'Su correo o contraseña no es correcta. Si no recuerda su contraseña, ',
            ),
            TextSpan(
              text: 'puede restablecerla ahora.',
              style: const TextStyle(
                color: AppColors.link,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.link,
              ),
              recognizer: resetRecognizer,
            ),
          ],
        ),
      );
    }

    return Text(
      failure.message,
      style: const TextStyle(
        fontSize: 12,
        height: 1.35,
        color: AppColors.error,
      ),
    );
  }
}
