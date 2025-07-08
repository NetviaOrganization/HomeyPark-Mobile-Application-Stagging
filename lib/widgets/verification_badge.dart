import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  final bool showText;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 24.0,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadgeIcon(),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verificado' : 'No verificado',
            style: TextStyle(
              fontSize: 12,
              color: isVerified ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    return _buildBadgeIcon();
  }

  Widget _buildBadgeIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isVerified ? Colors.green : Colors.orange,
        boxShadow: [
          BoxShadow(
            color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isVerified ? Icons.verified : Icons.warning,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

/// Widget más completo para mostrar el estado de verificación con tooltip
class VerificationBadgeWithTooltip extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadgeWithTooltip({
    super.key,
    required this.isVerified,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isVerified 
        ? 'Usuario verificado - Email confirmado' 
        : 'Usuario no verificado - Email pendiente de confirmación',
      child: VerificationBadge(
        isVerified: isVerified,
        size: size,
      ),
    );
  }
}

/// Widget para mostrar en cards o listas
class VerificationBadgeInline extends StatelessWidget {
  final bool isVerified;
  final String userName;

  const VerificationBadgeInline({
    super.key,
    required this.isVerified,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        VerificationBadgeWithTooltip(
          isVerified: isVerified,
          size: 20,
        ),
      ],
    );
  }
}
