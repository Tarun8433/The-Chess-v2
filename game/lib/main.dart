import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board_usage/features/online_room/widgets/online_custom_move_indicator.dart';
import 'features/game_history/widgets/chess_board_with_history.dart';
import 'features/offline/widgets/custom_move_indicator.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import 'features/auth/views/auth_hub.dart';
import 'features/play_with_frind/views/play_with_friend_hub.dart';
import 'features/available_games/views/available_games_home.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/models/user_model.dart';

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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chess Master',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: MyColors.primary,
          secondary: MyColors.accent,
          surface: MyColors.background,
          background: MyColors.tealGray,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MyColors.lightGraydark,
          foregroundColor: MyColors.white,
        ),
        scaffoldBackgroundColor: MyColors.tealGray,
        cardColor: MyColors.cardBackground,
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final UserModel? user;

  const MyHomePage({
    super.key,
    this.user,
  });

  // Global time control: per-player total time in milliseconds
  static const int kDefaultTimePerPlayerMs = 50 * 60 * 1000; // 50 minutes

  Future<void> _goToCustomIndicatorsBoard(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return CustomMoveIndicator();
    }));
  }

  Future<void> _goToHistoryExample(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ChessBoardWithHistory();
    }));
  }

  Future<void> _goToOnlineBoard(BuildContext context, String userName) async {
    final gameIdController = TextEditingController(text: 'demo-game');
    final playerIdController = TextEditingController(text: userName);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join or Create Online Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gameIdController,
              decoration: const InputDecoration(labelText: 'Game ID'),
            ),
            TextField(
              controller: playerIdController,
              decoration: const InputDecoration(labelText: 'Your Player ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop({
              'gameId': gameIdController.text.trim(),
              'playerId': playerIdController.text.trim(),
            }),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return OnlineCustomMoveIndicator(
        gameId: result['gameId']!,
        playerId: result['playerId']!,
        initialTimeMs: kDefaultTimePerPlayerMs,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? "Welcome, ${user!.name}" : "Chess Master"),
        actions: user != null
            ? [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    // Show user profile or settings
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Profile'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: ${user!.name}'),
                            const SizedBox(height: 8),
                            Text('Email: ${user!.emailAddress}'),
                            const SizedBox(height: 8),
                            Text('Code: ${user!.customerCode}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await UserPrefsService.clearUser();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthHub()),
                      );
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            ElevatedButton(
              onPressed: () => _goToCustomIndicatorsBoard(context),
              child: Text("See custom indicators board"),
            ),
            ElevatedButton(
              onPressed: () => _goToHistoryExample(context),
              child: Text("See history example"),
            ),
            ElevatedButton(
              onPressed: () => _goToOnlineBoard(context, user!.name),
              child: Text("Play online (Firebase)"),
            ),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlayWithFriendHub()),
                );
              },
              child: Text("Play with friend"),
            ),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AvailableGamesHome()),
                );
              },
              child: Text("Available games"),
            ),
          ],
        ),
      ),
    );
  }
}
