import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'trip_format.dart';

/// 11 · Add Transport Option for one directed leg.
class AddTransportOptionScreen extends StatelessWidget {
  const AddTransportOptionScreen({super.key, required this.args});

  final LegArgs args;

  @override
  Widget build(BuildContext context) {
    final store = context.read<TripStore>();
    final trip = store.byId(args.tripId);
    final leg = store.legFor(args.tripId, args.fromStopId, args.toStopId);
    if (trip == null || leg == null) {
      return const UnavailableScreen(
        message: 'This leg is no longer part of the route.',
      );
    }
    return _AddTransportForm(trip: trip, leg: leg);
  }
}

class _AddTransportForm extends StatefulWidget {
  const _AddTransportForm({required this.trip, required this.leg});

  final Trip trip;
  final RouteLeg leg;

  @override
  State<_AddTransportForm> createState() => _AddTransportFormState();
}

class _AddTransportFormState extends State<_AddTransportForm> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  final _departureText = TextEditingController();
  var _mode = TransportMode.train;
  TimeOfDay? _departure;
  var _autovalidate = AutovalidateMode.disabled;
  var _saving = false;

  /// The leg is travelled on the day the traveller leaves the first city.
  DateTime get _legDay => widget.leg.from.departure;

  @override
  void dispose() {
    _company.dispose();
    _price.dispose();
    _duration.dispose();
    _departureText.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departure ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Departure time',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _departure = picked;
      _departureText.text = TripFormat.time(_departureDateTime(picked));
    });
  }

  DateTime _departureDateTime(TimeOfDay time) => DateTime(
    _legDay.year,
    _legDay.month,
    _legDay.day,
    time.hour,
    time.minute,
  );

  String? _validatePrice(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a price';
    if (text.contains(',')) {
      return 'Use a dot for decimals, e.g. 19.50';
    }
    final minor = parseMoneyMinor(text);
    if (minor == null || minor <= 0) return 'Price must be a positive number';
    return null;
  }

  String? _validateDuration(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a duration';
    final minutes = parseDurationMinutes(text);
    if (minutes == null) return 'Use minutes or a format like 1h 35m';
    if (minutes <= 0) return 'Duration must be a positive number';
    if (minutes > 72 * 60) return 'Duration must be under 72 hours';
    return null;
  }

  void _save() {
    if (_saving) return;
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _saving = true;
    final id = context.read<TripStore>().addTransportOption(
      tripId: widget.trip.id,
      fromStopId: widget.leg.from.id,
      toStopId: widget.leg.to.id,
      mode: _mode,
      company: _company.text,
      priceMinor: parseMoneyMinor(_price.text)!,
      durationMinutes: parseDurationMinutes(_duration.text)!,
      departure: _departureDateTime(_departure!),
    );
    if (id == null) {
      _saving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This leg is no longer part of the route.'),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leg = widget.leg;
    final symbol = TripFormat.currencySymbol(widget.trip.currencyCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transport Option')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              Text(
                '${leg.from.name} → ${leg.to.name}',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                TripFormat.shortDate(_legDay),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const TripSectionLabel('TYPE'),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<TransportMode>(
                showSelectedIcon: false,
                segments: [
                  for (final mode in TransportMode.values)
                    ButtonSegment(value: mode, label: Text(mode.label)),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const Key('transport-company'),
                controller: _company,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Company / note'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a company or note'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('transport-price'),
                      controller: _price,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: symbol,
                      ),
                      validator: _validatePrice,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      key: const Key('transport-duration'),
                      controller: _duration,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: '1h 35m',
                      ),
                      validator: _validateDuration,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('transport-departure'),
                controller: _departureText,
                readOnly: true,
                onTap: _pickTime,
                decoration: InputDecoration(
                  labelText: 'Departure time',
                  hintText: 'HH:mm',
                  helperText: 'On ${TripFormat.shortDate(_legDay)}',
                  suffixIcon: const Icon(Icons.schedule, size: 18),
                ),
                validator: (_) =>
                    _departure == null ? 'Select a departure time' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _save, child: const Text('Save Option')),
            ],
          ),
        ),
      ),
    );
  }
}
