import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/clinic_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../utils/formatters.dart';
import 'screens.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  int _selectedSegment = 0; // 0: Active, 1: Inactive

  Future<void> _promptPasskeyAndToggleActive(
    BuildContext context,
    Doctor doctor,
  ) async {
    final isDeactivating = doctor.isActive;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => _DoctorPasskeyDialog(
        doctor: doctor,
        isDeactivating: isDeactivating,
        authProvider: authProvider,
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await clinicProvider.setDoctorActiveStatus(
          doctor.id,
          !isDeactivating,
          requestingRole: authProvider.currentRole,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDeactivating
                    ? '${doctor.titleName} has been deactivated.'
                    : '${doctor.titleName} has been reactivated.',
              ),
              backgroundColor: isDeactivating ? Colors.red.shade800 : Colors.teal,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final canPop = Navigator.canPop(context);
    final showAppBar = !isDesktop || canPop;
    final isOwner = Provider.of<AuthProvider>(context).isOwner;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                isOwner
                    ? 'Doctors & Chamber PINs'
                    : 'Doctor Rosters & Schedules',
              ),
            )
          : null,
      body: Selector<
        ClinicProvider,
        ({List<Doctor> active, List<Doctor> inactive})
      >(
        selector: (_, clinic) => (
          active: clinic.doctors,
          inactive: clinic.inactiveDoctors,
        ),
        builder: (context, data, child) {
          final activeDoctors = data.active;
          final inactiveDoctors = data.inactive;

          final displayedDoctors = !isOwner
              ? activeDoctors
              : (_selectedSegment == 0 ? activeDoctors : inactiveDoctors);

          return Column(
            children: [
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      ChoiceChip(
                        key: const Key('segment_active_doctors'),
                        selected: _selectedSegment == 0,
                        label: Text('Active Doctors (${activeDoctors.length})'),
                        selectedColor: Colors.teal.shade50,
                        labelStyle: TextStyle(
                          color: _selectedSegment == 0
                              ? Colors.teal.shade900
                              : Colors.grey.shade700,
                          fontWeight: _selectedSegment == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedSegment = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        key: const Key('segment_inactive_doctors'),
                        selected: _selectedSegment == 1,
                        label: Text(
                          'Inactive / Retired (${inactiveDoctors.length})',
                        ),
                        selectedColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: _selectedSegment == 1
                              ? Colors.grey.shade900
                              : Colors.grey.shade700,
                          fontWeight: _selectedSegment == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedSegment = 1),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: displayedDoctors.isEmpty
                    ? Center(
                        child: Text(
                          _selectedSegment == 1
                              ? 'No inactive doctors. All registered physicians are currently active.'
                              : 'No active doctors added yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: displayedDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = displayedDoctors[index];
                          return DoctorRosterCard(
                            doctor: doctor,
                            isOwner: isOwner,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddDoctorScreen(doctor: doctor),
                                ),
                              );
                            },
                            onChamberView: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorChamberScreen(
                                    doctor: doctor,
                                    isPreviewMode: true,
                                  ),
                                ),
                              );
                            },
                            onToggleActive: () =>
                                _promptPasskeyAndToggleActive(context, doctor),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              backgroundColor: Colors.teal,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Doctor',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

/// Card displaying doctor profile details, specialty, fee, available schedule,
/// chamber PIN badge (for owner), and navigation action triggers.
class DoctorRosterCard extends StatelessWidget {
  final Doctor doctor;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onChamberView;
  final VoidCallback? onToggleActive;

  const DoctorRosterCard({
    super.key,
    required this.doctor,
    required this.isOwner,
    this.onEdit,
    this.onChamberView,
    this.onToggleActive,
  });

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(icon, size: 12, color: iconColor),
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isActive = doctor.isActive;

    final actionButtons = Wrap(
      alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (isOwner && isActive)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              side: const BorderSide(color: Colors.teal),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
        if (isActive)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              side: const BorderSide(color: Colors.teal),
            ),
            onPressed: onChamberView,
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Chamber View'),
          ),
        if (isOwner)
          isActive
              ? OutlinedButton.icon(
                  key: Key('deactivate_btn_${doctor.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: onToggleActive,
                  icon: const Icon(Icons.pause_circle_outline, size: 16),
                  label: const Text('Deactivate'),
                )
              : ElevatedButton.icon(
                  key: Key('reactivate_btn_${doctor.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onToggleActive,
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('Reactivate Doctor'),
                ),
      ],
    );

    final doctorInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppFormatters.doctorTitle(doctor.name),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isActive ? null : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${AppFormatters.specialty(doctor.specialty)} • Fee: ₹${doctor.consultationFee}',
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.grey.shade700 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (!isActive)
              _buildBadge(
                icon: Icons.pause_circle_outline,
                label: 'INACTIVE',
                iconColor: const Color(0xFF64748B),
                textColor: const Color(0xFF475569),
                bgColor: const Color(0xFFE2E8F0),
                borderColor: const Color(0xFFCBD5E1),
                fontWeight: FontWeight.bold,
              ),
            if (isOwner && isActive)
              _buildBadge(
                icon: Icons.key,
                label: 'Chamber PIN: ${doctor.pin}',
                iconColor: Colors.amber,
                textColor: Colors.amber.shade900,
                bgColor: Colors.amber.shade50,
                borderColor: Colors.amber.shade300,
                fontWeight: FontWeight.bold,
              ),
            if (doctor.medicalRegNumber != null &&
                doctor.medicalRegNumber!.isNotEmpty)
              _buildBadge(
                icon: Icons.verified_user_outlined,
                label: 'Registration No. ${doctor.medicalRegNumber}',
                iconColor: isActive ? Colors.teal.shade700 : const Color(0xFF64748B),
                textColor: isActive ? Colors.teal.shade900 : const Color(0xFF475569),
                bgColor: isActive ? Colors.teal.shade50 : const Color(0xFFF1F5F9),
                borderColor: isActive ? Colors.teal.shade200 : const Color(0xFFCBD5E1),
              ),
            _buildBadge(
              icon: Icons.event_repeat,
              label: doctor.freeReviewDays > 0
                  ? 'Review: ${doctor.freeReviewDays}d'
                  : 'No Free Review',
              iconColor: !isActive
                  ? const Color(0xFF64748B)
                  : (doctor.freeReviewDays > 0
                      ? Colors.blue.shade700
                      : Colors.orange.shade700),
              textColor: !isActive
                  ? const Color(0xFF475569)
                  : (doctor.freeReviewDays > 0
                      ? Colors.blue.shade900
                      : Colors.orange.shade900),
              bgColor: !isActive
                  ? const Color(0xFFF1F5F9)
                  : (doctor.freeReviewDays > 0
                      ? Colors.blue.shade50
                      : Colors.orange.shade50),
              borderColor: !isActive
                  ? const Color(0xFFCBD5E1)
                  : (doctor.freeReviewDays > 0
                      ? Colors.blue.shade200
                      : Colors.orange.shade200),
            ),
            Text(
              doctor.availableDays.join(', '),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isActive ? Colors.white : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.grey.shade200 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isActive
                            ? Colors.teal.shade50
                            : const Color(0xFFE2E8F0),
                        child: Text(
                          AppFormatters.doctorInitials(doctor.name),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isActive
                                ? Colors.teal.shade800
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: doctorInfo),
                    ],
                  ),
                  const SizedBox(height: 12),
                  actionButtons,
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isActive
                        ? Colors.teal.shade50
                        : const Color(0xFFE2E8F0),
                    child: Text(
                      AppFormatters.doctorInitials(doctor.name),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isActive
                            ? Colors.teal.shade800
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: doctorInfo),
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              ),
      ),
    );
  }
}

