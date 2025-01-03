import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({super.key, required this.children, required this.color});

  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: children,
        ),
      ),
    );
  }
}
