class SubscriptionOverview {
  const SubscriptionOverview({
    required this.userBalance,
    required this.isSubscribed,
    required this.autoRenew,
    required this.packages,
    this.subscribedUntil,
  });

  final double userBalance;
  final bool isSubscribed;
  final String? subscribedUntil;
  final bool autoRenew;
  final List<SubscriptionPackage> packages;

  factory SubscriptionOverview.fromJson(Map<String, dynamic> json) {
    return SubscriptionOverview(
      userBalance: _double(json['user_balance']),
      isSubscribed: json['is_subscribed'] == true,
      subscribedUntil: json['subscribed_until']?.toString(),
      autoRenew: json['auto_renew'] == true,
      packages: (json['packages'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPackage.fromJson)
          .toList(),
    );
  }
}

class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.priceStudent,
    required this.priceDelegate,
    required this.description,
  });

  final int id;
  final String name;
  final int durationDays;
  final double priceStudent;
  final double priceDelegate;
  final String description;

  double get displayPrice => priceStudent > 0 ? priceStudent : priceDelegate;

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackage(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      durationDays: _int(json['duration_days']),
      priceStudent: _double(json['price_student']),
      priceDelegate: _double(json['price_delegate']),
      description: (json['description'] ?? 'استكشف مزايا النظام التعليمية.')
          .toString(),
    );
  }
}

int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _double(Object? value) => double.tryParse((value ?? 0).toString()) ?? 0;
