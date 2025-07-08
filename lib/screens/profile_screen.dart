import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/services/profile_service.dart';
import 'package:homeypark_mobile_application/widgets/profile_avatar.dart';
import 'package:homeypark_mobile_application/widgets/profile_info_field.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';
import '../providers/rewards_provider.dart'; // NUEVO

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
      // NUEVO: Cargar progreso de recompensas
      _loadRewardsData();
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

  // NUEVO: Cargar datos de recompensas
  void _loadRewardsData() async {
    final currentUser = context.read<IAMService>().currentUser;
    if (currentUser?.id != null) {
      final rewardsProvider = context.read<RewardsProvider>();
      await rewardsProvider.loadRewardsProgress(currentUser!.id as int);
      await rewardsProvider.loadAvailableRewards(currentUser.id as int);
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
      currentUser!.profileId,
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

            // NUEVO: Sección de recompensas TB10
            if (!_isEditing) _buildRewardsSection(),

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

  // NUEVO: Sección de recompensas TB10
  Widget _buildRewardsSection() {
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, child) {
        if (rewardsProvider.isLoadingProgress) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final progress = rewardsProvider.rewardsProgress;
        if (progress == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Programa de Recompensas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progreso hacia recompensa
                Text(
                  'Progreso hacia tu próxima recompensa',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),

                LinearProgressIndicator(
                  value: progress.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  '${progress.completedReservations} de ${progress.reservationsRequired} reservas completadas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 16),

                // Estado de elegibilidad
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: progress.isEligibleForReward
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: progress.isEligibleForReward
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        progress.isEligibleForReward
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: progress.isEligibleForReward
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          progress.isEligibleForReward
                              ? '¡Felicidades! Tienes recompensas disponibles'
                              : 'Sigue reservando para obtener recompensas',
                          style: TextStyle(
                            color: progress.isEligibleForReward
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Mostrar cupones activos si los hay
                if (rewardsProvider.hasActiveCoupons()) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Cupones Activos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...rewardsProvider.getActiveCoupons().map((coupon) =>
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${coupon.discountPercentage.toInt()}% de descuento',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Código: ${coupon.couponCode}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Vence: ${DateFormat('dd/MM/yyyy').format(coupon.expirationDate)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}