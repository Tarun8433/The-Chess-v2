import 'package:flutter/material.dart';
import '../models/piece_type.dart';
import 'chess_vectors_definitions.dart';
import 'chess_vector.dart';

class CapturedPiecesStrip extends StatelessWidget {
  final List<PieceType> pieces;
  final bool showAsBlackPieces;
  final double iconSize;
  final double spacing;

  const CapturedPiecesStrip({
    super.key,
    required this.pieces,
    required this.showAsBlackPieces,
    this.iconSize = 22,
    this.spacing = 6,
  });

  List<VectorDrawableElement> _definitionFor(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return showAsBlackPieces ? blackPawnDefinition : whitePawnDefinition;
      case PieceType.knight:
        return showAsBlackPieces ? blackKnightDefinition : whiteKnightDefinition;
      case PieceType.bishop:
        return showAsBlackPieces ? blackBishopDefinition : whiteBishopDefinition;
      case PieceType.rook:
        return showAsBlackPieces ? blackRookDefinition : whiteRookDefinition;
      case PieceType.queen:
        return showAsBlackPieces ? blackQueenDefinition : whiteQueenDefinition;
      case PieceType.king:
        return showAsBlackPieces ? blackKingDefinition : whiteKingDefinition;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: pieces
          .map(
            (p) => SizedBox(
              width: iconSize,
              height: iconSize,
              child: CustomPaint(
                painter: _PieceVectorPainter(_definitionFor(p)),
                size: Size.square(iconSize),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PieceVectorPainter extends CustomPainter {
  static const double _baseImageSize = 45.0;
  final List<VectorDrawableElement> elements;

  _PieceVectorPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _baseImageSize;
    canvas.save();
    canvas.scale(scale, scale);
    for (final vectorElement in elements) {
      vectorElement.paintIntoCanvas(canvas, vectorElement.drawingParameters);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PieceVectorPainter oldDelegate) {
    return oldDelegate.elements != elements;
  }
}