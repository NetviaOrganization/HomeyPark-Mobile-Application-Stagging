import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homeypark_mobile_application/services/vehicle_service.dart';
import 'package:homeypark_mobile_application/widgets/vehicle_card.dart';
import 'package:homeypark_mobile_application/screens/add_edit_vehicle_screen.dart';
import 'package:homeypark_mobile_application/model/vehicle.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleService>().fetchMyVehicles();
    });
  }

  void _onEditVehicle(Vehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(vehicle: vehicle),
      ),
    ).then((didChange) {
      if (didChange == true) {
        final userId = context.read<IAMService>().currentUser?.id;
        if (userId != null) {
          context.read<VehicleService>().fetchMyVehicles();
        }
      }
    });
  }

  void _onDeleteVehicle(int vehicleId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este vehículo?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await context.read<VehicleService>().deleteVehicle(vehicleId);
                if (mounted && !success) {
                  final errorMessage = context.read<VehicleService>().errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage ?? 'Error al eliminar el vehículo.')),
                  );
                } else if (mounted && success) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehículo eliminado con éxito.'), backgroundColor: Colors.green),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onAddVehicle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditVehicleScreen(),
      ),
    ).then((didChange) {
      if (didChange == true) {
        final userId = context.read<IAMService>().currentUser?.id;
        if (userId != null) {
          context.read<VehicleService>().fetchMyVehicles();
        }
      }
    });
  }
  
  Future<void> _refreshVehicles() async {
    // La recarga también es más simple
    await context.read<VehicleService>().fetchMyVehicles();
  }
  @override
  Widget build(BuildContext context) {
    final vehicleService = context.watch<VehicleService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
      ),
      body: _buildBody(vehicleService),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddVehicle,
        tooltip: 'Añadir Vehículo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(VehicleService vehicleService) {
    if (vehicleService.isLoading && vehicleService.vehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicleService.errorMessage != null && vehicleService.vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error: ${vehicleService.errorMessage}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (vehicleService.vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No tienes vehículos registrados.\n¡Añade tu primer vehículo para empezar!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _onAddVehicle,
                icon: const Icon(Icons.add),
                label: const Text('Añadir Vehículo'),
              )
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        final userId = context.read<IAMService>().currentUser?.id;
        if (userId != null) {
          return context.read<VehicleService>().fetchMyVehicles();
        }
        return Future.value();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: vehicleService.vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicleService.vehicles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: VehicleCard(
              vehicle: vehicle,
              onEdit: () => _onEditVehicle(vehicle),
              onDelete: () => _onDeleteVehicle(vehicle.id),
            ),
          );
        },
      ),
    );
  }
}