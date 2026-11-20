import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/demo_session.dart';
import '../../app/step22_routes.dart';
import '../../data/places_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'discover_common.dart';

class AddPlaceLogScreen extends StatefulWidget {
  const AddPlaceLogScreen({super.key, required this.args});

  final PlaceFormArgs args;

  @override
  State<AddPlaceLogScreen> createState() => _AddPlaceLogScreenState();
}

class _AddPlaceLogScreenState extends State<AddPlaceLogScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.args.place?.name);
  final _note = TextEditingController();
  final _location = TextEditingController();
  late String? _stopId = widget.args.stopId;
  late var _type = widget.args.place?.type ?? PlaceType.food;
  int? _rating;
  var _submitted = false;
  var _saved = false;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _location.dispose();
    super.dispose();
  }

  void _useDemoLocation(String hotelAddress) {
    _location.text = 'Near $hotelAddress';
  }

  void _submit() {
    if (_saved) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final trip = context.read<TripStore>().byId(widget.args.tripId);
    final stop = findStop(trip, _stopId);
    if (stop == null) return;

    _saved = true;
    context.read<PlacesStore>().addLog(
      tripId: widget.args.tripId,
      stopId: stop.id,
      name: _name.text,
      type: _type,
      rating: _rating!,
      authorId: context.read<DemoSession>().currentUserId,
      placeId: widget.args.place?.id,
      note: _note.text,
      location: _location.text,
    );
    FocusScope.of(context).unfocus();
    Navigator.pop(context, stop.id);
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.select(
      (TripStore store) => store.byId(widget.args.tripId),
    );
    if (trip == null) return const UnavailableScreen();
    final stops = trip.stops;
    final stop = findStop(trip, _stopId);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Place Log')),
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
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'log-stop:${stops.map((s) => s.id).join(',')}',
                  ),
                  initialValue: stop?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'City stop'),
                  hint: const Text('Choose a city'),
                  items: [
                    for (final s in stops)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  validator: (value) => findStop(trip, value) == null
                      ? 'Please choose a city'
                      : null,
                  onChanged: (value) => setState(() => _stopId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('log-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Place name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Please enter a place name'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Type', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<PlaceType>(
                  showSelectedIcon: false,
                  segments: [
                    for (final type in PlaceType.values)
                      ButtonSegment(value: type, label: Text(type.label)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) =>
                      setState(() => _type = selection.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                _RatingField(
                  value: _rating,
                  onChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('log-note'),
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('log-location'),
                  controller: _location,
                  decoration: InputDecoration(
                    labelText: 'Location (optional)',
                    suffixIcon: stop == null || stop.hotelAddress.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Use demo location',
                            icon: const Icon(Icons.my_location, size: 18),
                            onPressed: () =>
                                _useDemoLocation(stop.hotelAddress),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save Log'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingField extends StatelessWidget {
  const _RatingField({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<int>(
      validator: (_) => value == null ? 'Please choose a rating' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating', style: theme.textTheme.labelLarge),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                  isSelected: (value ?? 0) >= star,
                  onPressed: () {
                    onChanged(star);
                    field.didChange(star);
                  },
                  icon: const Icon(Icons.star_border),
                  selectedIcon: const Icon(Icons.star),
                ),
            ],
          ),
          if (field.errorText != null)
            Text(
              field.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
