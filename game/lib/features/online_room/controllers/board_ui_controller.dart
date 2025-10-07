import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chesslib;
import 'package:simple_chess_board/simple_chess_board.dart';

/// Board UI controller scoped for online room feature.
class BoardUiController extends GetxController {
  // Local chess engine used for UI helpers (not authoritative for server state)
  final chesslib.Chess chess =
      chesslib.Chess.fromFEN(chesslib.Chess.DEFAULT_POSITION);

  // Reactive board state
  final fen = chesslib.Chess.DEFAULT_POSITION.obs;
  final blackAtBottom = false.obs;

  // Review mode and submission/loading flags
  final reviewMode = false.obs;
  final isSubmitting = false.obs;

  // Review navigation support
  final reviewFen = chesslib.Chess.DEFAULT_POSITION.obs;
  final reviewArrow = Rxn<BoardArrow>();
  final reviewIndex = (-1).obs;
  int _lastSyncedMoveCount = 0;
  final MoveHistory moveHistory =
      MoveHistory(initialFen: chesslib.Chess.DEFAULT_POSITION);

  // Captured pieces per side
  final whiteCaptured = <PieceType>[].obs;
  final blackCaptured = <PieceType>[].obs;

  // Arrow for last move
  final lastMoveArrow = Rxn<BoardArrow>();

  // Cell highlights (kept simple for now)
  final Map<String, Color> highlightCells = <String, Color>{};

  void toggleOrientation() => blackAtBottom.toggle();

  void setCapturedPieces({
    required List<PieceType> white,
    required List<PieceType> black,
  }) {
    whiteCaptured.assignAll(white);
    blackCaptured.assignAll(black);
  }

  void tryMakingMove({required ShortMove move}) {
    final success = chess.move(<String, String?>{
      'from': move.from,
      'to': move.to,
      'promotion': move.promotion?.name,
    });
    if (success) {
      fen.value = chess.fen;
      lastMoveArrow.value = BoardArrow(from: move.from, to: move.to);
    }
  }

  void setReviewMode(bool enabled) => reviewMode.value = enabled;

  void setSubmitting(bool submitting) => isSubmitting.value = submitting;

  // -------- Review helpers --------
  void syncMoveHistory(List<String> moves) {
    if (moves.length == _lastSyncedMoveCount) return;
    // Reset and rebuild history
    final mh = MoveHistory(initialFen: chesslib.Chess.DEFAULT_POSITION);
    final local = chesslib.Chess.fromFEN(chesslib.Chess.DEFAULT_POSITION);
    for (final m in moves) {
      if (m.length < 4) continue;
      final from = m.substring(0, 2);
      final to = m.substring(2, 4);
      final promotion = m.length > 4 ? m.substring(4, 5) : null;
      final ok = local.move(<String, String?>{
        'from': from,
        'to': to,
        'promotion': promotion,
      });
      if (!ok) break;
      mh.addMove(move: m, fen: local.fen);
    }
    // Assign and adjust index
    moveHistory.history
      ..clear()
      ..addAll(mh.history);
    _lastSyncedMoveCount = moves.length;
    if (!reviewMode.value) {
      // follow live
      if (moveHistory.length > 0) {
        moveHistory.goToIndex(moveHistory.length - 1);
        reviewIndex.value = moveHistory.currentIndex;
        reviewFen.value = moveHistory.currentFen;
        reviewArrow.value = _deriveArrowFromIndex();
      } else {
        moveHistory.goToIndex(-1);
        reviewIndex.value = -1;
        reviewFen.value = chesslib.Chess.DEFAULT_POSITION;
        reviewArrow.value = null;
      }
    } else {
      // clamp if new moves appended
      if (moveHistory.currentIndex > moveHistory.length - 1) {
        moveHistory.goToIndex(moveHistory.length - 1);
      }
      reviewIndex.value = moveHistory.currentIndex;
      reviewFen.value = moveHistory.currentFen;
      reviewArrow.value = _deriveArrowFromIndex();
    }
  }

  BoardArrow? _deriveArrowFromIndex() {
    final idx = moveHistory.currentIndex;
    final m = moveHistory.getMoveAt(idx);
    if (m == null) return null;
    final mv = m.move;
    if (mv.length < 4) return null;
    return BoardArrow(from: mv.substring(0, 2), to: mv.substring(2, 4));
  }

  void goBack() {
    moveHistory.goBack();
    reviewIndex.value = moveHistory.currentIndex;
    reviewFen.value = moveHistory.currentFen;
    reviewArrow.value = _deriveArrowFromIndex();
  }

  void goForward() {
    moveHistory.goForward();
    reviewIndex.value = moveHistory.currentIndex;
    reviewFen.value = moveHistory.currentFen;
    reviewArrow.value = _deriveArrowFromIndex();
  }

  void goToStart() {
    moveHistory.goToIndex(-1);
    reviewIndex.value = moveHistory.currentIndex;
    reviewFen.value = chesslib.Chess.DEFAULT_POSITION;
    reviewArrow.value = null;
  }

  void goToEnd() {
    if (moveHistory.length > 0) {
      moveHistory.goToIndex(moveHistory.length - 1);
      reviewFen.value = moveHistory.currentFen;
      reviewArrow.value = _deriveArrowFromIndex();
      reviewIndex.value = moveHistory.currentIndex;
    } else {
      moveHistory.goToIndex(-1);
      reviewFen.value = chesslib.Chess.DEFAULT_POSITION;
      reviewArrow.value = null;
      reviewIndex.value = -1;
    }
  }
}