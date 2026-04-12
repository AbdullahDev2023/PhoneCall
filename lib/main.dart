import 'package:flutter/material.dart';

import 'app/phone_call_app.dart';
import 'app/phone_controller.dart';
import 'platform/phone_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhonePlatform.initialize();

  final controller = PhoneController();
  await controller.initialize();

  runApp(PhoneCallApp(controller: controller));
}
