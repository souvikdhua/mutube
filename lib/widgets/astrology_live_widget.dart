import 'package:flutter/material.dart' show Icons, MainAxisSize, SizedBox, EdgeInsets;
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:spotube/services/astrology/astrology_service.dart';

class AstrologyLiveWidget extends HookConsumerWidget {
  const AstrologyLiveWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astroState = ref.watch(astrologyProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Icon(Icons.auto_awesome, size: 16),
             const SizedBox(width: 8),
             Text("Ruler: ${astroState.ruler}"),
             const SizedBox(width: 16),
             Text("Intensity: ${astroState.intensity}%"),
          ],
        ),
      ),
    );
  }
}
