import 'package:flutter/widgets.dart';

import '../../ui/app_widgets.dart';

Widget expensesTripTab(String tripId) =>
    const PendingStep22Screen('Expenses', embedded: true);

Widget addExpenseScreen(String tripId) =>
    const PendingStep22Screen('Add Expense');

Widget settleUpScreen(String tripId) => const PendingStep22Screen('Settle Up');

Widget profileTab() => const PendingStep22Screen('Profile');
