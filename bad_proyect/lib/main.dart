// =============================================================================
// Living Grace — versión ESPAGUETI (anti-SOLID)
//
// Todo está mezclado a propósito: UI, HTTP, validación, navegación y estado
// global en un solo archivo. Sirve para contrastar con el proyecto raíz,
// que usa capas, contratos e inyección de dependencias.
// =============================================================================

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// variables globales porque "es más rápido" y todo el mundo las toca
String pantalla = "splash";
String token = "";
String tokenType = "bearer";
String nombreQueQuedo = "";
String correoQueQuedo = "";
String errorLogin = "";
String errorRegistro = "";
String URL = "https://living-grace-back.onrender.com";
Map datosUsuario = {};

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print("API: " + URL);
  runApp(MaterialApp(
    title: "Living Grace",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
    ),
    home: AppTodaMezclada(),
  ));
}

class AppTodaMezclada extends StatefulWidget {
  @override
  _AppTodaMezcladaState createState() => _AppTodaMezcladaState();
}

class _AppTodaMezcladaState extends State<AppTodaMezclada> {
  // todos los controllers viven aquí aunque no se usen en la pantalla actual
  TextEditingController loginUser = TextEditingController();
  TextEditingController loginPass = TextEditingController();
  TextEditingController nombres = TextEditingController();
  TextEditingController apellidos = TextEditingController();
  TextEditingController celular = TextEditingController();
  TextEditingController fechaTxt = TextEditingController();
  TextEditingController correo = TextEditingController();
  TextEditingController pass1 = TextEditingController();
  TextEditingController pass2 = TextEditingController();
  DateTime? fechaNacimiento;
  TapGestureRecognizer? recReset;
  TapGestureRecognizer? recIrRegistro;
  TapGestureRecognizer? recIrLogin;

