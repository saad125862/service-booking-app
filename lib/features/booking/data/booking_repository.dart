import '../../../core/network/api_client.dart';
import '../domain/appointment.dart';
import '../domain/availability.dart';

/// Availability, booking and the signed-in user's appointments.
class BookingRepository {
  BookingRepository(this._api);

  final ApiClient _api;

  /// [date] is a local calendar date, `YYYY-MM-DD`.
  Future<Availability> availability(String serviceId, String date) async {
    final res = await _api.get('/services/$serviceId/availability', query: {'date': date});
    return Availability.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Appointment> create({
    required String serviceId,
    required DateTime startTime,
    String? notes,
  }) async {
    final trimmed = notes?.trim() ?? '';
    final res = await _api.post('/appointments', data: {
      'serviceId': serviceId,
      'startTime': startTime.toUtc().toIso8601String(),
      if (trimmed.isNotEmpty) 'notes': trimmed,
    });
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }

  /// [scope] is `upcoming` or `past`.
  Future<List<Appointment>> list({required String scope}) async {
    final res = await _api.get('/appointments', query: {'scope': scope, 'limit': 50});
    return [for (final a in res.data as List) Appointment.fromJson(a as Map<String, dynamic>)];
  }

  Future<Appointment> detail(String id) async {
    final res = await _api.get('/appointments/$id');
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Appointment> cancel(String id) async {
    final res = await _api.patch('/appointments/$id/cancel');
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }
}
