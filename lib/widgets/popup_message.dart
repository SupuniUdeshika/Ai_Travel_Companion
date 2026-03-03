import 'package:flutter/material.dart';

class PopupMessage {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    bool isSuccess = true,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSuccess ? const Color(0xFF00DFD8) : Colors.orange,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? const Color(0xFF00DFD8) : Colors.orange,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) onConfirm();
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF00DFD8)),
            ),
          ),
        ],
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    VoidCallback? onConfirm,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      isSuccess: true,
      onConfirm: onConfirm,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String title = 'Error',
    VoidCallback? onConfirm,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      isSuccess: false,
      onConfirm: onConfirm,
    );
  }

  static void showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00DFD8),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF00DFD8),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void dismiss(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
