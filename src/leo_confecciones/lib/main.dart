import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/historial_cotizaciones.dart';
import 'providers/cotizacion_provider.dart';
import 'providers/productos_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/configuracion_provider.dart';
import 'providers/usuarios_provider.dart';
import 'services/firebase_service.dart';

void main() async {
  // 1. Asegurar que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializar Firebase
  try {
    await FirebaseService().init();
    print('🔥 Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
    // La app sigue funcionando aunque Firebase falle
  }
  
  // 3. Ejecutar la app
  runApp(const LeoConfeccionesApp());
}

class LeoConfeccionesApp extends StatelessWidget {
  const LeoConfeccionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CotizacionProvider()..cargarCotizaciones(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductosProvider()..cargarProductos(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientesProvider()..cargarClientes(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConfiguracionProvider()..cargarConfiguracion(),
        ),
        ChangeNotifierProvider(
          create: (_) => UsuariosProvider()..cargarUsuarios(),
        ),
      ],
      child: MaterialApp(
        title: 'LEO CONFECCIONES',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/historial': (context) => const HistorialCotizaciones(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}