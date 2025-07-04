// lib/widgets/vehicle_card.dart

import 'package:flutter/material.dart';
import '../model/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  // --- CAMBIO: Los callbacks ahora son de tipo VoidCallback ---
  // No necesitan recibir ningún argumento.
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleCard({
    Key? key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Placa: ${vehicle.licensePlate}",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${vehicle.brand} ${vehicle.model}",
              style: theme.textTheme.bodyMedium?.apply(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  // --- CAMBIO: onPressed ahora llama directamente a `onDelete` ---
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Borrar"),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  // --- CAMBIO: onPressed ahora llama directamente a `onEdit` ---
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Editar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}