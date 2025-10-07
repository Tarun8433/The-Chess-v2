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

class OnlineCustomMoveIndicator extends StatefulWidget {
  final String gameId;
  final String playerId;
  final int initialTimeMs;

  const OnlineCustomMoveIndicator({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.initialTimeMs,
  });

  @override
  State<OnlineCustomMoveIndicator> createState() =>
      _OnlineCustomMoveIndicatorState();
}

class _OnlineCustomMoveIndicatorState extends State<OnlineCustomMoveIndicator> {
  bool blackAtBottom = false;
  BoardArrow? _lastMoveArrowCoordinates;
  final _highlightCells = <String, Color>{};
  bool _createdMissingGame = false;
  bool _joinAttempted = false;
  bool _committingTimeout = false;
  bool _endedDialogShown = false;
  bool _historyUploaded = false;
  late final GameController gameCtrl;
  late final BoardUiController boardCtrl;
  // Captured strips now reactive via boardCtrl

  // Review Mode state
  bool _reviewMode = false;
  MoveHistory _moveHistory =
      MoveHistory(initialFen: chesslib.Chess.DEFAULT_POSITION);
  int _lastSyncedMoveCount = 0;

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

  @override
  void initState() {
    super.initState();
    gameCtrl = Get.put(GameController(), tag: widget.gameId);
    boardCtrl = Get.put(BoardUiController(), tag: 'board-${widget.gameId}');
    gameCtrl.startUiTick();
    // Initialize GetX flags
    boardCtrl.setReviewMode(false);
    boardCtrl.setSubmitting(false);
  }

  @override
  void dispose() {
    // Remove controller for this gameId
    Get.delete<GameController>(tag: widget.gameId, force: true);
    Get.delete<BoardUiController>(tag: 'board-${widget.gameId}', force: true);
    super.dispose();
  }

  void _syncMoveHistory(List<String> moves) {
    // Only rebuild when move count changes to avoid setState loops
    if (moves.length == _lastSyncedMoveCount) return;
    final mh = MoveHistory(initialFen: chesslib.Chess.DEFAULT_POSITION);
    final chess = chesslib.Chess.fromFEN(chesslib.Chess.DEFAULT_POSITION);
    for (final m in moves) {
      if (m.length < 4) continue;
      final from = m.substring(0, 2);
      final to = m.substring(2, 4);
      final promotion = m.length > 4 ? m.substring(4, 5) : null;
      final success = chess.move(<String, String?>{
        'from': from,
        'to': to,
        'promotion': promotion,
      });
      if (!success) {
        // If a move fails, stop syncing further to avoid wrong snapshots
        break;
      }
      mh.addMove(move: m, fen: chess.fen);
    }
    // Update local state without setState, since we are inside a StreamBuilder build
    _moveHistory = mh;
    _lastSyncedMoveCount = moves.length;
    // When not reviewing, follow live at end
    if (!_reviewMode) {
      if (_moveHistory.length > 0) {
        _moveHistory.goToIndex(_moveHistory.length - 1);
      } else {
        _moveHistory.goToIndex(-1);
      }
    } else {
      // Clamp index if new moves appended
      if (_moveHistory.currentIndex > _moveHistory.length - 1) {
        _moveHistory.goToIndex(_moveHistory.length - 1);
      }
    }
  }

  BoardArrow? _reviewArrow() {
    final idx = _moveHistory.currentIndex;
    final m = _moveHistory.getMoveAt(idx);
    if (m == null) return null;
    final mv = m.move;
    if (mv.length < 4) return null;
    return BoardArrow(from: mv.substring(0, 2), to: mv.substring(2, 4));
  }

