import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/screens/parking_form_screen.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/widgets/garage_card.dart';

class MyGaragesScreen extends StatefulWidget {
  const MyGaragesScreen({super.key});

  @override
  State<MyGaragesScreen> createState() => _MyGaragesScreenState();
}

class _MyGaragesScreenState extends State<MyGaragesScreen> {
  bool _loading = true;
  List<Parking> _parkings = [];

  @override
  void initState() {
    super.initState();
    _loadParkings();
  }

  Future<void> _loadParkings() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = await preferences.getUserId();
      final parkings = await ParkingService.getParkingListByUserId(userId);
      
      setState(() {
        _parkings = parkings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estacionamientos: $e')),
      );
    }
  }

  Future<void> _navigateToAddParking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ParkingFormScreen(),
      ),
    );

    if (result == true) {
      _loadParkings(); // Recargar la lista
    }
  }

  Future<void> _navigateToEditParking(Parking parking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingFormScreen(parking: parking),
      ),
    );

    if (result == true) {
      _loadParkings(); // Recargar la lista
    }
  }

  Future<void> _deleteParking(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este estacionamiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ParkingService.deleteParking(id);
        _loadParkings(); // Recargar la lista
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estacionamiento eliminado exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Estacionamientos',
          style: theme.textTheme.titleMedium,
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _navigateToAddParking,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _parkings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.garage_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes estacionamientos registrados',
                        style: theme.textTheme.titleMedium?.apply(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer estacionamiento para empezar a recibir reservas',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.apply(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _navigateToAddParking,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Estacionamiento'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _parkings.length,
                  itemBuilder: (context, index) {
                    final parking = _parkings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GarageCard(
                        id: parking.id,
                        parking: parking,
                        onEdit: (id) {
                          _navigateToEditParking(parking);
                        },
                        onDelete: _deleteParking,
                      ),
                    );
                  },
                ),
      floatingActionButton: _parkings.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddParking,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}