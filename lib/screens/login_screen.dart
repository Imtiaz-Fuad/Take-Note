import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:take_note/screens/notes.dart';
import 'package:take_note/screens/subscription_screen.dart';
import 'package:take_note/services/bdapps_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Convenience used by `main.dart` to read the persisted mobile, if any.
  static Future<String?> readSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('subscribedMobile');
  }

  /// Clears the persisted mobile — used on logout / unsubscription.
  static Future<void> clearSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subscribedMobile');
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _bdapps = BdappsService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final mobile = _mobileController.text.trim();
    if (!_isValid(mobile)) {
      setState(
        () => _error = 'Enter a valid mobile number (e.g. 01XXXXXXXXX).',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _bdapps.checkSubscription(mobile);
    if (!mounted) return;

    if (result['error'] != null) {
      setState(() {
        _loading = false;
        _error = result['error'].toString();
      });
      return;
    }

    final isSubscribed = result['isSubscribed'] == true;
    if (!isSubscribed) {
      setState(() {
        _loading = false;
        _error =
            'No active subscription for this number. Tap "Subscribe" below.';
      });
      return;
    }

    // Persist and route.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscribedMobile', mobile);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Notes()),
      (route) => false,
    );
  }

  Future<void> _openSubscribe() async {
    // Pre-fill the mobile field on the subscribe screen if user already typed one.
    final prefill = _mobileController.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(initialMobile: prefill),
      ),
    );

    // After returning from subscribe, attempt to use the typed number (in case
    // it was just subscribed from this same screen).
    if (!mounted) return;
    if (_mobileController.text.trim().isNotEmpty && !_loading) {
      _login();
    }
  }

  bool _isValid(String m) => RegExp(r'^01[3-9]\d{8}$').hasMatch(m);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to Take-Note',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with the mobile number used to subscribe to Take-Note updates.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      hintText: 'Mobile number (01XXXXXXXXX)',
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : _openSubscribe,
                    child: const Text('Not subscribed yet? Subscribe'),
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
