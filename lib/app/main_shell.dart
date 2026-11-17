import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../features/expenses/step22_expenses.dart' as expenses;
import '../features/groups/step22_groups.dart' as groups;
import 'demo_session.dart';
import 'my_trips_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select(
      (DemoSession session) => session.currentTab,
    );

    return Scaffold(
      body: switch (activeTab) {
        AppMainTab.trips => const MyTripsScreen(),
        AppMainTab.groups => groups.groupsTab(),
        AppMainTab.profile => expenses.profileTab(),
      },
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: activeTab.index,
          onTap: (index) =>
              context.read<DemoSession>().selectTab(AppMainTab.values[index]),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.luggage_outlined, size: 21),
              activeIcon: Icon(Icons.luggage, size: 21),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined, size: 21),
              activeIcon: Icon(Icons.groups, size: 21),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 21),
              activeIcon: Icon(Icons.person, size: 21),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
