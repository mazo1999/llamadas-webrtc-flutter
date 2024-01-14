import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meet/config/theme.dart';
import 'presentation/screens/screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // bool isDarkmode = true;
        return MaterialApp(
          theme: AppTheme(
            isDarkmode: true,
            darkColor: darkDynamic,
            lightColor: lightDynamic,
          ).getTheme(),
          title: 'Reuniones Flutter',
          initialRoute: '/',
          debugShowCheckedModeBanner: false,
          routes: {
            '/': (context) => const HomeScreen(),
            '/meets': (context) => const MeetsScreen(),
          },
        );
      },
    );
  }
}
