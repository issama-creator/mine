import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mine/core/game_config.dart';
import 'mine/managers/asset_manager.dart';
import 'mine/mine_runner_game.dart';
import 'mine/overlays/mine_overlays.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Assets live in flutter_application_1/assets/ (not assets/images/).
  // mine runner/assets/ is a separate source folder — copy into project assets/.
  Flame.images.prefix = 'assets/';
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Side-scroller — landscape keeps miner/road proportions on phones.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  runApp(const MineSliceApp());
}

class MineSliceApp extends StatelessWidget {
  const MineSliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mine Slice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0A08),
        useMaterial3: true,
      ),
      home: const MineGameScreen(),
    );
  }
}

class MineGameScreen extends StatefulWidget {
  const MineGameScreen({super.key});

  @override
  State<MineGameScreen> createState() => _MineGameScreenState();
}

class _MineGameScreenState extends State<MineGameScreen> {
  MineRunnerGame? _game;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _loadError = null;
      _game = null;
    });
    try {
      AssetManager.instance.reset();
      await AssetManager.instance.loadAll();
      if (!mounted) return;
      setState(() => _game = MineRunnerGame());
    } catch (e, st) {
      debugPrint('Mine Slice boot failed: $e\n$st');
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0A08),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Failed to load assets',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_loadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _boot, child: const Text('RETRY')),
              ],
            ),
          ),
        ),
      );
    }

    if (_game == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0A08),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFD54F)),
              SizedBox(height: 16),
              Text(
                'Loading Mine Slice…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A08),
      body: SizedBox.expand(
        child: GameWidget(
          game: _game!,
          backgroundBuilder: (_) => Container(
            color: const Color(0xFF0D0A08),
          ),
          overlayBuilderMap: {
          GameConfig.overlayTitle: (c, g) =>
              MineTitleOverlay(game: g as MineRunnerGame),
          GameConfig.overlayHud: (c, g) =>
              MineHudOverlay(game: g as MineRunnerGame),
          GameConfig.overlayGameOver: (c, g) =>
              MineGameOverOverlay(game: g as MineRunnerGame),
          GameConfig.overlayPause: (c, g) =>
              MinePauseOverlay(game: g as MineRunnerGame),
          GameConfig.overlayEvent: (c, g) =>
              MineEventOverlay(game: g as MineRunnerGame),
        },
        ),
      ),
    );
  }
}
