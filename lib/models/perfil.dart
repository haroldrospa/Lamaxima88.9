class Perfil {
  final String id;
  final String nombre;
  final String email;
  final String foto;
  final bool isAdmin;
  final DateTime createdAt;

  Perfil({
    required this.id,
    required this.nombre,
    required this.email,
    required this.foto,
    required this.isAdmin,
    required this.createdAt,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      foto: json['foto'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'foto': foto,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
