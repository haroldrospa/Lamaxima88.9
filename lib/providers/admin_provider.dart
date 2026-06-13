import 'package:flutter/material.dart';
import '../models/programa.dart';
import '../models/configuracion.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Programa> _programas = [];
  Configuracion? _configuracion;
  
  bool _isLoading = false;

  // Getters
  List<Programa> get programas => _programas;
  Configuracion? get configuracion => _configuracion;
  bool get isLoading => _isLoading;

  // Cargar todos los datos para las pantallas del panel admin
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _programas = await _supabaseService.fetchProgramas();
      _configuracion = await _supabaseService.fetchConfiguracion();
    } catch (e) {
      print('Error al cargar datos administrativos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Programas ---
  Future<void> savePrograma({
    String? id,
    required String nombre,
    required String locutor,
    required String horaInicio,
    required String horaFin,
    String? imagePath,
    String? existingImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      String imageUrl = existingImageUrl ?? '';
      if (imagePath != null && imagePath.isNotEmpty) {
        imageUrl = await _supabaseService.uploadImage(imagePath, 'programa_${DateTime.now().millisecond}.jpg');
      }

      final progObj = Programa(
        id: id ?? '',
        nombre: nombre,
        locutor: locutor,
        imagen: imageUrl,
        horaInicio: horaInicio,
        horaFin: horaFin,
      );

      if (id == null) {
        await _supabaseService.createPrograma(progObj);
      } else {
        await _supabaseService.updatePrograma(progObj);
      }
      await loadAllData();
    } catch (e) {
      print('Error al guardar programa: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removePrograma(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.deletePrograma(id);
      await loadAllData();
    } catch (e) {
      print('Error al eliminar programa: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Configuración ---
  Future<void> saveConfiguracion(Configuracion config) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.updateConfiguracion(config);
      _configuracion = config;
    } catch (e) {
      print('Error al guardar configuración: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
