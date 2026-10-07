import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor.dart';
import '../../providers/auth_provider.dart';

/// Top AppBar for Doctor Chamber session with doctor info, preview badge, and logout control.
class ChamberAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Doctor doctor;
  final bool isPreviewMode;

  const ChamberAppBar({
    super.key,
    required this.doctor,
    required this.isPreviewMode,
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
            child: Icon(Icons.local_hospital_rounded, color: Colors.teal.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPreviewMode ? Colors.purple.shade50 : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPreviewMode ? Colors.purple.shade200 : Colors.teal.shade200,
                        ),
                      ),
                      child: Text(
                        isPreviewMode ? 'OWNER PREVIEW' : 'CHAMBER CATALOG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isPreviewMode ? Colors.purple.shade700 : Colors.teal.shade700,
                        ),
                      ),
                    ),
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout of Chamber',
            onPressed: () => _confirmLogout(context),
          ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Chamber?'),
        content: const Text('Do you want to log out of this doctor chamber session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
