// lib/widgets/profile_info_field.dart

import 'package:flutter/material.dart';

class ProfileInfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditable;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const ProfileInfoField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isEditable = false,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Si estamos en modo edición, usamos el controller.
    if (isEditable && controller != null) {
      controller!.text = value;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: isEditable
          ? TextFormField(
              controller: controller,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ListTile(
              leading: Icon(icon, color: Theme.of(context).primaryColor),
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ),
    );
  }
}