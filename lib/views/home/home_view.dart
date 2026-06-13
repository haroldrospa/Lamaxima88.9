import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

import '../../theme.dart';
import '../../models/programa.dart';
import '../../models/configuracion.dart';
import '../../services/supabase_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../account/login_view.dart';
import '../admin/admin_dashboard.dart';
import '../shared/mini_player.dart';
import 'widgets/wave_visualizer.dart';
import 'widgets/tv_player.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  
  late Future<Map<String, dynamic>> _homeDataFuture;
  late AnimationController _rotationController;
  
  bool _isRadioTab = true; // Controla la pestaña activa: true para Radio, false para TV

  @override
  void initState() {
    super.initState();
    _refreshData();
    
    // Controlador de animación para rotar la carátula en reproducción de radio
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  void _refreshData() {
    setState(() {
      _homeDataFuture = Future.wait([
        _supabaseService.fetchConfiguracion(),
        _supabaseService.fetchProgramas(),
      ]).then((results) {
        return {
          'config': results[0] as Configuracion,
          'programas': results[1] as List<Programa>,
        };
      });
    });
  }

  // Lanzar enlace externo a redes sociales
  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final url = Uri.parse(urlString);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('No se pudo abrir la URL externamente, intentando por defecto: $e');
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (err) {
        print('Error abriendo URL: $err');
      }
    }
  }

  // Función para manejar el acceso al panel administrativo oculto
  void _handleAdminAccess(BuildContext context, AuthProvider auth) {
    if (auth.isAuthenticated && auth.isAdmin) {
      // Si ya es admin, ingresa directo
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else {
      // Si no, abre modal de inicio de sesión/registro
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
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const SizedBox(
              height: 520,
              child: LoginView(),
            ),
          );
        },
      ).then((_) {
        // Al cerrar el login modal, si se autenticó como admin, abrir el dashboard
        if (auth.isAuthenticated && auth.isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDarkMode ? 'assets/logo_dark.png' : 'assets/logo.png';
    
    // Controlar animación de rotación según reproducción de radio
    final isRadioPlaying = audioProvider.isPlaying && audioProvider.currentType == AudioType.radio;
    if (isRadioPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    Widget contentBody = FutureBuilder<Map<String, dynamic>>(
      future: _homeDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitRing(color: AppTheme.gold, size: 50.0),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text('Error al conectar con el servidor', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final config = data['config'] as Configuracion;
        final programas = data['programas'] as List<Programa>;

        // Calcular el programa que está al aire
        Programa? programaAlAire;
        for (final prog in programas) {
          if (prog.isOnAirNow()) {
            programaAlAire = prog;
            break;
          }
        }

        return Column(
          children: [
            // 1. SELECTOR DESLIZANTE DE TABS (RADIO / TV)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
                child: Row(
                  children: [
                    // Tab Radio
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRadioTab = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isRadioTab ? AppTheme.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons.radio, 
                                  color: _isRadioTab ? Colors.white : Colors.grey,
                                  size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RADIO FM',
                                style: TextStyle(
                                  color: _isRadioTab ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tab TV
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRadioTab = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isRadioTab ? AppTheme.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Icon(
                                  Icons.videocam, 
                                  color: !_isRadioTab ? Colors.white : Colors.grey,
                                  size: 18,
                               ),
                               const SizedBox(width: 8),
                               Text(
                                 'CABINA EN VIVO',
                                 style: TextStyle(
                                   color: !_isRadioTab ? Colors.white : Colors.grey,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12,
                                 ),
                               ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. DETALLE DE CONTENIDO SEGÚN LA PESTAÑA SELECCIONADA
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                },
                color: AppTheme.gold,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120.0), // Espacio extra para el MiniPlayer
                  child: Column(
                    children: [
                      if (_isRadioTab) ...[
                        // ==========================================
                        // PESTAÑA: RADIO FM
                        // ==========================================
                        const SizedBox(height: 24),
                        // Logotipo/Vinilo giratorio interactivo
                        Center(
                          child: RotationTransition(
                            turns: _rotationController,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.softBlack,
                                border: Border.all(color: AppTheme.gold, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.gold.withOpacity(0.3),
                                    blurRadius: 25,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.asset(
                                      logoAsset,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Nombre del programa al aire e indicador de estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _LiveIndicator(),
                            const SizedBox(width: 6),
                            Text(
                              isRadioPlaying ? 'ESCUCHANDO AHORA' : 'RADIO EN VIVO',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.gold, letterSpacing: 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          programaAlAire?.nombre ?? 'Música Continuada',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        
                        // Visualizador de ondas dinámicas
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          width: 200,
                          child: WaveVisualizer(
                            isPlaying: isRadioPlaying,
                            barCount: 15,
                          ),
                        ),
                        
                        // Control Play/Pause Gigante
                        const SizedBox(height: 10),
                        IconButton(
                          icon: Icon(
                            isRadioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          ),
                          iconSize: 90,
                          color: AppTheme.gold,
                          onPressed: () {
                            final name = programaAlAire?.nombre ?? 'Música Continuada';
                            final img = programaAlAire?.imagen;
                            audioProvider.playRadio(config.streamRadio, name, imageUrl: img);
                          },
                        ),
                        
                        // Control de Volumen
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50.0),
                          child: Row(
                            children: [
                              const Icon(Icons.volume_mute, color: Colors.grey, size: 18),
                              Expanded(
                                child: Slider(
                                  value: audioProvider.volume,
                                  min: 0.0,
                                  max: 1.0,
                                  activeColor: AppTheme.gold,
                                  onChanged: (val) => audioProvider.setVolume(val),
                                ),
                              ),
                              const Icon(Icons.volume_up, color: Colors.grey, size: 18),
                            ],
                          ),
                        ),
                      ] else ...[
                        // ==========================================
                        // PESTAÑA: TELEVISIÓN HD
                        // ==========================================
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Stack(
                              children: [
                                TvPlayer(videoUrl: config.streamTv),
                                const Positioned(
                                  top: 12,
                                  left: 12,
                                  child: _LiveBadge(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LiveIndicator(),
                            SizedBox(width: 6),
                            Text(
                              'TRANSMISIÓN EN VIVO',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.gold, letterSpacing: 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'La Máxima TV HD',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],

                      // ==========================================
                      // COMÚN: REDES (Fácil lectura)
                      // ==========================================
                      const SizedBox(height: 12),

                      // Redes Sociales
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text(
                              'SÍGUENOS EN REDES',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSocialButton(
                                  icon: Icons.camera_alt,
                                  color: const Color(0xFFE1306C),
                                  onPressed: () => _launchUrl(config.instagram),
                                ),
                                _buildSocialButton(
                                  icon: Icons.facebook,
                                  color: const Color(0xFF1877F2),
                                  onPressed: () => _launchUrl(config.facebook),
                                ),
                                _buildSocialButton(
                                  icon: Icons.music_note,
                                  color: Colors.black,
                                  onPressed: () => _launchUrl(config.tiktok),
                                ),
                                _buildSocialButton(
                                  icon: Icons.play_arrow,
                                  color: const Color(0xFFFF0000),
                                  onPressed: () => _launchUrl(config.youtube),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              '© 2026 La Máxima 88.9 FM. Todos los derechos reservados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          logoAsset,
          height: 48,
          fit: BoxFit.contain,
        ),
        elevation: 0,
        actions: [
          // Botón oculto de administración (subtil llave/escudo)
          IconButton(
            icon: Icon(
              authProvider.isAuthenticated && authProvider.isAdmin 
                  ? Icons.admin_panel_settings 
                  : Icons.admin_panel_settings_outlined,
              color: authProvider.isAuthenticated && authProvider.isAdmin 
                  ? AppTheme.gold 
                  : AppTheme.softBlack,
            ),
            tooltip: 'Administración',
            onPressed: () => _handleAdminAccess(context, authProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          contentBody,
          // MiniPlayer persistente flotante en la parte inferior
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withOpacity(_controller.value * 0.7 + 0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity((1.0 - _controller.value) * 0.6),
                blurRadius: _controller.value * 8 + 2,
                spreadRadius: (1.0 - _controller.value) * 3,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LiveIndicator(),
          SizedBox(width: 6),
          Text(
            'EN VIVO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  final String name;
  final String time;
  final String host;
  _ScheduleItem(this.name, this.time, this.host);
}

class _WeeklyScheduleWidget extends StatefulWidget {
  const _WeeklyScheduleWidget();

  @override
  State<_WeeklyScheduleWidget> createState() => _WeeklyScheduleWidgetState();
}

class _WeeklyScheduleWidgetState extends State<_WeeklyScheduleWidget> {
  final Map<String, List<_ScheduleItem>> _weeklySchedule = {
    "LUN": [
      _ScheduleItem("El Mañanero Máximo", "06:00 - 10:00", "Hosta Máxima"),
      _ScheduleItem("La Ruta de la Tarde", "10:00 - 14:00", "DJ Máxima"),
      _ScheduleItem("Top 40 Hits", "14:00 - 18:00", "DJ Máster"),
      _ScheduleItem("La Hora del Tapón", "18:00 - 22:00", "DJ Máxima & Co."),
      _ScheduleItem("Música Máxima", "22:00 - 06:00", "Música Continuada")
    ],
    "MAR": [
      _ScheduleItem("El Mañanero Máximo", "06:00 - 10:00", "Hosta Máxima"),
      _ScheduleItem("La Ruta de la Tarde", "10:00 - 14:00", "DJ Máxima"),
      _ScheduleItem("Top 40 Hits", "14:00 - 18:00", "DJ Máster"),
      _ScheduleItem("La Hora del Tapón", "18:00 - 22:00", "DJ Máxima & Co."),
      _ScheduleItem("Música Máxima", "22:00 - 06:00", "Música Continuada")
    ],
    "MIE": [
      _ScheduleItem("El Mañanero Máximo", "06:00 - 10:00", "Hosta Máxima"),
      _ScheduleItem("La Ruta de la Tarde", "10:00 - 14:00", "DJ Máxima"),
      _ScheduleItem("Top 40 Hits", "14:00 - 18:00", "DJ Máster"),
      _ScheduleItem("La Hora del Tapón", "18:00 - 22:00", "DJ Máxima & Co."),
      _ScheduleItem("Música Máxima", "22:00 - 06:00", "Música Continuada")
    ],
    "JUE": [
      _ScheduleItem("El Mañanero Máximo", "06:00 - 10:00", "Hosta Máxima"),
      _ScheduleItem("La Ruta de la Tarde", "10:00 - 14:00", "DJ Máxima"),
      _ScheduleItem("Top 40 Hits", "14:00 - 18:00", "DJ Máster"),
      _ScheduleItem("La Hora del Tapón", "18:00 - 22:00", "DJ Máxima & Co."),
      _ScheduleItem("Música Máxima", "22:00 - 06:00", "Música Continuada")
    ],
    "VIE": [
      _ScheduleItem("El Mañanero Máximo", "06:00 - 10:00", "Hosta Máxima"),
      _ScheduleItem("La Ruta de la Tarde", "10:00 - 14:00", "DJ Máxima"),
      _ScheduleItem("Top 40 Hits", "14:00 - 18:00", "DJ Máster"),
      _ScheduleItem("La Hora del Tapón", "18:00 - 22:00", "DJ Máxima & Co."),
      _ScheduleItem("Música Máxima", "22:00 - 06:00", "Música Continuada")
    ],
    "SAB": [
      _ScheduleItem("El Calentón del Sábado", "08:00 - 12:00", "DJ Máster"),
      _ScheduleItem("Los Clásicos de la Máxima", "12:00 - 18:00", "DJ Carlos"),
      _ScheduleItem("Fiesta Máxima", "18:00 - 06:00", "Música Continuada")
    ],
    "DOM": [
      _ScheduleItem("Domingo de Clásicos", "08:00 - 14:00", "DJ Carlos"),
      _ScheduleItem("El Solazo de la Tarde", "14:00 - 22:00", "DJ Máster"),
      _ScheduleItem("Música Máxima", "22:00 - 06:00", "Música Continuada")
    ]
  };

  late String _selectedDay;
  final List<String> _dayKeys = ["LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"];
  final Map<String, String> _dayLabels = {
    "LUN": "L",
    "MAR": "M",
    "MIE": "M",
    "JUE": "J",
    "VIE": "V",
    "SAB": "S",
    "DOM": "D"
  };

  @override
  void initState() {
    super.initState();
    // Seleccionar el día actual de la semana
    final int weekday = DateTime.now().weekday; // 1 = Lunes, 7 = Domingo
    final List<String> weekdayMapping = ["DOM", "LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"];
    _selectedDay = weekdayMapping[weekday];
  }

  @override
  Widget build(BuildContext context) {
    final programs = _weeklySchedule[_selectedDay] ?? [];

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Selector de Días
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _dayKeys.map((day) {
                final isSelected = day == _selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.gold : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.gold 
                            : Theme.of(context).dividerColor.withOpacity(0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[day]!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Lista de Programas
            SizedBox(
              height: 160,
              child: programs.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay programación para este día',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: programs.length,
                      itemBuilder: (context, index) {
                        final prog = programs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white.withOpacity(0.03) 
                                  : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prog.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Locución: ${prog.host}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10, 
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  prog.time,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
