import 'package:material_ui/material_ui.dart';

import '../../data/demo_models.dart';
import '../trips/trip_format.dart';

/// Shared formatting and small widgets of the expense screens.
abstract final class ExpenseFormat {
  /// €1,240.00 — always two decimals and thousands separators.
  static String money(int minor, String currencyCode) {
    final symbol = TripFormat.currencySymbol(currencyCode);
    final sign = minor < 0 ? '−' : '';
    final value = minor.abs();
    final cents = (value % 100).toString().padLeft(2, '0');
    return '$sign$symbol${_grouped(value ~/ 100)}.$cents';
  }

  /// +€69.00 / −€18.50 / €0.00
  static String signedMoney(int minor, String currencyCode) {
    if (minor > 0) return '+${money(minor, currencyCode)}';
    return money(minor, currencyCode);
  }

  static String _grouped(int whole) {
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// "Naz" for a current or former member, or a readable fallback.
String memberName(String userId) {
  final user = demoUsers[userId];
  if (user == null) return 'Former member';
  return user.displayName.split(' ').first;
}

String memberInitial(String userId) {
  final name = memberName(userId);
  return name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.userId, {super.key, this.radius = 14});

  final String userId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.surfaceContainerHighest,
      foregroundColor: colors.onSurfaceVariant,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.outline),
        ),
        alignment: Alignment.center,
        child: Text(
          memberInitial(userId),
          style: TextStyle(fontSize: radius * 0.85),
        ),
      ),
    );
  }
}

/// Small uppercase heading such as "EXPENSES" or "BALANCES".
class ExpenseSectionLabel extends StatelessWidget {
  const ExpenseSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
