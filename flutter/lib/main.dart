import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'const.dart';
import 'ui/layout.dart';
import 'state/state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => AppState(),

      child: MaterialApp(
        title: Const.appName,
        debugShowCheckedModeBanner: true,

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: Const.lightColorScheme,
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        ),
        home: Layout(),
      ),
    );
  }
}
