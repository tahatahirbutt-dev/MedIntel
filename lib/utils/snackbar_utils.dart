import 'package:flutter/material.dart';

/// Shows a floating [SnackBar] that is guaranteed to close after [duration],
/// even if the user never taps the optional action.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
            )
          : null,
    ),
  );
  // Belt-and-suspenders: force-close even if the action is never tapped.
  Future.delayed(duration, messenger.hideCurrentSnackBar);
}
