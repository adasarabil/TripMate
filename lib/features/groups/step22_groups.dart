import 'package:flutter/widgets.dart';

import '../../ui/app_widgets.dart';
import 'group_detail_screen.dart';
import 'my_groups_screen.dart';

Widget groupsTab() => const MyGroupsScreen();

Widget groupDetailScreen(String groupId) => GroupDetailScreen(groupId: groupId);

Widget joinGroupScreen() => const PendingStep22Screen('Join Group');

Widget settingsScreen() => const PendingStep22Screen('Settings');
