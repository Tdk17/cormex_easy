import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerDependencies();
  runApp(const CormexEasyBootstrap());
}

class CormexEasyBootstrap extends StatefulWidget {
  const CormexEasyBootstrap({super.key});

  @override
  State<CormexEasyBootstrap> createState() => _CormexEasyBootstrapState();
}

class _CormexEasyBootstrapState extends State<CormexEasyBootstrap> {
  late final Future<void> _initialization = initializeDependencies();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const CormexEasyApp();
        }
        return MaterialApp(
          title: 'CormeX Easy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const _StartupSplash(),
        );
      },
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF170308),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF7A1830),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x557A1830),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: SizedBox.square(
                  dimension: 82,
                  child: Center(
                    child: Text(
                      'Cx',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 22),
              Text(
                'CormeX Easy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Serviços perto de você',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 26),
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFD8A84E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