  Widget _reviewToggle() {
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
                setState(() {
                  _reviewMode = v;
                  // When entering review, default to end of history
                  if (v) {
                    if (_moveHistory.length > 0) {
                      _moveHistory.goToIndex(_moveHistory.length - 1);
                    } else {
                      _moveHistory.goToIndex(-1);
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEndDialog({
    required String winnerColor,
    required List<String> moves,
    String? playerColor,
  }) {
    void _printMoves(List<String> mvs) {
      debugPrint('===== Game history (${mvs.length} moves) =====');
      for (int i = 0; i < mvs.length; i++) {
        debugPrint('${i + 1}. ${mvs[i]}');
      }
      debugPrint('===== End history =====');
    }

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
            // Print history when back is pressed; keep dialog open
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
                  // Print and navigate home
                  _printMoves(moves);
                  Navigator.of(context).pop(); // close dialog
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

  Future<void> _tryMoveTransactional(
      {required ShortMove move, required String currentFen}) async {
    final gameRef = games.doc(widget.gameId);
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
      final playerColor =
          data['players']?[widget.playerId] as String?; // 'w' or 'b'
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
      int whiteTimeMs = (data['whiteTimeMs'] as int?) ?? widget.initialTimeMs;
      int blackTimeMs = (data['blackTimeMs'] as int?) ?? widget.initialTimeMs;
      final prevMoveCount = List<String>.from(data['moves'] ?? const []).length;
      // Clocks are active only if both seated and at least one move exists
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

  Future<void> _ensureAutoJoin(
      DocumentReference<Map<String, dynamic>> gameRef) async {
    if (_joinAttempted) return;
    _joinAttempted = true;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(gameRef);
        if (!snap.exists) {
          throw Exception('Game not found');
        }
        final data = snap.data()!;
        final players = Map<String, dynamic>.from(data['players'] ?? const {});
        // If already assigned, do nothing
        if (players.containsKey(widget.playerId)) return;
        final whiteTaken = players.values.contains('w');
        final blackTaken = players.values.contains('b');
        // Assign first available color; prefer white, else black
        String? assignColor;
        if (!whiteTaken) {
          assignColor = 'w';
        } else if (!blackTaken) {
          assignColor = 'b';
        }
        if (assignColor == null) {
          // Both seats taken; remain spectator
          return;
        }
        players[widget.playerId] = assignColor;
        tx.update(gameRef, {
          'players': players,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Default orientation based on assignment
        blackAtBottom = assignColor == 'b';
      });
      setState(() {});
    } catch (_) {
      // Ignore errors; user will spectate if join fails
    }
  }

  Future<void> _commitTimeoutIfNeeded(
      DocumentReference<Map<String, dynamic>> gameRef,
      String winnerColor) async {
    if (_committingTimeout) return;
    _committingTimeout = true;
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
        if (!clocksActive) return; // clocks not started yet
        final lastTurnTs = data['lastTurnAt'] as Timestamp?;
        final lastTurnAt = lastTurnTs?.toDate() ?? DateTime.now();
        final now = DateTime.now();
        int whiteTimeMs = (data['whiteTimeMs'] as int?) ?? widget.initialTimeMs;
        int blackTimeMs = (data['blackTimeMs'] as int?) ?? widget.initialTimeMs;
        final elapsedMs = now.difference(lastTurnAt).inMilliseconds;
        int loserRemaining = sideToMoveIsWhite
            ? (whiteTimeMs - elapsedMs)
            : (blackTimeMs - elapsedMs);
        if (loserRemaining > 0) return; // Not yet timed out
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
      // Ignore
    } finally {
      _committingTimeout = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameDoc = games.doc(widget.gameId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Game'),
        // Orientation now follows player color automatically
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: gameDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            if (!_createdMissingGame) {
              _createdMissingGame = true;
              // Auto-create game document with empty players map
              games.doc(widget.gameId).set({
                'fen': chesslib.Chess.DEFAULT_POSITION,
                'moves': <String>[],
                'updatedAt': FieldValue.serverTimestamp(),
                'players': <String, String>{},
                'whiteTimeMs': widget.initialTimeMs,
                'blackTimeMs': widget.initialTimeMs,
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
          final playerColor = players[widget.playerId] as String?;
          // Auto-join if a seat is open
          if (playerColor == null &&
              (!players.values.contains('w') ||
                  !players.values.contains('b'))) {
            _ensureAutoJoin(gameDoc);
            return const Center(child: CircularProgressIndicator());
          }
          final fen =
              (data['fen'] as String?) ?? chesslib.Chess.DEFAULT_POSITION;
          final sideToMoveIsWhite = fen.split(' ')[1] == 'w';
          final status = (data['status'] as String?) ?? 'ongoing';
          final winnerColor = data['winner'] as String?;
          int whiteTimeMs =
              (data['whiteTimeMs'] as int?) ?? widget.initialTimeMs;
          int blackTimeMs =
              (data['blackTimeMs'] as int?) ?? widget.initialTimeMs;
          final lastTurnTs = data['lastTurnAt'] as Timestamp?;
          final lastTurnAt = lastTurnTs?.toDate();
          final moves = List<String>.from(data['moves'] ?? const []);
          final moveCount = moves.length;
          final bothSeated =
              players.values.contains('w') && players.values.contains('b');
          // Sync local move history snapshots for Review Mode
          _syncMoveHistory(moves);
          // Update controller from snapshot for reactive labels
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
                to: lastMoveStr.substring(2, 4));
          }

          // Show end-of-game dialog once when stream reports ended
          if (status == 'ended' && winnerColor != null && !_endedDialogShown) {
            _endedDialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showEndDialog(
                winnerColor: winnerColor,
                moves: moves,
                playerColor: playerColor,
              );
            });
            // Trigger one-time upload of game history
            if (!_historyUploaded) {
              _historyUploaded = true;
              // Use local synced history snapshots
              Future.microtask(() async {
                try {
                  await GameHistoryUploader.uploadGameHistory(
                    gameId: widget.gameId,
                    playerId: widget.playerId,
                    winnerColor: winnerColor,
                    history: _moveHistory.history,
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
              // Avoid local setState to reduce flicker; rely on stream update
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Move rejected: $e')),
              );
            } finally {
              boardCtrl.setSubmitting(false);
            }
          }

          final whiteTaken = players.values.contains('w');
          final blackTaken = players.values.contains('b');
          // Derive player labels for display
          String? whitePlayerId;
          String? blackPlayerId;
          for (final entry in players.entries) {
            if (entry.value == 'w') whitePlayerId = entry.key;
            if (entry.value == 'b') blackPlayerId = entry.key;
          }
          // Labels driven by GetX controller, only text rebuilds
          final whiteLabelWidget = Obx(() => Text(
                'White: ${whitePlayerId ?? 'Waiting'}  ${gameCtrl.whiteLabel.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ));
          final blackLabelWidget = Obx(() => Text(
                'Black: ${blackPlayerId ?? 'Waiting'}  ${gameCtrl.blackLabel.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ));

          // If clock expired on side to move and game not ended, commit timeout
          // Timers only active after both seated and at least one move (white moved)
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
              _commitTimeoutIfNeeded(gameDoc, 'b');
            } else if (timedOutBlack) {
              _commitTimeoutIfNeeded(gameDoc, 'w');
            }
          }

          if (playerColor == null && whiteTaken && blackTaken) {
            // Game is full; allow spectating but prevent moving
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _reviewToggle(),
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
                // Top captured strip for spectator view: top is Black
                Obx(() => CapturedPiecesStrip(
                      pieces: boardCtrl.blackCaptured.toList(),
                      showAsBlackPieces: false,
                    )),
                Obx(() => Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white)),
                      child: _boardOnly(
                        fen: boardCtrl.reviewMode.value
                            ? _moveHistory.currentFen
                            : fen,
                        lastArrow: boardCtrl.reviewMode.value
                            ? _reviewArrow()
                            : lastArrow,
                        onMove: ({required ShortMove move}) async =>
                            submitMove(move: move),
                        blackSideAtBottom: false,
                        isInteractive: false,
                        nonInteractiveText: boardCtrl.reviewMode.value
                            ? 'REVIEW MODE'
                            : 'SPECTATING',
                        engineThinking: boardCtrl.isSubmitting.value &&
                            !boardCtrl.reviewMode.value,
                      ),
                    )),
                Obx(() => boardCtrl.reviewMode.value
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: MoveNavigationControls(
                          moveHistory: _moveHistory,
                          onGoBack: () => setState(() {
                            _moveHistory.goBack();
                          }),
                          onGoForward: () => setState(() {
                            _moveHistory.goForward();
                          }),
                          onGoToStart: () => setState(() {
                            _moveHistory.goToIndex(-1);
                          }),
                          onGoToEnd: () => setState(() {
                            if (_moveHistory.length > 0) {
                              _moveHistory.goToIndex(_moveHistory.length - 1);
                            }
                          }),
                        ),
                      )
                    : const SizedBox.shrink()),
                // Bottom captured strip: bottom is White
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

          // No manual join; auto-assignment handles seating

          // Already a player: render interactive board
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _reviewToggle(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child:
                    (playerColor == 'b') ? whiteLabelWidget : blackLabelWidget,
              ),
              // Top captured strip shows pieces captured by the opponent at top
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
                      fen: boardCtrl.reviewMode.value
                          ? _moveHistory.currentFen
                          : fen,
                      lastArrow: boardCtrl.reviewMode.value
                          ? _reviewArrow()
                          : lastArrow,
                      onMove: ({required ShortMove move}) async =>
                          submitMove(move: move),
                      blackSideAtBottom: playerColor == 'b',
                      isInteractive: !boardCtrl.reviewMode.value,
                      nonInteractiveText:
                          boardCtrl.reviewMode.value ? 'REVIEW MODE' : null,
                      engineThinking: boardCtrl.isSubmitting.value &&
                          !boardCtrl.reviewMode.value,
                    ),
                  )),
              Obx(() => boardCtrl.reviewMode.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: MoveNavigationControls(
                        moveHistory: _moveHistory,
                        onGoBack: () => setState(() {
                          _moveHistory.goBack();
                        }),
                        onGoForward: () => setState(() {
                          _moveHistory.goForward();
                        }),
                        onGoToStart: () => setState(() {
                          _moveHistory.goToIndex(-1);
                        }),
                        onGoToEnd: () => setState(() {
                          if (_moveHistory.length > 0) {
                            _moveHistory.goToIndex(_moveHistory.length - 1);
                          }
                        }),
                      ),
                    )
                  : const SizedBox.shrink()),
              // Bottom captured strip shows pieces captured by the player at bottom
              Obx(() {
                final bottomPieces = (playerColor == 'b')
                    ? boardCtrl.blackCaptured.toList()
                    : boardCtrl.whiteCaptured.toList();
                final showBlackIcons = (playerColor == 'b') ? false : true;
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
            ],
          );
        },
      ),
    );
  }

  Widget _boardOnly(
      {required String fen,
      BoardArrow? lastArrow,
      required Future<void> Function({required ShortMove move}) onMove,
      required bool blackSideAtBottom,
      bool isInteractive = true,
      String? nonInteractiveText,
      bool engineThinking = false}) {
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
        normalMoveIndicatorBuilder: (cellSize) => SizedBox(
          width: cellSize,
          height: cellSize,
          child: Center(
            child: AnimatedContainer(
              width: cellSize * 0.3,
              height: cellSize * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.cyan.withValues(alpha: 0.7),
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
        cellHighlights: _highlightCells,
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
        lastMoveToHighlight: lastArrow ?? _lastMoveArrowCoordinates,
        showCoordinatesZone: true,
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
          boardCtrl.setCapturedPieces(
            white: whiteCapturedPieces,
            black: blackCapturedPieces,
          );
        },
      ),
    );
  }
}
