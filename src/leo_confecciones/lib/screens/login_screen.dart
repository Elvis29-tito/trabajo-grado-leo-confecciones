import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../providers/usuarios_provider.dart';
import '../utils/mensajes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _mensajeError = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar usuarios al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UsuariosProvider>(context, listen: false);
      provider.cargarUsuarios();
    });
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _iniciarSesion() async {
    String email = _usuarioController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _mensajeError = 'Ingrese usuario y contraseña';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensajeError = '';
    });

    try {
      final provider = Provider.of<UsuariosProvider>(context, listen: false);
      final success = await provider.login(email, password);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Limpiar campos
        _usuarioController.clear();
        _passwordController.clear();
        
        // Navegar al Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _mensajeError = provider.error ?? 'Usuario o contraseña incorrectos';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensajeError = 'Error al iniciar sesión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3A5F), Color(0xFF2C5F8A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.curtains,
                      size: 80,
                      color: Color(0xFF1A3A5F),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'LEO CONFECCIONES',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5F),
                      ),
                    ),
                    const Text(
                      'Gestión de Ventas y Stock',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _usuarioController,
                      decoration: const InputDecoration(
                        labelText: 'Email o Usuario',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        hintText: 'admin@leo.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _iniciarSesion(),
                    ),
                    if (_mensajeError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _mensajeError,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0xFF1A3A5F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'INGRESAR',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Usuario: admin@leo.com  |  Contraseña: 1234',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}