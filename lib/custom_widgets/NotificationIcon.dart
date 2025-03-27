// import 'dart:async';
// import 'package:flutter/material.dart';
// // import 'package:flutter_application/services/NotificationService.dart';

// class NotificationIcon extends StatefulWidget {
//   const NotificationIcon({super.key});

//   @override
//   State<NotificationIcon> createState() => _NotificationIconState();
// }

// class _NotificationIconState extends State<NotificationIcon> {
//   int notificationCount = 0;
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     //_fetchNotificationCount();
//     _startPolling();
//   }

//   // Future<void> _fetchNotificationCount() async {
//   //   int count = await NotificationService().fetchNotificationCount();
//   //   setState(() => notificationCount = count);
//   // }

//   void _startPolling() {
//     // _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchNotificationCount());
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 40, // Largeur adaptée à l'icône
//       height: 40, // Hauteur adaptée à l'icône
//       child: Stack(
//         clipBehavior: Clip.none, // Permet au badge de déborder
//         children: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.black, size: 30),
//             padding: EdgeInsets.zero, // Supprime le padding par défaut
//             onPressed: () => Navigator.pushNamed(context, '/notifications'),
//           ),
//           if (notificationCount > 0)
//             Positioned(
//               right: -2, // Ajustement de position
//               top: -2,   // Ajustement de position
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       spreadRadius: 1,
//                       blurRadius: 2,
//                     )
//                   ],
//                 ),
//                 constraints: const BoxConstraints(
//                   minWidth: 20,
//                   minHeight: 20,
//                 ),
//                 child: Text(
//                   notificationCount > 9 ? '9+' : '$notificationCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12, // Taille de police augmentée
//                     fontWeight: FontWeight.bold,
//                     height: 1.2,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }