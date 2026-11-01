import 'dart:convert';
import 'dart:io';

import '../content/content_auth_repository.dart';

/// Server-verified subscription state returned by the authenticated billing
/// sync function. Client SDK profiles are not authorization evidence.
class ServerBillingSnapshot {
  static const complimentaryProductId =
      'com.ardasayar.linglossa.premium.complimentary';

  const ServerBillingSnapshot({
    required this.premiumActive,
    this.sandboxActive = false,
    required this.environment,
    required this.productId,
    required this.expiresAt,
    required this.startsAt,
    required this.willRenew,
    required this.syncedAt,
    required this.purchaseAllowed,
    required this.purchaseEnvironment,
  });

  final bool premiumActive;
  final bool sandboxActive;
  final String environment;
  final String? productId;
  final DateTime? expiresAt;
  final DateTime? startsAt;
  final bool? willRenew;
  final DateTime syncedAt;

  /// Server-side policy decision for this authenticated account.
  final bool purchaseAllowed;
  final String purchaseEnvironment;

  factory ServerBillingSnapshot.fromJson(Object? value, {DateTime? now}) {
    if (value is! Map<String, dynamic> ||
        value['entitlement'] != 'premium' ||
        value['is_active'] is! bool ||
        value['environment'] is! String ||
        value['purchase_allowed'] is! bool ||
        value['purchase_environment'] is! String ||
        value['synced_at'] is! String) {
      throw const FormatException('Invalid billing sync response.');
    }
    DateTime? parseDate(Object? date) => date == null
        ? null
        : date is String
        ? DateTime.tryParse(date)
        : null;
    final syncedAt = parseDate(value['synced_at']);
    if (syncedAt == null) {
      throw const FormatException('Invalid billing sync timestamp.');
    }
    final expiresAt = parseDate(value['expires_at']);
    final startsAt = parseDate(value['starts_at']);
    if ((value['expires_at'] != null && expiresAt == null) ||
        (value['starts_at'] != null && startsAt == null)) {
      throw const FormatException('Invalid billing sync dates.');
    }
    final productId = value['product_id'];
    final willRenew = value['will_renew'];
    if ((productId != null && productId is! String) ||
        (willRenew != null && willRenew is! bool)) {
      throw const FormatException('Invalid billing sync fields.');
    }
    final environment = value['environment'] as String;
    final purchaseEnvironment = value['purchase_environment'] as String;
    if (!const {'Production', 'Sandbox'}.contains(environment) ||
        !const {'Production', 'Sandbox'}.contains(purchaseEnvironment)) {
      throw const FormatException('Invalid billing environment.');
    }
    const supportedProducts = {
      'com.ardasayar.linglossa.premium.monthly',
      'com.ardasayar.linglossa.premium.yearly',
      complimentaryProductId,
    };
    if (productId != null && !supportedProducts.contains(productId)) {
      throw const FormatException('Unsupported billing product.');
    }
    final complimentary = productId == complimentaryProductId;
    if (complimentary &&
        (environment != 'Production' ||
            willRenew != false ||
            startsAt == null ||
            expiresAt == null ||
            !expiresAt.isAfter(startsAt))) {
      throw const FormatException('Invalid complimentary entitlement.');
    }
    final checkedAt = now ?? DateTime.now();
    final hasStarted = !complimentary || !startsAt!.isAfter(checkedAt);
    final isActive = value['is_active'] == true;
    final notExpired = expiresAt == null || expiresAt.isAfter(checkedAt);
    if (isActive && productId == null) {
      throw const FormatException('Active entitlement has no product.');
    }
    final verifiedActive =
        isActive &&
        hasStarted &&
        notExpired &&
        supportedProducts.contains(productId);
    return ServerBillingSnapshot(
      premiumActive: verifiedActive && environment == 'Production',
      sandboxActive: verifiedActive && environment == 'Sandbox',
      environment: environment,
      productId: productId as String?,
      expiresAt: expiresAt,
      startsAt: startsAt,
      willRenew: willRenew as bool?,
      syncedAt: syncedAt,
      purchaseAllowed: value['purchase_allowed'] as bool,
      purchaseEnvironment: purchaseEnvironment,
    );
  }
}

abstract interface class BillingSyncGateway {
  Future<ServerBillingSnapshot> sync();
}

class SupabaseBillingSyncGateway implements BillingSyncGateway {
  SupabaseBillingSyncGateway(this.auth, {HttpClient? client})
    : _client = client ?? (HttpClient()..connectionTimeout = _requestTimeout);

  static const _requestTimeout = Duration(seconds: 15);

  final ContentAuthRepository auth;
  final HttpClient _client;

  @override
  Future<ServerBillingSnapshot> sync() async {
    final token = await auth.accessToken();
    final endpoint = Uri.parse(auth.url).resolve('/functions/v1/billing-sync');
    final request = await _client.postUrl(endpoint).timeout(_requestTimeout);
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set('apikey', auth.publicKey)
      ..contentType = ContentType.json;
    request.write('{}');
    final response = await request.close().timeout(_requestTimeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Billing sync failed with HTTP ${response.statusCode}.',
        uri: endpoint,
      );
    }

    return ServerBillingSnapshot.fromJson(jsonDecode(body));
  }

  void close() => _client.close(force: true);
}
