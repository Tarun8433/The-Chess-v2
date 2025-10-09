import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:simple_chess_board/simple_chess_board.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import 'package:get/get.dart';
import '../../settings/settings_controller.dart';

class ChessBoardWithHistory extends StatefulWidget {
  const ChessBoardWithHistory({super.key});

  @override
  State<ChessBoardWithHistory> createState() => _ChessBoardWithHistoryState();
}

class _ChessBoardWithHistoryState extends State<ChessBoardWithHistory> {
  late chess.Chess _chess;
  late MoveHistory _moveHistory;
  String? _customFen;
  List<PieceType> _whiteCaptured = [];
  List<PieceType> _blackCaptured = [];

  // Example: Start from a custom position (Sicilian Defense)
  static const String _initialFen =
      'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2';

  @override
  void initState() {
    super.initState();
    _chess = chess.Chess.fromFEN(_initialFen);
    _moveHistory = MoveHistory(initialFen: _initialFen);
  }

  String get _currentFen => _customFen ?? _chess.fen;

  void _onMove(ShortMove move) {
    final chessCopy = chess.Chess.fromFEN(_chess.fen);

    try {
      // Try to make the move
      final success = chessCopy.move({
        'from': move.from,
        'to': move.to,
        'promotion': move.promotion?.name,
      });

      if (success) {
        // Move was successful
        setState(() {
          _chess = chessCopy;
          _customFen = null; // Reset custom FEN since we're at current position
        });

        // Add to history
        _moveHistory.addMove(
          move: '${move.from}${move.to}${move.promotion?.name ?? ''}',
          fen: _chess.fen,
          san: null, // SAN can be computed later if needed
        );
      }
    } catch (e) {
      // Invalid move
      if (kDebugMode) {
        print('Invalid move: $e');
      }
    }
  }

  void _onPromotionCommitted({
    required ShortMove moveDone,
    required PieceType pieceType,
  }) {
    moveDone.promotion = pieceType;
    _onMove(moveDone);
  }

  // Navigation callbacks
  void _goBack() {
    final previousFen = _moveHistory.goBack();
    setState(() {
      _customFen = previousFen;
    });
  }

  void _goForward() {
    final nextFen = _moveHistory.goForward();
    if (nextFen != null) {
      setState(() {
        _customFen = nextFen;
      });
    }
  }

  void _goToStart() {
    setState(() {
      _customFen = _moveHistory.initialFen;
      _moveHistory.goToIndex(-1);
    });
  }

  void _goToEnd() {
    if (_moveHistory.length > 0) {
      setState(() {
        _customFen = null; // Go to current game position
        _moveHistory.goToIndex(_moveHistory.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.put(SettingsController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Board with History'),
        actions: [
          Obx(() => Row(
                children: [
                  const Text('Sound', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: settings.soundEnabled.value,
                    onChanged: (v) => settings.setSoundEnabled(v),
                  ),
                ],
              )),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chess Board and captured pieces, constrained to a square plus strips
          LayoutBuilder(
            builder: (context, constraints) {
              // Use the available width for the board; compute a fixed strip height
              final double maxWidth = constraints.maxWidth;
              const double stripHeight =
                  28.0; // fits default iconSize 22 + spacing
              final double boardSize = maxWidth; // board will be square

              return Center(
                child: SizedBox(
                  width: boardSize,
                  // total height: top strip + board + bottom strip
                  height: boardSize + stripHeight * 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: stripHeight,
                        child: Center(
                          child: CapturedPiecesStrip(
                            pieces: _blackCaptured,
                            showAsBlackPieces: false,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: SimpleChessBoard(
                            fen: _currentFen,
                            whitePlayerType: PlayerType.human,
                            blackPlayerType: PlayerType.human,
                            onMove: ({required ShortMove move}) =>
                                _onMove(move),
                            playSounds: settings.soundEnabled.value,
                            onPromote: () async {
                              // Simple promotion to queen for demo
                              return PieceType.queen;
                            },
                            onPromotionCommited: _onPromotionCommitted,
                            onTap: ({required String cellCoordinate}) {
                              // Handle cell taps if needed
                            },
                            chessBoardColors: ChessBoardColors()
                              ..lightSquaresColor = MyColors.lightGray
                              ..darkSquaresColor = MyColors.tealGray
                              ..coordinatesZoneColor = MyColors.cardBackground
                              ..lastMoveArrowColor = MyColors.amber
                              ..circularProgressBarColor = MyColors.cyan
                              ..coordinatesColor = MyColors.white
                              ..startSquareColor = MyColors.orange
                              ..endSquareColor = MyColors.cyan
                              ..possibleMovesColor =
                                  MyColors.mediumGray.withAlpha(128)
                              ..dndIndicatorColor =
                                  MyColors.mediumGray.withAlpha(64),
                            cellHighlights: {},
                            showPossibleMoves: true,
                            isInteractive: _moveHistory.canGoForward == false,
                            nonInteractiveText: 'ANALYZING POSITION',
                            nonInteractiveTextStyle: const TextStyle(
                              color: MyColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                            nonInteractiveOverlayColor: MyColors.tealGray,
                            onCapturedPiecesChanged: ({
                              required whiteCapturedPieces,
                              required blackCapturedPieces,
                            }) {
                              setState(() {
                                _whiteCaptured = whiteCapturedPieces;
                                _blackCaptured = blackCapturedPieces;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: stripHeight,
                        child: Center(
                          child: CapturedPiecesStrip(
                            pieces: _whiteCaptured,
                            showAsBlackPieces: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Navigation Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Move navigation
                MoveNavigationControls(
                  moveHistory: _moveHistory,
                  onGoBack: _goBack,
                  onGoForward: _goForward,
                  onGoToStart: _goToStart,
                  onGoToEnd: _goToEnd,
                  style: NavigationControlsStyle(
                    decoration: BoxDecoration(
                      color: MyColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: MyColors.black.withAlpha(25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Move history info
                if (_moveHistory.length > 0)
                  Text(
                    'Position ${_moveHistory.currentIndex + 2} of ${_moveHistory.length + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
