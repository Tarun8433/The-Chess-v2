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

//////////////////////////////////////////////////////////////////////////////////////

class BattleApp extends StatelessWidget {
  const BattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battle UI',
      theme: ThemeData(
        useMaterial3: true,
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
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
      home: const BattleHomePage(),
    );
  }
}

class BattleHomePage extends StatefulWidget {
  const BattleHomePage({super.key});

  @override
  State<BattleHomePage> createState() => _BattleHomePageState();
}

class _BattleHomePageState extends State<BattleHomePage> {
  // Tighter viewport so neighbors visibly "peek" in.
  final _pageCtrl = PageController(viewportFraction: 0.68);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() => setState(() => _page = _pageCtrl.page ?? 0));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use themed colors from MyColors via Theme

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Top-right menu
            Positioned(
              top: 6,
              right: 2,
              child: IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN
                SizedBox(
                  width: 132,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _PointsPill(),
                        SizedBox(height: 22),
                        _Headline(),
                        SizedBox(height: 18),
                        AvatarWithDot(initials: 'AL', status: Colors.green),
                        SizedBox(height: 14),
                        AvatarWithDot(initials: 'BK', status: Colors.red),
                        SizedBox(height: 14),
                        AvatarWithDot(initials: 'CS', status: Colors.green),
                        SizedBox(height: 14),
                        AvatarWithDot(initials: 'DM', status: Colors.orange),
                        SizedBox(height: 14),
                        AvatarWithDot(initials: 'EV', status: Colors.green),
                        Spacer(),
                        _AddButton(),
                      ],
                    ),
                  ),
                ),

                // RIGHT: TILTED, 3D CARD CAROUSEL
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Slight tilt of the entire rail to emulate the mock
                      return Transform.rotate(
                        angle: -0.06, // ~-3.5 degrees
                        alignment: Alignment.centerRight,
                        child: PageView.builder(
                          scrollDirection: Axis.vertical,
                          controller: _pageCtrl,
                          padEnds: false,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final data = _cards[index];
                            final delta = (_page - index);
                            final adelta = delta.abs();

                            // Depth, scale, and parallax
                            final scale = 1 - (adelta * 0.12).clamp(0, 0.22);
                            final translateY = 28.0 * adelta; // vertical drift
                            final translateX = -8.0 * delta; // slight parallax
                            final rotZ = 0.05 * -delta; // local tilt
                            final rotY = 0.28 * delta; // 3D swivel

                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translate(translateX, translateY)
                                ..setEntry(3, 2, 0.0012) // perspective
                                ..rotateY(rotY)
                                ..rotateZ(rotZ)
                                ..scale(scale),
                              child: PlayOptionCard(
                                dark: data.dark,
                                icon: data.icon,
                                title: data.title,
                                subtitle: data.subtitle,
                                badge: data.badge,
                                onPressed: () {},
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Right-bottom floating purple slice (subtle accent like mock)
            Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: MyColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Battle\nwith our\nfriend',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MyColors.lightGraydark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(
            radius: 10,
            backgroundColor: MyColors.amber,
            child: Icon(Icons.stars, size: 14, color: MyColors.black),
          ),
          SizedBox(width: 8),
          Text(
            '480 point',
            style: TextStyle(
              color: MyColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: MyColors.primary,
        elevation: 0,
        child: const Icon(Icons.add, color: MyColors.white),
      ),
    );
  }
}

class AvatarWithDot extends StatelessWidget {
  final String initials;
  final Color status;

  const AvatarWithDot(
      {super.key, required this.initials, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: MyColors.cardBackground,
            child: Text(
              '🙂', // placeholder; swap with images or initials if you prefer
              style: TextStyle(fontSize: 18),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: MyColors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(blurRadius: 1, color: Colors.black12)],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: status, shape: BoxShape.circle),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PlayOptionCard extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onPressed;

  const PlayOptionCard({
    super.key,
    required this.dark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? MyColors.cardBackground : MyColors.white;
    final fg = dark ? MyColors.white : MyColors.black;
    final sub = MyColors.mediumGray;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: const Offset(0, 18),
            color: MyColors.black.withOpacity(dark ? 0.35 : 0.10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dark ? MyColors.lightGraydark : MyColors.tealGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium,
                      size: 16, color: dark ? MyColors.amber : MyColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    badge!,
                    style: TextStyle(
                        fontSize: 12, color: sub, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Icon(icon, size: 28, color: fg),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.12,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 13, color: sub)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                foregroundColor: MyColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onPressed,
              child: const Text('Play now',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  final bool dark;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  const _CardData({
    required this.dark,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });
}

const _cards = <_CardData>[
  _CardData(
    dark: false,
    icon: Icons.tune,
    title: 'Play with\nCustom',
    subtitle: 'Make custom rules\nand start your match',
  ),
  _CardData(
    dark: true,
    icon: Icons.group,
    title: 'Play with\nFriend',
    subtitle: 'Choose and play\nwith your friend',
    badge: 'Recommended',
  ),
  _CardData(
    dark: false,
    icon: Icons.shuffle,
    title: 'Play with\nRandom',
    subtitle: 'Quick match with\nanyone online',
  ),
];
