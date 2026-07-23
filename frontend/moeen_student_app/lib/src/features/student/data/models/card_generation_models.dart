class GeneratedCard {
  const GeneratedCard({
    required this.id,
    required this.code,
    required this.amount,
    required this.isUsed,
    required this.createdAt,
    this.usedAt,
  });

  final int id;
  final String code;
  final double amount;
  final bool isUsed;
  final DateTime? createdAt;
  final DateTime? usedAt;

  factory GeneratedCard.fromJson(Map<String, dynamic> json) {
    return GeneratedCard(
      id: _int(json['id']),
      code: (json['code'] ?? '').toString(),
      amount: _double(json['amount']),
      isUsed: _bool(json['is_used']),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      usedAt: DateTime.tryParse((json['used_at'] ?? '').toString()),
    );
  }
}

class CardGenerationOverview {
  const CardGenerationOverview({
    required this.balance,
    required this.cards,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final double balance;
  final List<GeneratedCard> cards;
  final int currentPage;
  final int lastPage;
  final int total;

  int get availableCount => cards.where((card) => !card.isUsed).length;
  int get usedCount => cards.where((card) => card.isUsed).length;

  factory CardGenerationOverview.fromJson(Map<String, dynamic> json) {
    final cardsData = json['cards'];
    final paginator = cardsData is Map
        ? cardsData.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final rawCards = paginator['data'] is List
        ? paginator['data'] as List
        : const <dynamic>[];

    return CardGenerationOverview(
      balance: _double(json['balance']),
      cards: rawCards
          .whereType<Map>()
          .map(
            (card) => GeneratedCard.fromJson(
              card.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      currentPage: _int(paginator['current_page'], fallback: 1),
      lastPage: _int(paginator['last_page'], fallback: 1),
      total: _int(paginator['total']),
    );
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(Object? value) {
  return value == true || value == 1 || value == '1' || value == 'true';
}
