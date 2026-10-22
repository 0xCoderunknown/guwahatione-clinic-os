import 'package:flutter/material.dart';

import '../../core/engines/data_export_engine.dart';
import '../../services/booking_service.dart';
import '../../services/catalogue_service.dart';
import '../../services/consultation_service.dart';
import '../../services/patient_service.dart';
import '../../utils/platform_file_download.dart';

enum ExportType {
  revenue('Revenue & Tax Audit', 'Financial collection, payment modes (Cash/UPI/Free), and fee ledger', Icons.account_balance_wallet_outlined),
  appointments('Appointments & Queue', 'Daily token sequence, check-in times, patient details, and statuses', Icons.list_alt_rounded),
  patients('Patient Directory', 'Patient registry, phone numbers, demographics, and clinical allergies', Icons.people_outline_rounded),
  medicines('Medicine Catalogue', 'Prescription formulary, brand names, compositions, and dosages', Icons.medication_outlined),
  consultations('Clinical Consultations', 'Prescription records, diagnoses, complaints, and follow-ups', Icons.assignment_outlined);

  final String title;
  final String description;
  final IconData icon;

  const ExportType(this.title, this.description, this.icon);
}

enum ExportDateRange {
  today('Today'),
  last7Days('Last 7 Days'),
  thisMonth('This Month'),
  all('All Time');

  final String label;
  const ExportDateRange(this.label);
}

/// Dialog allowing clinic owners to export operational data to CSV for accountant tax audits or local backups.
class ClinicDataExportDialog extends StatefulWidget {
  const ClinicDataExportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ClinicDataExportDialog(),
    );
  }

  @override
  State<ClinicDataExportDialog> createState() => _ClinicDataExportDialogState();
}

class _ClinicDataExportDialogState extends State<ClinicDataExportDialog> {
  ExportType _selectedType = ExportType.revenue;
  ExportDateRange _selectedRange = ExportDateRange.today;
  bool _isExporting = false;
  String? _errorMessage;

  (DateTime?, DateTime?) _calculateDateBounds() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case ExportDateRange.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start);
      case ExportDateRange.last7Days:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        return (start, now);
      case ExportDateRange.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return (start, now);
      case ExportDateRange.all:
        return (null, null);
    }
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final bounds = _calculateDateBounds();
      final now = DateTime.now();
      final dateTag = DataExportEngine.formatIndianDate(now);
      String filename = '';
      String csvContent = '';

      switch (_selectedType) {
        case ExportType.revenue:
          final appts = await BookingService().fetchAppointmentsForExport(
            startDate: bounds.$1,
            endDate: bounds.$2,
          );
          csvContent = DataExportEngine.exportRevenueLedgerCsv(appts);
          filename = 'guwahatione_revenue_ledger_$dateTag.csv';
          break;

        case ExportType.appointments:
          final appts = await BookingService().fetchAppointmentsForExport(
            startDate: bounds.$1,
            endDate: bounds.$2,
          );
          csvContent = DataExportEngine.exportAppointmentsCsv(appts);
          filename = 'guwahatione_appointments_$dateTag.csv';
          break;

        case ExportType.patients:
          final patients = await PatientService().getAllPatientsForExport();
          csvContent = DataExportEngine.exportPatientsCsv(patients);
          filename = 'guwahatione_patients_$dateTag.csv';
          break;

        case ExportType.medicines:
          final medicines = await CatalogueService().getAllMedicinesForExport();
          csvContent = DataExportEngine.exportMedicinesCsv(medicines);
          filename = 'guwahatione_medicines_formulary_$dateTag.csv';
          break;

        case ExportType.consultations:
          final consults = await ConsultationService().getAllConsultationsForExport(
            startDate: bounds.$1,
            endDate: bounds.$2,
          );
          csvContent = DataExportEngine.exportConsultationsCsv(consults);
          filename = 'guwahatione_consultations_$dateTag.csv';
          break;
      }

      downloadPlatformFile(
        filename: filename,
        content: csvContent,
        mimeType: 'text/csv;charset=utf-8;',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Downloaded $filename successfully')),
              ],
            ),
            backgroundColor: const Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = 'Export failed: $e';
        });
      }
    }
  }

  bool get _supportsDateFilter =>
      _selectedType == ExportType.revenue ||
      _selectedType == ExportType.appointments ||
      _selectedType == ExportType.consultations;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
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
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: const Icon(
                      Icons.file_download_outlined,
                      color: Color(0xFF0F766E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Export Clinic Data (CSV)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Accountant tax audits • Offline backups • Zero third-party data leak',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Export Categories
              const Text(
                'Select Data Ledger to Export:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ExportType.values.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final type = ExportType.values[index];
                    final isSelected = type == _selectedType;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isExporting
                          ? null
                          : () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0FDFA)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0F766E)
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type.icon,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSelected
                                          ? const Color(0xFF0F766E)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : Colors.grey.shade400,
                                  width: isSelected ? 5 : 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Date Range Filter (Conditional)
              if (_supportsDateFilter) ...[
                const Text(
                  'Date Range Filter:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ExportDateRange.values.map((range) {
                    final isSelected = range == _selectedRange;
                    return ChoiceChip(
                      label: Text(range.label),
                      selected: isSelected,
                      selectedColor: const Color(0xFFCCFBF1),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569),
                      ),
                      onSelected: _isExporting
                          ? null
                          : (sel) {
                              if (sel) setState(() => _selectedRange = range);
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isExporting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isExporting ? null : _handleDownload,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(
                      _isExporting ? 'Generating CSV...' : 'Download (.csv)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
