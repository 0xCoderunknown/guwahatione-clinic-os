import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../widgets/widgets.dart';

/// Screen coordinator for adding or editing a doctor's credentials and schedule.
class AddDoctorScreen extends StatelessWidget {
  final Doctor? doctor;

  const AddDoctorScreen({super.key, this.doctor});

  @override
  Widget build(BuildContext context) {
    final isEditing = doctor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Doctor' : 'Add Doctor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DoctorForm(
          doctor: doctor,
          onSaved: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
