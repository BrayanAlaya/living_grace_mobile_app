import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/layouts/auth_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/failures/register_failure.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onSubmit,
    this.failure,
    this.onLogin,
  });

  final Future<void> Function(
    String displayName,
    String identifier,
    String password,
    String confirmPassword,
  ) onSubmit;
  final RegisterFailure? failure;
  final VoidCallback? onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TapGestureRecognizer _loginRecognizer;

  @override
  void initState() {
    super.initState();
    _loginRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onLogin?.call();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _loginRecognizer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await widget.onSubmit(
      _nameController.text,
      _identifierController.text,
      _passwordController.text,
      _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  if (widget.failure != null) ...[
                    _RegisterErrorBanner(failure: widget.failure!),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    label: 'Nombre',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'E-mail',
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Confirmar Contraseña',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: 'Crear Cuenta',
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                text: '¿Ya tienes una cuenta? ',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.footerText,
                ),
                children: [
                  TextSpan(
                    text: 'Inicia Sesión',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: _loginRecognizer,
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

class _RegisterErrorBanner extends StatelessWidget {
  const _RegisterErrorBanner({required this.failure});

  final RegisterFailure failure;

  @override
  Widget build(BuildContext context) {
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
