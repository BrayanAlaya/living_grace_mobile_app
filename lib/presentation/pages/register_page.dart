import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/layouts/auth_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/register_data.dart';
import '../../domain/failures/register_failure.dart';
import '../../register/ministry/ministry_catalog.dart';
import '../../register/register_validator.dart';
import '../widgets/app_select_field.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.catalog,
    required this.validator,
    required this.onSubmit,
    this.failure,
    this.onLogin,
    this.initialStep = 0,
  });

  final MinistryCatalog catalog;
  final RegisterValidator validator;
  final Future<void> Function(RegisterData data) onSubmit;
  final RegisterFailure? failure;
  final VoidCallback? onLogin;
  final int initialStep;

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
  late int _step;
  String? _ministryId;
  String? _serviceAreaId;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _loginRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onLogin?.call();
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _birthDateController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _birthDateController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_refresh);
      controller.dispose();
    }
    _loginRecognizer.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

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

  bool get _canContinue => widget.validator.isPersonalDataComplete(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        birthDate: _birthDate == null ? '' : _apiDate(_birthDate!),
        email: _emailController.text,
      );

  bool get _canRegister => widget.validator.isCredentialsComplete(
        ministryId: _ministryId,
        serviceAreaId: _serviceAreaId,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

  Future<void> _submit() async {
    await widget.onSubmit(
      RegisterData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        birthDate: _birthDate == null ? '' : _apiDate(_birthDate!),
        email: _emailController.text,
        ministryId: _ministryId ?? '',
        serviceAreaId: _serviceAreaId ?? '',
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
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
                    Text(
                      widget.failure!.message,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _step == 0 ? 'Datos Personales' : 'Credenciales',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_step == 0) _personalFields() else _credentialsFields(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: _step == 0 ? 'Continuar' : 'Regístrate',
            onPressed: _step == 0
                ? (_canContinue ? () => setState(() => _step = 1) : null)
                : (_canRegister ? _submit : null),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Ya tienes una cuenta? ',
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

  Widget _personalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _credentialsFields() {
    final areas = widget.catalog.areasFor(_ministryId);
    final ministrySelected = _ministryId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField<String>(
          label: 'Ministerio',
          placeholder: 'Elige un ministerio',
          value: _ministryId,
          options: [
            for (final ministry in widget.catalog.ministries)
              AppSelectOption(value: ministry.id, label: ministry.name),
          ],
          onChanged: (id) {
            setState(() {
              _ministryId = id;
              _serviceAreaId = null;
            });
          },
        ),
        const SizedBox(height: 16),
        AppSelectField<String>(
          label: 'Área de servicio',
          placeholder: ministrySelected
              ? 'Elige un área'
              : 'Selecciona un ministerio',
          value: _serviceAreaId,
          enabled: ministrySelected,
          options: [
            for (final area in areas)
              AppSelectOption(value: area.id, label: area.name),
          ],
          onChanged: (id) => setState(() => _serviceAreaId = id),
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
          onSubmitted: (_) {
            if (_canRegister) _submit();
          },
        ),
      ],
    );
  }
}
