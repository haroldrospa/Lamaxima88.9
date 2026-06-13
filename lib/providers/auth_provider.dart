import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  User? _user;
  Perfil? _perfil;
  bool _isLoading = true;

  // Getters
  User? get user => _user;
  Perfil? get perfil => _perfil;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _perfil?.isAdmin ?? false;

  AuthProvider() {
    // Escuchar los cambios del estado de autenticación
    _supabaseService.authStateChanges.listen((state) async {
      _user = state.user;
      if (_user != null) {
        _isLoading = true;
        notifyListeners();
        
        // Cargar el perfil detallado del usuario (contiene si es admin)
        _perfil = await _supabaseService.fetchPerfil(_user!.id);
      } else {
        _perfil = null;
      }
      _isLoading = false;
      notifyListeners();
    });
    
    // Carga inicial al instanciar el proveedor
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _user = _supabaseService.currentUser;
    if (_user != null) {
      _perfil = await _supabaseService.fetchPerfil(_user!.id);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Registro de usuario
  Future<void> register(String email, String password, String nombre) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.signUp(
        email: email,
        password: password,
        nombre: nombre,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Inicio de sesión
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.signIn(email: email, password: password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Cierre de sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.signOut();
      _user = null;
      _perfil = null;
    } catch (e) {
      print('Error al cerrar sesión: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recargar perfil (útil tras actualizar foto o nombre)
  Future<void> reloadPerfil() async {
    if (_user != null) {
      _perfil = await _supabaseService.fetchPerfil(_user!.id);
      notifyListeners();
    }
  }
}
