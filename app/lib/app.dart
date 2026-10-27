import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/main_navigation.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class FlightAttendanceApp extends StatelessWidget {
  final AppState appState;

  const FlightAttendanceApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: '航班打卡',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: appState.themeMode.value,
        initialBinding: BindingsBuilder(() {
          Get.put<AppState>(appState, permanent: true);
        }),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    return Obx(() {
      if (state.startupError.value != null) {
        return Scaffold(
          backgroundColor: context.palette.bg,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✈️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      state.startupError.value!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      if (!state.booted.value) {
        return Scaffold(
          backgroundColor: context.palette.bg,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return const MainNavigation();
    });
  }
}
