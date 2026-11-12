import 'package:flutter/material.dart';

import '../../core/layouts/auth_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/failures/auth_failure.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Recupera el acceso con la clave temporal del admin y `POST /auth/change-password`.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.onSubmit,
    required this.onBack,
    this.failure,
  });

  final Future<AuthFailure?> Function({
    required String identifier,
    required String temporaryPassword,
    required String newPassword,
  })
  onSubmit;
  final VoidCallback onBack;
  final AuthFailure? failure;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifier = TextEditingController();
  final _temporary = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _identifier.dispose();
    _temporary.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifier.text.trim();
    final temporary = _temporary.text;
    final next = _next.text;
    if (identifier.isEmpty || temporary.isEmpty || next.isEmpty) {
      setState(() => _error = 'Completa correo, clave temporal y nueva contraseña.');
      return;
    }
    if (next.length < 8) {
      setState(
        () => _error = 'La nueva contraseña debe tener al menos 8 caracteres.',
      );
      return;
    }
    if (next != _confirm.text) {
      setState(() => _error = 'La confirmación no coincide.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await widget.onSubmit(
      identifier: identifier,
      temporaryPassword: temporary,
      newPassword: next,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = failure?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _error ?? widget.failure?.message;
    return AuthLayout(
      headerFlex: 2,
      bodyFlex: 8,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _submitting ? null : widget.onBack,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            const Text(
              'Olvidé mi contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pide a un administrador una clave temporal. Inicia con esa clave y elige una nueva.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.label, height: 1.35),
            ),
            const SizedBox(height: 20),
            if (message != null) ...[
              Text(
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: 'Correo electrónico',
              controller: _identifier,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Contraseña temporal',
              controller: _temporary,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Nueva contraseña',
              controller: _next,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirmar contraseña',
              controller: _confirm,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Cambiar contraseña',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
