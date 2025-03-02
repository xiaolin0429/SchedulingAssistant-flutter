import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'presentation/blocs/home/home_bloc.dart';
import 'presentation/blocs/home/home_event.dart';
import 'presentation/blocs/shift/shift_bloc.dart';
import 'presentation/blocs/shift/shift_event.dart';
import 'presentation/blocs/alarm/alarm_bloc.dart';
import 'presentation/blocs/alarm/alarm_event.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/blocs/shift_type/shift_type_bloc.dart';
import 'presentation/blocs/shift_type/shift_type_event.dart';
import 'presentation/pages/main_screen.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/app_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => di.getIt<HomeBloc>()..add(const LoadHomeData()),
        ),
        BlocProvider<ShiftBloc>(
          create: (_) => di.getIt<ShiftBloc>()..add(const LoadShifts()),
        ),
        BlocProvider<AlarmBloc>(
          create: (_) => di.getIt<AlarmBloc>()..add(const LoadAlarms()),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => di.getIt<SettingsBloc>()..add(const LoadSettings()),
        ),
        BlocProvider<ShiftTypeBloc>(
          create: (_) => di.getIt<ShiftTypeBloc>()..add(const LoadShiftTypes()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return MaterialApp(
              title: '排班助手',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
              ),
              darkTheme: ThemeData.dark(useMaterial3: true),
              themeMode: state.themeMode == 'dark' 
                ? ThemeMode.dark 
                : (state.themeMode == 'light' ? ThemeMode.light : ThemeMode.system),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'),
                Locale('en', 'US'),
              ],
              locale: state.language == 'zh' ? const Locale('zh', 'CN') : const Locale('en', 'US'),
              localeResolutionCallback: (locale, supportedLocales) {
                debugPrint('系统区域设置: $locale');
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale?.languageCode) {
                    debugPrint('使用匹配的区域设置: $supportedLocale');
                    return supportedLocale;
                  }
                }
                debugPrint('使用默认区域设置: ${supportedLocales.first}');
                return supportedLocales.first;
              },
              home: const MainScreen(),
            );
          }
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );
  }
}
