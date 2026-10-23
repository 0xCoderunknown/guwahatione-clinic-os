import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor.dart';
import '../../providers/auth_provider.dart';

/// Top AppBar for Doctor Chamber session with doctor info, preview badge, and logout control.
class ChamberAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Doctor doctor;
  final bool isPreviewMode;
  final VoidCallback? onLogout;

  const ChamberAppBar({
    super.key,
    required this.doctor,
    required this.isPreviewMode,
    this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: Colors.teal.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doctor.titleName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPreviewMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Text(
                          'PREVIEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${doctor.specialty} • Fee: ₹${doctor.consultationFee}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isPreviewMode)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            tooltip: 'Close Preview',
            onPressed: () => Navigator.pop(context),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: MediaQuery.of(context).size.width >= 600
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.nightlife_rounded,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    label: const Text(
                      'End Shift & Exit',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    onPressed: onLogout ?? () => _confirmLogout(context),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.nightlife_rounded,
                      color: Color(0xFF475569),
                    ),
                    tooltip: 'End Shift & Exit',
                    onPressed: onLogout ?? () => _confirmLogout(context),
                  ),
          ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nightlife_rounded, color: Color(0xFF334155)),
            SizedBox(width: 8),
            Text('End Shift & Exit?'),
          ],
        ),
        content: const Text(
          'This will conclude your OPD shift for today, notify reception that consultations are closed, and log you out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('End Shift & Exit'),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
    );
  }
}
