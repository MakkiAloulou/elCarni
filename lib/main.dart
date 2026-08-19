import 'package:flutter/material.dart';

import 'screens/root_scaffold.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ElCarniApp());
}

class ElCarniApp extends StatelessWidget {
  const ElCarniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'elCarni',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootScaffold(),
    );
  }
}
