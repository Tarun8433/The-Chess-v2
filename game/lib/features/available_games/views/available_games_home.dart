import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_chess_board_usage/features/auth/models/user_model.dart';
import 'package:simple_chess_board_usage/features/online_room/widgets/online_custom_move_indicator.dart';
import 'package:simple_chess_board_usage/features/play_with_frind/services/room_service.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';

class AvailableGamesHome extends StatefulWidget {
  const AvailableGamesHome({super.key});

  @override
  State<AvailableGamesHome> createState() => _AvailableGamesHomeState();
}

class _AvailableGamesHomeState extends State<AvailableGamesHome> {
  static const String _endpoint =
      'https://chessgame.signaturesoftware.co.in/api/CS/GameList';

  bool _loading = false;
  String? _error;
  List<Map<String, String>> _games = const [];

  Future<void> _fetchGames() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.get(Uri.parse(_endpoint));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Status ${resp.statusCode}');
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final response = body['Response'] as List<dynamic>?;
      final games = response
              ?.map((e) => {
                    'SrNo': (e['SrNo'] ?? '').toString(),
                    'zone': (e['zone'] ?? '').toString(),
                  })
              .toList() ??
          <Map<String, String>>[];
      setState(() => _games = games);
    } catch (e) {
      setState(() => _error = 'Failed to load: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

// Updated method with proper error handling
  Future<void> _checkRoomExist(BuildContext context, String gameId) async {
    if (gameId.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Invalid Game ID'),
          content: Text('Game ID is empty.'),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(
          'https://chessgame.signaturesoftware.co.in/api/CS/GameRoomSet');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Roomid': '',
          'Gameid': gameId,
          'Playerid': '',
        }),
      );

      // Parse response using model
      final gameRoomResponse = GameRoomResponse.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
      );

      log("CheckRoomExist==> ${resp.body} ---- ${jsonEncode({
            'Roomid': '',
            'Gameid': gameId,
            'Playerid': '',
          })}");

      // Check status code and response
      if (gameRoomResponse.statusCode == '404' ||
          gameRoomResponse.response == null ||
          gameRoomResponse.response!.isEmpty) {
        _createAndEnter();
        return;
      }

    

      // Success - show game room details
      final firstRoom = gameRoomResponse.response!.first;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Game Room Found'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: Success'),
                Text('Message: ${firstRoom.msg ?? 'Game room available'}'),
                const SizedBox(height: 12),
                const Text('Room Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Room ID: ${firstRoom.roomId ?? 'N/A'}'),
                Text('Game ID: ${firstRoom.gameId ?? 'N/A'}'),
                Text('Player ID: ${firstRoom.playerId ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to connect to server: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  static const int kDefaultTimePerPlayerMs = 50 * 60 * 1000;
  String? _gameId;
  final TextEditingController _playerIdCtrl =
      TextEditingController(text: 'player-me');
  bool _creating = false;

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
  void initState() {
    super.initState();
    getPlayerInfo();
    _fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available games'),
        backgroundColor: MyColors.lightGraydark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const Text('Available games'),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchGames,
                child: ListView.separated(
                  itemCount: _games.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final g = _games[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(g['zone'] ?? ''),
                      subtitle: Text('ID: ${g['SrNo'] ?? ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _checkRoomExist(
                        context,
                        (g['SrNo'] ?? '').trim(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class for the API response
class GameRoomResponse {
  final List<GameRoom>? response;
  final bool status;
  final String statusCode;
  final String? message;

  GameRoomResponse({
    this.response,
    required this.status,
    required this.statusCode,
    this.message,
  });

  factory GameRoomResponse.fromJson(Map<String, dynamic> json) {
    return GameRoomResponse(
      response: json['Response'] != null
          ? (json['Response'] as List)
              .map((item) => GameRoom.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      status: json['Status'] ?? false,
      statusCode: json['StatusCode']?.toString() ?? '500',
      message: json['Message'],
    );
  }
}

// Model class for individual game room data
class GameRoom {
  final String? msg;
  final String? roomId;
  final String? playerId;
  final String? gameId;

  GameRoom({
    this.msg,
    this.roomId,
    this.playerId,
    this.gameId,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      msg: json['msg'],
      roomId: json['Roomid'],
      playerId: json['Playerid'],
      gameId: json['Gameid'],
    );
  }
}
