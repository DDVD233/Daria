import 'package:flutter/material.dart';

/// Wraps [child] and paints the gray vertical line that connects the avatars of
/// consecutive notes in a Twitter-style thread.
///
/// The line is drawn in two segments at the avatar's horizontal center so it
/// never crosses the avatar itself: from the top of [child] down to [avatarTop]
/// when [connectTop], and from [avatarBottom] down to the bottom of [child]
/// when [connectBottom]. Coordinates are relative to [child]; [avatarCenterX] is
/// mirrored automatically in right-to-left layouts. When neither end connects,
/// [child] is returned unchanged.
class ThreadConnector extends StatelessWidget {
  const ThreadConnector({
    super.key,
    required this.color,
    required this.avatarCenterX,
    required this.avatarTop,
    required this.avatarBottom,
    required this.connectTop,
    required this.connectBottom,
    required this.child,
  });

  final Color color;
  final double avatarCenterX;
  final double avatarTop;
  final double avatarBottom;
  final bool connectTop;
  final bool connectBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!connectTop && !connectBottom) {
      return child;
    }
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ThreadConnectorPainter(
              color: color,
              avatarCenterX: avatarCenterX,
              avatarTop: avatarTop,
              avatarBottom: avatarBottom,
              connectTop: connectTop,
              connectBottom: connectBottom,
              direction: Directionality.of(context),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ThreadConnectorPainter extends CustomPainter {
  const _ThreadConnectorPainter({
    required this.color,
    required this.avatarCenterX,
    required this.avatarTop,
    required this.avatarBottom,
    required this.connectTop,
    required this.connectBottom,
    required this.direction,
  });

  final Color color;
  final double avatarCenterX;
  final double avatarTop;
  final double avatarBottom;
  final bool connectTop;
  final bool connectBottom;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final x = switch (direction) {
      TextDirection.rtl => size.width - avatarCenterX,
      TextDirection.ltr => avatarCenterX,
    };
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    if (connectTop) {
      canvas.drawLine(Offset(x, 0.0), Offset(x, avatarTop), paint);
    }
    if (connectBottom) {
      canvas.drawLine(Offset(x, avatarBottom), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ThreadConnectorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.avatarCenterX != avatarCenterX ||
        oldDelegate.avatarTop != avatarTop ||
        oldDelegate.avatarBottom != avatarBottom ||
        oldDelegate.connectTop != connectTop ||
        oldDelegate.connectBottom != connectBottom ||
        oldDelegate.direction != direction;
  }
}
