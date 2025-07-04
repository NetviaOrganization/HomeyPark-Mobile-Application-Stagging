import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:flutter_easy_recaptcha_v2/flutter_easy_recaptcha_v2.dart';
import 'package:intl/intl.dart';

import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthDateController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  DateTime? _selectedBirthDate; // Para guardar la fecha seleccionada

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _birthDateController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        // Formateamos la fecha para mostrarla en el TextField
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _showRecaptchaBottomSheet();
  }

  void _showRecaptchaBottomSheet() {
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    if (recaptchaSiteKey == null) {
      _onRecaptchaError("La clave del sitio reCAPTCHA no está configurada.");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: RecaptchaV2(
                  apiKey: recaptchaSiteKey,
                  onVerifiedSuccessfully: (String token) {
                    Navigator.pop(context); 
                    _signUpWithToken(token); 
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signUpWithToken(String token) async {
    final signUpData = SignUpData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthDate: _selectedBirthDate!, // El validador asegura que no es nulo
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      recaptchaToken: token,
    );

    final iamService = Provider.of<IAMService>(context, listen: false);
    final success = await iamService.signUp(signUpData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente! Por favor, inicia sesión.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _onRecaptchaError(String? error) {
    debugPrint('reCAPTCHA Error: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Error de verificación. Por favor, intenta de nuevo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkText,
        title: const Text('Crear Cuenta', style: TextStyle(color: AppColors.darkText)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildForm(),
              const SizedBox(height: 24),
              AuthLinkText(
                text: '¿Ya tienes una cuenta? ',
                linkText: 'Inicia Sesión',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 80),
        const SizedBox(height: 16),
        const Text('Únete a la comunidad', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkText), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Crea tu cuenta para comenzar', style: TextStyle(fontSize: 16, color: AppColors.subtleText), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildForm() {
  return Form(
    key: _formKey,
    child: Column(
      children: [
        // --- NUEVOS CAMPOS DEL FORMULARIO ---
        CustomTextFormField(
          controller: _firstNameController,
          labelText: 'Nombres',
          iconData: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, ingresa tus nombres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: _lastNameController,
          labelText: 'Apellidos',
          iconData: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, ingresa tus apellidos';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _birthDateController,
          readOnly: true, // El campo no se puede escribir, solo se actualiza con el selector.
          decoration: InputDecoration(
            labelText: 'Fecha de Nacimiento',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onTap: () => _selectBirthDate(context),
          validator: (value) {
            if (_selectedBirthDate == null) {
              return 'Por favor, selecciona tu fecha de nacimiento';
            }
            // Podrías añadir una validación de edad mínima si quisieras
            // final age = DateTime.now().difference(_selectedBirthDate!).inDays / 365;
            // if (age < 18) {
            //   return 'Debes ser mayor de 18 años';
            // }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // --- FIN DE NUEVOS CAMPOS ---
        
        CustomTextFormField(
          controller: _emailController,
          labelText: 'Email',
          iconData: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => (value != null && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
              ? null
              : 'Por favor ingresa un email válido',
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: _passwordController,
          labelText: 'Contraseña',
          iconData: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          toggleObscureText: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Por favor ingresa una contraseña';
            if (value.length < 8) return 'Debe tener al menos 8 caracteres';
            if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Debe contener al menos una mayúscula';
            if (!RegExp(r'[a-z]').hasMatch(value)) return 'Debe contener al menos una minúscula';
            if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe contener al menos un número';
            if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Debe contener un carácter especial';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: _confirmPasswordController,
          labelText: 'Confirmar Contraseña',
          iconData: Icons.lock_person_outlined,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          toggleObscureText: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Por favor, confirma tu contraseña';
            if (value != _passwordController.text) return 'Las contraseñas no coinciden';
            return null;
          },
        ),
        const SizedBox(height: 32),
        Consumer<IAMService>(
          builder: (context, iamService, child) {
            return Column(
              children: [
                PrimaryButton(
                  text: 'Crear Cuenta',
                  isLoading: iamService.isLoading,
                  onPressed: _handleSignUp,
                ),
                ErrorMessageWidget(errorMessage: iamService.errorMessage),
              ],
            );
          },
        ),
      ],
    ),
  );
}
}