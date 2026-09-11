import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String phone,
    required String birthDate,
    required String email,
    required String password,
    required String confirmPassword,
  }) onSubmit;
  final RegisterFailure? failure;
  final VoidCallback? onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TapGestureRecognizer _loginRecognizer;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _loginRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onLogin?.call();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _loginRecognizer.dispose();
    super.dispose();
  }

  String _apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    setState(() {
      _birthDate = picked;
      _birthDateController.text = _displayDate(picked);
    });
  }

  Future<void> _submit() async {
    await widget.onSubmit(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      birthDate: _birthDate == null ? '' : _apiDate(_birthDate!),
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      headerFlex: 2,
      bodyFlex: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  if (widget.failure != null) ...[
                    _RegisterErrorBanner(failure: widget.failure!),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Datos Personales',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Nombres',
                    controller: _firstNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Apellidos',
                    controller: _lastNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Celular',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 9,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Fecha Nacimiento',
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      onPressed: _pickBirthDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.label,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Correo Electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirmar Contraseña',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: 'Crear Cuenta',
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
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
