import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/models/financial_ledger.dart';
import '../data/models/card_generation_models.dart';
import '../data/models/student_dashboard.dart';
import '../data/models/subscription_models.dart';
import '../data/student_repositories.dart';

final studentDashboardControllerProvider =
    AsyncNotifierProvider<StudentDashboardController, StudentDashboard>(
      StudentDashboardController.new,
    );

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionOverview>(
      SubscriptionController.new,
    );

final ledgerControllerProvider =
    AsyncNotifierProvider<LedgerController, FinancialLedger>(
      LedgerController.new,
    );

final cardGenerationControllerProvider =
    AsyncNotifierProvider<CardGenerationController, CardGenerationOverview>(
      CardGenerationController.new,
    );

final cardGenerationAccessProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session?.hasPermissionSlug('generate_cards') == true) {
    return true;
  }

  try {
    await ref.watch(cardGenerationRepositoryProvider).fetch(page: 1);
    return true;
  } on ApiException catch (error) {
    if (error.statusCode == 403) return false;
    rethrow;
  }
});

class StudentDashboardController extends AsyncNotifier<StudentDashboard> {
  @override
  Future<StudentDashboard> build() =>
      _guard(() => ref.watch(studentDashboardRepositoryProvider).fetch());

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

class SubscriptionController extends AsyncNotifier<SubscriptionOverview> {
  @override
  Future<SubscriptionOverview> build() =>
      _guard(() => ref.watch(subscriptionRepositoryProvider).fetch());

  Future<String?> redeem(String code) =>
      _act(() => ref.read(subscriptionRepositoryProvider).redeem(code));

  Future<String?> subscribe(int packageId) =>
      _act(() => ref.read(subscriptionRepositoryProvider).subscribe(packageId));

  Future<String?> toggleAutoRenew(bool value) => _act(
    () => ref.read(subscriptionRepositoryProvider).toggleAutoRenew(value),
  );

  Future<String?> _act(Future<String> Function() action) async {
    try {
      final message = await action();
      state = const AsyncLoading();
      state = await AsyncValue.guard(build);
      return message;
    } on ApiException catch (error) {
      await _handleAuthError(ref, error);
      rethrow;
    }
  }
}

class LedgerController extends AsyncNotifier<FinancialLedger> {
  int _page = 1;

  int get page => _page;

  @override
  Future<FinancialLedger> build() => _fetch(1);

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page));
  }

  Future<String> exportUrl() async {
    try {
      return await ref.read(ledgerRepositoryProvider).exportUrl();
    } on ApiException catch (error) {
      await _handleAuthError(ref, error);
      rethrow;
    }
  }

  Future<List<int>> exportPdf() async {
    try {
      return await ref.read(ledgerRepositoryProvider).exportPdf();
    } on ApiException catch (error) {
      await _handleAuthError(ref, error);
      rethrow;
    }
  }

  Future<FinancialLedger> _fetch(int page) async {
    _page = page;
    return _guard(() => ref.watch(ledgerRepositoryProvider).fetch(page: page));
  }
}

class CardGenerationController extends AsyncNotifier<CardGenerationOverview> {
  int _page = 1;

  @override
  Future<CardGenerationOverview> build() => _fetch(1);

  Future<void> goToPage(int page) async {
    if (page < 1 || page == _page) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(_page));
  }

  Future<String> generate({required int count, required double amount}) async {
    try {
      final message = await ref
          .read(cardGenerationRepositoryProvider)
          .generate(count: count, amount: amount);
      _page = 1;
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetch(1));
      ref.invalidate(subscriptionControllerProvider);
      ref.invalidate(ledgerControllerProvider);
      return message;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      rethrow;
    }
  }

  Future<CardGenerationOverview> _fetch(int page) async {
    _page = page;
    return ref.read(cardGenerationRepositoryProvider).fetch(page: page);
  }
}

Future<T> _guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException {
    rethrow;
  }
}

Future<void> _handleAuthError(Ref ref, ApiException error) async {
  if (error.statusCode == 401 || error.statusCode == 403) {
    await ref.read(authControllerProvider.notifier).logout();
  }
}
