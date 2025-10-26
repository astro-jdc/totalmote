import 'package:flutter/material.dart';

class RemoteButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final double size;
  final Color? color;

  const RemoteButton({
    Key? key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.size = 60,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color ?? const Color(0xFF0f3460),
          borderRadius: BorderRadius.circular(size / 2),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, size: size * 0.5),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}