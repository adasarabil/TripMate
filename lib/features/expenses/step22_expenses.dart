import 'package:flutter/widgets.dart';

import 'add_expense_screen.dart';
import 'expenses_tab.dart';
import 'profile_screen.dart';
import 'settle_up_screen.dart';

Widget expensesTripTab(String tripId) => ExpensesTab(tripId: tripId);

Widget addExpenseScreen(String tripId) => AddExpenseScreen(tripId: tripId);

Widget settleUpScreen(String tripId) => SettleUpScreen(tripId: tripId);

Widget profileTab() => const ProfileScreen();