class _DoctorPasskeyDialog extends StatefulWidget {
  final Doctor doctor;
  final bool isDeactivating;
  final AuthProvider authProvider;

  const _DoctorPasskeyDialog({
    required this.doctor,
    required this.isDeactivating,
    required this.authProvider,
  });

  @override
  State<_DoctorPasskeyDialog> createState() => _DoctorPasskeyDialogState();
}

class _DoctorPasskeyDialogState extends State<_DoctorPasskeyDialog> {
  late final TextEditingController _pinController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    final enteredPin = _pinController.text.trim();
    final isValid = widget.authProvider.verifyOwnerMasterPin(enteredPin);
    if (isValid) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorText = 'Incorrect Owner Master Passkey';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeactivating = widget.isDeactivating;
    final doctor = widget.doctor;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isDeactivating
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: isDeactivating ? Colors.red.shade700 : Colors.teal,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDeactivating ? 'Deactivate Doctor' : 'Reactivate Doctor',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeactivating
                  ? 'Deactivating ${doctor.titleName} will remove them from the walk-in booking desk, live queue rosters, and chamber login.\n\nAll past consultations, prescriptions, and financial audit records will remain permanently intact.'
                  : 'Reactivating ${doctor.titleName} will restore them to active OPD booking, queue rosters, and chamber login.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Enter 6-digit Owner Master Passkey to authorize:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('admin_passkey_input'),
              controller: _pinController,
              obscureText: true,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: ClinicConfig.current.features.isTestingModeActive
                    ? '000000'
                    : '••••••',
                helperText: ClinicConfig.current.features.isTestingModeActive
                    ? '🧪 Testing Mode: Enter 000000'
                    : null,
                counterText: '',
                errorText: _errorText,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('confirm_passkey_action_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDeactivating
                ? Colors.red.shade700
                : Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(isDeactivating ? 'Deactivate' : 'Reactivate'),
        ),
      ],
    );
  }
}
