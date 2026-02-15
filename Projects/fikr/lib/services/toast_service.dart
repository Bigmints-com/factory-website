import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  static void showSuccess(
    BuildContext context, {
    required String title,
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: description != null ? Text(description) : null,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      icon: const FaIcon(FontAwesomeIcons.circleCheck),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: description != null ? Text(description) : null,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      icon: const FaIcon(FontAwesomeIcons.circleExclamation),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: description != null ? Text(description) : null,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      icon: const FaIcon(FontAwesomeIcons.circleInfo),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
    );
  }
}
