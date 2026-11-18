import 'package:material_ui/material_ui.dart';

import '../../data/trip_store.dart';

abstract final class TripFormat {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const currencies = ['EUR', 'USD', 'GBP', 'TRY'];

  static const _symbols = {'EUR': '€', 'USD': r'$', 'GBP': '£', 'TRY': '₺'};

  static String currencySymbol(String code) => _symbols[code] ?? '$code ';

  /// 14 Jul
  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  /// 14/07/2026 (day/month/year, as shown in the form fields).
  static String fieldDate(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  /// 12–14 Jul, 30 Jul–2 Aug, 30 Dec 2026–2 Jan 2027
  static String dateRange(DateTime start, DateTime end) {
    final startMonth = _months[start.month - 1];
    final endMonth = _months[end.month - 1];
    if (start.year != end.year) {
      return '${start.day} $startMonth ${start.year}–'
          '${end.day} $endMonth ${end.year}';
    }
    if (start.month != end.month) {
      return '${start.day} $startMonth–${end.day} $endMonth';
    }
    if (start.day == end.day) return '${start.day} $startMonth';
    return '${start.day}–${end.day} $startMonth';
  }

  /// 09:10
  static String time(DateTime date) =>
      '${_two(date.hour)}:${_two(date.minute)}';

  /// €19, €19.50, ₺250
  static String money(int minor, String currencyCode) {
    final symbol = currencySymbol(currencyCode);
    final whole = minor ~/ 100;
    final cents = minor.remainder(100);
    if (cents == 0) return '$symbol$whole';
    return '$symbol$whole.${_two(cents)}';
  }

  /// 1h 35m, 45m, 2h
  static String duration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes.remainder(60);
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  static IconData modeIcon(TransportMode mode) => switch (mode) {
    TransportMode.bus => Icons.directions_bus_outlined,
    TransportMode.train => Icons.train_outlined,
    TransportMode.flight => Icons.flight_outlined,
  };

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// Parses user money input such as "19", "19.5" or "19.50" into minor units.
/// Returns null for anything else, including comma decimals.
int? parseMoneyMinor(String input) {
  final text = input.trim();
  final match = RegExp(r'^(\d{1,7})(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

/// Parses "95", "1h 35m", "2h", "45m" or "1:35" into minutes.
int? parseDurationMinutes(String input) {
  final text = input.trim().toLowerCase();
  if (text.isEmpty) return null;
  final plain = RegExp(r'^\d{1,4}$');
  if (plain.hasMatch(text)) return int.parse(text);
  final clock = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(text);
  if (clock != null) {
    return int.parse(clock.group(1)!) * 60 + int.parse(clock.group(2)!);
  }
  final units = RegExp(r'^(?:(\d{1,2})\s*h)?\s*(?:(\d{1,3})\s*m(?:in)?)?$')
      .firstMatch(text);
  if (units != null && (units.group(1) != null || units.group(2) != null)) {
    final hours = int.parse(units.group(1) ?? '0');
    final minutes = int.parse(units.group(2) ?? '0');
    return hours * 60 + minutes;
  }
  return null;
}

/// A read-only form field that opens a date picker and shows dd/mm/yyyy.
class TripDateField extends StatefulWidget {
  const TripDateField({
    super.key,
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    required this.validator,
    this.initialPickerDate,
  });

  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialPickerDate;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<DateTime> validator;

  @override
  State<TripDateField> createState() => _TripDateFieldState();
}

class _TripDateFieldState extends State<TripDateField> {
  late final _controller = TextEditingController(text: _text(widget.value));

  static String _text(DateTime? value) =>
      value == null ? '' : TripFormat.fieldDate(value);

  @override
  void didUpdateWidget(TripDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync a value changed by the parent after this frame, never mid-build.
    if (_controller.text != _text(widget.value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final text = _text(widget.value);
        if (mounted && _controller.text != text) _controller.text = text;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    var initial = widget.value ?? widget.initialPickerDate ?? widget.firstDate;
    if (initial.isBefore(widget.firstDate)) initial = widget.firstDate;
    if (initial.isAfter(widget.lastDate)) initial = widget.lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      helpText: widget.label,
      fieldHintText: 'dd/mm/yyyy',
    );
    if (picked == null || !mounted) return;
    _controller.text = _text(picked);
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _pick,
      validator: (_) => widget.validator(widget.value),
      // Slightly smaller text and a compact icon keep the full dd/mm/yyyy
      // visible when two date fields share a 320 px wide row.
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'dd/mm/yyyy',
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
      ),
    );
  }
}

/// Small uppercase section label used in the trip forms.
class TripSectionLabel extends StatelessWidget {
  const TripSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

Future<bool> confirmTripAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true && context.mounted;
}
