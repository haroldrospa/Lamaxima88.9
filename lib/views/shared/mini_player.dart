import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/audio_provider.dart';
import '../../theme.dart';
import '../podcast/podcast_detail_view.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    if (audioProvider.currentType == AudioType.none) {
      return const SizedBox.shrink();
    }

    final isPodcast = audioProvider.currentType == AudioType.podcast;
    final title = audioProvider.currentProgramName;
    final subtitle = isPodcast 
        ? (audioProvider.currentPodcast?.descripcion ?? '') 
        : 'Radio En Vivo - La Máxima';

    final imageUrl = isPodcast 
        ? audioProvider.currentPodcast?.imagen 
        : null;

    return Container(
      margin: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              if (isPodcast && audioProvider.currentPodcast != null) {
                // Navegar a los detalles del podcast
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PodcastDetailView(podcast: audioProvider.currentPodcast!),
                  ),
                );
              }
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(
                width: 48,
                height: 48,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.gold.withOpacity(0.2),
                          child: const Icon(Icons.music_note, color: AppTheme.gold),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.gold,
                          child: const Icon(Icons.radio, color: Colors.white),
                        ),
                      )
                    : Container(
                        color: AppTheme.gold,
                        child: const Icon(Icons.radio, color: Colors.white, size: 28),
                      ),
              ),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (audioProvider.isBuffering)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SpinKitRing(color: AppTheme.gold, size: 24.0, borderWidth: 2.0),
                  )
                else
                  IconButton(
                    icon: Icon(
                      audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppTheme.gold,
                      size: 36,
                    ),
                    onPressed: () => audioProvider.togglePlay(),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => audioProvider.stop(),
                ),
              ],
            ),
          ),
          
          // Barra de progreso inferior solo para podcasts
          if (isPodcast)
            StreamBuilder<Duration>(
              stream: audioProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = audioProvider.player.duration ?? Duration.zero;
                
                double progress = 0.0;
                if (duration.inMilliseconds > 0) {
                  progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                      minHeight: 3.0,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 4.0),
        ],
      ),
    );
  }
}
