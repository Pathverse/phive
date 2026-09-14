import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import '../models/naming_models.dart';

const expectedNamingStores = [
  'namingparent',
  'namingcard',
  'autonamingcard',
  'cards_v1',
  'auto_cards_v1',
  '__ref_NamingParent_NamingCard',
  '__ref_NamingParent_AutoNamingCard',
  'cards_by_parent_v1',
  'auto_cards_by_parent_v1',
];

void registerNamingAdapters() {
  Hive.registerAdapter(NamingParentAdapter());
  Hive.registerAdapter(NamingCardAdapter());
  Hive.registerAdapter(AutoNamingCardAdapter());
  Hive.registerAdapter(CustomNamingCardAdapter());
  Hive.registerAdapter(AutoCustomNamingCardAdapter());
}

Future<PHiveRouter> openNamingRouter(String backend, {String? path}) async {
  final PHiveRouter router = backend == 'dynamic'
      ? PHiveDynamicRouter()
      : PHiveStaticRouter(collectionName: 'naming_static', path: path);
  router.applyDescriptors(const [
    NamingParentRouterDescriptor(),
    NamingCardRouterDescriptor(),
    AutoNamingCardRouterDescriptor(),
    CustomNamingCardRouterDescriptor(),
    AutoCustomNamingCardRouterDescriptor(),
  ]);
  await router.ensureOpen();
  return router;
}

void requireNaming(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> namingRoundTrip(PHiveRouter router, {required bool write}) async {
  final parent = NamingParent('parent');
  if (write) await router.store(parent);
  requireNaming(
    (await router.get<NamingParent>('parent'))?.id == 'parent',
    'Parent did not survive storage',
  );
  await _child(router, parent, NamingCard('card', 'parent'), write);
  await _child(router, parent, AutoNamingCard('auto', 'parent'), write);
  await _child(router, parent, CustomNamingCard('custom', 'parent'), write);
  await _child(
    router,
    parent,
    AutoCustomNamingCard('auto-custom', 'parent'),
    write,
  );
}

Future<void> _child<T extends NamingChild>(
  PHiveRouter router,
  NamingParent parent,
  T original,
  bool write,
) async {
  if (write) await router.store<T>(original);
  final restored = await router.get<T>(original.id);
  requireNaming(
    restored != null &&
        restored.id == original.id &&
        restored.parentId == 'parent' &&
        !identical(original, restored),
    'Child did not deserialize from storage',
  );
  final children = await router.getContainer(
    router.containerOf<T, NamingParent>(parent),
  );
  requireNaming(
    children.length == 1 && children.single.id == original.id,
    'Relationship did not survive storage',
  );
}
