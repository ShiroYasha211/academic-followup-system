import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffRefreshState {
  const StaffRefreshState({
    required this.version,
    required this.online,
    required this.refreshing,
    this.lastRefreshAt,
  });

  final int version;
  final bool online;
  final bool refreshing;
  final DateTime? lastRefreshAt;

  StaffRefreshState copyWith({
    int? version,
    bool? online,
    bool? refreshing,
    DateTime? lastRefreshAt,
  }) {
    return StaffRefreshState(
      version: version ?? this.version,
      online: online ?? this.online,
      refreshing: refreshing ?? this.refreshing,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
    );
  }
}

final staffRefreshCoordinatorProvider =
    NotifierProvider<StaffRefreshCoordinator, StaffRefreshState>(
      StaffRefreshCoordinator.new,
    );

class StaffRefreshCoordinator extends Notifier<StaffRefreshState> {
  DateTime? _lastTriggeredAt;

  @override
  StaffRefreshState build() {
    return const StaffRefreshState(
      version: 0,
      online: true,
      refreshing: false,
    );
  }

  void setOnline(bool value) {
    if (state.online == value) return;
    state = state.copyWith(online: value);
    if (value) triggerRefresh();
  }

  void triggerRefresh({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastTriggeredAt != null &&
        now.difference(_lastTriggeredAt!) < const Duration(seconds: 8)) {
      return;
    }
    _lastTriggeredAt = now;
    state = state.copyWith(
      version: state.version + 1,
      refreshing: true,
      lastRefreshAt: now,
    );
    Future<void>.delayed(const Duration(seconds: 2), () {
      final current = state;
      if (current.version == state.version) {
        state = current.copyWith(refreshing: false);
      }
    });
  }
}
