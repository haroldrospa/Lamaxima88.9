import 'package:flutter/material.dart';

class Programa {
  final String id;
  final String nombre;
  final String locutor;
  final String imagen;
  final String horaInicio; // Formato: "HH:mm:ss" o "HH:mm"
  final String horaFin;    // Formato: "HH:mm:ss" o "HH:mm"

  Programa({
    required this.id,
    required this.nombre,
    required this.locutor,
    required this.imagen,
    required this.horaInicio,
    required this.horaFin,
  });

  factory Programa.fromJson(Map<String, dynamic> json) {
    return Programa(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      locutor: json['locutor'] as String? ?? '',
      imagen: json['imagen'] as String? ?? '',
      horaInicio: json['hora_inicio'] as String? ?? '00:00:00',
      horaFin: json['hora_fin'] as String? ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'locutor': locutor,
      'imagen': imagen,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    };
  }

  // Verifica si el programa está al aire según la hora del sistema
  bool isOnAirNow() {
    try {
      final now = TimeOfDay.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final startParts = horaInicio.split(':');
      final endParts = horaFin.split(':');

      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (endMinutes < startMinutes) {
        // El programa cruza la medianoche (ej. 23:00 a 01:00)
        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
      }

      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } catch (e) {
      return false;
    }
  }

  // Formatea la hora de inicio y fin para presentación del usuario (ej. 19:00 - 20:00)
  String get formattedSchedule {
    String cleanTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return timeStr;
    }
    return '${cleanTime(horaInicio)} - ${cleanTime(horaFin)}';
  }
}
