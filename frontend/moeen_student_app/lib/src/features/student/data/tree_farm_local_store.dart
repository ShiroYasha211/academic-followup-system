import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final treeFarmLocalStoreProvider = Provider<TreeFarmLocalStore>((ref) {
  return const TreeFarmLocalStore();
});

class TreeFarmLocalStore {
  const TreeFarmLocalStore();

  Future<TreeFarmLocalState> load() async {
    final file = await _file();
    if (!await file.exists()) return const TreeFarmLocalState();
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return const TreeFarmLocalState();
      return TreeFarmLocalState.fromJson(decoded);
    } catch (_) {
      return const TreeFarmLocalState();
    }
  }

  Future<void> save(TreeFarmLocalState state) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/moeen_tree_farm/state.json');
  }
}

class TreeFarmLocalState {
  const TreeFarmLocalState({
    this.activeSession,
    this.pendingSessions = const [],
    this.pendingThoughts = const [],
    this.pendingPlants = const [],
  });

  final Map<String, dynamic>? activeSession;
  final List<Map<String, dynamic>> pendingSessions;
  final List<Map<String, dynamic>> pendingThoughts;
  final List<Map<String, dynamic>> pendingPlants;

  factory TreeFarmLocalState.fromJson(Map<String, dynamic> json) {
    return TreeFarmLocalState(
      activeSession: _mapOrNull(json['active_session']),
      pendingSessions: _mapList(json['pending_sessions']),
      pendingThoughts: _mapList(json['pending_thoughts']),
      pendingPlants: _mapList(json['pending_plants']),
    );
  }

  TreeFarmLocalState copyWith({
    Map<String, dynamic>? activeSession,
    bool clearActiveSession = false,
    List<Map<String, dynamic>>? pendingSessions,
    List<Map<String, dynamic>>? pendingThoughts,
    List<Map<String, dynamic>>? pendingPlants,
  }) {
    return TreeFarmLocalState(
      activeSession: clearActiveSession
          ? null
          : activeSession ?? this.activeSession,
      pendingSessions: pendingSessions ?? this.pendingSessions,
      pendingThoughts: pendingThoughts ?? this.pendingThoughts,
      pendingPlants: pendingPlants ?? this.pendingPlants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_session': activeSession,
      'pending_sessions': pendingSessions,
      'pending_thoughts': pendingThoughts,
      'pending_plants': pendingPlants,
    };
  }

  bool get hasExpiredPendingSession {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 24));
    return pendingSessions.any((session) {
      final raw = session['started_at']?.toString();
      final startedAt = raw == null ? null : DateTime.tryParse(raw)?.toUtc();
      return startedAt != null && startedAt.isBefore(cutoff);
    });
  }
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }).toList();
}
