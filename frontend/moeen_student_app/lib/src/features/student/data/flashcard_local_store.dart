import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final flashcardLocalStoreProvider = Provider<FlashcardLocalStore>((ref) {
  return const FlashcardLocalStore();
});

class FlashcardLocalStore {
  const FlashcardLocalStore();

  Future<FlashcardLocalState> load() async {
    final file = await _file();
    if (!await file.exists()) return const FlashcardLocalState();
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return const FlashcardLocalState();
      return FlashcardLocalState.fromJson(decoded);
    } catch (_) {
      return const FlashcardLocalState();
    }
  }

  Future<void> save(FlashcardLocalState state) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<void> addPendingProgress({
    required int itemId,
    required String responseLevel,
  }) async {
    final state = await load();
    final pending = [
      ...state.pendingProgress,
      {
        'item_id': itemId,
        'response_level': responseLevel,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      },
    ];
    await save(state.copyWith(pendingProgress: pending));
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/moeen_flashcards/state.json');
  }
}

class FlashcardLocalState {
  const FlashcardLocalState({this.pendingProgress = const []});

  final List<Map<String, dynamic>> pendingProgress;

  factory FlashcardLocalState.fromJson(Map<String, dynamic> json) {
    return FlashcardLocalState(
      pendingProgress: _mapList(json['pending_progress']),
    );
  }

  FlashcardLocalState copyWith({List<Map<String, dynamic>>? pendingProgress}) {
    return FlashcardLocalState(
      pendingProgress: pendingProgress ?? this.pendingProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {'pending_progress': pendingProgress};
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }).toList();
}
