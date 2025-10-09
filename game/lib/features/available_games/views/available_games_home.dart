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

      // Decide based on response content
      final hasResponse = gameRoomResponse.response != null &&
          gameRoomResponse.response!.isNotEmpty;
      if (!hasResponse) {
        // No room info returned; re-check once to avoid stale cache or race
        try {
          final confirmResp = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'Roomid': '',
              'Gameid': gameId,
              'Playerid': '',
            }),
          );
          final confirm = GameRoomResponse.fromJson(
            jsonDecode(confirmResp.body) as Map<String, dynamic>,
          );
          final confirmHasRoom = confirm.response != null &&
              confirm.response!.isNotEmpty &&
              (confirm.response!.first.roomId ?? '').isNotEmpty;
          if (confirmHasRoom) {
            final firstRoom = confirm.response!.first;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnlineCustomMoveIndicator(
                  gameId: firstRoom.roomId!,
                  playerId: _playerIdCtrl.text.trim(),
                  initialTimeMs: kDefaultTimePerPlayerMs,
                ),
              ),
            );
            return;
          }
        } catch (_) {}
        // Still no room info; create one and enter
        await _createAndEnter(gameId);
        return;
      }
      final firstRoom = gameRoomResponse.response!.first;
      final msg = (firstRoom.msg ?? '').trim();
      if (msg == "RoomId does not Exist") {
        await _createAndEnter(gameId);
      } else {
        log("Room Created Successfully: ${_playerIdCtrl.text.trim()}  -- ${firstRoom.roomId!}");
        // Room exists -> navigate to it
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnlineCustomMoveIndicator(
              gameId: firstRoom.roomId!,
              playerId: _playerIdCtrl.text.trim(),
              initialTimeMs: kDefaultTimePerPlayerMs,
            ),
          ),
        );
      }
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

  Future<void> _createAndEnter(String gameIdFromBackend) async {
    setState(() => _creating = true);
    try {
      final doc = await RoomService.createAutoRoom(
          initialTimeMs: kDefaultTimePerPlayerMs);
      setState(() => _gameId = doc.id);

      log("Auto Gen Room Id: ${doc.id}");
      if (!mounted) return;
      await _createRoomInBackend(context, doc.id, gameIdFromBackend);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _createRoomInBackend(
      BuildContext context, String roomId, String gameIdFromBackend) async {
    if (roomId.isEmpty) {
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
          'https://chessgame.signaturesoftware.co.in/api/CS/GameRoomSetAdd');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Roomid': roomId,
          'Gameid': gameIdFromBackend,
          'Playerid': _playerIdCtrl.text.trim(),
        }),
      );

      // Parse response using model
      final gameRoomResponse = GameRoomResponse.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
      );

      log("createRoomInBackend==> ${resp.body} ---- ${jsonEncode({
            'Roomid': roomId,
            'Gameid': gameIdFromBackend,
            'Playerid': _playerIdCtrl.text.trim(),
          })}");

      final hasResponse = gameRoomResponse.response != null &&
          gameRoomResponse.response!.isNotEmpty;
      final successMsg = hasResponse
          ? (gameRoomResponse.response!.first.msg ?? '').trim()
          : '';
      final success = (gameRoomResponse.status == true) ||
          successMsg == "Room Added Successfully";
      if (success) {
        log("Room Created Successfully: $roomId");
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnlineCustomMoveIndicator(
              gameId: roomId,
              playerId: _playerIdCtrl.text.trim(),
              initialTimeMs: kDefaultTimePerPlayerMs,
            ),
          ),
        );
      } else {
        await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Room Creation Failed'),
                  content: Text(
                      'Backend did not confirm room creation. Message: ${hasResponse ? (gameRoomResponse.response!.first.msg ?? '') : (gameRoomResponse.message ?? 'Unknown')}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ));
      }
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
