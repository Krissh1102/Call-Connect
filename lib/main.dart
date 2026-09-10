import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/call/call_bloc.dart';
import 'blocs/contacts/contacts_bloc.dart';
import 'blocs/history/history_bloc.dart';
import 'core/app_keys.dart';
import 'core/call_flow_listener.dart';
import 'core/connectivity_banner.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/calling_service.dart';
import 'services/local_storage_service.dart';
import 'services/user_service.dart';

void main() {
  runApp(const ConnectCallApp());
}

class ConnectCallApp extends StatelessWidget {
  const ConnectCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ---- Services (singletons for the app's lifetime) ----
    final storage = LocalStorageService();
    final authService = AuthService(storage);
    final userService = UserService(storage);
    final callingService = CallingService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authService)),
        BlocProvider(create: (_) => ContactsBloc(userService)),
        BlocProvider(create: (_) => HistoryBloc(storage)),
        BlocProvider(create: (_) => CallBloc(callingService, storage)),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system, // Bonus 3 — Dark Mode
        builder: (context, child) => ConnectivityBanner(
          child: CallFlowListener(child: child ?? const SizedBox.shrink()),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
