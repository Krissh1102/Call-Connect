import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final String colorHex;
  final double radius;
  final bool showOnlineDot;
  final bool isOnline;

  const UserAvatar({
    super.key,
    required this.initials,
    required this.colorHex,
    this.radius = 24,
    this.showOnlineDot = false,
    this.isOnline = false,
  });

  Color get _color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: _color,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.7,
            ),
          ),
        ),
        if (showOnlineDot)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: radius * 0.42,
              height: radius * 0.42,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF2ECC71) : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
