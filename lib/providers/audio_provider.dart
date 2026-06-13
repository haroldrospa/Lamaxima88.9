import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/podcast.dart';

enum AudioType { radio, podcast, none }

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  
  AudioType _currentType = AudioType.none;
  Podcast? _currentPodcast;
  String _currentProgramName = 'Radio Máxima';
  String _currentSongName = 'La Máxima 88.9 FM';
  
  bool _isBuffering = false;
  double _volume = 1.0;

  // Getters
  AudioPlayer get player => _player;
  AudioType get currentType => _currentType;
  Podcast? get currentPodcast => _currentPodcast;
  String get currentProgramName => _currentProgramName;
  String get currentSongName => _currentSongName;
  bool get isPlaying => _player.playing;
  bool get isBuffering => _isBuffering;
  double get volume => _volume;

  // Streams de estado para UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  AudioProvider() {
    // Escuchar cambios de estado para notificar a la UI
    _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering;
      notifyListeners();
    });
    
    // Escuchar el volumen
    _player.volumeStream.listen((vol) {
      _volume = vol;
      notifyListeners();
    });
  }

  // Reproducir Streaming de Radio en Vivo
  Future<void> playRadio(String radioUrl, String programName, {String? imageUrl}) async {
    try {
      _currentType = AudioType.radio;
      _currentPodcast = null;
      _currentProgramName = programName;
      notifyListeners();

      await _player.stop();
      
      final source = AudioSource.uri(
        Uri.parse(radioUrl),
        tag: MediaItem(
          id: 'radio_live_889',
          album: 'La Máxima 88.9 FM',
          title: 'RADIO EN VIVO',
          artist: programName,
          artUri: imageUrl != null ? Uri.parse(imageUrl) : null,
        ),
      );

      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      print('Error al reproducir radio: $e');
      _currentType = AudioType.none;
      notifyListeners();
    }
  }

  // Reproducir un Podcast específico
  Future<void> playPodcast(Podcast podcast) async {
    try {
      _currentType = AudioType.podcast;
      _currentPodcast = podcast;
      _currentProgramName = podcast.titulo;
      notifyListeners();

      await _player.stop();

      final source = AudioSource.uri(
        Uri.parse(podcast.audioUrl),
        tag: MediaItem(
          id: podcast.id,
          album: 'Podcast',
          title: podcast.titulo,
          artist: podcast.descripcion,
          artUri: podcast.imagen.isNotEmpty ? Uri.parse(podcast.imagen) : null,
        ),
      );

      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      print('Error al reproducir podcast: $e');
      _currentType = AudioType.none;
      _currentPodcast = null;
      notifyListeners();
    }
  }

  // Pausar reproducción
  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  // Reanudar reproducción
  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  // Alternar reproducción (Play/Pause)
  Future<void> togglePlay() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  // Detener por completo
  Future<void> stop() async {
    await _player.stop();
    _currentType = AudioType.none;
    _currentPodcast = null;
    notifyListeners();
  }

  // Buscar una posición específica (para podcasts)
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // Ajustar volumen (0.0 a 1.0)
  Future<void> setVolume(double vol) async {
    final cleanVol = vol.clamp(0.0, 1.0);
    await _player.setVolume(cleanVol);
    _volume = cleanVol;
    notifyListeners();
  }

  // Actualizar metadatos de canción actual dinámicamente
  void updateSongName(String songName) {
    _currentSongName = songName;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
