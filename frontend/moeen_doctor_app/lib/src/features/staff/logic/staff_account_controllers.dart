import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/refresh/staff_refresh_coordinator.dart';
import '../../auth/data/staff_auth_session.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/staff_account_models.dart';
import '../data/staff_account_repository.dart';

final staffAccountRepositoryProvider = Provider<StaffAccountRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final cachePrefix =
      'staff.account.${session?.email ?? 'guest'}.${session?.workspace.name ?? 'doctor'}';
  return StaffAccountRepository(
    ref.watch(authenticatedApiClientProvider),
    cache: ref.watch(offlineCacheProvider),
    cachePrefix: cachePrefix,
  );
});

final staffDashboardProvider = FutureProvider.autoDispose
    .family<StaffDashboardData, StaffWorkspace>((ref, workspace) {
      ref.watch(
        staffRefreshCoordinatorProvider.select((state) => state.version),
      );
      return _dashboardWithOfflineFallback(ref, workspace);
    });

final staffProfileProvider = FutureProvider.autoDispose
    .family<StaffProfile, StaffWorkspace>((ref, workspace) {
      ref.watch(
        staffRefreshCoordinatorProvider.select((state) => state.version),
      );
      return ref.watch(staffAccountRepositoryProvider).profile(workspace);
    });

final staffSubscriptionProvider =
    AsyncNotifierProvider.family<
      StaffSubscriptionController,
      StaffSubscriptionOverview,
      StaffWorkspace
    >(StaffSubscriptionController.new);

final staffLedgerProvider =
    AsyncNotifierProvider.family<
      StaffLedgerController,
      StaffFinancialLedger,
      StaffWorkspace
    >(StaffLedgerController.new);

final staffAdministrativeSettingsProvider =
    AsyncNotifierProvider<
      StaffAdministrativeSettingsController,
      StaffAdministrativeSettings
    >(StaffAdministrativeSettingsController.new);

Future<StaffDashboardData> _dashboardWithOfflineFallback(
  Ref ref,
  StaffWorkspace workspace,
) async {
  try {
    return await ref.watch(staffAccountRepositoryProvider).dashboard(workspace);
  } on ApiException catch (error) {
    if (error.statusCode == 401 ||
        (error.statusCode == 403 && error.code != 'subscription_required')) {
      await _handleAuthError(ref, error);
    }
    rethrow;
  }
}

class StaffSubscriptionController
    extends FamilyAsyncNotifier<StaffSubscriptionOverview, StaffWorkspace> {
  @override
  Future<StaffSubscriptionOverview> build(StaffWorkspace workspace) {
    ref.watch(staffRefreshCoordinatorProvider.select((state) => state.version));
    return _guard(
      () => ref.watch(staffAccountRepositoryProvider).subscription(workspace),
    );
  }

  Future<String> redeem(String code) =>
      _act(() => ref.read(staffAccountRepositoryProvider).redeem(arg, code));

  Future<String> subscribe(int packageId) => _act(
    () => ref.read(staffAccountRepositoryProvider).subscribe(arg, packageId),
  );

  Future<String> toggleAutoRenew(bool value) => _act(
    () => ref.read(staffAccountRepositoryProvider).toggleAutoRenew(arg, value),
  );

  Future<String> _act(Future<String> Function() action) async {
    final message = await _guard(action);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
    return message;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      await _handleAuthError(ref, error);
      rethrow;
    }
  }
}

class StaffLedgerController
    extends FamilyAsyncNotifier<StaffFinancialLedger, StaffWorkspace> {
  int _page = 1;

  int get page => _page;

  @override
  Future<StaffFinancialLedger> build(StaffWorkspace workspace) {
    ref.watch(staffRefreshCoordinatorProvider.select((state) => state.version));
    return _fetch(1);
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page));
  }

  Future<List<int>> exportPdf() {
    return _guard(
      () => ref.read(staffAccountRepositoryProvider).exportLedger(arg),
    );
  }

  Future<StaffFinancialLedger> _fetch(int page) {
    _page = page;
    return _guard(
      () => ref.read(staffAccountRepositoryProvider).ledger(arg, page: page),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      await _handleAuthError(ref, error);
      rethrow;
    }
  }
}

class StaffAdministrativeSettingsController
    extends AsyncNotifier<StaffAdministrativeSettings> {
  @override
  Future<StaffAdministrativeSettings> build() {
    ref.watch(staffRefreshCoordinatorProvider.select((state) => state.version));
    return _guard(
      () => ref.read(staffAccountRepositoryProvider).administrativeSettings(),
    );
  }

  Future<String> save({
    required int absenceDeprivationPercentage,
    required int excusesDeadlineDays,
    required String excuseReceiver,
    required int qrRotationSeconds,
    required int doctorInitialStarBalance,
  }) async {
    final message = await _guard(
      () => ref
          .read(staffAccountRepositoryProvider)
          .updateAdministrativeSettings(
            absenceDeprivationPercentage: absenceDeprivationPercentage,
            excusesDeadlineDays: excusesDeadlineDays,
            excuseReceiver: excuseReceiver,
            qrRotationSeconds: qrRotationSeconds,
            doctorInitialStarBalance: doctorInitialStarBalance,
          ),
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
    return message;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      await _handleAuthError(ref, error);
      rethrow;
    }
  }
}

Future<void> _handleAuthError(Ref ref, ApiException error) async {
  if (error.statusCode == 401 ||
      (error.statusCode == 403 && error.code != 'subscription_required')) {
    await ref.read(authControllerProvider.notifier).logout();
  }
}
