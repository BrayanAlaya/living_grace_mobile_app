import 'package:flutter/material.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/failures/auth_failure.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// `POST /auth/change-password`
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
    required this.onSubmit,
    this.forced = false,
    this.onBack,
  });

  final Future<AuthFailure?> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSubmit;
  final bool forced;
  final VoidCallback? onBack;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _current.text;
    final next = _next.text;
    final confirm = _confirm.text;
    if (current.isEmpty || next.isEmpty) {
      setState(() => _error = 'Completa la contraseña actual y la nueva.');
      return;
    }
    if (next.length < 8) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'La confirmación no coincide.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await widget.onSubmit(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure != null) {
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (!widget.forced && widget.onBack != null)
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.chevron_left_rounded),
                  )
                else
                  const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Cambiar contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.forced
                  ? 'Debes cambiar la contraseña temporal antes de continuar.'
                  : 'Ingresa tu contraseña actual y la nueva.',
              style: const TextStyle(color: AppColors.label, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: 'Contraseña actual',
              controller: _current,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nueva contraseña',
              controller: _next,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirmar contraseña',
              controller: _confirm,
              obscureText: true,
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Guardar',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
