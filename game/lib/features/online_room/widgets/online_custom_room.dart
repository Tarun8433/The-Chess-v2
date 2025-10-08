import 'package:flutter/material.dart';
import 'online_custom_move_indicator.dart';

/// A lightweight copy of the online room widget that wraps
/// [OnlineCustomMoveIndicator] for custom room flows (e.g., named rooms).
///
/// Use this when you want a distinct widget/class name for routing or
/// feature toggles without duplicating the underlying game logic.
class OnlineCustomRoom extends StatelessWidget {
  final String gameId;
  final String playerId;
  final int initialTimeMs;

  const OnlineCustomRoom({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.initialTimeMs,
  });

  @override
  Widget build(BuildContext context) {
    return OnlineCustomMoveIndicator(
      gameId: gameId,
      playerId: playerId,
      initialTimeMs: initialTimeMs,
    );
  }
}