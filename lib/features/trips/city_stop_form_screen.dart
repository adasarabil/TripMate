import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'trip_format.dart';

/// 07 · Add / Edit City Stop. A null stop ID means add mode.
class CityStopFormScreen extends StatelessWidget {
  const CityStopFormScreen({super.key, required this.args});

  final CityEditArgs args;

  @override
  Widget build(BuildContext context) {
    final store = context.read<TripStore>();
    final trip = store.byId(args.tripId);
    final stopId = args.stopId;
    final stop = stopId == null ? null : store.stopById(args.tripId, stopId);
    if (trip == null || (stopId != null && stop == null)) {
      return const UnavailableScreen(
        message: 'This city stop is no longer part of the trip.',
      );
    }
    return _CityStopForm(trip: trip, stop: stop);
  }
}

class _CityStopForm extends StatefulWidget {
  const _CityStopForm({required this.trip, required this.stop});

  final Trip trip;
  final CityStop? stop;

  @override
  State<_CityStopForm> createState() => _CityStopFormState();
}

class _CityStopFormState extends State<_CityStopForm> {
  final _formKey = GlobalKey<FormState>();
  late final _city = TextEditingController(text: widget.stop?.name);
  late final _hotelName = TextEditingController(text: widget.stop?.hotelName);
  late final _hotelAddress = TextEditingController(
    text: widget.stop?.hotelAddress,
  );
  late DateTime? _arrival = widget.stop?.arrival;
  late DateTime? _departure = widget.stop?.departure;
  var _autovalidate = AutovalidateMode.disabled;
  var _saving = false;

  bool get _isEdit => widget.stop != null;

  @override
  void dispose() {
    _city.dispose();
    _hotelName.dispose();
    _hotelAddress.dispose();
    super.dispose();
  }

  String? _withinTrip(DateTime value, String label) {
    final trip = widget.trip;
    if (value.isBefore(trip.start) || value.isAfter(trip.end)) {
      return '$label must be within the trip '
          '(${TripFormat.dateRange(trip.start, trip.end)})';
    }
    return null;
  }

  void _save() {
    if (_saving) return;
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _saving = true;
    final savedId = context.read<TripStore>().saveStop(
      widget.trip.id,
      stopId: widget.stop?.id,
      name: _city.text,
      arrival: _arrival!,
      departure: _departure!,
      hotelName: _hotelName.text,
      hotelAddress: _hotelAddress.text,
    );
    if (savedId == null) {
      _saving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This stop is no longer available.')),
      );
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final stop = widget.stop;
    if (stop == null) return;
    final store = context.read<TripStore>();
    if (!await confirmTripAction(
      context,
      title: 'Delete city stop?',
      message:
          'Delete ${stop.name} from ${widget.trip.title}? Its transport '
          'options are removed too.',
      confirmLabel: 'Delete',
    )) {
      return;
    }
    store.removeStop(widget.trip.id, stop.id);
    if (!mounted) return;
    // If the editor was opened from the stop's itinerary, that page now
    // shows a deleted stop, so return all the way to the trip's route.
    Navigator.popUntil(
      context,
      (route) => route.settings.name == AppRoute.tripDetail || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = widget.trip;
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit City Stop' : 'Add City Stop')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              TextFormField(
                key: const Key('stop-city'),
                controller: _city,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a city' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TripDateField(
                      key: const Key('stop-arrival'),
                      label: 'Arrival',
                      value: _arrival,
                      firstDate: trip.start,
                      lastDate: trip.end,
                      onChanged: (date) => setState(() => _arrival = date),
                      validator: (value) => value == null
                          ? 'Select an arrival date'
                          : _withinTrip(value, 'Arrival'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TripDateField(
                      key: const Key('stop-departure'),
                      label: 'Departure',
                      value: _departure,
                      firstDate: trip.start,
                      lastDate: trip.end,
                      initialPickerDate: _arrival,
                      onChanged: (date) => setState(() => _departure = date),
                      validator: (value) {
                        if (value == null) return 'Select a departure date';
                        final arrival = _arrival;
                        if (arrival != null && value.isBefore(arrival)) {
                          return 'Departure can’t be before arrival';
                        }
                        return _withinTrip(value, 'Departure');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const TripSectionLabel('ACCOMMODATION'),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('stop-hotel-name'),
                controller: _hotelName,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Hotel name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a hotel name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('stop-hotel-address'),
                controller: _hotelAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Hotel address',
                  suffixIcon: Tooltip(
                    message:
                        'Demo address. Real location search comes in '
                        'Step 3.',
                    child: Icon(Icons.location_on_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nearby recommendations are sorted by distance to this '
                'address.',
                style: hint,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _save, child: const Text('Save Stop')),
              if (_isEdit) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  onPressed: _delete,
                  child: const Text('Delete Stop'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
