/// AgentFlow entry point (design doc §16).
///
/// Boots the Riverpod [ProviderScope] and mounts [AgentFlowApp]. Everything else
/// — database, repositories, engine, router — is constructed lazily by providers
/// so tests can override any layer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AgentFlowApp()));
}
