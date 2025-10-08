import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:simple_chess_board_usage/features/auth/models/user_model.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import '../services/room_service.dart';
import '../../online_room/widgets/online_custom_move_indicator.dart';

class QuickPlayScreen extends StatefulWidget {
  const QuickPlayScreen({super.key});

  @override
  State<QuickPlayScreen> createState() => _QuickPlayScreenState();
}

class _QuickPlayScreenState extends State<QuickPlayScreen> {
  static const int kDefaultTimePerPlayerMs = 50 * 60 * 1000;
  String? _gameId;
  final TextEditingController _playerIdCtrl =
      TextEditingController(text: 'player-me');
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    getPlayerInfo();
  }

  void getPlayerInfo() async {
    final user = await UserPrefsService.loadUser();
    if (user != null) {
      setState(() => _playerIdCtrl.text = user.name);
    }
  }

  Future<void> _createAndEnter() async {
    setState(() => _creating = true);
    try {
      final doc = await RoomService.createAutoRoom(
          initialTimeMs: kDefaultTimePerPlayerMs);
      setState(() => _gameId = doc.id);

      log("Auto Gen Room Id: ${doc.id}");
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OnlineCustomMoveIndicator(
            gameId: doc.id,
            playerId: _playerIdCtrl.text.trim(),
            initialTimeMs: kDefaultTimePerPlayerMs,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.lightGraydark,
        title: const Text('Quick Play'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We will create a room for you and wait for opponent.'),
            TextField(
              controller: _playerIdCtrl,
              decoration: const InputDecoration(labelText: 'Your Player ID'),
            ),
            ElevatedButton(
              onPressed: _creating ? null : _createAndEnter,
              child: Text(_creating ? 'Creating…' : 'Create & Enter'),
            ),
            if (_gameId != null)
              Text('Room created: $_gameId (share this if needed)'),
          ],
        ),
      ),
    );
  }
}
