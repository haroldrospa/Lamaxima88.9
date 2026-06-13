import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../../models/configuracion.dart';
import '../../providers/admin_provider.dart';

class ManageConfig extends StatefulWidget {
  const ManageConfig({super.key});

  @override
  State<ManageConfig> createState() => _ManageConfigState();
}

class _ManageConfigState extends State<ManageConfig> {
  final _formKey = GlobalKey<FormState>();
  
  final _streamRadioController = TextEditingController();
  final _streamTvController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _twitterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = context.read<AdminProvider>().configuracion;
    if (config != null) {
      _streamRadioController.text = config.streamRadio;
      _streamTvController.text = config.streamTv;
      _facebookController.text = config.facebook;
      _instagramController.text = config.instagram;
      _youtubeController.text = config.youtube;
      _tiktokController.text = config.tiktok;
      _twitterController.text = config.twitter;
    }
  }

  @override
  void dispose() {
    _streamRadioController.dispose();
    _streamTvController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final adminProvider = context.read<AdminProvider>();

    final updatedConfig = Configuracion(
      id: 1, // Siempre es 1
      streamRadio: _streamRadioController.text.trim(),
      streamTv: _streamTvController.text.trim(),
      facebook: _facebookController.text.trim(),
      instagram: _instagramController.text.trim(),
      youtube: _youtubeController.text.trim(),
      tiktok: _tiktokController.text.trim(),
      twitter: _twitterController.text.trim(),
    );

    try {
      await adminProvider.saveConfiguracion(updatedConfig);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada con éxito.'), backgroundColor: AppTheme.gold),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar configuración: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFIGURACIÓN GENERAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
      ),
      body: adminProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Transmisión
                    const Text(
                      'URLS DE TRANSMISIÓN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _streamRadioController,
                      decoration: const InputDecoration(
                        labelText: 'Streaming Radio (Audio)',
                        hintText: 'https://servidor.com/radio',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _streamTvController,
                      decoration: const InputDecoration(
                        labelText: 'Streaming TV Live (HLS / .m3u8)',
                        hintText: 'https://servidor.com/hls/live.m3u8',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 24),

                    // Redes Sociales
                    const Text(
                      'ENLACES DE REDES SOCIALES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _facebookController,
                      decoration: const InputDecoration(labelText: 'Facebook Link'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(labelText: 'Instagram Link'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(labelText: 'X (Twitter) Link'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tiktokController,
                      decoration: const InputDecoration(labelText: 'TikTok Link'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _youtubeController,
                      decoration: const InputDecoration(labelText: 'YouTube Link'),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('GUARDAR CONFIGURACIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
