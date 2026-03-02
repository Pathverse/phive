import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_example/hive_registrar.g.dart';

import 'models/user_profile.dart';

const int encryptedStringTypeId = 300;
const int localNonceTypeId = 301;
const String userProfilesBoxName = 'user_profiles';
const String primaryUserKey = 'primary';

void printStage(String stage, String note) {
  print('');
  print('=== STAGE: $stage ===');
  print(note);
}

class DemoSeedProvider implements PHiveSeedProvider {
  @override
  final String id;

  final String seed;

  const DemoSeedProvider(this.id, this.seed);

  @override
  Object resolveSeed(PHiveCtx ctx) => seed;
}

PHiveCtx createDemoCtx() {
  return PHiveCtx(
    boxName: userProfilesBoxName,
    storageScope: PHiveStorageScope.box,
    seedProviders: <String, PHiveSeedProvider>{
      'profile_email_seed': const DemoSeedProvider(
        'profile_email_seed',
        'seed-alpha',
      ),
    },
    seedProviderResolver: (seedId, ctx) {
      if (seedId == 'token_seed') {
        return const DemoSeedProvider('token_seed', 'seed-beta');
      }
      return null;
    },
  );
}

PHiveHookRegistry createDemoHookRegistry() {
  final hookRegistry = PHiveHookRegistry();

  hookRegistry.registerPreWrite(EncryptedVar.actionKey, (variable, ctx) {
    print('preWrite hook -> ${ctx.varId}');
  });
  hookRegistry.registerPostRead(EncryptedVar.actionKey, (variable, ctx) {
    print('postRead hook -> ${ctx.varId}');
  });

  return hookRegistry;
}

void registerDemoAdapters({
  required PHiveStringCipher cipher,
  required PHiveCtx baseCtx,
  PHiveHookRegistry? hookRegistry,
}) {
  Hive.registerAdapters();

  Hive
    ..registerAdapter(
      encryptedStringVarAdapter(
        typeId: encryptedStringTypeId,
        cipher: cipher,
        hookRegistry: hookRegistry,
        baseCtx: baseCtx,
      ),
    )
    ..registerAdapter(
      localNonceStringVarAdapter(
        typeId: localNonceTypeId,
        cipher: cipher,
        hookRegistry: hookRegistry,
        baseCtx: baseCtx,
      ),
    );
}

UserProfile createDemoProfile() {
  return UserProfile(
    id: 'u_1',
    email: encryptedStringVar('demo@phive.dev', seedId: 'profile_email_seed'),
    token: localNonceStringVar('token-123', seedId: 'token_seed'),
  );
}

void printProfileFlow(
  String label,
  UserProfile profile,
  PHiveStringCipher cipher,
  PHiveCtx ctx,
) {
  print(
    '[$label] Inspecting wrapper values and derived raw payload snapshots.',
  );
  final rawEmailPayload = profile.email.toEncryptedPayload(cipher, ctx: ctx);
  final rawTokenPayload = profile.token.toEncryptedPayload(cipher, ctx: ctx);

  final decodedEmailPayload = PHiveVar.fromStoragePayload(rawEmailPayload);
  final decodedTokenPayload = PHiveVar.fromStoragePayload(rawTokenPayload);

  print('[$label] id: ${profile.id}');
  print('[$label] email.value: ${profile.email.value}');
  print('[$label] token.value: ${profile.token.value}');
  print('[$label] raw email payload: $rawEmailPayload');
  print('[$label] raw token payload: $rawTokenPayload');
  print('[$label] decoded email metadata: ${decodedEmailPayload.metadata}');
  print('[$label] decoded token metadata: ${decodedTokenPayload.metadata}');
}
