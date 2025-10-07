import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
  import 'package:simple_chess_board_usage/theme/my_colors.dart';
import '../controllers/board_ui_controller.dart';

class CustomMoveIndicator extends StatefulWidget {
  const CustomMoveIndicator({super.key});

  @override
  State<CustomMoveIndicator> createState() => _CustomMoveIndicatorState();
}

class _CustomMoveIndicatorState extends State<CustomMoveIndicator> {
  late final BoardUiController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(BoardUiController());
  }

  void tryMakingMove({required ShortMove move}) {
    ctrl.tryMakingMove(move: move);
  }

  Future<PieceType?> handlePromotion(BuildContext context) {
    return showDialog<PieceType>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Promotion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Queen"),
                onTap: () => Navigator.of(context).pop(PieceType.queen),
              ),
              ListTile(
                title: const Text("Rook"),
                onTap: () => Navigator.of(context).pop(PieceType.rook),
              ),
              ListTile(
                title: const Text("Bishop"),
                onTap: () => Navigator.of(context).pop(PieceType.bishop),
              ),
              ListTile(
                title: const Text("Knight"),
                onTap: () => Navigator.of(context).pop(PieceType.knight),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("With custom move indicator"),
        actions: [
          IconButton(
            onPressed: () {
              ctrl.toggleOrientation();
            },
            icon: const Icon(Icons.swap_vert),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            // Top side shows pieces captured by the player on top
            Obx(() {
              final blackBottom = ctrl.blackAtBottom.value;
              final topPieces = blackBottom ? ctrl.whiteCaptured : ctrl.blackCaptured;
              final topShowBlackIcons = blackBottom ? true : false;
              return CapturedPiecesStrip(
                pieces: topPieces,
                showAsBlackPieces: topShowBlackIcons,
              );
            }),
            Obx(() => SimpleChessBoard(
              engineThinking: false,
              fen: ctrl.fen.value,
              onMove: tryMakingMove,
              blackSideAtBottom: ctrl.blackAtBottom.value,
              whitePlayerType: PlayerType.human,
              blackPlayerType: PlayerType.human,
              showPossibleMoves: true,
          // Custom widget for normal moves (empty squares)
          normalMoveIndicatorBuilder: (cellSize) => SizedBox(
            width: cellSize,
            height: cellSize,
            child: Center(
              child: Container(
                width: cellSize * 0.3,
                height: cellSize * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyColors.cyan.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          // Custom widget for capture moves (squares with opponent pieces)
          captureMoveIndicatorBuilder: (cellSize) => Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: MyColors.red,
                width: cellSize * 0.05,
              ),
            ),
            child: Icon(
              Icons.close,
              color: MyColors.red,
              size: cellSize * 0.5,
            ),
          ),
          onPromote: () => handlePromotion(context),
          cellHighlights: ctrl.highlightCells,
        chessBoardColors: ChessBoardColors()
          ..lightSquaresColor = MyColors.lightGray
          ..darkSquaresColor = MyColors.tealGray
          ..coordinatesZoneColor = MyColors.cardBackground
          ..lastMoveArrowColor = MyColors.amber
          ..circularProgressBarColor = MyColors.cyan
          ..coordinatesColor = MyColors.white
          ..startSquareColor = MyColors.orange
          ..endSquareColor = MyColors.cyan
          ..possibleMovesColor = MyColors.mediumGray.withAlpha(128)
          ..dndIndicatorColor = MyColors.mediumGray.withAlpha(64),
          onPromotionCommited: ({required moveDone, required pieceType}) {
            moveDone.promotion = pieceType;
            tryMakingMove(move: moveDone);
          },
          onTap: ({required cellCoordinate}) {},
          highlightLastMoveSquares: true,
          lastMoveToHighlight: ctrl.lastMoveArrow.value,
          showCoordinatesZone: false,
          onCapturedPiecesChanged: ({
            required whiteCapturedPieces,
            required blackCapturedPieces,
          }) {
            ctrl.setCapturedPieces(
              white: whiteCapturedPieces,
              black: blackCapturedPieces,
            );
          },
        )),
            // Bottom side shows pieces captured by the player at bottom
            Obx(() {
              final blackBottom = ctrl.blackAtBottom.value;
              final bottomPieces = blackBottom ? ctrl.blackCaptured : ctrl.whiteCaptured;
              final bottomShowBlackIcons = blackBottom ? false : true;
              return CapturedPiecesStrip(
                pieces: bottomPieces,
                showAsBlackPieces: bottomShowBlackIcons,
              );
            }),
          ],
        ),
      ),
    );
  }
}
