import 'package:flutter/material.dart';

import '../../core/engines/revenue_engine.dart';

/// Card displaying doctor-specific daily consultation volume, review count,
/// and realized revenue statistics.
class DoctorStatisticsCard extends StatelessWidget {
  final DoctorAnalyticsSummary stats;
  final VoidCallback? onTap;

  const DoctorStatisticsCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stats.doctorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹${stats.realizedRevenue}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatMetricItem(
                    label: "Total",
                    value: "${stats.totalPatients}",
                    color: Colors.black,
                  ),
                  _StatMetricItem(
                    label: "Done",
                    value: "${stats.completed}",
                    color: Colors.green,
                  ),
                  _StatMetricItem(
                    label: "Pending",
                    value: "${stats.pending}",
                    color: Colors.orange,
                  ),
                  _StatMetricItem(
                    label: "Free/Fam",
                    value: "${stats.free}",
                    color: Colors.blue,
                  ),
                ],
              ),
              if (stats.absent > 0) ...[
                const SizedBox(height: 8),
                Text(
                  "${stats.absent} patient(s) marked absent/no-show",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
