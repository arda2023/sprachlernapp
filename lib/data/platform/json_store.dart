import '../../presentation/providers/reading_providers.dart';
import 'sqlite_platform.dart';
import 'json_store_native.dart'
    if (dart.library.js_interop) 'json_store_web.dart'
    as platform;

JsonStore platformJsonStore(String name) => platform.createJsonStore(name);

/// Only the account claiming the original phone database may migrate its UI
/// documents. Other accounts must never inherit that person's imported texts.
class AccountLegacyJsonStore implements JsonStore {
  AccountLegacyJsonStore(this.name, this.accountId);
  final String name;
  final String? accountId;
  @override
  Future<Object?> read() async => await canMigrateLegacyJson(accountId)
      ? platformJsonStore(name).read()
      : null;
  @override
  Future<void> write(Object? json) =>
      throw UnsupportedError('Migration source is read-only.');
}
