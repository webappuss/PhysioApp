import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() => _run(AppEnvironment.production);

void mainDevelopment() => _run(AppEnvironment.development);
void mainStaging()     => _run(AppEnvironment.staging);

Future<void> _run(AppEnvironment env) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(env);
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(ProviderScope(child: _AppInit(env: env)));
}

class _AppInit extends ConsumerStatefulWidget {
  final AppEnvironment env;
  const _AppInit({required this.env});
  @override
  ConsumerState<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends ConsumerState<_AppInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) => const PhysioConnectApp();
}
