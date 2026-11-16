import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/discount_repository.dart';
import '../domain/discount_request.dart';

final discountRepositoryProvider =
    Provider<DiscountRepository>((ref) => DiscountRepository(ref.watch(apiClientProvider)));

/// The customer's own discount requests, newest first.
final myDiscountsProvider = FutureProvider.autoDispose<List<DiscountRequest>>(
  (ref) => ref.read(discountRepositoryProvider).mine(),
);

/// The approved, unexpired discount that would apply to a booking of [serviceId] (the best one).
DiscountRequest? bestDiscountFor(List<DiscountRequest> requests, String serviceId, double price) {
  DiscountRequest? best;
  for (final r in requests) {
    if (!r.appliesTo(serviceId)) continue;
    if (best == null || r.amountFor(price) > best.amountFor(price)) best = r;
  }
  return best;
}
