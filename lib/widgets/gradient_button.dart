import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final bool isSecondary;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 20, // Increased default border radius
    this.isSecondary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientColors = isSecondary
        ? [Colors.transparent, Colors.transparent]
        : onPressed != null
        ? [Color(0xFF007CF0), Color(0xFF00DFD8)]
        : [Colors.grey, Colors.grey];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed != null && !isSecondary
            ? [
                BoxShadow(
                  color: Color(0xFF007CF0).withOpacity(0.4), // Enhanced shadow
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
        border: isSecondary
            ? Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2.0,
              ) // Thicker border
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 20), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}
