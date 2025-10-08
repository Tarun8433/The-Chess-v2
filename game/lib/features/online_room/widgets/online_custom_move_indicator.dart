import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chesslib;
import 'package:simple_chess_board/simple_chess_board.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/game_history_uploader.dart';
import '../controllers/game_controller.dart';
import '../controllers/board_ui_controller.dart';

class OnlineCustomMoveIndicator extends StatelessWidget {
  final String gameId;
  final String playerId;
  final int initialTimeMs;

  const OnlineCustomMoveIndicator({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.initialTimeMs,
  });

  CollectionReference<Map<String, dynamic>> get games =>
      FirebaseFirestore.instance.collection('games');

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

  void _printMoves(List<String> mvs) {
    debugPrint('===== Game history (${mvs.length} moves) =====');
    for (int i = 0; i < mvs.length; i++) {
      debugPrint('${i + 1}. ${mvs[i]}');
    }
    debugPrint('===== End history =====');
  }

  // Compute a cell highlight map that tints the king square when the side to move is in check.
  Map<String, Color> _computeKingInCheckHighlights(String fen) {
    try {
      final c = chesslib.Chess.fromFEN(fen);
      // chesslib follows chess.js API; in_check indicates side-to-move is in check.
      final inCheck = c.in_check;
      if (inCheck != true) return const <String, Color>{};

      final turnColor = c.turn; // chess.Color.WHITE or chess.Color.BLACK
      for (final sq in chesslib.Chess.SQUARES.keys) {
        final p = c.get(sq);
        if (p != null &&
            p.type == chesslib.PieceType.KING &&
            p.color == turnColor) {
          return <String, Color>{sq: Colors.red};
        }
      }
    } catch (_) {
      // If anything goes wrong, do not highlight.
    }
    return const <String, Color>{};
  }

