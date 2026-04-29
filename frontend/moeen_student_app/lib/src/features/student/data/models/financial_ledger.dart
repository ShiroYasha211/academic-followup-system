class FinancialLedger {
  const FinancialLedger({
    required this.balance,
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final double balance;
  final List<FinancialTransaction> transactions;
  final int currentPage;
  final int lastPage;
  final int total;

  factory FinancialLedger.fromJson(Map<String, dynamic> json) {
    final paginator = json['transactions'] as Map<String, dynamic>? ?? const {};
    return FinancialLedger(
      balance: _double(json['balance']),
      transactions: (paginator['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FinancialTransaction.fromJson)
          .toList(),
      currentPage: _int(paginator['current_page']),
      lastPage: _int(paginator['last_page']),
      total: _int(paginator['total']),
    );
  }
}

class FinancialTransaction {
  const FinancialTransaction({
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

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
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

int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _double(Object? value) => double.tryParse((value ?? 0).toString()) ?? 0;
