import 'package:flutter/material.dart';

class EndgameDialogManager {
  static Future<void> _showSummary({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<String> moves = const <String>[],
    String? winnerColor, // 'w' or 'b'
    String? playerColor, // 'w' or 'b'
  }) async {
    final youWon = winnerColor != null && playerColor != null && playerColor == winnerColor;
    final youLost = winnerColor != null && playerColor != null && playerColor != winnerColor;
    final finalTitle = youWon
        ? 'You won — $title'
        : youLost
            ? 'You lost — $title'
            : title;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(finalTitle),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(subtitle),
                    ),
                  if (moves.isNotEmpty) const Text('Game history:'),
                  if (moves.isNotEmpty) const SizedBox(height: 6),
                  if (moves.isNotEmpty)
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

  // Normal Game Endings
  static Future<void> showCheckmate({
    required BuildContext context,
    required List<String> moves,
    String? winnerColor,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Checkmate',
        subtitle: winnerColor == 'w' ? 'Winner: White' : winnerColor == 'b' ? 'Winner: Black' : null,
        moves: moves,
        winnerColor: winnerColor,
        playerColor: playerColor,
      );

  static Future<void> showResignation({
    required BuildContext context,
    required List<String> moves,
    String? winnerColor,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Resignation',
        subtitle: winnerColor == 'w' ? 'Winner: White' : winnerColor == 'b' ? 'Winner: Black' : null,
        moves: moves,
        winnerColor: winnerColor,
        playerColor: playerColor,
      );

  static Future<void> showTimeout({
    required BuildContext context,
    required List<String> moves,
    String? winnerColor,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Timeout / Flag fall',
        subtitle: winnerColor == 'w' ? 'Winner: White' : winnerColor == 'b' ? 'Winner: Black' : null,
        moves: moves,
        winnerColor: winnerColor,
        playerColor: playerColor,
      );

  static Future<void> showStalemate({
    required BuildContext context,
    required List<String> moves,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Draw — Stalemate',
        moves: moves,
        playerColor: playerColor,
      );

  static Future<void> showDrawByAgreement({
    required BuildContext context,
    required List<String> moves,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Draw — Agreement',
        moves: moves,
        playerColor: playerColor,
      );

  static Future<void> showInsufficientMaterial({
    required BuildContext context,
    required List<String> moves,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Draw — Insufficient material',
        moves: moves,
        playerColor: playerColor,
      );

  // static Future<void> showThreefoldRepetition({
  //   required BuildContext context,
  //   required List<String> moves,
  //   String? playerColor,
  // }) => _showSummary(
  //       context: context,
  //       title: 'Draw — Threefold repetition',
  //       moves: moves,
  //       playerColor: playerColor,
  //     );

  // static Future<void> showFiftyMoveRule({
  //   required BuildContext context,
  //   required List<String> moves,
  //   String? playerColor,
  // }) => _showSummary(
  //       context: context,
  //       title: 'Draw — 50-move rule',
  //       moves: moves,
  //       playerColor: playerColor,
  //     );

  static Future<void> showDrawClaim({
    required BuildContext context,
    required String claimReason,
    required List<String> moves,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Draw — $claimReason',
        moves: moves,
        playerColor: playerColor,
      );

  // Technical/Connection Issues
  static Future<void> showDisconnection({
    required BuildContext context,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Disconnected',
        subtitle: 'You have been disconnected. Trying to reconnect…',
        playerColor: playerColor,
      );

  static Future<void> showAbandonedGame({
    required BuildContext context,
    required List<String> moves,
    String? winnerColor,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Game Abandoned',
        subtitle: winnerColor == null
            ? 'Game ended due to abandonment.'
            : (winnerColor == 'w' ? 'Winner: White' : 'Winner: Black'),
        moves: moves,
        winnerColor: winnerColor,
        playerColor: playerColor,
      );

  static Future<void> showServerCrash({
    required BuildContext context,
  }) => _showSummary(
        context: context,
        title: 'Server Issue',
        subtitle: 'A server error occurred. Please try again later.',
      );

  static Future<void> showInternetLost({
    required BuildContext context,
  }) => _showSummary(
        context: context,
        title: 'Internet Connection Lost',
        subtitle: 'Please check your connection and retry.',
      );

  // Platform-Specific Outcomes
  static Future<void> showAutomaticLossDisconnection({
    required BuildContext context,
    required List<String> moves,
    String? winnerColor,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Automatic Loss (Disconnection)',
        subtitle: winnerColor == 'w' ? 'Winner: White' : winnerColor == 'b' ? 'Winner: Black' : null,
        moves: moves,
        winnerColor: winnerColor,
        playerColor: playerColor,
      );

  static Future<void> showGameAborted({
    required BuildContext context,
    List<String> moves = const <String>[],
  }) => _showSummary(
        context: context,
        title: 'Game Aborted',
        subtitle: 'The game was aborted in the opening phase.',
        moves: moves,
      );

  static Future<void> showFairPlayViolation({
    required BuildContext context,
    required String message,
    List<String> moves = const <String>[],
  }) => _showSummary(
        context: context,
        title: 'Fair Play Violation',
        subtitle: message,
        moves: moves,
      );

  static Future<void> showTimeoutWithInsufficientMaterial({
    required BuildContext context,
    required List<String> moves,
    String? playerColor,
  }) => _showSummary(
        context: context,
        title: 'Draw — Timeout with Insufficient Material',
        moves: moves,
        playerColor: playerColor,
      );
}