import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/payment_method.dart';
import '../booking_providers.dart';

/// "Pay ৳X online": gets a gateway checkout link for the booking, opens it in the browser, then
/// waits and checks the booking until the server has confirmed the payment with the gateway.
///
/// [initialUrl] is used by the assistant, which already created the link; otherwise a new
/// link is requested when the button is tapped.
class PayOnlineButton extends ConsumerStatefulWidget {
  const PayOnlineButton({
    super.key,
    required this.appointmentId,
    required this.amount,
    this.initialUrl,
    this.pollInterval = const Duration(seconds: 4),
  });

  final String appointmentId;
  final double amount;
  final String? initialUrl;
  final Duration pollInterval;

  @override
  ConsumerState<PayOnlineButton> createState() => _PayOnlineButtonState();
}

enum _Phase { idle, opening, waiting, paid }

class _PayOnlineButtonState extends ConsumerState<PayOnlineButton> with WidgetsBindingObserver {
  _Phase _phase = _Phase.idle;
  String? _url;
  String? _error;
  Timer? _timer;
  int _polls = 0;

  static const _maxPolls = 75; // about five minutes

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the browser: check right away instead of waiting for the next tick.
    if (state == AppLifecycleState.resumed && _phase == _Phase.waiting) _check();
  }

  Future<void> _pay() async {
    setState(() {
      _phase = _Phase.opening;
      _error = null;
    });
    try {
      // A link the assistant made can be stale, a fresh one is cheap: only reuse it once.
      final url = _url ?? (await ref.read(bookingRepositoryProvider).startOnlinePayment(widget.appointmentId)).url;
      _url = null;
      final opened = await ref.read(urlOpenerProvider)(Uri.parse(url));
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _phase = _Phase.idle;
          _error = "Couldn't open the payment page. Please try again.";
        });
        return;
      }
      setState(() => _phase = _Phase.waiting);
      _polls = 0;
      _timer?.cancel();
      _timer = Timer.periodic(widget.pollInterval, (_) => _check());
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.idle;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _check() async {
    if (!mounted || _phase != _Phase.waiting) return;
    _polls++;
    try {
      final a = await ref.read(bookingRepositoryProvider).detail(widget.appointmentId);
      if (!mounted) return;
      if (a.paymentStatus == PaymentStatus.paid) {
        _timer?.cancel();
        setState(() => _phase = _Phase.paid);
        refreshBookings(ref, appointmentId: widget.appointmentId);
        return;
      }
    } on ApiException {
      // Keep waiting: a missed check is fine, the next one will catch up.
    }
    if (_polls >= _maxPolls && mounted) {
      _timer?.cancel();
      setState(() => _phase = _Phase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_phase == _Phase.paid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_outlined, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment received. Thank you!',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    final busy = _phase == _Phase.opening;
    final waiting = _phase == _Phase.waiting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pay securely online',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            waiting
                ? "Finish paying in the page that opened. We'll update this booking as soon as the payment is confirmed."
                : 'Card, bKash, Nagad and more. You pay exactly ${Formatters.price(widget.amount)}.',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: 12),
          if (waiting)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Waiting for payment…', style: theme.textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(onPressed: _check, child: const Text("I've paid")),
                    TextButton(onPressed: _pay, child: const Text('Open again')),
                  ],
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : _pay,
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.payment),
                label: Text('Pay ${Formatters.price(widget.amount)}'),
              ),
            ),
        ],
      ),
    );
  }
}
