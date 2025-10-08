import 'package:flutter/material.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import 'manual_create_room_screen.dart';
import 'quick_play_screen.dart';

class PlayWithFriendHub extends StatelessWidget {
  const PlayWithFriendHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play With Friend'),
        backgroundColor: MyColors.lightGraydark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            const Text(
              'Choose how to create or join a game:',
              style: TextStyle(fontSize: 16),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Create Game ID manually (share with friend)'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManualCreateRoomScreen()),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.flash_on_outlined),
              label: const Text('Quick Play (auto-generated room, wait for opponent)'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuickPlayScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}