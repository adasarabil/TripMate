import 'package:flutter_test/flutter_test.dart';
import 'package:tripmate/data/group_store.dart';

void main() {
  test('seed lists the three demo groups, not the reserved one', () {
    final store = GroupStore();
    expect(store.visibleGroups.map((g) => g.id), [
      'interrail-gang',
      'weekend-izmir',
      'balkan-tour',
    ]);
    expect(store.byId('cappadocia-crew')?.inviteCode, 'TRP-7M2Q');
  });

  test('invite codes and usernames are normalized', () {
    expect(GroupStore.normalizeCode('  trp-7m2q '), 'TRP-7M2Q');
    expect(GroupStore.normalizeUsername(' @DemoElif '), 'demoelif');
    expect(GroupStore.normalizeUsername('@'), '');
  });

  test('join adds the user once and rejects unknown codes', () {
    final store = GroupStore();
    expect(store.joinWithCode('TRP-0000'), (JoinResult.notFound, null));

    expect(store.joinWithCode(' trp-7m2q'), (
      JoinResult.joined,
      'cappadocia-crew',
    ));
    expect(store.byId('cappadocia-crew')!.memberIds, ['naz', 'ata', 'ada']);
    expect(store.visibleGroups.last.id, 'cappadocia-crew');

    expect(store.joinWithCode('TRP-7M2Q'), (
      JoinResult.alreadyMember,
      'cappadocia-crew',
    ));
    expect(store.byId('cappadocia-crew')!.memberIds, ['naz', 'ata', 'ada']);
  });

  test('leaving hides a group but keeps it for history and re-join', () {
    final store = GroupStore();
    store.leaveGroup('interrail-gang');
    expect(
      store.visibleGroups.map((g) => g.id),
      isNot(contains('interrail-gang')),
    );
    final kept = store.byId('interrail-gang')!;
    expect(kept.memberIds, hasLength(5));

    expect(store.joinWithCode('TRP-4K9X').$1, JoinResult.joined);
    expect(store.isVisible('interrail-gang'), isTrue);
    expect(store.byId('interrail-gang')!.memberIds, hasLength(5));
  });

  test('username invite handles empty, unknown, member and success', () {
    final store = GroupStore();
    const id = 'interrail-gang';
    expect(store.inviteByUsername(id, '  '), InviteResult.empty);
    expect(store.inviteByUsername(id, '@nobody'), InviteResult.unknownUser);
    expect(store.inviteByUsername(id, '@nazzagli'), InviteResult.alreadyMember);
    expect(store.inviteByUsername(id, '@DemoElif'), InviteResult.added);
    expect(store.byId(id)!.memberIds.last, 'demo-elif');
    expect(store.inviteByUsername(id, 'demoelif'), InviteResult.alreadyMember);
    expect(
      store.inviteByUsername('missing', 'demoelif'),
      InviteResult.unknownGroup,
    );
  });

  test('owner cannot be removed, other members can', () {
    final store = GroupStore();
    expect(store.removeMember('interrail-gang', 'ada'), isFalse);
    expect(store.removeMember('interrail-gang', 'naz'), isTrue);
    expect(store.byId('interrail-gang')!.memberIds, isNot(contains('naz')));
    expect(store.removeMember('interrail-gang', 'naz'), isFalse);
  });

  test('create group trims, makes the user owner and unique IDs/codes', () {
    final store = GroupStore();
    expect(() => store.createGroup('   '), throwsArgumentError);
    final first = store.createGroup('  Ski Trip ');
    final second = store.createGroup('Ski Trip');
    expect(first, isNot(second));
    final group = store.byId(first)!;
    expect(group.name, 'Ski Trip');
    expect(group.ownerId, 'ada');
    expect(group.memberIds, ['ada']);
    expect(group.inviteCode, matches(RegExp(r'^TRP-[A-Z0-9]{4}$')));
    expect(group.inviteCode, isNot(store.byId(second)!.inviteCode));
    expect(store.visibleGroups.map((g) => g.id), containsAll([first, second]));
  });
}
