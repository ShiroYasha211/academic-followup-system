class StaffSubscriptionOverview {
  const StaffSubscriptionOverview({
    required this.userBalance,
    required this.isSubscribed,
    required this.autoRenew,
    required this.packages,
    this.subscribedUntil,
  });

  final double userBalance;
  final bool isSubscribed;
  final bool autoRenew;
  final String? subscribedUntil;
  final List<StaffSubscriptionPackage> packages;

  factory StaffSubscriptionOverview.fromJson(Map<String, dynamic> json) {
    return StaffSubscriptionOverview(
      userBalance: _double(json['user_balance']),
      isSubscribed: json['is_subscribed'] == true,
      autoRenew: json['auto_renew'] == true,
      subscribedUntil: json['subscribed_until']?.toString(),
      packages: (json['packages'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => StaffSubscriptionPackage.fromJson(_map(item)))
          .toList(),
    );
  }
}

class StaffSubscriptionPackage {
  const StaffSubscriptionPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.description,
    required this.effectivePrice,
  });

  final int id;
  final String name;
  final int durationDays;
  final String description;
  final double effectivePrice;

  factory StaffSubscriptionPackage.fromJson(Map<String, dynamic> json) {
    final fallbackPrice =
        json['price_doctor'] ??
        json['price_administrative'] ??
        json['price_student'] ??
        json['price_delegate'];
    return StaffSubscriptionPackage(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      durationDays: _int(json['duration_days']),
      description: (json['description'] ?? 'استكشف مزايا النظام الأكاديمي.')
          .toString(),
      effectivePrice: _double(json['effective_price'] ?? fallbackPrice),
    );
  }
}

class StaffFinancialLedger {
  const StaffFinancialLedger({
    required this.balance,
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final double balance;
  final List<StaffFinancialTransaction> transactions;
  final int currentPage;
  final int lastPage;
  final int total;

  factory StaffFinancialLedger.fromJson(Map<String, dynamic> json) {
    final paginator = _map(json['transactions']);
    return StaffFinancialLedger(
      balance: _double(json['balance']),
      transactions: (paginator['data'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => StaffFinancialTransaction.fromJson(_map(item)))
          .toList(),
      currentPage: _int(paginator['current_page']),
      lastPage: _int(paginator['last_page']),
      total: _int(paginator['total']),
    );
  }
}

class StaffFinancialTransaction {
  const StaffFinancialTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.action,
    required this.description,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
  });

  final int id;
  final double amount;
  final String type;
  final String action;
  final String description;
  final double balanceBefore;
  final double balanceAfter;
  final String createdAt;

  factory StaffFinancialTransaction.fromJson(Map<String, dynamic> json) {
    return StaffFinancialTransaction(
      id: _int(json['id']),
      amount: _double(json['amount']),
      type: (json['type'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      balanceBefore: _double(json['balance_before']),
      balanceAfter: _double(json['balance_after']),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class StaffProfile {
  const StaffProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.availableWorkspaces,
    this.university,
    this.college,
    this.major,
  });

  final String name;
  final String email;
  final String role;
  final String status;
  final List<String> availableWorkspaces;
  final String? university;
  final String? college;
  final String? major;

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      university: json['university']?.toString(),
      college: json['college']?.toString(),
      major: json['major']?.toString(),
      availableWorkspaces: (json['available_workspaces'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class StaffAdministrativeSettings {
  const StaffAdministrativeSettings({
    required this.id,
    required this.name,
    required this.absenceDeprivationPercentage,
    required this.excusesDeadlineDays,
    required this.excuseReceiver,
    required this.qrRotationSeconds,
  });

  final int id;
  final String name;
  final int absenceDeprivationPercentage;
  final int excusesDeadlineDays;
  final String excuseReceiver;
  final int qrRotationSeconds;

  factory StaffAdministrativeSettings.fromJson(Map<String, dynamic> json) {
    return StaffAdministrativeSettings(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      absenceDeprivationPercentage: _int(
        json['absence_deprivation_percentage'],
      ),
      excusesDeadlineDays: _int(json['excuses_deadline_days']),
      excuseReceiver: (json['excuse_receiver'] ?? 'administrative')
          .toString(),
      qrRotationSeconds: _int(json['qr_rotation_seconds']),
    );
  }
}

class StaffDashboardData {
  const StaffDashboardData({required this.raw, required this.isAdministrative});

  final Map<String, dynamic> raw;
  final bool isAdministrative;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _double(Object? value) => double.tryParse((value ?? 0).toString()) ?? 0;
