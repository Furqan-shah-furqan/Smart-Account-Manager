import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'login_page.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const SmartAccountManagerApp());
}

class SmartAccountManagerApp extends StatefulWidget {
  const SmartAccountManagerApp({super.key});

  @override
  State<SmartAccountManagerApp> createState() => _SmartAccountManagerAppState();
}

class _SmartAccountManagerAppState extends State<SmartAccountManagerApp> {
  final SupabaseService service = SupabaseService();
  late final AppState appState = AppState(service: service);

  bool loading = true;

  @override
  void initState() {
    super.initState();
    prepare();
  }

  Future<void> prepare() async {
    if (service.currentUser != null) {
      await appState.loadAll();
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> refresh() async {
    await appState.loadAll();
    if (mounted) setState(() {});
  }

  Future<void> logout() async {
    await service.signOut();
    appState.clearLocal();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Account Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: loading
          ? const LoadingScreen()
          : service.currentUser == null
              ? LoginPage(service: service, onLoggedIn: refresh)
              : AppShell(
                  state: appState,
                  onChanged: refresh,
                  onLogout: logout,
                ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
