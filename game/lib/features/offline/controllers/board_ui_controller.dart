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
}