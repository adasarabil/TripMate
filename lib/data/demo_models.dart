class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.groupId,
    required this.start,
    required this.end,
    required this.currencyCode,
    required this.stops,
    this.coverAsset,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String groupId;
  final DateTime start;
  final DateTime end;
  final String currencyCode;
  final List<CityStop> stops;
  final String? coverAsset;
  final String? imageUrl;
}

class CityStop {
  const CityStop({
    required this.id,
    required this.name,
    required this.arrival,
    required this.departure,
    required this.hotelName,
    required this.hotelAddress,
  });

  final String id;
  final String name;
  final DateTime arrival;
  final DateTime departure;
  final String hotelName;
  final String hotelAddress;
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final List<String> memberIds;
}

class DemoUser {
  const DemoUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
  });

  final String id;
  final String username;
  final String displayName;
  final String email;
}

const demoUsers = <String, DemoUser>{
  'ada': DemoUser(
    id: 'ada',
    username: 'adasarabil',
    displayName: 'Ada Derviş Sarabil',
    email: 'ada@example.com',
  ),
  'naz': DemoUser(
    id: 'naz',
    username: 'nazzagli',
    displayName: 'Naz Zağlı',
    email: 'naz@example.com',
  ),
  'ata': DemoUser(
    id: 'ata',
    username: 'atabalci',
    displayName: 'Ata Balcı',
    email: 'ata@example.com',
  ),
  'emre': DemoUser(
    id: 'emre',
    username: 'emretutal',
    displayName: 'Emre Tutal',
    email: 'emre@example.com',
  ),
  'arda': DemoUser(
    id: 'arda',
    username: 'ardakoculu',
    displayName: 'Arda Koçulu',
    email: 'arda@example.com',
  ),
  'demo-elif': DemoUser(
    id: 'demo-elif',
    username: 'demoelif',
    displayName: 'Elif',
    email: 'elif@example.com',
  ),
};
