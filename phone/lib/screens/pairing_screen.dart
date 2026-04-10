/// Pairing screen for establishing secure sync with the Avodah server.
///
/// Displayed when `/api/sync/status` returns `needsPairing: true`.
///
/// Flow:
/// 1. [PairingScreen] checks pairing status
/// 2. If unpaired, initiates pairing via [PhonePairingService.startPairing]
/// 3. Displays the server's 6-digit passcode + TLS fingerprint for verification
/// 4. User confirms on phone after verifying match on server screen
/// 5. [PhonePairingService.confirmPairing] completes the handshake
/// 6. On success, navigates back to resume sync
///
/// AC2: Phone app shows "Pair with Server" screen when needsPairing:true
/// AC8: If self-signed cert not approved, phone shows cert fingerprint dialog
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/crypto_sync_service.dart';
import '../services/pairing_service.dart';

/// Arguments for [PairingScreen].
class PairingScreenArgs {
  final CryptoSyncService cryptoClient;
  final String nodeId;

  const PairingScreenArgs({
    required this.cryptoClient,
    required this.nodeId,
  });
}

/// Pairing screen widget.
class PairingScreen extends StatefulWidget {
  final PairingScreenArgs args;

  const PairingScreen({super.key, required this.args});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  late final PhonePairingService _pairingService;

  /// Pairing state machine states.
  static const _kStateLoading = 'loading';
  static const _kStateShowPasscode = 'show_passcode';
  static const _kStatePairing = 'pairing';
  static const _kStateError = 'error';
  static const _kStateSuccess = 'success';

  String _state = _kStateLoading;
  String? _errorMessage;

  // Passcode info (populated after startPairing)
  String? _passcode;
  String? _serverFingerprint;
  List<int>? _serverPubKeyBytes;

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  void _initPairing() {
    _pairingService = PhonePairingService(
      cryptoClient: widget.args.cryptoClient,
      nodeId: widget.args.nodeId,
    );
    _startPairingFlow();
  }

  Future<void> _startPairingFlow() async {
    setState(() => _state = _kStateLoading);

    // First check status to get the fingerprint
    PairingStatus? status;
    try {
      status = await _pairingService.checkPairingStatus();
    } on Exception catch (e) {
      // Check if there's a pending cert fingerprint
      final pendingFingerprint =
          widget.args.cryptoClient.checkPendingCertFingerprint();
      if (pendingFingerprint != null) {
        // Show cert approval dialog
        if (!mounted) return;
        final approved = await _showCertApprovalDialog(pendingFingerprint);
        if (!mounted) return;
        if (approved) {
          await widget.args.cryptoClient.approveCert(pendingFingerprint);
          // Retry status check
          if (!mounted) return;
          status = await _pairingService.checkPairingStatus();
        } else {
          widget.args.cryptoClient.rejectCert();
          setState(() {
            _state = _kStateError;
            _errorMessage = 'Certificate not approved. Pairing requires TLS verification.';
          });
          return;
        }
      } else {
        debugPrint('[PairingScreen] Status check error: $e');
        if (!mounted) return;
        setState(() {
          _state = _kStateError;
          _errorMessage = 'Failed to connect to server: $e';
        });
        return;
      }
    }

    if (!mounted) return;

    if (!status.needsPairing) {
      // Already paired — just go back
      Navigator.of(context).pop(true);
      return;
    }

    // Store fingerprint if provided
    _serverFingerprint = status.serverFingerprint;

    // Initiate pairing to get passcode
    try {
      final result = await _pairingService.startPairing();
      if (!mounted) return;

      _passcode = result['passcode'] as String;
      _serverPubKeyBytes = base64Decode(result['serverPubKey'] as String);
      setState(() => _state = _kStateShowPasscode);
    } catch (e) {
      debugPrint('[PairingScreen] Start pairing error: $e');
      if (!mounted) return;
      setState(() {
        _state = _kStateError;
        _errorMessage = 'Failed to start pairing: $e';
      });
    }
  }

  Future<bool> _showCertApprovalDialog(String fingerprint) async {
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CertApprovalDialog(fingerprint: fingerprint),
    );
    return approved ?? false;
  }

  Future<void> _confirmPairing() async {
    if (_passcode == null || _serverPubKeyBytes == null) return;

    setState(() => _state = _kStatePairing);

    try {
      final result = await _pairingService.confirmPairing(
        passcode: _passcode!,
        serverPubKeyBytes: _serverPubKeyBytes!,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _state = _kStateSuccess);
        // Give a moment to show success, then pop
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _state = _kStateError;
          _errorMessage = result.error ?? 'Pairing failed';
        });
      }
    } catch (e) {
      debugPrint('[PairingScreen] Confirm pairing error: $e');
      if (!mounted) return;
      setState(() {
        _state = _kStateError;
        _errorMessage = 'Pairing failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair with Server'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _kStateLoading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to server...'),
            ],
          ),
        );

      case _kStateShowPasscode:
        return _buildPasscodeView();

      case _kStatePairing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Completing pairing...'),
              SizedBox(height: 8),
              Text(
                'Keep this screen open.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );

      case _kStateError:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Pairing Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _startPairingFlow,
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );

      case _kStateSuccess:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text('Pairing Complete!'),
              SizedBox(height: 8),
              Text(
                'Secure connection established.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );

      default:
        return const Center(child: Text('Unknown state'));
    }
  }

  Widget _buildPasscodeView() {
    final theme = Theme.of(context);
    final passcode = _passcode ?? '------';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(Icons.lock_outline, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Verify Server',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Compare the code below with your server screen,\nthen tap Confirm to pair.',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Passcode display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'SERVER PASSCODE',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                // Display passcode with spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: passcode.split('').map((char) {
                    return Container(
                      width: 40,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Certificate fingerprint
          if (_serverFingerprint != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'TLS Certificate Fingerprint',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _serverFingerprint!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verify this matches your server\'s displayed fingerprint.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],

          // Confirm button
          FilledButton.icon(
            onPressed: _confirmPairing,
            icon: const Icon(Icons.check),
            label: const Text('Confirm & Pair'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown when the server presents an untrusted certificate.
///
/// AC8: If self-signed cert not approved, phone shows cert fingerprint dialog.
class _CertApprovalDialog extends StatelessWidget {
  final String fingerprint;

  const _CertApprovalDialog({required this.fingerprint});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.security, color: Colors.amber, size: 48),
      title: const Text('Certificate Not Trusted'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The server\'s TLS certificate could not be verified. '
            'This may happen with self-signed certificates.',
          ),
          const SizedBox(height: 16),
          const Text(
            'SHA-256 Fingerprint:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fingerprint,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'If you trust this certificate, approve it below. '
            'You may be asked to approve again after app restart.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Reject'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Approve Once'),
        ),
      ],
    );
  }
}
