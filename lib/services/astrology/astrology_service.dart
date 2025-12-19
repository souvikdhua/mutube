import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:spotube/provider/audio_player/audio_player.dart';
import 'package:spotube/provider/youtube_engine/youtube_engine.dart';
import 'package:spotube/models/metadata/metadata.dart';
import 'package:spotube/services/logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AstrologyState {
  final String vibe;
  final String intensity;
  final String ruler;
  final String search;

  AstrologyState({
    this.vibe = "Connect", 
    this.intensity = "0.0", 
    this.ruler = "Unknown", 
    this.search = ""
  });
}

class AstrologyNotifier extends Notifier<AstrologyState> {
  Timer? _timer;

  @override
  AstrologyState build() {
    // Start timer on build
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchAndQueue();
    });
    // Initial fetch
    Future.microtask(() => fetchAndQueue());
    
    ref.onDispose(() {
      _timer?.cancel();
    });

    return AstrologyState();
  }

  Future<void> fetchAndQueue() async {
    try {
      // In production, replace with actual URL or use loopback
      final url = Uri.parse('http://127.0.0.1:8888/.netlify/functions/get_song_prediction');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prediction = data['search_query'];
        final meta = data['metadata'];
        
        state = AstrologyState(
          vibe: meta['ascendant'] ?? "Unknown",
          intensity: (meta['intensity'] ?? 0).toString(),
          ruler: meta['planetary_ruler'] ?? "Unknown",
          search: prediction
        );

        // Queue the track
        await _queueTrack(prediction);
      }
    } catch (e) {
      // Slient fail or log
      // AppLogger.reportError(e, StackTrace.current); 
      // Using print since Logger might not be initialized if called to early
      print("Astrology Fetch Error: $e");
    }
  }

  Future<void> _queueTrack(String query) async {
    final engine = ref.read(youtubeEngineProvider);
    final audioPlayerNotifier = ref.read(audioPlayerProvider.notifier);

    // Search
    try {
        final results = await engine.searchVideos(query);
        if (results.isNotEmpty) {
          final video = results.first;
          
          final track = SpotubeFullTrackObject(
            id: video.id.value,
            name: video.title,
            externalUri: video.url,
            artists: [
                SpotubeSimpleArtistObject(
                    id: video.channelId.value,
                    name: video.author,
                    externalUri: video.url, // Placeholder
                )
            ],
            album: SpotubeSimpleAlbumObject(
                id: "yt_album",
                name: "YouTube",
                externalUri: video.url,
                albumType: SpotubeAlbumType.album,
                artists: [],
                releaseDate: "2024-01-01",
                images: [
                    SpotubeImageObject(
                        url: video.thumbnails.highResUrl,
                        width: 480,
                        height: 360
                    )
                ]
            ),
            durationMs: video.duration?.inMilliseconds ?? 0,
            isrc: "",
            explicit: false,
          );
    
          // Add to queue
          await audioPlayerNotifier.addTrack(track);
        }
    } catch (e) {
        print("Astrology Queue Error: $e");
    }
  }
}

final astrologyProvider = NotifierProvider<AstrologyNotifier, AstrologyState>(() {
  return AstrologyNotifier();
});
