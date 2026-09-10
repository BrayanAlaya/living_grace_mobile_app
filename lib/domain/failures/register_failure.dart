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

class WeakPasswordFailure extends RegisterFailure {
  const WeakPasswordFailure()
      : super('La contraseña debe tener al menos 6 caracteres.');
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