  @override
  void initState() {
    super.initState();
    recReset = TapGestureRecognizer()
      ..onTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restablecer contraseña próximamente")),
        );
      };
    recIrRegistro = TapGestureRecognizer()
      ..onTap = () {
        errorLogin = "";
        errorRegistro = "";
        setState(() {
          pantalla = "register";
        });
      };
    recIrLogin = TapGestureRecognizer()
      ..onTap = () {
        errorLogin = "";
        errorRegistro = "";
        setState(() {
          pantalla = "login";
        });
      };
    // splash a los 2.2 segundos hardcoded
    Future.delayed(Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        pantalla = "login";
      });
    });
  }

  @override
  void dispose() {
    loginUser.dispose();
    loginPass.dispose();
    nombres.dispose();
    apellidos.dispose();
    celular.dispose();
    fechaTxt.dispose();
    correo.dispose();
    pass1.dispose();
    pass2.dispose();
    recReset?.dispose();
    recIrRegistro?.dispose();
    recIrLogin?.dispose();
    super.dispose();
  }

  // login + http + parseo + UI todo junto
  void hacerLogin() async {
    var u = loginUser.text.trim();
    var p = loginPass.text;
    errorLogin = "";
    if (u == "" || p == "") {
      setState(() {
        errorLogin = "Ingresa tu correo y contraseña para continuar.";
        pantalla = "login";
      });
      return;
    }

    setState(() {
      pantalla = "loadingLogin";
    });

    try {
      var url = Uri.parse(URL + "/auth/login");
      var body = {"identifier": u, "password": p};
      print("┌──────── API REQUEST ────────");
      print("│ POST " + url.toString());
      print("│ body: " + jsonEncode({"identifier": u, "password": "********"}));
      print("└─────────────────────────────");

      var res = await http
          .post(
            url,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 45));

      print("┌──────── API RESPONSE ───────");
      print("│ status: " + res.statusCode.toString());
      print("│ body: " + res.body);
      print("└─────────────────────────────");

      if (res.statusCode == 200) {
        var json = jsonDecode(res.body);
        token = json["access_token"] ?? "";
        tokenType = json["token_type"] ?? "bearer";
        correoQueQuedo = u;
        if (u.contains("@")) {
          nombreQueQuedo = u.split("@")[0];
        } else {
          nombreQueQuedo = u;
        }
        datosUsuario["email"] = u;
        datosUsuario["name"] = nombreQueQuedo;
        datosUsuario["token"] = token;
        setState(() {
          pantalla = "home";
          errorLogin = "";
        });
      } else {
        setState(() {
          pantalla = "login";
          errorLogin =
              "Su correo o contraseña no es correcta. Si no recuerda su contraseña, puede restablecerla ahora.";
        });
      }
    } catch (e) {
      print("error login: " + e.toString());
      setState(() {
        pantalla = "login";
        errorLogin = "No pudimos conectar. Intenta de nuevo más tarde.";
      });
    }
  }

  // registro + validaciones + http + snackbar todo junto
  void hacerRegistro() async {
    var n = nombres.text.trim();
    var a = apellidos.text.trim();
    var cel = celular.text.trim();
    var mail = correo.text.trim();
    var p1 = pass1.text;
    var p2 = pass2.text;
    errorRegistro = "";

    if (n == "" ||
        a == "" ||
        cel == "" ||
        fechaNacimiento == null ||
        mail == "" ||
        p1 == "" ||
        p2 == "") {
      setState(() {
        errorRegistro = "Completa todos los campos para crear tu cuenta.";
        pantalla = "register";
      });
      return;
    }

    var emailOk = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(mail);
    if (!emailOk) {
      setState(() {
        errorRegistro = "Ingresa un correo electrónico válido.";
        pantalla = "register";
      });
      return;
    }

    if (!RegExp(r'^9\d{8}$').hasMatch(cel)) {
      setState(() {
        errorRegistro = "Ingresa un celular peruano de 9 dígitos.";
        pantalla = "register";
      });
      return;
    }

    if (p1.length < 8) {
      setState(() {
        errorRegistro = "La contraseña debe tener al menos 8 caracteres.";
        pantalla = "register";
      });
      return;
    }

    if (p1 != p2) {
      setState(() {
        errorRegistro = "Las contraseñas no coinciden.";
        pantalla = "register";
      });
      return;
    }

    var mes = fechaNacimiento!.month.toString().padLeft(2, "0");
    var dia = fechaNacimiento!.day.toString().padLeft(2, "0");
    var fechaApi = fechaNacimiento!.year.toString() + "-" + mes + "-" + dia;

    setState(() {
      pantalla = "loadingRegister";
    });

    try {
      var url = Uri.parse(URL + "/users/register");
      // username no está en el form, se manda estático
      var body = {
        "email": mail,
        "username": "usuario",
        "password": p1,
        "first_name": n,
        "last_name": a,
        "phone": cel,
        "birth_date": fechaApi,
      };
      print("┌──────── API REQUEST ────────");
      print("│ POST " + url.toString());
      print("│ body: " +
          jsonEncode({
            ...body,
            "password": "********",
          }));
      print("└─────────────────────────────");

      var res = await http
          .post(
            url,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 45));

      print("┌──────── API RESPONSE ───────");
      print("│ status: " + res.statusCode.toString());
      print("│ body: " + res.body);
      print("└─────────────────────────────");

      if (res.statusCode == 201) {
        nombres.clear();
        apellidos.clear();
        celular.clear();
        fechaTxt.clear();
        correo.clear();
        pass1.clear();
        pass2.clear();
        fechaNacimiento = null;
        setState(() {
          pantalla = "login";
          errorRegistro = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cuenta creada. Ahora inicia sesión.")),
        );
      } else {
        var msg = "No pudimos crear la cuenta. Intenta de nuevo.";
        try {
          var j = jsonDecode(res.body);
          if (j["detail"] != null) {
            if (j["detail"] is String) {
              msg = j["detail"];
            } else if (j["detail"] is List && j["detail"].length > 0) {
              msg = j["detail"][0]["msg"] ?? msg;
            }
          }
          var txt = msg.toString().toLowerCase();
          if (txt.contains("already") ||
              txt.contains("registered") ||
              txt.contains("existe")) {
            msg = "Ya existe una cuenta con este correo.";
          }
        } catch (e) {}
        setState(() {
          pantalla = "register";
          errorRegistro = msg;
        });
      }
    } catch (e) {
      print("error register: " + e.toString());
      setState(() {
        pantalla = "register";
        errorRegistro = "No pudimos conectar. Intenta de nuevo más tarde.";
      });
    }
  }

  void pickFecha() async {
    var now = DateTime.now();
    var picked = await showDatePicker(
      context: context,
      initialDate: fechaNacimiento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    fechaNacimiento = picked;
    var d = picked.day.toString().padLeft(2, "0");
    var m = picked.month.toString().padLeft(2, "0");
    fechaTxt.text = d + "/" + m + "/" + picked.year.toString();
    setState(() {});
  }

  // logo copiado/pegado como función suelta
  Widget logo(Color color, double living, double grace) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Living",
          style: GoogleFonts.playfairDisplay(
            fontSize: living,
            fontWeight: FontWeight.w500,
            height: 1,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
        Text(
          "Grace",
          style: GoogleFonts.playfairDisplay(
            fontSize: grace,
            fontWeight: FontWeight.w600,
            height: 0.92,
            letterSpacing: -1.5,
            color: color,
          ),
        ),
      ],
    );
  }

  // misma decoración de input repetida a mano en cada campo
  InputDecoration deco({Widget? icono}) {
    return InputDecoration(
      filled: true,
      fillColor: Color(0xFFE8E8E8),
      counterText: "",
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      suffixIcon: icono,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget campo(String label, TextEditingController c,
      {bool pass = false,
      TextInputType? tipo,
      int? max,
      List<TextInputFormatter>? fmt,
      bool readOnly = false,
      VoidCallback? onTap,
      Widget? icono,
      Function(String)? onDone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF9A9A9A),
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: c,
          obscureText: pass,
          readOnly: readOnly,
          keyboardType: tipo,
          maxLength: max,
          inputFormatters: fmt,
          onTap: onTap,
          onSubmitted: onDone,
          style: TextStyle(fontSize: 15, color: Colors.black),
          decoration: deco(icono: icono),
        ),
      ],
    );
  }

  Widget botonNegro(String texto, VoidCallback fn) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: fn,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 0,
          ),
          child: Text(
            texto,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget pantallaCarga(String msg) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Center(child: logo(Colors.black, 28, 56)),
              Align(
                alignment: Alignment(0, 0.55),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      msg,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget layoutAuth({required Widget child, int h = 4, int b = 6}) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              flex: h,
              child: SafeArea(
                bottom: false,
                child: Center(child: logo(Colors.white, 26, 52)),
              ),
            ),
            Expanded(
              flex: b,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(72),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(32, 20, 32, 20),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // un switch gigante en vez de páginas / rutas / capas
    if (pantalla == "splash") {
      return pantallaCarga("Cargando...");
    }

    if (pantalla == "loadingLogin") {
      return pantallaCarga("Iniciando Sesión...");
    }

    if (pantalla == "loadingRegister") {
      return pantallaCarga("Creando tu cuenta...");
    }

    if (pantalla == "home") {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Text(
                    "Inicio",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        logo(Colors.black, 22, 44),
                        SizedBox(height: 28),
                        Text(
                          "Bienvenido, " + nombreQueQuedo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          correoQueQuedo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9A9A9A),
                          ),
                        ),
                        Spacer(),
                        botonNegro("Cerrar sesión", () {
                          token = "";
                          tokenType = "bearer";
                          nombreQueQuedo = "";
                          correoQueQuedo = "";
                          datosUsuario = {};
                          loginPass.clear();
                          setState(() {
                            pantalla = "login";
                          });
                        }),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (pantalla == "register") {
      return layoutAuth(
        h: 2,
        b: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8),
                    if (errorRegistro != "")
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          errorRegistro,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    Text(
                      "Datos Personales",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    campo("Nombres", nombres, tipo: TextInputType.name),
                    SizedBox(height: 16),
                    campo("Apellidos", apellidos, tipo: TextInputType.name),
                    SizedBox(height: 16),
                    campo(
                      "Celular",
                      celular,
                      tipo: TextInputType.phone,
                      max: 9,
                      fmt: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    SizedBox(height: 16),
                    campo(
                      "Fecha Nacimiento",
                      fechaTxt,
                      readOnly: true,
                      onTap: pickFecha,
                      icono: IconButton(
                        onPressed: pickFecha,
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: Color(0xFF9A9A9A),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    campo(
                      "Correo Electrónico",
                      correo,
                      tipo: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    campo("Contraseña", pass1, pass: true),
                    SizedBox(height: 16),
                    campo(
                      "Confirmar Contraseña",
                      pass2,
                      pass: true,
                      onDone: (v) {
                        hacerRegistro();
                      },
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            botonNegro("Crear Cuenta", hacerRegistro),
            SizedBox(height: 16),
            Center(
              child: Text.rich(
                TextSpan(
                  text: "¿Ya tienes una cuenta? ",
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
                  children: [
                    TextSpan(
                      text: "Inicia Sesión",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: recIrLogin,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // login por defecto
    return layoutAuth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spacer(flex: 2),
          if (errorLogin != "")
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: errorLogin.contains("restablecerla")
                  ? Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFFE53935),
                        ),
                        children: [
                          TextSpan(
                            text:
                                "Su correo o contraseña no es correcta. Si no recuerda su contraseña, ",
                          ),
                          TextSpan(
                            text: "puede restablecerla ahora.",
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF1565C0),
                            ),
                            recognizer: recReset,
                          ),
                        ],
                      ),
                    )
                  : Text(
                      errorLogin,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFFE53935),
                      ),
                    ),
            ),
          campo(
            "E-mail o Usuario",
            loginUser,
            tipo: TextInputType.emailAddress,
          ),
          SizedBox(height: 18),
          campo(
            "Contraseña",
            loginPass,
            pass: true,
            onDone: (v) {
              hacerLogin();
            },
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Recuperación de contraseña próximamente"),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFB0B0B0),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "¿Olvidaste tu contraseña?",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          SizedBox(height: 28),
          botonNegro("Iniciar Sesión", hacerLogin),
          Spacer(flex: 3),
          Center(
            child: Text.rich(
              TextSpan(
                text: "Aún no tienes una cuenta? ",
                style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
                children: [
                  TextSpan(
                    text: "Regístrate",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: recIrRegistro,
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
