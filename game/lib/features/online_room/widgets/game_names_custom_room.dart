// import 'package:flutter/material.dart';
// import 'package:simple_chess_board_usage/theme/my_colors.dart';
// import 'online_custom_move_indicator.dart';

// /// A custom room widget that shows the game name (gameId) in the AppBar
// /// and composes the existing online room gameplay UI.
// class GameNamesCustomRoom extends StatelessWidget {
//   final String gameId;
//   final String playerId;
//   final int initialTimeMs;

//   const GameNamesCustomRoom({
//     super.key,
//     required this.gameId,
//     required this.playerId,
//     required this.initialTimeMs,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: MyColors.lightGraydark,
//         title: Text('Room: $gameId'),
//       ),
//       body: OnlineCustomMoveIndicator(
//         gameId: gameId,
//         playerId: playerId,
//         initialTimeMs: initialTimeMs,
//       ),
//     );
//   }
// }
