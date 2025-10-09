import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chesslib;
import 'package:simple_chess_board/simple_chess_board.dart';

class BoardUiController extends GetxController {
  // Local chess engine for offline/custom play
  final chesslib.Chess chess =
      chesslib.Chess.fromFEN(chesslib.Chess.DEFAULT_POSITION);

  // Reactive board state
  final fen = chesslib.Chess.DEFAULT_POSITION.obs;
  final blackAtBottom = false.obs;

  // Move history for offline play
  final MoveHistory moveHistory =
      MoveHistory(initialFen: chesslib.Chess.DEFAULT_POSITION);
  // Reactive mirror of moves for UI updates
  final RxList<HistoryMove> moves = <HistoryMove>[].obs;

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
      // Encode move as long algebraic (e.g., e2e4, with optional promotion suffix)
      final promotionLetter = _promotionLetter(move.promotion);
      final encoded = '${move.from}${move.to}${promotionLetter ?? ''}';
      moveHistory.addMove(move: encoded, fen: chess.fen);
      // Update reactive list
      moves.assignAll(moveHistory.history);
    }
  }

  String? _promotionLetter(PieceType? pt) {
    if (pt == null) return null;
    switch (pt) {
      case PieceType.pawn:
        return null;
      case PieceType.queen:
        return 'q';
      case PieceType.rook:
        return 'r';
      case PieceType.bishop:
        return 'b';
      case PieceType.knight:
        return 'n';
      case PieceType.king:
        // King promotion is not legal; return null to avoid invalid notation
        return null;
    }
  }

  // Optional review helpers if needed later
  void goBack() {
    final previousFen = moveHistory.goBack();
    fen.value = previousFen;
    lastMoveArrow.value = _deriveArrowFromIndex();
  }

  void goForward() {
    final nextFen = moveHistory.goForward();
    if (nextFen != null) {
      fen.value = nextFen;
      lastMoveArrow.value = _deriveArrowFromIndex();
    }
  }

  void goToStart() {
    final startFen = moveHistory.goToIndex(-1);
    fen.value = startFen;
    lastMoveArrow.value = null;
  }

  void goToEnd() {
    final len = moveHistory.length;
    if (len > 0) {
      final endFen = moveHistory.goToIndex(len - 1);
      fen.value = endFen;
      lastMoveArrow.value = _deriveArrowFromIndex();
    } else {
      goToStart();
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
}