import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/logic/auth_controller.dart';
import '../../student/data/models/financial_ledger.dart';
import '../../student/data/models/subscription_models.dart';
import '../data/delegate_repositories.dart';

final delegateDashboardProvider =
    AsyncNotifierProvider<DelegateDashboardController, Map<String, dynamic>>(
      DelegateDashboardController.new,
    );

final delegateSubscriptionProvider =
    AsyncNotifierProvider<DelegateSubscriptionController, SubscriptionOverview>(
      DelegateSubscriptionController.new,
    );

final delegateLedgerProvider =
    AsyncNotifierProvider<DelegateLedgerController, FinancialLedger>(
      DelegateLedgerController.new,
    );

final delegateUnreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final data = await ref.watch(delegateRepositoryProvider).notifications();
      final sentWarnings = _asList(data['sent_warnings']);
      final value = data['unread_count'] ?? data['count'];
      if (value is num) return value.toInt();
      return sentWarnings.where((item) {
        final map = _asMap(item);
        return (map['read_at'] ?? '').toString().isEmpty;
      }).length;
    });

class DelegateDashboardController extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() =>
      _guard(ref, () => ref.watch(delegateRepositoryProvider).dashboard());
}

class DelegateSubscriptionController
    extends AsyncNotifier<SubscriptionOverview> {
  @override
  Future<SubscriptionOverview> build() => _guard(
    ref,
    () => ref.watch(delegateSubscriptionRepositoryProvider).fetch(),
  );

  Future<String> redeem(String code) =>
      _act(() => ref.read(delegateSubscriptionRepositoryProvider).redeem(code));

  Future<String> subscribe(int packageId) => _act(
    () => ref.read(delegateSubscriptionRepositoryProvider).subscribe(packageId),
  );

  Future<String> toggleAutoRenew(bool value) => _act(
    () =>
        ref.read(delegateSubscriptionRepositoryProvider).toggleAutoRenew(value),
  );

  Future<String> _act(Future<String> Function() action) async {
    final message = await _guard(ref, action);
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
    return message;
  }
}

class DelegateLedgerController extends AsyncNotifier<FinancialLedger> {
  int _page = 1;

  int get page => _page;

  @override
  Future<FinancialLedger> build() => _fetch(1);

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page));
  }

  Future<List<int>> exportPdf() =>
      _guard(ref, () => ref.read(delegateLedgerRepositoryProvider).exportPdf());

  Future<FinancialLedger> _fetch(int page) {
    _page = page;
    return _guard(
      ref,
      () => ref.watch(delegateLedgerRepositoryProvider).fetch(page: page),
    );
  }
}

Future<T> _guard<T>(Ref ref, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException catch (error) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      await ref.read(authControllerProvider.notifier).logout();
    }
    rethrow;
  }
}

List<dynamic> _asList(Object? value) => value is List ? value : const [];

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map)
    return value.map((key, value) => MapEntry(key.toString(), value));
  return const {};
}
