abstract final class AppRoute {
  static const welcome = '/';
  static const logIn = '/login';
  static const signUp = '/signup';
  static const home = '/home';

  static const createTrip = '/trips/new';
  static const tripDetail = '/trips/detail';
  static const editCityStop = '/trips/city/edit';
  static const itinerary = '/trips/city/itinerary';
  static const addActivity = '/trips/city/activity/new';
  static const transportOptions = '/trips/transport';
  static const addTransportOption = '/trips/transport/new';
  static const addExpense = '/trips/expense/new';
  static const settleUp = '/trips/settle';
  static const addPlaceLog = '/trips/places/new';
  static const nearby = '/trips/nearby';

  static const groupDetail = '/groups/detail';
  static const joinGroup = '/groups/join';
  static const settings = '/settings';
}

class CityStopArgs {
  const CityStopArgs(this.tripId, this.stopId);

  final String tripId;
  final String stopId;
}

class CityEditArgs {
  const CityEditArgs(this.tripId, [this.stopId]);

  final String tripId;
  final String? stopId;
}

class ActivityArgs {
  const ActivityArgs(this.tripId, this.stopId, this.day);

  final String tripId;
  final String stopId;
  final DateTime day;
}

class LegArgs {
  const LegArgs(this.tripId, this.fromStopId, this.toStopId);

  final String tripId;
  final String fromStopId;
  final String toStopId;
}

class PlaceFormArgs {
  const PlaceFormArgs(this.tripId, [this.stopId]);

  final String tripId;
  final String? stopId;
}
