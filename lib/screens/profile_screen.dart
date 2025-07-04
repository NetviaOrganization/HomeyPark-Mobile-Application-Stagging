import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/services/profile_service.dart';
import 'package:homeypark_mobile_application/widgets/profile_avatar.dart';
import 'package:homeypark_mobile_application/widgets/profile_info_field.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileService>().clearErrorMessage();
    });
     final currentUser = context.read<IAMService>().currentUser;
    _firstNameController = TextEditingController(text: currentUser?.profile.firstName ?? '');
    _lastNameController = TextEditingController(text: currentUser?.profile.lastName ?? '');
    _selectedBirthDate = currentUser?.profile.birthDate;
    if (currentUser?.profile.birthDate != null) {
      _birthDateController = TextEditingController(
          text: DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(currentUser!.profile.birthDate));
    } else {
      _birthDateController = TextEditingController();
    }
  
  
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        final currentUser = context.read<IAMService>().currentUser;
        _firstNameController.text = currentUser?.firstName ?? '';
        _lastNameController.text = currentUser?.lastName ?? '';
        _selectedBirthDate = currentUser?.profile.birthDate;
        _birthDateController.text = currentUser?.profile.birthDate != null
            ? DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(currentUser!.profile.birthDate)
            : '';
        context.read<ProfileService>().clearErrorMessage();
      }
    });
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(picked);
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final currentUser = context.read<IAMService>().currentUser;
    if (currentUser?.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: ID de usuario no encontrado.')));
      }
      return;
    }

    final profileService = context.read<ProfileService>();
     final success = await profileService.updateProfile(
      currentUser!.profileId, // Añadimos 'profileId:'
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthDate: _selectedBirthDate,
    );

    if (mounted && success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil actualizado con éxito.'),
            backgroundColor: AppColors.primaryGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<IAMService>().currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('No se ha podido cargar el perfil del usuario.')),
      );
    }

    if (!_isEditing) {
      _firstNameController.text = currentUser.firstName;
      _lastNameController.text = currentUser.lastName;
      _birthDateController.text = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(currentUser.birthDate);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Cancelar' : 'Editar Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ProfileAvatar(
              name: currentUser.fullName,
              radius: 60,
              onEdit: _isEditing
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Función para cambiar foto no implementada.')));
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            _isEditing
                ? _buildEditForm()
                : _buildProfileInfo(currentUser),
            const SizedBox(height: 32),
            if (_isEditing)
              Consumer<ProfileService>(
                builder: (context, profileService, child) {
                  return Column(
                    children: [
                      PrimaryButton(
                        text: 'Guardar Cambios',
                        isLoading: profileService.isLoading,
                        onPressed: _saveProfileChanges,
                      ),
                      ErrorMessageWidget(errorMessage: profileService.errorMessage),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user) {
    return Column(
      children: [
        ProfileInfoField(
          icon: Icons.person_outline,
          label: 'Nombre Completo',
          value: user.fullName,
        ),
        const Divider(height: 32),
        ProfileInfoField(
          icon: Icons.calendar_month_outlined,
          label: 'Fecha de Nacimiento',
          value: DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(user.birthDate),
        ),
        ProfileInfoField(
          icon: Icons.email_outlined,
          label: 'Correo Electrónico',
          value: user.email,
        ),
      ],
    );
  }

   Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ProfileInfoField(
            isEditable: true,
            controller: _firstNameController,
            icon: Icons.person_outline,
            label: 'Nombres',
            value: '',
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'El nombre es requerido' : null,
          ),
          const SizedBox(height: 16),
          ProfileInfoField(
            isEditable: true,
            controller: _lastNameController,
            icon: Icons.person_outline,
            label: 'Apellidos',
            value: '',
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'El apellido es requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birthDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Fecha de Nacimiento',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(),
            ),
            onTap: () => _selectBirthDate(context),
            validator: (value) => (_selectedBirthDate == null) ? 'La fecha es requerida' : null,
          ),
          const Divider(height: 32),
          ProfileInfoField(
            icon: Icons.email_outlined,
            label: 'Correo Electrónico (no se puede cambiar)',
            value: context.read<IAMService>().currentUser!.email,
          ),
        ],
      ),
    );
  }
}