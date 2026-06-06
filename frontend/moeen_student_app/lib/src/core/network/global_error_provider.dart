import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalDeviceError {
  final String message;

  const GlobalDeviceError({
    required this.message,
  });
}

final globalDeviceErrorProvider = StateProvider<GlobalDeviceError?>((ref) => null);
