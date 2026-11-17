import 'package:flutter/foundation.dart';

import 'demo_fixtures.dart';
import 'demo_models.dart';

class GroupStore extends ChangeNotifier {
  List<Group> get visibleGroups => DemoFixtures.groups;

  Group? byId(String id) {
    for (final group in DemoFixtures.groups) {
      if (group.id == id) return group;
    }
    return null;
  }
}
