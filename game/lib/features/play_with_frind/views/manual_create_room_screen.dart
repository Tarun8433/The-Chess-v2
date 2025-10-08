import 'package:flutter/material.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import '../../online_room/widgets/game_names_custom_room.dart';

class ManualCreateRoomScreen extends StatefulWidget {
  const ManualCreateRoomScreen({super.key});

  @override
  State<ManualCreateRoomScreen> createState() => _ManualCreateRoomScreenState();
}

class _ManualCreateRoomScreenState extends State<ManualCreateRoomScreen> {
  final _gameIdCtrl = TextEditingController(text: 'my-room');
  final _playerIdCtrl = TextEditingController(text: 'player-me');
  static const int kDefaultTimePerPlayerMs = 50 * 60 * 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.lightGraydark,
        title: const Text('Create Manual Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 12,
          children: [
            TextField(
              controller: _gameIdCtrl,
              decoration: const InputDecoration(labelText: 'Game ID (share with friend)'),
            ),
            TextField(
              controller: _playerIdCtrl,
              decoration: const InputDecoration(labelText: 'Your Player ID'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final gameId = _gameIdCtrl.text.trim();
                final playerId = _playerIdCtrl.text.trim();
                if (gameId.isEmpty || playerId.isEmpty) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameNamesCustomRoom(
                      gameId: gameId,
                      playerId: playerId,
                      initialTimeMs: kDefaultTimePerPlayerMs,
                    ),
                  ),
                );
              },
              child: const Text('Create & Enter Room'),
            ),
          ],
        ),
      ),
    );
  }
}