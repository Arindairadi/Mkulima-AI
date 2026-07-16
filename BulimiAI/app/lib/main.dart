import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Entry point.
///
/// Firebase.initializeApp(), Isar.open(), and other async bootstrapping
/// will be added here in Step 6 (Authentication) and Step 12 (Farm
/// Management / offline storage). Kept minimal for Step 1 so the scaffold
/// is provably runnable before more moving parts are introduced.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MkulimaApp(),
    ),
  );
}
