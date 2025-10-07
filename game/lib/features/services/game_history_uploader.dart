import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simple_chess_board/models/move_history.dart';

class GameHistoryUploader {
  // Placeholder endpoint; user will replace later
  static const String _endpoint = 'https://example.com/api/game-history';

  static Future<void> uploadGameHistory({
    required String gameId,
    required String playerId,
    required String winnerColor,
    required List<HistoryMove> history,
  }) async {
    final payload = {
      'gameId': gameId,
      'playerId': playerId,
      'winnerColor': winnerColor,
      'moves': history
          .map((h) => {
                'move': h.move,
                'fen': h.fen,
                'san': h.san,
                'timestamp': h.timestamp.toIso8601String(),
              })
          .toList(),
    };

    try {
      final resp = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Upload failed with status ${resp.statusCode}');
      }
    } catch (_) {
      // Swallow errors for now; upload is best-effort
    }
  }
}