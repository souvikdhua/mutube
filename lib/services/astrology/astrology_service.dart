import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:spotube/provider/audio_player/audio_player.dart';
import 'package:spotube/provider/youtube_engine/youtube_engine.dart';
import 'package:spotube/models/metadata/metadata.dart';
import 'package:media_kit/media_kit.dart';

class AstrologyState {
  final String vibe;
  final String intensity;
  final String ruler;
  final String search;
  final double valence;
  final double energy;

  AstrologyState({
    this.vibe = "Connect", 
    this.intensity = "0.0", 
    this.ruler = "Unknown", 
    this.search = "",
    this.valence = 0.5,
    this.energy = 0.5
  });
}

class AstrologyNotifier extends Notifier<AstrologyState> {
  Timer? _timer;

  @override
  AstrologyState build() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchAndQueue();
    });
    Future.microtask(() => fetchAndQueue());
    
    ref.onDispose(() {
      _timer?.cancel();
    });

    return AstrologyState();
  }

  Future<void> fetchAndQueue() async {
    try {
      // In production, replace with actual URL
      final url = Uri.parse('http://127.0.0.1:8888/.netlify/functions/get_song_prediction');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prediction = data['search_query'];
        final features = data['spotify_features'];
        final astro = data['astrology_data'];
        
        state = AstrologyState(
          vibe: "${astro['moon_sign']} Moon", // V2: Use Moon Sign as primary vibe indicator
          intensity: "${(features['energy'] * 100).toInt()}%",
          ruler: astro['mars_sign'] ?? "Unknown", // V2: Use Mars as 'Active Ruler'
          search: prediction,
          valence: features['valence']?.toDouble() ?? 0.5,
          energy: features['energy']?.toDouble() ?? 0.5
        );

        await _queueTrack(prediction);
      }
    } catch (e) {
      print("Astrology Fetch Error V2: $e");
    }
  }

  Future<void> _queueTrack(String query) async {
    final engine = ref.read(youtubeEngineProvider);
    final audioPlayerNotifier = ref.read(audioPlayerProvider.notifier);

    // Filter results that map closely to our target duration or other metadata if possible
    // For now, we rely on the specific search query "Deep House 124bpm" to do the work.
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
                    externalUri: video.url, 
                )
            ],
            album: SpotubeSimpleAlbumObject(
                id: "yt_album",
                name: "Cosmic Mix", // Custom album name for the vibe
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
