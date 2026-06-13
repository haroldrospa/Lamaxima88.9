import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/programa.dart';
import '../models/configuracion.dart';
import '../models/perfil.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // AUTENTICACIÓN
  // ==========================================

  // Obtener usuario actual de Supabase Auth
  User? get currentUser => _client.auth.currentUser;

  // Stream del estado de autenticación
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Registro con Email y Contraseña
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nombre,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': nombre},
    );
  }

  // Inicio de Sesión con Email y Contraseña
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Cerrar Sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Obtener Perfil de Usuario público
  Future<Perfil?> fetchPerfil(String uid) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (response != null) {
        return Perfil.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }

  // Actualizar perfil de usuario
  Future<void> updatePerfil({
    required String uid,
    required String nombre,
    String? fotoUrl,
  }) async {
    final updates = {
      'nombre': nombre,
      if (fotoUrl != null) 'foto': fotoUrl,
    };
    await _client.from('users').update(updates).eq('id', uid);
  }

  // ==========================================
  // CONSULTAS PÚBLICAS (Lectoras)
  // ==========================================

  // Obtener todos los programas
  Future<List<Programa>> fetchProgramas() async {
    final response = await _client
        .from('programas')
        .select()
        .order('hora_inicio', ascending: true);
    return (response as List).map((json) => Programa.fromJson(json)).toList();
  }

  // Obtener configuración global (siempre id = 1)
  Future<Configuracion> fetchConfiguracion() async {
    final response = await _client
        .from('configuracion')
        .select()
        .eq('id', 1)
        .single();
    return Configuracion.fromJson(response);
  }

  // ==========================================
  // CARGA DE ARCHIVOS (Storage)
  // ==========================================

  // Subir imagen a Supabase Storage y retornar URL pública
  Future<String> uploadImage(String filePath, String fileName) async {
    final file = File(filePath);
    final fileExtension = fileName.split('.').last;
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}.$fileExtension';

    await _client.storage.from('imagenes').upload(uniqueName, file);
    return _client.storage.from('imagenes').getPublicUrl(uniqueName);
  }

  // ==========================================
  // OPERACIONES ADMINISTRATIVAS (CRUD)
  // ==========================================

  // --- Programas ---
  Future<void> createPrograma(Programa programa) async {
    await _client.from('programas').insert({
      'nombre': programa.nombre,
      'locutor': programa.locutor,
      'imagen': programa.imagen,
      'hora_inicio': programa.horaInicio,
      'hora_fin': programa.horaFin,
    });
  }

  Future<void> updatePrograma(Programa programa) async {
    await _client.from('programas').update({
      'nombre': programa.nombre,
      'locutor': programa.locutor,
      'imagen': programa.imagen,
      'hora_inicio': programa.horaInicio,
      'hora_fin': programa.horaFin,
    }).eq('id', programa.id);
  }

  Future<void> deletePrograma(String id) async {
    await _client.from('programas').delete().eq('id', id);
  }

  // --- Configuración Global ---
  Future<void> updateConfiguracion(Configuracion config) async {
    await _client.from('configuracion').update(config.toJson()).eq('id', 1);
  }
}
