import 'package:flutter/material.dart';

class MyDarahMark extends StatelessWidget {
  const MyDarahMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/mydarah_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Icon(
        Icons.bloodtype_rounded,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class MyDarahWordmark extends StatelessWidget {
  const MyDarahWordmark({
    super.key,
    this.markSize = 34,
    this.textStyle,
    this.showTagline = false,
    this.onDark = false,
  });

  final double markSize;
  final TextStyle? textStyle;
  final bool showTagline;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        textStyle ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
          color: onDark ? Colors.white : const Color(0xFF78152A),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (markSize > 0) ...[
          if (onDark)
            Container(
              width: markSize,
              height: markSize,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                shape: BoxShape.circle,
              ),
              child: MyDarahMark(size: markSize - 8),
            )
          else
            MyDarahMark(size: markSize),
          const SizedBox(width: 8),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MyDarah', style: titleStyle),
            if (showTagline)
              Text(
                'Give blood. Save lives.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF7C6A6D),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
