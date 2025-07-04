import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easy_recaptcha_v2/flutter_easy_recaptcha_v2.dart';

import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';
import 'package:homeypark_mobile_application/screens/sign_up_screen.dart';
import 'package:homeypark_mobile_application/widgets/auth_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _showRecaptchaBottomSheet();
  }

  void _showRecaptchaBottomSheet() {
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    final recaptchaSecretKey = dotenv.env['RECAPTCHA_SECRET_KEY'];

    if (recaptchaSiteKey == null || recaptchaSecretKey == null) {
      _onRecaptchaError("Las claves de reCAPTCHA no están configuradas.");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return SizedBox(
          height: MediaQuery.of(modalContext).size.height * 0.8,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ),
              Expanded(
                child: RecaptchaV2(
                   apiKey: recaptchaSiteKey,
                  // --- LÓGICA SIMPLIFICADA ---
                  // Ahora, simplemente obtenemos el token y se lo pasamos
                  // a nuestro servicio para que él se encargue de todo.
                  onVerifiedSuccessfully: (String token) {
                    Navigator.pop(modalContext); // Cierra el modal
                    _signInWithToken(token); // Llama a la lógica de inicio de sesión
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSignUp() {
    Provider.of<IAMService>(context, listen: false).clearErrorMessage();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  Future<void> _signInWithToken(String token) async {
    final signInData = SignInData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      recaptchaToken: token, // Pasamos el token, aunque el servicio ya no lo use para verificar.
    );
    final iamService = Provider.of<IAMService>(context, listen: false);
    await iamService.signIn(signInData);
  }

  void _onRecaptchaError(String? error) {
    debugPrint('reCAPTCHA Error: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Error de verificación.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildForm(),
              const SizedBox(height: 24),
              AuthLinkText(
                text: '¿No tienes una cuenta? ',
                linkText: 'Regístrate',
                onTap: _navigateToSignUp,
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
        Image.asset('assets/images/logo.png', height: 100),
        const SizedBox(height: 24),
        const Text('Bienvenido de vuelta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkText), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Inicia sesión para continuar en HomeyPark', style: TextStyle(fontSize: 16, color: AppColors.subtleText), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFormField(controller: _emailController, labelText: 'Email', iconData: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) { if (value == null || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) { return 'Por favor ingresa un email válido'; } return null; }),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _passwordController, labelText: 'Contraseña', iconData: Icons.lock_outline, isPassword: true, obscureText: _obscurePassword, toggleObscureText: () => setState(() => _obscurePassword = !_obscurePassword), validator: (value) { if (value == null || value.isEmpty) { return 'Por favor ingresa tu contraseña'; } return null; }),
          const SizedBox(height: 24),
          Consumer<IAMService>(builder: (context, iamService, child) {
            return Column(
              children: [
                PrimaryButton(text: 'Iniciar Sesión', isLoading: iamService.isLoading, onPressed: _handleSignIn),
                ErrorMessageWidget(errorMessage: iamService.errorMessage),
              ],
            );
          }),
        ],
      ),
    );
  }
}