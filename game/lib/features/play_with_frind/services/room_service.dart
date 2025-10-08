import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chess/chess.dart' as chesslib;

/// Service to create and fetch online game rooms.
class RoomService {
  static final CollectionReference<Map<String, dynamic>> _games =
      FirebaseFirestore.instance.collection('games');

  /// Create a game with an auto-generated ID and default payload.
  /// Returns the created document reference.
  static Future<DocumentReference<Map<String, dynamic>>> createAutoRoom({
    required int initialTimeMs,
  }) async {
    final doc = await _games.add({
      'fen': chesslib.Chess.DEFAULT_POSITION,
      'moves': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
      'players': <String, String>{},
      'whiteTimeMs': initialTimeMs,
      'blackTimeMs': initialTimeMs,
      'lastTurnAt': FieldValue.serverTimestamp(),
      'status': 'ongoing',
      'winner': null,
    });
    return doc;
  }

  /// Returns a reference to a manual room by ID. The room will be
  /// lazily created by the gameplay widget if it does not exist.
  static DocumentReference<Map<String, dynamic>> manualRoomRef(String gameId) {
    return _games.doc(gameId);
  }
}