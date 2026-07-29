import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:take_note/screens/login_screen.dart';
import 'package:take_note/services/bdapps_service.dart';

enum _Step { checking, enterMobile, enterOtp, subscribed, unsubscribed }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.initialMobile,
    this.onUnsubscribed,
  });

  /// Optional mobile to pre-fill.
  final String? initialMobile;

  /// Called after a successful unsubscribe so the caller can pop / redirect.
  final VoidCallback? onUnsubscribed;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _bdapps = BdappsService();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.enterMobile;
  String? _referenceNo;
  String? _statusMessage;
  bool _loading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.initialMobile;
    if (saved != null && saved.isNotEmpty) {
      _mobileController.text = saved;
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isValidMobile(String m) => RegExp(r'^01[3-9]\d{8}$').hasMatch(m);

  // ---------------- Actions ----------------

  Future<void> _checkStatus() async {
    final mobile = _mobileController.text.trim();
    if (!_isValidMobile(mobile)) {
      _setMessage('Enter a valid mobile number (01XXXXXXXXX).', error: true);
      return;
    }

    setState(() => _loading = true);
    final result = await _bdapps.checkSubscription(mobile);
    if (!mounted) return;

    if (result['error'] != null) {
      setState(() {
        _loading = false;
        _statusMessage = result['error'].toString();
        _isError = true;
      });
      return;
    }

    if (result['isSubscribed'] == true) {
      setState(() {
        _loading = false;
        _step = _Step.subscribed;
        _statusMessage = 'You are subscribed to Take-Note updates.';
        _isError = false;
      });
    } else {
      setState(() {
        _loading = false;
        _statusMessage = 'Not subscribed yet. Tap "Send OTP" to subscribe.';
        _isError = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    final mobile = _mobileController.text.trim();
    if (!_isValidMobile(mobile)) {
      _setMessage('Enter a valid mobile number first.', error: true);
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = null;
      _isError = false;
    });

    final result = await _bdapps.sendOtp(mobile);
    if (!mounted) return;

    if (result['success'] == true && result['referenceNo'] != null) {
      setState(() {
        _loading = false;
        _referenceNo = result['referenceNo'].toString();
        _step = _Step.enterOtp;
        _statusMessage = 'OTP sent. Enter the 6-digit code below.';
      });
    } else {
      setState(() {
        _loading = false;
        _statusMessage =
            result['message']?.toString() ??
            result['error']?.toString() ??
            'Failed to send OTP.';
        _isError = true;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _referenceNo == null) {
      _setMessage('Enter the OTP you received.', error: true);
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = null;
      _isError = false;
    });

    final result = await _bdapps.verifyOtp(otp, _referenceNo!);
    if (!mounted) return;
    final statusCode = result['statusCode']?.toString().toUpperCase() ?? '';

    if (statusCode == 'S1000' || statusCode == 'SUCCESS') {
      setState(() {
        _loading = false;
        _step = _Step.subscribed;
        _statusMessage = 'Subscription confirmed. Welcome to Take-Note!';
        _isError = false;
      });
      // Persist the new mobile so the app drops the user on the notes screen
      // (or login -> notes if app is restarted).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscribedMobile', _mobileController.text.trim());
      if (!mounted) return;
      // Pop back to caller after a brief moment so user sees the success.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      });
    } else {
      setState(() {
        _loading = false;
        _statusMessage =
            result['statusDetail']?.toString() ??
            result['message']?.toString() ??
            'OTP verification failed.';
        _isError = true;
      });
    }
  }

  /// Show a confirmation dialog, then call unsubscribe directly.
  Future<void> _confirmAndUnsubscribe() async {
    final mobile = _mobileController.text.trim();
    if (!_isValidMobile(mobile)) {
      _setMessage('Enter your mobile number first.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm unsubscription'),
        content: Text(
          'Unsubscribe $mobile from Take-Note updates? You can resubscribe anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _statusMessage = null;
      _isError = false;
    });

    final result = await _bdapps.unsubscribe(mobile);
    if (!mounted) return;

    if (result['success'] == true || result['statusCode'] == 'S1000') {
      // Clear persisted mobile
      await LoginScreen.clearSavedMobile();

      setState(() {
        _loading = false;
        _step = _Step.unsubscribed;
        _statusMessage = 'You have been unsubscribed successfully.';
        _isError = false;
        _referenceNo = null;
        _otpController.clear();
      });

      // Notify caller (login screen or notes screen) and pop.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        widget.onUnsubscribed?.call();
        Navigator.of(context).pop(true);
      });
    } else {
      setState(() {
        _loading = false;
        _statusMessage =
            result['statusDetail']?.toString() ??
            result['message']?.toString() ??
            result['error']?.toString() ??
            'Unsubscribe failed.';
        _isError = true;
      });
    }
  }

  void _setMessage(String text, {bool error = false}) {
    setState(() {
      _statusMessage = text;
      _isError = error;
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                enabled: _step != _Step.enterOtp && !_loading,
                decoration: const InputDecoration(
                  hintText: 'Mobile number (01XXXXXXXXX)',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 16),

              if (_step == _Step.enterOtp) ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  enabled: !_loading,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Enter OTP',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isError ? Colors.red : Colors.green).withOpacity(
                      0.08,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isError ? Colors.red : Colors.green).withOpacity(
                        0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _isError ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    switch (_step) {
      case _Step.subscribed:
        return Column(
          children: [
            const _StatusBanner(
              icon: Icons.verified_outlined,
              title: 'You are subscribed',
              message:
                  'You can manage your Take-Note updates from here. Tap unsubscribe below to stop receiving updates at any time.',
              tone: _BannerTone.success,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Unsubscribe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: _confirmAndUnsubscribe,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh status'),
              onPressed: _checkStatus,
            ),
          ],
        );

      case _Step.enterOtp:
        return Column(
          children: [
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('Verify OTP'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _sendOtp, child: const Text('Resend OTP')),
          ],
        );

      case _Step.unsubscribed:
        return ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        );

      case _Step.enterMobile:
      case _Step.checking:
        return Column(
          children: [
            ElevatedButton(
              onPressed: _sendOtp,
              child: const Text('Subscribe — Send OTP'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _checkStatus,
              child: const Text('Check Subscription Status'),
            ),
          ],
        );
    }
  }
}

enum _BannerTone { success }

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String message;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == _BannerTone.success ? Colors.green : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
