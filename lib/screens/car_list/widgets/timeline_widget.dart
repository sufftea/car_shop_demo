import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({
    required this.swipeAnim,
    required this.expandProgress,
    required this.year,
    super.key,
  });

  final double expandProgress;
  final Animation<double> swipeAnim;
  final int year;

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  static const _yearFraction = 0.20;
  static const _scaleup = 1.2;

  late final pageCtrl = PageController(
    initialPage: widget.year,
    viewportFraction: _yearFraction,
  );

  @override
  void initState() {
    super.initState();

    widget.swipeAnim.addListener(onSwipeUpdate);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      pageCtrl.jumpToPage(widget.year);
      onSwipeUpdate();
    });
  }

  @override
  void dispose() {
    super.dispose();

    widget.swipeAnim.removeListener(onSwipeUpdate);
  }

  @override
  void didUpdateWidget(covariant TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    pageCtrl.jumpToPage(widget.year);
  }

  void onSwipeUpdate() {
    final targetPage = widget.year - widget.swipeAnim.value;

    pageCtrl.jumpTo(
      targetPage * pageCtrl.position.viewportDimension * _yearFraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 64,
                  child: Center(
                    child: Text(
                      'Timeline',
                      style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Transform.scale(
                    scale: lerpDouble(_scaleup, 1, widget.expandProgress)!,
                    child: buildYears(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PageView buildYears() {
    return PageView.builder(
      padEnds: true,
      controller: pageCtrl,
      pageSnapping: false,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Center(
          child: AnimatedBuilder(
            animation: pageCtrl,
            builder: (context, child) {
              final double t;

              if (pageCtrl.position.hasContentDimensions) {
                t = clampDouble((index - pageCtrl.page!).abs(), 0, 1);
              } else {
                t = index == widget.year ? 0.0 : 1.0;
              }

              return Stack(
                children: [
                  Text(
                    index.toString(),
                    style: GoogleFonts.urbanist(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = Colors.black,
                    ),
                  ),
                  Text(
                    index.toString(),
                    style: GoogleFonts.urbanist(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.fill
                        ..strokeWidth = 1
                        ..color = Colors.black.withOpacity(1 - t),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