  void _showEndDialog({
    required BuildContext context,
    required String winnerColor,
    required List<String> moves,
    String? playerColor,
  }) {
    final youWon = playerColor != null && playerColor == winnerColor;
    final youLost = playerColor != null && playerColor != winnerColor;
    final title = youWon
        ? 'You won on time'
        : youLost
            ? 'You lost on time'
            : 'Game ended';
    final winnerText = winnerColor == 'w' ? 'White' : 'Black';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            _printMoves(moves);
            return false;
          },
          child: AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!youWon && !youLost)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('Winner: $winnerText'),
                    ),
                  const Text('Game history:'),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: moves.length,
                      itemBuilder: (context, index) {
                        final move = moves[index];
                        final moveNumber = index + 1;
                        return Text('$moveNumber. $move');
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _printMoves(moves);
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tryMoveTransactional({
    required ShortMove move,
    required String currentFen,
  }) async {
    final gameRef = games.doc(gameId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(gameRef);
      if (!snap.exists) {
        throw Exception('Game not found');
      }
      final data = snap.data()!;
      if ((data['status'] as String?) == 'ended') {
        throw Exception('Game already ended');
      }
      final serverFen =
          (data['fen'] as String?) ?? chesslib.Chess.DEFAULT_POSITION;
      // Revalidate against server fen
      final chess = chesslib.Chess.fromFEN(serverFen);
      final success = chess.move(<String, String?>{
        'from': move.from,
        'to': move.to,
        'promotion': move.promotion?.name,
      });
      if (!success) {
        throw Exception('Illegal move');
      }
      // Enforce turn
      final sideToMoveIsWhite = serverFen.split(' ')[1] == 'w';
      final playerColor = data['players']?[playerId] as String?; // 'w' or 'b'
      if (playerColor == null ||
          (sideToMoveIsWhite && playerColor != 'w') ||
          (!sideToMoveIsWhite && playerColor != 'b')) {
        throw Exception('Not your turn');
      }

      // Decrement clock for the side that just moved
      final lastTurnTs = data['lastTurnAt'] as Timestamp?;
      final lastTurnAt = lastTurnTs?.toDate() ?? DateTime.now();
      final now = DateTime.now();
      final players = Map<String, dynamic>.from(data['players'] ?? const {});
      final bothSeated =
          players.values.contains('w') && players.values.contains('b');
      int whiteTimeMs = (data['whiteTimeMs'] as int?) ?? initialTimeMs;
      int blackTimeMs = (data['blackTimeMs'] as int?) ?? initialTimeMs;
      final prevMoveCount = List<String>.from(data['moves'] ?? const []).length;
      final clocksActiveBefore = bothSeated && prevMoveCount > 0;
      final elapsedMs =
          clocksActiveBefore ? now.difference(lastTurnAt).inMilliseconds : 0;
      if (sideToMoveIsWhite) {
        whiteTimeMs = whiteTimeMs - elapsedMs;
        if (whiteTimeMs <= 0) {
          tx.update(gameRef, {
            'status': 'ended',
            'winner': 'b',
            'whiteTimeMs': 0,
            'blackTimeMs': blackTimeMs,
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          throw Exception('White ran out of time');
        }
      } else {
        blackTimeMs = blackTimeMs - elapsedMs;
        if (blackTimeMs <= 0) {
          tx.update(gameRef, {
            'status': 'ended',
            'winner': 'w',
            'whiteTimeMs': whiteTimeMs,
            'blackTimeMs': 0,
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          throw Exception('Black ran out of time');
        }
      }

      final newFen = chess.fen;
      final moveStr = '${move.from}${move.to}${move.promotion?.name ?? ''}';
      final moves = List<String>.from(data['moves'] ?? const []);
      moves.add(moveStr);
      tx.update(gameRef, {
        'fen': newFen,
        'lastMove': moveStr,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastTurnAt': FieldValue.serverTimestamp(),
        'whiteTimeMs': whiteTimeMs,
        'blackTimeMs': blackTimeMs,
        'moves': moves,
      });
    });
  }

  Future<void> _ensureAutoJoin(DocumentReference<Map<String, dynamic>> gameRef,
      GameController gameCtrl, BoardUiController boardCtrl) async {
    if (gameCtrl.joinAttempted.value) return;
    gameCtrl.joinAttempted.value = true;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(gameRef);
        if (!snap.exists) {
          throw Exception('Game not found');
        }
        final data = snap.data()!;
        final players = Map<String, dynamic>.from(data['players'] ?? const {});
        if (players.containsKey(playerId)) return;
        final whiteTaken = players.values.contains('w');
        final blackTaken = players.values.contains('b');
        String? assignColor;
        if (!whiteTaken) {
          assignColor = 'w';
        } else if (!blackTaken) {
          assignColor = 'b';
        }
        if (assignColor == null) {
          return;
        }
        players[playerId] = assignColor;
        tx.update(gameRef, {
          'players': players,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Default orientation based on assignment
        boardCtrl.blackAtBottom.value = assignColor == 'b';
      });
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _commitTimeoutIfNeeded(
      DocumentReference<Map<String, dynamic>> gameRef,
      String winnerColor,
      GameController gameCtrl) async {
    if (gameCtrl.committingTimeout.value) return;
    gameCtrl.committingTimeout.value = true;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(gameRef);
        if (!snap.exists) return;
        final data = snap.data()!;
        if ((data['status'] as String?) == 'ended') return;
        final serverFen =
            (data['fen'] as String?) ?? chesslib.Chess.DEFAULT_POSITION;
        final sideToMoveIsWhite = serverFen.split(' ')[1] == 'w';
        final players = Map<String, dynamic>.from(data['players'] ?? const {});
        final moves = List<String>.from(data['moves'] ?? const []);
        final bothSeated =
            players.values.contains('w') && players.values.contains('b');
        final clocksActive = bothSeated && moves.isNotEmpty;
        if (!clocksActive) return;
        final lastTurnTs = data['lastTurnAt'] as Timestamp?;
        final lastTurnAt = lastTurnTs?.toDate() ?? DateTime.now();
        final now = DateTime.now();
        int whiteTimeMs = (data['whiteTimeMs'] as int?) ?? initialTimeMs;
        int blackTimeMs = (data['blackTimeMs'] as int?) ?? initialTimeMs;
        final elapsedMs = now.difference(lastTurnAt).inMilliseconds;
        int loserRemaining = sideToMoveIsWhite
            ? (whiteTimeMs - elapsedMs)
            : (blackTimeMs - elapsedMs);
        if (loserRemaining > 0) return;
        tx.update(gameRef, {
          'status': 'ended',
          'winner': winnerColor,
          'whiteTimeMs': sideToMoveIsWhite ? 0 : whiteTimeMs,
          'blackTimeMs': sideToMoveIsWhite ? blackTimeMs : 0,
          'endedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {
    } finally {
      gameCtrl.committingTimeout.value = false;
    }
  }

  Widget _reviewToggle(BoardUiController boardCtrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Review Mode'),
            const SizedBox(width: 10),
            Switch(
              value: boardCtrl.reviewMode.value,
              onChanged: (v) {
                boardCtrl.setReviewMode(v);
                if (v) {
                  boardCtrl.goToEnd();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardOnly({
    required BoardUiController boardCtrl,
    required String fen,
    BoardArrow? lastArrow,
    required Future<void> Function({required ShortMove move}) onMove,
    required bool blackSideAtBottom,
    bool isInteractive = true,
    String? nonInteractiveText,
    bool engineThinking = false,
    required BuildContext context,
  }) {
    return Center(
      child: SimpleChessBoard(
        key: ValueKey('board-${blackSideAtBottom ? 'b' : 'w'}'),
        engineThinking: engineThinking,
        fen: fen,
        onMove: onMove,
        blackSideAtBottom: blackSideAtBottom,
        whitePlayerType: PlayerType.human,
        blackPlayerType: PlayerType.human,
        isInteractive: isInteractive,
        nonInteractiveText: nonInteractiveText ?? "",
        showPossibleMoves: true,
        // Highlight the king if the side to move is in check.
        cellHighlights: _computeKingInCheckHighlights(fen),
        normalMoveIndicatorBuilder: (cellSize) => SizedBox(
          width: cellSize,
          height: cellSize,
          child: Center(
            child: AnimatedContainer(
              width: cellSize * 0.3,
              height: cellSize * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.cyan.withOpacity(0.7),
              ),
              duration: const Duration(milliseconds: 120),
            ),
          ),
        ),
        captureMoveIndicatorBuilder: (cellSize) => Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: MyColors.red,
              width: cellSize * 0.05,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Icon(
              Icons.close,
              color: MyColors.red,
              size: cellSize * 0.5,
            ),
          ),
        ),
        onPromote: () => handlePromotion(context),
        chessBoardColors: ChessBoardColors()
          ..lightSquaresColor = MyColors.lightGray
          ..darkSquaresColor = MyColors.tealGray
          ..coordinatesZoneColor = MyColors.cardBackground
          ..lastMoveArrowColor = MyColors.amber
          ..circularProgressBarColor = MyColors.transparent
          ..coordinatesColor = MyColors.white
          ..startSquareColor = MyColors.orange
          ..endSquareColor = MyColors.cyan
          ..possibleMovesColor = MyColors.mediumGray.withAlpha(128)
          ..dndIndicatorColor = MyColors.mediumGray.withAlpha(64),
        onPromotionCommited: ({required moveDone, required pieceType}) async {
          moveDone.promotion = pieceType;
          await onMove(move: moveDone);
        },
        onTap: ({required cellCoordinate}) {},
        highlightLastMoveSquares: true,
        lastMoveToHighlight: lastArrow ?? boardCtrl.lastMoveArrow.value,
        showCoordinatesZone: true,
        nonInteractiveTextStyle: const TextStyle(
          color: MyColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
        nonInteractiveOverlayColor: MyColors.tealGray,
        onCapturedPiecesChanged: ({
          required List<PieceType> whiteCapturedPieces,
          required List<PieceType> blackCapturedPieces,
        }) {
          boardCtrl.setCapturedPieces(
            white: whiteCapturedPieces,
            black: blackCapturedPieces,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controllers exist
    final gameCtrl = Get.put(GameController(), tag: gameId);
    final boardCtrl = Get.put(BoardUiController(), tag: 'board-$gameId');
    gameCtrl.ensureUiTickStarted();
    // Do not reset reactive flags here; controllers manage their own defaults

    final gameDoc = games.doc(gameId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Game'),
        actions: [
          _reviewToggle(boardCtrl),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: gameDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            if (!gameCtrl.createdMissingGame.value) {
              gameCtrl.createdMissingGame.value = true;
              games.doc(gameId).set({
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
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data()!;
          final players =
              Map<String, dynamic>.from(data['players'] ?? const {});
          final playerColor = players[playerId] as String?;
          if (playerColor == null &&
              (!players.values.contains('w') ||
                  !players.values.contains('b'))) {
            // Attempt auto-join, but continue to render a friendly waiting UI below.
            _ensureAutoJoin(gameDoc, gameCtrl, boardCtrl);
          }
          final fen =
              (data['fen'] as String?) ?? chesslib.Chess.DEFAULT_POSITION;
          final fenParts = fen.split(' ');
          final sideToMoveIsWhite =
              fenParts.length > 1 ? fenParts[1] == 'w' : true;
          final status = (data['status'] as String?) ?? 'ongoing';
          final winnerColor = data['winner'] as String?;
          int whiteTimeMs = (data['whiteTimeMs'] as int?) ?? initialTimeMs;
          int blackTimeMs = (data['blackTimeMs'] as int?) ?? initialTimeMs;
          final lastTurnTs = data['lastTurnAt'] as Timestamp?;
          final lastTurnAt = lastTurnTs?.toDate();
          final moves = List<String>.from(data['moves'] ?? const []);
          final moveCount = moves.length;
          final bothSeated =
              players.values.contains('w') && players.values.contains('b');

          // Sync move history into controller for review
          boardCtrl.syncMoveHistory(moves);

          // Update game controller reactive state
          gameCtrl.updateFromSnapshot(
            newFen: fen,
            newStatus: status,
            newWinner: winnerColor,
            newWhiteTimeMs: whiteTimeMs,
            newBlackTimeMs: blackTimeMs,
            newLastTurnAt: lastTurnAt,
            newMoveCount: moveCount,
            newBothSeated: bothSeated,
          );

          final lastMoveStr = data['lastMove'] as String?;
          BoardArrow? lastArrow;
          if (lastMoveStr != null && lastMoveStr.length >= 4) {
            lastArrow = BoardArrow(
              from: lastMoveStr.substring(0, 2),
              to: lastMoveStr.substring(2, 4),
            );
          }

          if (status == 'ended' &&
              winnerColor != null &&
              !gameCtrl.endedDialogShown.value) {
            gameCtrl.endedDialogShown.value = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showEndDialog(
                context: context,
                winnerColor: winnerColor,
                moves: moves,
                playerColor: playerColor,
              );
            });
            if (!gameCtrl.historyUploaded.value) {
              gameCtrl.historyUploaded.value = true;
              Future.microtask(() async {
                try {
                  await GameHistoryUploader.uploadGameHistory(
                    gameId: gameId,
                    playerId: playerId,
                    winnerColor: winnerColor,
                    history: boardCtrl.moveHistory.history,
                  );
                } catch (_) {}
              });
            }
          }

          Future<void> submitMove({required ShortMove move}) async {
            try {
              if (playerColor == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('You are spectating. Join to play.')),
                );
                return;
              }
              boardCtrl.setSubmitting(true);
              await _tryMoveTransactional(move: move, currentFen: fen);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Move rejected: Is\'s not you turn!')),
              );
            } finally {
              boardCtrl.setSubmitting(false);
            }
          }

          // Timeout check
          if (status == 'ongoing' && (bothSeated && moveCount > 0)) {
            final now = DateTime.now();
            final elapsedMs = lastTurnAt != null
                ? now.difference(lastTurnAt).inMilliseconds
                : 0;
            final whiteRemain =
                whiteTimeMs - (sideToMoveIsWhite ? elapsedMs : 0);
            final blackRemain =
                blackTimeMs - (!sideToMoveIsWhite ? elapsedMs : 0);
            final timedOutWhite = sideToMoveIsWhite && whiteRemain <= 0;
            final timedOutBlack = !sideToMoveIsWhite && blackRemain <= 0;
            if (timedOutWhite) {
              _commitTimeoutIfNeeded(gameDoc, 'b', gameCtrl);
            } else if (timedOutBlack) {
              _commitTimeoutIfNeeded(gameDoc, 'w', gameCtrl);
            }
          }

          // Labels
          String? whitePlayerId;
          String? blackPlayerId;
          for (final entry in players.entries) {
            if (entry.value == 'w') whitePlayerId = entry.key;
            if (entry.value == 'b') blackPlayerId = entry.key;
          }
          final whiteLabelWidget = Obx(() => Text(
                'White: ${whitePlayerId ?? 'Waiting'}   ${gameCtrl.whiteLabel.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ));
          final blackLabelWidget = Obx(() => Text(
                'Black: ${blackPlayerId ?? 'Waiting'}   ${gameCtrl.blackLabel.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ));

          // Waiting screen: show until both players have joined
          if (!bothSeated) {
            if (playerColor == null) {
              // Try auto-assign again in case it races with render
              _ensureAutoJoin(gameDoc, gameCtrl, boardCtrl);
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Waiting for opponent to join…',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: whiteLabelWidget,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: blackLabelWidget,
                ),
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  'Room ID: $gameId',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share the Room ID with your friend to join.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            );
          }

          if (playerColor == null && bothSeated) {
            // Spectator view
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (status == 'ended' && winnerColor != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                        'Game over. Winner: ${winnerColor == 'w' ? 'White' : 'Black'}'),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('Game is full. You are spectating.'),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: blackLabelWidget,
                ),
                Obx(() => CapturedPiecesStrip(
                      pieces: boardCtrl.blackCaptured.toList(),
                      showAsBlackPieces: false,
                    )),
                Obx(() => Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white)),
                      child: _boardOnly(
                        boardCtrl: boardCtrl,
                        fen: boardCtrl.reviewMode.value
                            ? boardCtrl.moveHistory.currentFen
                            : fen,
                        lastArrow: boardCtrl.reviewMode.value
                            ? boardCtrl.reviewArrow.value
                            : lastArrow,
                        onMove: ({required ShortMove move}) async =>
                            submitMove(move: move),
                        blackSideAtBottom: false,
                        isInteractive: false,
                        nonInteractiveText: boardCtrl.reviewMode.value
                            ? 'REVIEW MODE'
                            : 'SPECTATING',
                        engineThinking: false,
                        context: context,
                      ),
                    )),
                Obx(() {
                  // Depend on reviewIndex to trigger rebuild when navigating/syncing
                  final _ = boardCtrl.reviewIndex.value;
                  return boardCtrl.reviewMode.value
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: MoveNavigationControls(
                            moveHistory: boardCtrl.moveHistory,
                            onGoBack: () => boardCtrl.goBack(),
                            onGoForward: () => boardCtrl.goForward(),
                            onGoToStart: () => boardCtrl.goToStart(),
                            onGoToEnd: () => boardCtrl.goToEnd(),
                          ),
                        )
                      : const SizedBox.shrink();
                }),
                Obx(() => CapturedPiecesStrip(
                      pieces: boardCtrl.whiteCaptured.toList(),
                      showAsBlackPieces: true,
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: whiteLabelWidget,
                ),
              ],
            );
          }

          // Player view
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // _reviewToggle(boardCtrl),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child:
                    (playerColor == 'b') ? whiteLabelWidget : blackLabelWidget,
              ),
              Obx(() {
                final topPieces = (playerColor == 'b')
                    ? boardCtrl.whiteCaptured.toList()
                    : boardCtrl.blackCaptured.toList();
                final showBlackIcons = (playerColor == 'b') ? true : false;
                return CapturedPiecesStrip(
                  pieces: topPieces,
                  showAsBlackPieces: showBlackIcons,
                );
              }),
              Obx(() => Container(
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.white)),
                    child: _boardOnly(
                      boardCtrl: boardCtrl,
                      fen: boardCtrl.reviewMode.value
                          ? boardCtrl.moveHistory.currentFen
                          : fen,
                      lastArrow: boardCtrl.reviewMode.value
                          ? boardCtrl.reviewArrow.value
                          : lastArrow,
                      onMove: ({required ShortMove move}) async =>
                          submitMove(move: move),
                      blackSideAtBottom: playerColor == 'b',
                      isInteractive: !boardCtrl.reviewMode.value,
                      nonInteractiveText:
                          boardCtrl.reviewMode.value ? 'REVIEW MODE' : null,
                      engineThinking: false,
                      context: context,
                    ),
                  )),
              Obx(() {
                final bottomPieces = (playerColor == 'b')
                    ? boardCtrl.blackCaptured.toList()
                    : boardCtrl.whiteCaptured.toList();
                final showBlackIcons = (playerColor == 'w') ? true : false;
                return CapturedPiecesStrip(
                  pieces: bottomPieces,
                  showAsBlackPieces: showBlackIcons,
                );
              }),
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child:
                    (playerColor == 'b') ? blackLabelWidget : whiteLabelWidget,
              ),
              Obx(() {
                // Depend on reviewIndex to trigger rebuild when navigating/syncing
                final _ = boardCtrl.reviewIndex.value;
                return boardCtrl.reviewMode.value
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: MoveNavigationControls(
                          moveHistory: boardCtrl.moveHistory,
                          onGoBack: () => boardCtrl.goBack(),
                          onGoForward: () => boardCtrl.goForward(),
                          onGoToStart: () => boardCtrl.goToStart(),
                          onGoToEnd: () => boardCtrl.goToEnd(),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          );
        },
      ),
    );
  }
}
