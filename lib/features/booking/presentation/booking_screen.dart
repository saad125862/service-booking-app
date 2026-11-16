import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../../services/domain/service.dart';
import '../../services/presentation/services_providers.dart';
import '../../services/presentation/widgets/service_image.dart';
import '../domain/availability.dart';
import 'booking_providers.dart';
import 'widgets/date_strip.dart';
import 'widgets/slot_grid.dart';

/// Pick a date and an available time slot, add optional notes and confirm.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.serviceId, this.service});

  final String serviceId;
  final Service? service;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late final DateTime _today = dateOnly(DateTime.now());
  late DateTime _date = _today;
  TimeSlot? _slot;
  final _notes = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  AvailabilityQuery get _query =>
      (serviceId: widget.serviceId, date: DateFormat('yyyy-MM-dd').format(_date));

  void _selectDate(DateTime date) {
    if (date == _date) return;
    setState(() {
      _date = date;
      _slot = null;
      _error = null;
    });
  }

  Future<void> _confirm() async {
    final slot = _slot;
    if (slot == null || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final appointment = await ref.read(bookingRepositoryProvider).create(
            serviceId: widget.serviceId,
            startTime: slot.start,
            notes: _notes.text,
          );
      refreshBookings(ref);
      if (!mounted) return;
      context.go('/booking/${appointment.id}/confirmed', extra: appointment);
    } on ApiException catch (e) {
      // The slot may have been taken meanwhile: reload the slots and ask for another.
      if (e.code == 'SLOT_UNAVAILABLE' || e.code == 'INVALID_SLOT') {
        ref.invalidate(availabilityProvider(_query));
      }
      if (mounted) {
        setState(() {
          _error = e.message;
          if (e.code == 'SLOT_UNAVAILABLE' || e.code == 'INVALID_SLOT') _slot = null;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fetched = ref.watch(serviceDetailProvider(widget.serviceId));
    final service = fetched.value ?? widget.service;
    final availability = ref.watch(availabilityProvider(_query));

    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book appointment')),
        body: fetched.hasError
            ? ErrorView(
                message: fetched.error is ApiException ? (fetched.error as ApiException).message : 'Please try again.',
                onRetry: () => ref.invalidate(serviceDetailProvider(widget.serviceId)),
              )
            : const LoadingView(),
      );
    }

    final slot = _slot;
    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      SizedBox(width: 88, height: 88, child: ServiceImage(url: service.imageUrl)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Formatters.price(service.price)}  ·  ${Formatters.duration(service.durationMinutes)}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _SectionTitle('Select a date'),
              DateStrip(selected: _date, today: _today, onSelected: _selectDate),
              const SizedBox(height: 20),
              const _SectionTitle('Select a time'),
              SlotGrid(
                availability: availability,
                selected: _slot,
                onSelected: (s) => setState(() {
                  _slot = s;
                  _error = null;
                }),
                onRetry: () => ref.invalidate(availabilityProvider(_query)),
              ),
              if (availability.value != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    'Times are shown in ${availability.value!.timeZone} time.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 20),
              const _SectionTitle('Notes (optional)'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppTextField(
                  controller: _notes,
                  label: 'Anything the provider should know?',
                  maxLines: 3,
                  maxLength: 500,
                  enabled: !_submitting,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: StatusBanner(message: _error!),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (slot != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.event_available, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${Formatters.date(_date)} at ${slot.label}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            Formatters.price(service.price),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppButton(
                    label: slot == null ? 'Select a time' : 'Confirm booking',
                    icon: slot == null ? null : Icons.check_circle_outline,
                    loading: _submitting,
                    onPressed: slot == null ? null : _confirm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );
}
