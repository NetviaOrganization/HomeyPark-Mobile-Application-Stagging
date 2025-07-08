import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:homeypark_mobile_application/services/email_verification_service.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String userName;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.userName,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isCodeSent = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  void _sendVerificationCode() async {
    final emailService = context.read<EmailVerificationService>();
    final success = await emailService.sendVerificationEmail(widget.email, widget.userName);
    
    if (success) {
      setState(() {
        _isCodeSent = true;
      });
      _focusNodes[0].requestFocus();
    }
  }

  void _verifyCode() async {
    if (_verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el código completo')),
      );
      return;
    }

    final emailService = context.read<EmailVerificationService>();
    final success = await emailService.verifyCode(widget.email, _verificationCode);
    
    if (success && mounted) {
      Navigator.of(context).pop(true); // Retorna true si la verificación fue exitosa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Email verificado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailVerificationService>(
      builder: (context, emailService, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Verificar Email'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isCodeSent) ...[
                  Text(
                    'Enviaremos un código de verificación a:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.email,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Ingresa el código de 6 dígitos enviado a:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 40,
                        height: 50,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onCodeChanged(value, index),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 16),
                if (emailService.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            emailService.errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (emailService.successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            emailService.successMessage!,
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: emailService.isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            if (!_isCodeSent)
              ElevatedButton(
                onPressed: emailService.isLoading ? null : _sendVerificationCode,
                child: emailService.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar Código'),
              )
            else ...[
              TextButton(
                onPressed: emailService.isLoading ? null : () {
                  setState(() {
                    _isCodeSent = false;
                    for (var controller in _controllers) {
                      controller.clear();
                    }
                  });
                  emailService.clearSuccessMessage();
                  emailService.clearErrorMessage();
                },
                child: const Text('Reenviar'),
              ),
              ElevatedButton(
                onPressed: emailService.isLoading ? null : _verifyCode,
                child: emailService.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verificar'),
              ),
            ],
          ],
        );
      },
    );
  }
}
