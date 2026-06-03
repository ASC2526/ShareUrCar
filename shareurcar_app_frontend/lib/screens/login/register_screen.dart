import 'dart:async';
import '../../app_theme.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final centerController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  Timer? _centerDebounce;
  List<Map<String, dynamic>> centerSuggestions = [];

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmController.text) {
      showError("Las contraseñas no coinciden");
      return;
    }

    try {
      final fullName = nameController.text.trim().split(" ");
      final firstname = fullName.first;
      final lastname = fullName.length > 1 ? fullName.sublist(1).join(" ") : "";

      await ApiService.register({
        "firstname": firstname,
        "lastname": lastname,
        "email": emailController.text,
        "password": passwordController.text,
        "center": centerController.text,
        "rating": 0,
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Éxito"),
          content: Text("Cuenta creada correctamente"),
        ),
      ).then((_) {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      showError(e.toString().replaceAll("Exception: ", ""));
    }
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text("Error"), content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kSecondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 30),

              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.directions_car,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 15),

              Text(
                "Crear cuenta",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                "Únete a ShareUrCar",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),

              SizedBox(height: 30),

              input("Nombre completo", nameController, Icons.person),
              input("Correo electrónico", emailController, Icons.email),
              Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: centerController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Centro Educativo (Ej: Mare Nostrum)",
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.school, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white24,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        if (_centerDebounce?.isActive ?? false) {
                          _centerDebounce!.cancel();
                        }
                        _centerDebounce = Timer(
                          Duration(milliseconds: 600),
                          () async {
                            final sug = await ApiService.getCenterSuggestions(
                              val,
                            );
                            if (mounted) {
                              setState(() => centerSuggestions = sug);
                            }
                          },
                        );
                      },
                    ),
                    // desplegable de resultados
                    if (centerSuggestions.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: centerSuggestions.length,
                          itemBuilder: (context, idx) => ListTile(
                            leading: Icon(
                              Icons.account_balance,
                              size: 18,
                              color: kPrimary,
                            ),
                            title: Text(
                              centerSuggestions[idx]['name'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            onTap: () => setState(() {
                              centerController.text =
                                  centerSuggestions[idx]['name'];
                              centerSuggestions.clear();
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              input(
                "Contraseña",
                passwordController,
                Icons.lock,
                obscure: true,
              ),
              input(
                "Confirmar contraseña",
                confirmController,
                Icons.lock,
                obscure: true,
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(15),
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text("Crear cuenta →"),
              ),

              SizedBox(height: 15),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "¿Ya tienes cuenta? Iniciar sesión",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget input(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.white24,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
