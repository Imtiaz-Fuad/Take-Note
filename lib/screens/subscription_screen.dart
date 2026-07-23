import 'package:flutter/material.dart';
import 'package:take_note/services/bdapps_service.dart';

enum _Step { checking, enterMobile, enterOtp, subscribed, unsubscribed }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

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

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) return;

    setState(() => _loading = true);
    final result = await _bdapps.checkSubscription(mobile);
    setState(() {
      _loading = false;
      if (result['error'] != null) {
        _statusMessage = result['error'].toString();
      } else if (result['isSubscribed'] == true) {
        _step = _Step.subscribed;
        _statusMessage = 'You are subscribed.';
      } else {
        _step = _Step.enterMobile;
        _statusMessage = 'Not subscribed yet.';
      }
    });
  }

  Future<void> _sendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      setState(() => _statusMessage = 'Enter a mobile number first.');
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final result = await _bdapps.sendOtp(mobile);

    setState(() {
      _loading = false;
      if (result['success'] == true && result['referenceNo'] != null) {
        _referenceNo = result['referenceNo'].toString();
        _step = _Step.enterOtp;
        _statusMessage = 'OTP sent. Enter the code below.';
      } else {
        _statusMessage = result['message']?.toString() ??
            result['error']?.toString() ??
            'Failed to send OTP.';
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _referenceNo == null) return;

    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final result = await _bdapps.verifyOtp(otp, _referenceNo!);
    final statusCode = result['statusCode']?.toString().toUpperCase() ?? '';

    setState(() {
      _loading = false;
      if (statusCode == 'S1000' || statusCode == 'SUCCESS') {
        _step = _Step.subscribed;
        _statusMessage = 'Subscription confirmed.';
      } else {
        _statusMessage = result['statusDetail']?.toString() ??
            result['message']?.toString() ??
            'OTP verification failed.';
      }
    });
  }

  Future<void> _unsubscribe() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) return;

    setState(() => _loading = true);
    final result = await _bdapps.unsubscribe(mobile);

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _step = _Step.enterMobile;
        _statusMessage = 'Unsubscribed successfully.';
        _otpController.clear();
        _referenceNo = null;
      } else {
        _statusMessage = result['error']?.toString() ??
            result['statusDetail']?.toString() ??
            'Unsubscribe failed.';
      }
    });
  }

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
                enabled: _step != _Step.subscribed,
                decoration: const InputDecoration(hintText: 'Mobile number (01XXXXXXXXX)'),
              ),
              const SizedBox(height: 16),

              if (_step == _Step.enterOtp) ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Enter OTP'),
                ),
                const SizedBox(height: 16),
              ],

              if (_statusMessage != null) ...[
                Text(_statusMessage!, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
              ],

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_step == _Step.subscribed)
                ElevatedButton(
                  onPressed: _unsubscribe,
                  child: const Text('Unsubscribe'),
                )
              else if (_step == _Step.enterOtp)
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text('Verify OTP'),
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _sendOtp,
                      child: const Text('Subscribe (Send OTP)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _checkStatus,
                      child: const Text('Check Subscription Status'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}