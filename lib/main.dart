import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'theme.dart';
import 'views/home/home_view.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/admin_provider.dart';

// ==========================================
// CONFIGURACIÓN DE CREDENCIALES DE SUPABASE
// Reemplaza estos valores con las credenciales de tu proyecto.
// ==========================================
const String supabaseUrl = 'https://tu-proyecto.supabase.co';
const String supabaseAnonKey = 'tu-anon-key-de-supabase';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar reproducción en segundo plano
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.lamaxima885.channel.audio',
    androidNotificationChannelName: 'La Máxima Audio Playback',
    androidNotificationOngoing: true,
  );

  bool isSupabaseConfigured = false;

  // Inicializar Supabase con control de errores para evitar crashes por placeholders
  if (supabaseUrl != 'https://tu-proyecto.supabase.co' && 
      supabaseAnonKey != 'tu-anon-key-de-supabase') {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      isSupabaseConfigured = true;
    } catch (e) {
      print('Error al conectar con Supabase: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        // Estos solo se instancian si Supabase se inicializó correctamente
        if (isSupabaseConfigured) ...[
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
      ],
      child: MyApp(isConfigured: isSupabaseConfigured),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isConfigured;

  const MyApp({super.key, required this.isConfigured});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'La Máxima 88.9 FM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: isConfigured 
          ? const HomeView() 
          : const SupabaseSetupGuideScreen(),
    );
  }
}

// Pantalla informativa elegante si la base de datos no está vinculada aún
class SupabaseSetupGuideScreen extends StatelessWidget {
  const SupabaseSetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.settings_suggest,
                      size: 64,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'LA MÁXIMA 88.9 FM',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Paso de Configuración Requerido',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildStep(
                      num: '1',
                      title: 'Crea tu Proyecto en Supabase',
                      desc: 'Crea una cuenta gratuita en supabase.com y lanza un nuevo proyecto.',
                    ),
                    _buildStep(
                      num: '2',
                      title: 'Ejecuta el Script SQL',
                      desc: 'Ve a la pestaña SQL Editor en Supabase y ejecuta el contenido del archivo "supabase_schema.sql" simplificado.',
                    ),
                    _buildStep(
                      num: '3',
                      title: 'Configura el Storage Bucket',
                      desc: 'En Supabase Storage, crea una carpeta (bucket) pública llamada "imagenes".',
                    ),
                    _buildStep(
                      num: '4',
                      title: 'Agrega tus API Keys',
                      desc: 'Copia tu Project URL y Anon Key e ingrésalas en "lib/main.dart".',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Una vez configuradas las llaves en lib/main.dart, la aplicación se iniciará automáticamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.gold, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
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

  Widget _buildStep({required String num, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
