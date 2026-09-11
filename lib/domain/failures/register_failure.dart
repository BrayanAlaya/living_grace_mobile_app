sealed class RegisterFailure {
  const RegisterFailure(this.message);

  final String message;
}

class EmptyRegisterFieldsFailure extends RegisterFailure {
  const EmptyRegisterFieldsFailure()
      : super('Completa todos los campos para crear tu cuenta.');
}

class InvalidEmailFailure extends RegisterFailure {
  const InvalidEmailFailure()
      : super('Ingresa un correo electrónico válido.');
}

class InvalidPhoneFailure extends RegisterFailure {
  const InvalidPhoneFailure()
      : super('Ingresa un celular peruano de 9 dígitos.');
}

class WeakPasswordFailure extends RegisterFailure {
  const WeakPasswordFailure()
      : super('La contraseña debe tener al menos 8 caracteres.');
}

class PasswordMismatchFailure extends RegisterFailure {
  const PasswordMismatchFailure()
      : super('Las contraseñas no coinciden.');
}

class EmailAlreadyRegisteredFailure extends RegisterFailure {
  const EmailAlreadyRegisteredFailure()
      : super('Ya existe una cuenta con este correo.');
}

class RegisterNetworkFailure extends RegisterFailure {
  const RegisterNetworkFailure()
      : super('No pudimos conectar. Intenta de nuevo más tarde.');
}

class RegisterValidationFailure extends RegisterFailure {
  const RegisterValidationFailure(super.message);
}

class RegisterUnexpectedFailure extends RegisterFailure {
  const RegisterUnexpectedFailure([
    super.message = 'No pudimos crear la cuenta. Intenta de nuevo.',
  ]);
}
