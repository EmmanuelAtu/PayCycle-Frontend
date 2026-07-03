enum BillingCycle { daily, weekly, monthly, quarterly }

extension BillingCycleLabel on BillingCycle {
  String get label {
    switch (this) {
      case BillingCycle.daily:     return 'Daily';
      case BillingCycle.weekly:    return 'Weekly';
      case BillingCycle.monthly:   return 'Monthly';
      case BillingCycle.quarterly: return 'Quarterly';
    }
  }

  String get billedLabel {
    switch (this) {
      case BillingCycle.daily:     return 'Billed daily';
      case BillingCycle.weekly:    return 'Billed weekly';
      case BillingCycle.monthly:   return 'Billed monthly';
      case BillingCycle.quarterly: return 'Billed quarterly';
    }
  }
}

enum SubscriberStatus { active, failed, overdue }

extension SubscriberStatusLabel on SubscriberStatus {
  String get label {
    switch (this) {
      case SubscriberStatus.active:  return 'Active';
      case SubscriberStatus.failed:  return 'Failed';
      case SubscriberStatus.overdue: return 'Overdue';
    }
  }
}

class Plan {
  final String id;
  final String name;
  final double amount;
  final BillingCycle cycle;
  final int? billingDay;       // used for monthly/quarterly (1–28)
  final int activeCount;
  final int failedCount;
  final int overdueCount;
  final String paymentLink;

  const Plan({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    this.billingDay,
    this.activeCount = 0,
    this.failedCount = 0,
    this.overdueCount = 0,
    this.paymentLink = '',
  });

  int get totalSubscribers => activeCount + failedCount + overdueCount;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        cycle: BillingCycle.values.firstWhere(
          (e) => e.name == json['cycle'],
          orElse: () => BillingCycle.monthly,
        ),
        billingDay: json['billing_day'] as int?,
        activeCount: json['active_count'] as int? ?? 0,
        failedCount: json['failed_count'] as int? ?? 0,
        overdueCount: json['overdue_count'] as int? ?? 0,
        paymentLink: json['payment_link'] as String? ?? '',
      );
}

class Subscriber {
  final String id;
  final String name;
  final String email;
  final SubscriberStatus status;
  final String? lastPaidDate;
  final String? failureReason;

  const Subscriber({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.lastPaidDate,
    this.failureReason,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  factory Subscriber.fromJson(Map<String, dynamic> json) => Subscriber(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        status: SubscriberStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SubscriberStatus.active,
        ),
        lastPaidDate: json['last_paid_date'] as String?,
        failureReason: json['failure_reason'] as String?,
      );
}