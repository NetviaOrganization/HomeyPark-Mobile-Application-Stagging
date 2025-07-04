import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/widgets/places_autocomplete_dialog.dart';

import '../services/places_service.dart';

class ParkingFormScreen extends StatefulWidget {
  final Parking? parking; // null para agregar, Parking para editar

  const ParkingFormScreen({super.key, this.parking});

  @override
  State<ParkingFormScreen> createState() => _ParkingFormScreenState();
}

class _ParkingFormScreenState extends State<ParkingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Controllers
  final _widthController = TextEditingController();
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _spaceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _numDirectionController = TextEditingController();
  final _streetController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();

  double? _latitude;
  double? _longitude;

  bool get isEditing => widget.parking != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadParkingData();
    }
  }

  void _loadParkingData() {
    final parking = widget.parking!;
    _widthController.text = parking.width.toString();
    _lengthController.text = parking.length.toString();
    _heightController.text = parking.height.toString();
    _priceController.text = parking.price.toString();
    _phoneController.text = parking.phone;
    _spaceController.text = parking.space.toString();
    _descriptionController.text = parking.description;
    _addressController.text = parking.location.address;
    _numDirectionController.text = parking.location.numDirection;
    _streetController.text = parking.location.street;
    _districtController.text = parking.location.district;
    _cityController.text = parking.location.city;
    _latitude = parking.location.latitude;
    _longitude = parking.location.longitude;
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<PlaceDetails>(
      context: context,
      builder: (context) => PlacesAutocompleteDialog(
        onPlaceSelected: (place) {
          Navigator.of(context).pop(place);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result.address ?? '';
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _savePark() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ubicación')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final profileId = await preferences.getUserId();

      if (isEditing) {
        // Editar estacionamiento existente
        final updateData = {
          'width': double.parse(_widthController.text),
          'length': double.parse(_lengthController.text),
          'height': double.parse(_heightController.text),
          'price': double.parse(_priceController.text),
          'phone': _phoneController.text,
          'space': int.parse(_spaceController.text),
          'description': _descriptionController.text,
          'address': _addressController.text,
          'numDirection': _numDirectionController.text,
          'street': _streetController.text,
          'district': _districtController.text,
          'city': _cityController.text,
          'latitude': _latitude,
          'longitude': _longitude,
        };

        await ParkingService.updateParking(widget.parking!.id, updateData);
      } else {
        // Crear nuevo estacionamiento
        await ParkingService.createParking(
          profileId: profileId,
          width: double.parse(_widthController.text),
          length: double.parse(_lengthController.text),
          height: double.parse(_heightController.text),
          price: double.parse(_priceController.text),
          phone: _phoneController.text,
          space: int.parse(_spaceController.text),
          description: _descriptionController.text,
          address: _addressController.text,
          numDirection: _numDirectionController.text,
          street: _streetController.text,
          district: _districtController.text,
          city: _cityController.text,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      Navigator.pop(context, true); // Retorna true para indicar éxito
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Estacionamiento' : 'Agregar Estacionamiento',
          style: theme.textTheme.titleMedium,
        ),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dimensiones
              Text('Dimensiones', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: 'Ancho (m)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lengthController,
                      decoration: const InputDecoration(
                        labelText: 'Largo (m)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Alto (m)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Precio y espacios
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio por hora (S/)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _spaceController,
                      decoration: const InputDecoration(
                        labelText: 'Espacios disponibles',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Ubicación
              Text('Ubicación', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),

              // Botón para seleccionar ubicación
              OutlinedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.location_on),
                label: Text(_latitude != null ? 'Ubicación seleccionada' : 'Seleccionar ubicación'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 8),

              // Campos de dirección
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numDirectionController,
                      decoration: const InputDecoration(
                        labelText: 'Número',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Calle',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'Distrito',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _savePark,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Actualizar' : 'Crear Estacionamiento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _spaceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _numDirectionController.dispose();
    _streetController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}