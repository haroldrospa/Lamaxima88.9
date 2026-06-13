import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../../models/programa.dart';
import '../../providers/admin_provider.dart';

class ManagePrograms extends StatefulWidget {
  const ManagePrograms({super.key});

  @override
  State<ManagePrograms> createState() => _ManageProgramsState();
}

class _ManageProgramsState extends State<ManagePrograms> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _locutorController = TextEditingController();
  final _imagenUrlController = TextEditingController();
  
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 9, minute: 0);
  
  String? _editingId;

  @override
  void dispose() {
    _nombreController.dispose();
    _locutorController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  // Utilidad para formatear TimeOfDay a String "HH:mm:00"
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Utilidad para parsear "HH:mm:ss" o "HH:mm" a TimeOfDay
  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = isStart ? _horaInicio : _horaFin;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.gold,
              onPrimary: Colors.white,
              onSurface: AppTheme.softBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  void _openFormModal([Programa? programa]) {
    if (programa != null) {
      _editingId = programa.id;
      _nombreController.text = programa.nombre;
      _locutorController.text = programa.locutor;
      _imagenUrlController.text = programa.imagen;
      _horaInicio = _parseTimeString(programa.horaInicio);
      _horaFin = _parseTimeString(programa.horaFin);
    } else {
      _editingId = null;
      _nombreController.clear();
      _locutorController.clear();
      _imagenUrlController.clear();
      _horaInicio = const TimeOfDay(hour: 8, minute: 0);
      _horaFin = const TimeOfDay(hour: 9, minute: 0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder( // Permite actualizar las horas seleccionadas en tiempo real dentro del modal
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _editingId == null ? 'Nuevo Programa' : 'Editar Programa',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre del Programa'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _locutorController,
                        decoration: const InputDecoration(labelText: 'Locutor / Host'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),

                      // Selectores de Hora
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _selectTime(context, true);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.access_time, color: AppTheme.gold),
                              label: Text('Inicio: ${_horaInicio.format(context)}', style: const TextStyle(color: AppTheme.softBlack)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _selectTime(context, false);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.access_time, color: AppTheme.gold),
                              label: Text('Fin: ${_horaFin.format(context)}', style: const TextStyle(color: AppTheme.softBlack)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _imagenUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de Foto del Locutor',
                          hintText: 'https://ejemplo.com/locutor.jpg',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('GUARDAR PROGRAMA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final adminProvider = context.read<AdminProvider>();
    Navigator.pop(context); // Cerrar bottom sheet

    try {
      await adminProvider.savePrograma(
        id: _editingId,
        nombre: _nombreController.text.trim(),
        locutor: _locutorController.text.trim(),
        horaInicio: _formatTimeOfDay(_horaInicio),
        horaFin: _formatTimeOfDay(_horaFin),
        existingImageUrl: _imagenUrlController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Programa guardado con éxito.'), backgroundColor: AppTheme.gold),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar programa: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Programa'),
        content: const Text('¿Estás seguro de que deseas eliminar este programa de la programación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<AdminProvider>().removePrograma(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programa eliminado con éxito.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final programas = adminProvider.programas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROGRAMAS Y GRILLA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 80.0),
        itemCount: programas.length,
        itemBuilder: (context, index) {
          final programa = programas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10.0),
            child: ListTile(
              title: Text(programa.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Locutor: ${programa.locutor} | Horario: ${programa.formattedSchedule}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _openFormModal(programa),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _delete(programa.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.white,
        onPressed: () => _openFormModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
