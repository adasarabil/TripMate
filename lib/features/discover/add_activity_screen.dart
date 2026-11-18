import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/places_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'discover_common.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key, required this.args});

  final ActivityArgs args;

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _note = TextEditingController();
  final _timeText = TextEditingController();
  DateTime? _day;
  TimeOfDay? _time;
  var _submitted = false;
  var _saved = false;

  @override
  void initState() {
    super.initState();
    _day = DateUtils.dateOnly(widget.args.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _note.dispose();
    _timeText.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _timeText.text = DiscoverFormat.time(
        DateTime(2000, 1, 1, picked.hour, picked.minute),
      );
    });
  }

  void _submit(List<DateTime> days) {
    if (_saved) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final day = _day!;
    final time = _time!;
    if (!days.contains(day)) return;

    _saved = true;
    context.read<PlacesStore>().addActivity(
      tripId: widget.args.tripId,
      stopId: widget.args.stopId,
      start: DateTime(day.year, day.month, day.day, time.hour, time.minute),
      title: _title.text,
      location: _location.text,
      note: _note.text,
    );
    FocusScope.of(context).unfocus();
    Navigator.pop(context, day);
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.select(
      (TripStore store) => store.byId(widget.args.tripId),
    );
    final stop = findStop(trip, widget.args.stopId);
    if (stop == null) {
      return const UnavailableScreen(
        message: 'This city stop is no longer part of the trip.',
      );
    }
    final days = stopDays(stop);
    final day = days.contains(_day) ? _day : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${stop.name} · '
                  '${DiscoverFormat.dateRange(stop.arrival, stop.departure)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<DateTime>(
                  key: ValueKey('activity-day:${days.first}-${days.last}'),
                  initialValue: day,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: [
                    for (final (index, value) in days.indexed)
                      DropdownMenuItem(
                        value: value,
                        child: Text(
                          'Day ${index + 1} · '
                          '${DiscoverFormat.shortDate(value)}',
                        ),
                      ),
                  ],
                  validator: (value) => value == null || !days.contains(value)
                      ? 'Please choose a day of this stop'
                      : null,
                  onChanged: (value) => setState(() => _day = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('activity-time'),
                  controller: _timeText,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: 'Choose a time',
                    suffixIcon: Icon(Icons.schedule, size: 18),
                  ),
                  onTap: _pickTime,
                  validator: (_) =>
                      _time == null ? 'Please choose a time' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('activity-title'),
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('activity-location'),
                  controller: _location,
                  decoration: InputDecoration(
                    labelText: 'Location (optional)',
                    helperText: stop.hotelAddress.isEmpty
                        ? null
                        : 'Tap the pin to use the hotel address (demo).',
                    suffixIcon: stop.hotelAddress.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Use hotel address',
                            icon: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                            ),
                            onPressed: () =>
                                _location.text = stop.hotelAddress,
                          ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('activity-note'),
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => _submit(days),
                  child: const Text('Add to Itinerary'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
