import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homeypark_mobile_application/model/vehicle.dart';
import 'package:homeypark_mobile_application/services/vehicle_service.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart'; // Asumo que aquí está tu PrimaryButton
import 'package:homeypark_mobile_application/services/iam_service.dart';
class AddEditVehicleScreen extends StatefulWidget {
  /// El vehículo es opcional. Si es nulo, estamos en modo "Añadir".
  /// Si no es nulo, estamos en modo "Editar".
  final Vehicle? vehicle;
  
  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _licensePlateController;

  bool _isLoading = false;
  String? _errorMessage;

  /// Determinamos si estamos en modo edición basándonos en si se pasó un vehículo.
  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores con los datos del vehículo si estamos editando.
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  /// Maneja la lógica de guardar el vehículo (crear o actualizar).
  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vehicleService = context.read<VehicleService>();
    bool success = false;

    try {
      if (_isEditing) {
        success = await vehicleService.updateVehicle(
          widget.vehicle!.id,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _licensePlateController.text.trim().toUpperCase(),
        );
      } else {
        // Obtenemos el profileId del usuario actual
       success = await vehicleService.addVehicle(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _licensePlateController.text.trim().toUpperCase(),
          profileId: context.read<IAMService>().currentUser?.profileId ?? 0, // Asegúrate de que el usuario esté autenticado
        );
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehículo guardado con éxito.'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
        Navigator.of(context).pop(true); // Devuelve `true` para indicar que hubo cambios
      } else if (mounted && !success) {
        setState(() {
          _errorMessage = vehicleService.errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Vehículo' : 'Añadir Vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(labelText: 'Placa del Vehículo', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'La placa es requerida.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'La marca es requerida.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'El modelo es requerido.' : null,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Guardar Vehículo',
                isLoading: _isLoading,
                onPressed: _onSave,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ErrorMessageWidget(errorMessage: _errorMessage),
                ),
            ],
          ),
        ),
      ),
    );
  }
}