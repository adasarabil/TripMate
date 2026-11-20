import 'package:flutter/foundation.dart';

import 'demo_fixtures.dart';
import 'demo_models.dart';

/// Result of a username invite from Group Detail.
enum InviteResult { added, empty, unknownUser, alreadyMember, unknownGroup }

/// Result of entering an invite code on Join Group.
enum JoinResult { joined, notFound, alreadyMember }

/// Travel groups of the demo user.
///
/// Leaving a group only hides it from [visibleGroups]; the record stays in the
/// store so that [byId] keeps resolving old `Trip.groupId` values and expense
/// payer/share IDs. Joining again with the invite code makes it visible.
class GroupStore extends ChangeNotifier {
  GroupStore({this.currentUserId = 'ada'});

  /// Demo user whose groups are listed. Matches `DemoSession.currentUserId`.
  final String currentUserId;

  /// Demo group that is not in My Groups yet, reserved for the Join Group
  /// success path. Its code TRP-7M2Q is listed in the Step 2.2 PR notes.
  static const joinableDemoGroup = Group(
    id: 'cappadocia-crew',
    name: 'Cappadocia Crew',
    inviteCode: 'TRP-7M2Q',
    ownerId: 'naz',
    memberIds: ['naz', 'ata'],
  );

  final List<Group> _groups = [...DemoFixtures.groups, joinableDemoGroup];
  final Set<String> _hiddenIds = {};
  var _idCounter = 0;

  /// Groups the current user belongs to and has not left, in creation order.
  List<Group> get visibleGroups => List.unmodifiable(
    _groups.where(
      (group) =>
          group.memberIds.contains(currentUserId) &&
          !_hiddenIds.contains(group.id),
    ),
  );

  /// Any known group, including ones the user left.
  Group? byId(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  bool isVisible(String id) => visibleGroups.any((group) => group.id == id);

  /// Upper-cases and trims a typed invite code.
  static String normalizeCode(String raw) => raw.trim().toUpperCase();

  /// Lower-cases, trims and drops a leading `@` from a typed username.
  static String normalizeUsername(String raw) {
    final trimmed = raw.trim().toLowerCase();
    return trimmed.startsWith('@') ? trimmed.substring(1).trim() : trimmed;
  }

  /// Creates a group owned by the current user and returns its ID.
  String createGroup(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    final id = _newId(trimmed);
    _groups.add(
      Group(
        id: id,
        name: trimmed,
        inviteCode: _newInviteCode(),
        ownerId: currentUserId,
        memberIds: [currentUserId],
      ),
    );
    notifyListeners();
    return id;
  }

  /// Hides the group from My Groups without deleting its record.
  void leaveGroup(String id) {
    if (byId(id) == null || !_hiddenIds.add(id)) return;
    notifyListeners();
  }

  /// Finds a group by invite code, including ones the user left.
  Group? byInviteCode(String raw) {
    final code = normalizeCode(raw);
    for (final group in _groups) {
      if (group.inviteCode == code) return group;
    }
    return null;
  }

  /// Joins the group with [rawCode]. Returns the result and the group ID.
  (JoinResult, String?) joinWithCode(String rawCode) {
    final group = byInviteCode(rawCode);
    if (group == null) return (JoinResult.notFound, null);
    if (isVisible(group.id)) return (JoinResult.alreadyMember, group.id);

    _hiddenIds.remove(group.id);
    if (!group.memberIds.contains(currentUserId)) {
      _replace(group, memberIds: [...group.memberIds, currentUserId]);
    }
    notifyListeners();
    return (JoinResult.joined, group.id);
  }

  /// Adds the demo user with [rawUsername] to the group.
  InviteResult inviteByUsername(String groupId, String rawUsername) {
    final group = byId(groupId);
    if (group == null) return InviteResult.unknownGroup;
    final username = normalizeUsername(rawUsername);
    if (username.isEmpty) return InviteResult.empty;

    DemoUser? user;
    for (final candidate in demoUsers.values) {
      if (candidate.username.toLowerCase() == username) user = candidate;
    }
    if (user == null) return InviteResult.unknownUser;
    if (group.memberIds.contains(user.id)) return InviteResult.alreadyMember;

    _replace(group, memberIds: [...group.memberIds, user.id]);
    notifyListeners();
    return InviteResult.added;
  }

  /// Removes a member. The owner cannot be removed. Returns whether it did.
  bool removeMember(String groupId, String userId) {
    final group = byId(groupId);
    if (group == null ||
        userId == group.ownerId ||
        !group.memberIds.contains(userId)) {
      return false;
    }
    _replace(
      group,
      memberIds: [
        for (final id in group.memberIds)
          if (id != userId) id,
      ],
    );
    notifyListeners();
    return true;
  }

  void _replace(Group group, {required List<String> memberIds}) {
    final index = _groups.indexWhere((g) => g.id == group.id);
    _groups[index] = Group(
      id: group.id,
      name: group.name,
      inviteCode: group.inviteCode,
      ownerId: group.ownerId,
      memberIds: List.unmodifiable(memberIds),
    );
  }

  String _newId(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = slug.isEmpty ? 'group' : slug;
    var id = base;
    while (byId(id) != null) {
      id = '$base-${++_idCounter}';
    }
    return id;
  }

  String _newInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var seed = _groups.length * 7919 + _idCounter;
    while (true) {
      final buffer = StringBuffer('TRP-');
      var value = seed;
      for (var i = 0; i < 4; i++) {
        buffer.write(alphabet[value % alphabet.length]);
        value = value ~/ alphabet.length + 13 * (i + 1);
      }
      final code = buffer.toString();
      if (byInviteCode(code) == null) return code;
      seed++;
    }
  }
}
