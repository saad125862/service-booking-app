import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/booking_repository.dart';
import '../domain/appointment.dart';
import '../domain/availability.dart';
import '../domain/payment_method.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) => BookingRepository(ref.watch(apiClientProvider)));

enum BookingScope { upcoming, past }

/// Payment options the customer can pick when booking.
final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>(
  (ref) => ref.read(bookingRepositoryProvider).paymentMethods(),
);

/// The signed-in user's appointments for one tab of My Bookings.
final myBookingsProvider = FutureProvider.autoDispose.family<List<Appointment>, BookingScope>(
  (ref, scope) => ref.read(bookingRepositoryProvider).list(scope: scope.name),
);

final appointmentDetailProvider = FutureProvider.autoDispose.family<Appointment, String>(
  (ref, id) => ref.read(bookingRepositoryProvider).detail(id),
);

/// Slots for one service on one day. [date] is `YYYY-MM-DD`.
typedef AvailabilityQuery = ({String serviceId, String date});

final availabilityProvider = FutureProvider.autoDispose.family<Availability, AvailabilityQuery>(
  (ref, q) => ref.read(bookingRepositoryProvider).availability(q.serviceId, q.date),
);

/// Makes the bookings tabs and any open details reload after a booking or cancellation.
void refreshBookings(WidgetRef ref, {String? appointmentId}) {
  ref.invalidate(myBookingsProvider);
  if (appointmentId != null) ref.invalidate(appointmentDetailProvider(appointmentId));
}
