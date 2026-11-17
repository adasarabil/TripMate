import 'demo_models.dart';

abstract final class DemoFixtures {
  static final today = DateTime(2026, 7);

  static const groups = [
    Group(
      id: 'interrail-gang',
      name: 'Interrail Gang',
      inviteCode: 'TRP-4K9X',
      ownerId: 'ada',
      memberIds: ['ada', 'naz', 'ata', 'emre', 'arda'],
    ),
    Group(
      id: 'weekend-izmir',
      name: 'Weekend Izmir',
      inviteCode: 'TRP-IZ3R',
      ownerId: 'ada',
      memberIds: ['ada', 'naz', 'emre'],
    ),
    Group(
      id: 'balkan-tour',
      name: 'Balkan Tour',
      inviteCode: 'TRP-BL4N',
      ownerId: 'ada',
      memberIds: ['ada', 'naz', 'ata', 'arda'],
    ),
  ];

  static final trips = List<Trip>.unmodifiable([
    Trip(
      id: 'interrail-summer',
      title: 'Interrail Summer',
      groupId: 'interrail-gang',
      start: DateTime(2026, 7, 12),
      end: DateTime(2026, 7, 19),
      currencyCode: 'EUR',
      stops: List.unmodifiable([
        CityStop(
          id: 'rome',
          name: 'Rome',
          arrival: DateTime(2026, 7, 12),
          departure: DateTime(2026, 7, 14),
          hotelName: 'Hotel Roma',
          hotelAddress: 'Rome, Italy',
        ),
        CityStop(
          id: 'florence',
          name: 'Florence',
          arrival: DateTime(2026, 7, 14),
          departure: DateTime(2026, 7, 16),
          hotelName: 'Ostello Bello',
          hotelAddress: 'Florence, Italy',
        ),
        CityStop(
          id: 'venice',
          name: 'Venice',
          arrival: DateTime(2026, 7, 16),
          departure: DateTime(2026, 7, 19),
          hotelName: 'Generator Venice',
          hotelAddress: 'Venice, Italy',
        ),
      ]),
    ),
    Trip(
      id: 'weekend-in-izmir',
      title: 'Weekend in Izmir',
      groupId: 'weekend-izmir',
      start: DateTime(2026, 10, 3),
      end: DateTime(2026, 10, 5),
      currencyCode: 'TRY',
      stops: List.unmodifiable([
        CityStop(
          id: 'izmir',
          name: 'Izmir',
          arrival: DateTime(2026, 10, 3),
          departure: DateTime(2026, 10, 4),
          hotelName: 'Izmir City Hotel',
          hotelAddress: 'Izmir, Türkiye',
        ),
        CityStop(
          id: 'cesme',
          name: 'Çeşme',
          arrival: DateTime(2026, 10, 4),
          departure: DateTime(2026, 10, 5),
          hotelName: 'Çeşme Beach Hotel',
          hotelAddress: 'Çeşme, Türkiye',
        ),
      ]),
    ),
    Trip(
      id: 'balkan-tour',
      title: 'Balkan Tour',
      groupId: 'balkan-tour',
      start: DateTime(2026, 4, 10),
      end: DateTime(2026, 4, 16),
      currencyCode: 'EUR',
      stops: List.unmodifiable([
        CityStop(
          id: 'sarajevo',
          name: 'Sarajevo',
          arrival: DateTime(2026, 4, 10),
          departure: DateTime(2026, 4, 12),
          hotelName: 'Sarajevo City Hotel',
          hotelAddress: 'Sarajevo, Bosnia and Herzegovina',
        ),
        CityStop(
          id: 'mostar',
          name: 'Mostar',
          arrival: DateTime(2026, 4, 12),
          departure: DateTime(2026, 4, 14),
          hotelName: 'Mostar Old Town Hotel',
          hotelAddress: 'Mostar, Bosnia and Herzegovina',
        ),
        CityStop(
          id: 'kotor',
          name: 'Kotor',
          arrival: DateTime(2026, 4, 14),
          departure: DateTime(2026, 4, 16),
          hotelName: 'Kotor Bay Hotel',
          hotelAddress: 'Kotor, Montenegro',
        ),
      ]),
    ),
  ]);
}
