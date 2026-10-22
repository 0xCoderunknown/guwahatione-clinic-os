import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Modal dialog allowing the Clinic Owner to update the 4-digit Receptionist PIN
/// and the 6-digit Owner Master Passkey with cloud synchronization.
class SecuritySettingsDialog extends StatefulWidget {
  const SecuritySettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SecuritySettingsDialog(),
    );
  }

  @override
  State<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
  bool _isOwnerVerified = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Verification Controller
  final _verifyPinController = TextEditingController();
  bool _obscureVerifyPin = true;

  // Step 2: New PIN Controllers
  final _receptionPinController = TextEditingController();
  final _confirmReceptionPinController = TextEditingController();
  bool _obscureReceptionPin = true;

  final _ownerPinController = TextEditingController();
  final _confirmOwnerPinController = TextEditingController();
  bool _obscureOwnerPin = true;

  @override
  void dispose() {
    _verifyPinController.dispose();
    _receptionPinController.dispose();
    _confirmReceptionPinController.dispose();
    _ownerPinController.dispose();
    _confirmOwnerPinController.dispose();
    super.dispose();
  }

  void _verifyCurrentOwner(AuthProvider auth) {
    final entered = _verifyPinController.text.trim();
    if (entered.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current Master Passkey.');
      return;
    }

    if (!auth.verifyOwnerMasterPin(entered)) {
      setState(() => _errorMessage = 'Incorrect Master Passkey. Access denied.');
      return;
    }

    setState(() {
      _isOwnerVerified = true;
      _errorMessage = null;
    });
  }

  Future<void> _savePins(AuthProvider auth) async {
    setState(() {
      _errorMessage = null;
    });

    final newRecPin = _receptionPinController.text.trim();
    final confirmRecPin = _confirmReceptionPinController.text.trim();
    final newOwnerPin = _ownerPinController.text.trim();
    final confirmOwnerPin = _confirmOwnerPinController.text.trim();

    if (newRecPin.isEmpty && newOwnerPin.isEmpty) {
      setState(() {
        _errorMessage = 'No changes entered. Enter a new Reception PIN or Master Passkey.';
      });
      return;
    }

    // Validate Reception PIN
    if (newRecPin.isNotEmpty) {
      if (newRecPin.length != 4 || int.tryParse(newRecPin) == null) {
        setState(() {
          _errorMessage = 'Receptionist PIN must be exactly 4 digits.';
        });
        return;
      }
      if (newRecPin != confirmRecPin) {
        setState(() {
          _errorMessage = 'Receptionist PIN confirmation does not match.';
        });
        return;
      }
    }

    // Validate Owner Master PIN
    if (newOwnerPin.isNotEmpty) {
      if (newOwnerPin.length != 6 || int.tryParse(newOwnerPin) == null) {
        setState(() {
          _errorMessage = 'Owner Master Passkey must be exactly 6 digits.';
        });
        return;
      }
      if (newOwnerPin != confirmOwnerPin) {
        setState(() {
          _errorMessage = 'Owner Master Passkey confirmation does not match.';
        });
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await auth.updateSecurityPins(
        newOwnerPin: newOwnerPin.isNotEmpty ? newOwnerPin : null,
        newReceptionistPin: newRecPin.isNotEmpty ? newRecPin : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F766E),
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Access PINs updated and synchronized to clinic cloud.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to sync PINs to cloud: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF16A34A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinic Security & PIN Store',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Multi-terminal cloud-synchronized access PINs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFE2E8F0)),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Body content
              if (!_isOwnerVerified)
                _buildVerificationStep(auth)
              else
                Flexible(child: _buildSettingsStep(auth)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Security Verification Required',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your current 6-digit Owner Master Passkey to access security settings and rotate clinic PINs.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _verifyPinController,
          obscureText: _obscureVerifyPin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Current Master Passkey',
            hintText: 'Enter 6 digits',
            prefixIcon: const Icon(Icons.key_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureVerifyPin ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureVerifyPin = !_obscureVerifyPin),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onSubmitted: (_) => _verifyCurrentOwner(auth),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _verifyCurrentOwner(auth),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Verify & Proceed'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsStep(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Reception Desk PIN
          _buildPinCard(
            title: 'Receptionist Access PIN (4 Digits)',
            badgeText: auth.isCustomReceptionistPinSet ? 'Custom Active' : 'Default (0000)',
            badgeColor: auth.isCustomReceptionistPinSet
                ? const Color(0xFF16A34A)
                : const Color(0xFF64748B),
            description:
                'Used by counter staff to check in walk-in patients, manage lobby queues, and collect consultation fees.',
            controller: _receptionPinController,
            confirmController: _confirmReceptionPinController,
            isObscured: _obscureReceptionPin,
            maxLength: 4,
            hintText: 'New 4-digit PIN',
            onToggleObscure: () =>
                setState(() => _obscureReceptionPin = !_obscureReceptionPin),
          ),
          const SizedBox(height: 16),

          // Section 2: Owner Master Passkey
          _buildPinCard(
            title: 'Owner Master Passkey (6 Digits)',
            badgeText: auth.isCustomOwnerPinSet ? 'Custom Active' : 'Default Passkey',
            badgeColor: auth.isCustomOwnerPinSet
                ? const Color(0xFF16A34A)
                : const Color(0xFFD97706),
            description:
                'Provides full administrative authority: doctor CRUD, fee configurations, deactivations, and security audits.',
            controller: _ownerPinController,
            confirmController: _confirmOwnerPinController,
            isObscured: _obscureOwnerPin,
            maxLength: 6,
            hintText: 'New 6-digit Passkey',
            onToggleObscure: () => setState(() => _obscureOwnerPin = !_obscureOwnerPin),
          ),
          const SizedBox(height: 14),

          // Doctor PIN note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Doctor chamber PINs are configured individually per practitioner under Doctors & Chamber PINs.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : () => _savePins(auth),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_sync_rounded, size: 18),
                label: Text(_isLoading ? 'Saving...' : 'Save & Sync to Cloud'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required TextEditingController controller,
    required TextEditingController confirmController,
    required bool isObscured,
    required int maxLength,
    required String hintText,
    required VoidCallback onToggleObscure,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isObscured,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLength),
                  ],
                  decoration: InputDecoration(
                    hintText: hintText,
                    labelText: 'New PIN',
                    isDense: true,
                    prefixIcon: const Icon(Icons.lock_outline, size: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscured ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                      ),
                      onPressed: onToggleObscure,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: confirmController,
                  obscureText: isObscured,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLength),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Confirm PIN',
                    labelText: 'Confirm',
                    isDense: true,
                    prefixIcon: const Icon(Icons.lock_reset, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
