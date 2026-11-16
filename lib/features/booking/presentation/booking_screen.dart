import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../discounts/presentation/discount_providers.dart';
import '../../services/domain/service.dart';
import '../../services/presentation/services_providers.dart';
import '../../services/presentation/widgets/service_image.dart';
import '../domain/availability.dart';
import '../domain/payment_method.dart';
import 'booking_providers.dart';
import 'widgets/date_strip.dart';
import 'widgets/payment_picker.dart';
import 'widgets/slot_grid.dart';

/// Pick a date and an available time slot, give the address, choose how to pay and confirm.
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
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _addressFocus = FocusNode();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  PaymentMethod? _method;
  bool _saveAddress = true;
  bool _submitting = false;
  String? _error;

  /// The address saved on the user's profile, used to prefill the form.
  String get _profileAddress => ref.read(authProvider).value?.address?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _address.text = _profileAddress;
    // Only offer to save when the profile has no address yet.
    _saveAddress = _profileAddress.isEmpty;
  }

  @override
  void dispose() {
    _address.dispose();
    _addressFocus.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  AvailabilityQuery get _query => (serviceId: widget.serviceId, date: DateFormat('yyyy-MM-dd').format(_date));

  void _selectDate(DateTime date) {
    if (date == _date) return;
    setState(() {
      _date = date;
      _slot = null;
      _error = null;
    });
  }

  Future<void> _confirm(PaymentMethod? method) async {
    final slot = _slot;
    if (slot == null || _submitting) return;
    if (method == null) {
      setState(() => _error = 'Choose how you would like to pay.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _addressFocus.requestFocus(); // scrolls the first problem into view
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final appointment = await ref
          .read(bookingRepositoryProvider)
          .create(
            serviceId: widget.serviceId,
            startTime: slot.start,
            address: _address.text,
            paymentMethodId: method.id,
            paymentReference: method.requiresReference ? _reference.text : null,
            notes: _notes.text,
          );
      refreshBookings(ref);
      ref.invalidate(myDiscountsProvider); // a used discount is consumed
      _saveDefaultAddress();
      if (!mounted) return;
      context.go('/booking/${appointment.id}/confirmed', extra: appointment);
    } on ApiException catch (e) {
      // The slot may have been taken meanwhile: reload the slots and ask for another.
      final slotProblem = e.code == 'SLOT_UNAVAILABLE' || e.code == 'INVALID_SLOT';
      if (slotProblem) ref.invalidate(availabilityProvider(_query));
      if (mounted) {
        setState(() {
          _error = e.details.isNotEmpty ? e.details.values.join('\n') : e.message;
          if (slotProblem) _slot = null;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Saves the address to the profile (best effort) when the user asked for it.
  void _saveDefaultAddress() {
    final address = _address.text.trim();
    if (!_saveAddress || address == _profileAddress) return;
    ref.read(authProvider.notifier).updateProfile(address: address).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addressChanged = _address.text.trim() != _profileAddress && _address.text.trim().length >= 5;
    final fetched = ref.watch(serviceDetailProvider(widget.serviceId));
    final service = fetched.value ?? widget.service;
    final availability = ref.watch(availabilityProvider(_query));
    final methods = ref.watch(paymentMethodsProvider);

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

    // The customer's own approved discount (one order only) is shown before they confirm.
    final discounts = ref.watch(myDiscountsProvider).value ?? const [];
    final discount = bestDiscountFor(discounts, widget.serviceId, service.price);
    final discountAmount = discount?.amountFor(service.price) ?? 0;
    final payable = service.price - discountAmount;

    final availableMethods = methods.value ?? const <PaymentMethod>[];
    // Keep the choice valid; default to the first option once they load.
    final method =
        availableMethods.where((m) => m.id == _method?.id).firstOrNull ??
        (availableMethods.isEmpty ? null : availableMethods.first);

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
                                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (discount != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your approved discount (${discount.discountLabel}) is applied to this order. '
                            'It works for this one order only.',
                            style: TextStyle(color: scheme.onTertiaryContainer, height: 1.3),
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
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 20),
              const _SectionTitle('Service address'),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _address,
                        focusNode: _addressFocus,
                        label: 'Where should we come?',
                        hint: 'House, road, area, city',
                        prefixIcon: Icons.location_on_outlined,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2,
                        maxLength: 300,
                        validator: Validators.address,
                        enabled: !_submitting,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (addressChanged)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Save as my default address'),
                          value: _saveAddress,
                          onChanged: _submitting ? null : (v) => setState(() => _saveAddress = v),
                        ),
                      const SizedBox(height: 20),
                      const Align(alignment: Alignment.centerLeft, child: _SectionTitle('Payment', padded: false)),
                      PaymentPicker(
                        methods: methods,
                        selected: method,
                        onSelected: (m) => setState(() {
                          _method = m;
                          _error = null;
                        }),
                        referenceController: _reference,
                        enabled: !_submitting,
                        onRetry: () => ref.invalidate(paymentMethodsProvider),
                      ),
                    ],
                  ),
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
                          Icon(Icons.event_available, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${Formatters.date(_date)} at ${slot.label}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (discountAmount > 0) ...[
                            Text(
                              Formatters.price(service.price),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            Formatters.price(payable),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppButton(
                    label: slot == null ? 'Select a time' : 'Confirm booking',
                    icon: slot == null ? null : Icons.check_circle_outline,
                    loading: _submitting,
                    onPressed: slot == null ? null : () => _confirm(method),
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
  const _SectionTitle(this.text, {this.padded = true});
  final String text;
  final bool padded;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(padded ? 20 : 0, 0, padded ? 20 : 0, 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
  );
}
