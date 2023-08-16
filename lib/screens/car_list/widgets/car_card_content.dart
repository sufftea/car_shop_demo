import 'dart:ui';

import 'package:car_shop/screens/car_list/data/car_list.dart';
import 'package:car_shop/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lorem_ipsum/lorem_ipsum.dart';

final lorem = loremIpsum(paragraphs: 2);

class CarCardWidget extends StatefulWidget {
  CarCardWidget({
    required this.scrollController,
    required this.draggableController,
    required this.contentAnim,
    required this.cardFraction,
    required int year,
    super.key,
  }) : carData = CarData.fromYear(year);

  static const contentHeight = 550.0;

  final ScrollController scrollController;
  final DraggableScrollableController draggableController;
  final Animation<double> contentAnim;
  final double cardFraction;
  final CarData carData;

  @override
  State<CarCardWidget> createState() => _CarCardWidgetState();
}

class _CarCardWidgetState extends State<CarCardWidget> {
  double topSafeArea = 0;

  /// Scroll offset at the time when the drag with handle started
  double dragStartScrollOffset = 0;

  double calculateExpandProgress() {
    final t = remap(
      widget.cardFraction,
      1,
      0,
      1,
      widget.draggableController.isAttached
          ? widget.draggableController.size
          : widget.cardFraction,
    );
    return t;
  }

  @override
  Widget build(BuildContext context) {
    topSafeArea = MediaQuery.paddingOf(context).top;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: buildStack(),
    );
  }

  Widget buildStack() {
    return Stack(
      children: [
        buildGradient(),
        Positioned.fill(
          child: CustomScrollView(
            // primary: false,
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: buildContent(),
              ),
            ],
          ),
        ),
        buildHandle(),
      ],
    );
  }

  Widget buildHandle() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.draggableController,
        widget.contentAnim,
      ]),
      builder: (context, child) {
        final t = calculateExpandProgress();
        return Positioned(
          top: 0,
          right: 0,
          left: 0,
          child: GestureDetector(
            onVerticalDragStart: (details) {
              dragStartScrollOffset = widget.scrollController.offset;
            },
            onVerticalDragUpdate: (details) {
              final c = widget.draggableController;
              final destination =
                  c.pixelsToSize(c.pixels - details.primaryDelta!);

              final sc = widget.scrollController;
              if (destination <= 1) {
                c.jumpTo(destination);

                final t = remap(widget.cardFraction, 1, 0, 1, destination);
                sc.jumpTo(dragStartScrollOffset * t);
              }
            },
            onVerticalDragEnd: (details) {
              final c = widget.draggableController;

              if (c.size < (widget.cardFraction + 1) / 2) {
                c.animateTo(
                  widget.cardFraction,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              } else {
                c.animateTo(
                  1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: switch ((
                  widget.contentAnim.isCompleted,
                  widget.scrollController.positions.first.pixels == 0
                )) {
                  (false, true) => Colors.transparent,
                  (false, false) =>
                    Colors.white.withOpacity(widget.contentAnim.value),
                  _ => Colors.white,
                },
                border: Border(
                  bottom: BorderSide(
                    color: Color.lerp(
                      Colors.transparent,
                      Colors.black,
                      t,
                    )!,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: lerpDouble(0, topSafeArea, t),
                  ),
                  SizedBox(
                    height: lerpDouble(24, 64, t),
                    child: Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Positioned buildGradient() {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, cons) {
        return AnimatedBuilder(
          animation:
              widget.contentAnim.drive(CurveTween(curve: Curves.easeOutQuart)),
          builder: (context, child) {
            final t = widget.contentAnim.value;
            final heightFactor = cons.maxHeight / cons.maxWidth;

            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: const [Colors.white, Color(0xff0e0e0e)],
                  stops: [lerpDouble(0, 1, t)!, 0.9],
                  radius: heightFactor * 2 * t,
                  center: const Alignment(0, 2),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget buildContent() {
    return AnimatedBuilder(
      animation: widget.contentAnim,
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: TextStyle(
            color: Color.lerp(
              Colors.white,
              Colors.black,
              widget.contentAnim.value,
            ),
          ),
          child: child!,
        );
      },
      child: Column(
        children: [
          AnimatedBuilder(
            animation: widget.draggableController,
            builder: (context, child) {
              final t = calculateExpandProgress();
              return SizedBox(
                height: lerpDouble(24, topSafeArea + 64, t),
              );
            },
          ),
          const SizedBox(height: 16),
          buildYears(),
          buildCar(),
          buildImageSlideIndicator(),
          buildTitle(),
          buildDetails(),
          const SizedBox(
            height: 32,
          ),
        ],
      ),
    );
  }

  Widget buildImageSlideIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 4; ++i) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  (i + 1).toString(),
                  style: GoogleFonts.urbanist(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (i == 0)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 22),
          ]
        ],
      ),
    );
  }

  Widget buildDetails() {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Column(
        children: [
          const Divider(
            height: 96,
            thickness: 0.5,
            color: Colors.black,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 200,
                alignment: Alignment.topLeft,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      '1968-1982',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Sportcars',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(
            height: 96,
            thickness: 1,
            color: Colors.black,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Text(
              lorem,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32),
      child: Text(
        widget.carData.name,
        textAlign: TextAlign.start,
        style: GoogleFonts.cormorant(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildCar() {
    return LayoutBuilder(builder: (context, cons) {
      return AnimatedBuilder(
        animation:
            widget.contentAnim.drive(CurveTween(curve: Curves.easeInOutCubic)),
        builder: (context, child) {
          return Transform.scale(
            scale: lerpDouble(1, 2, widget.contentAnim.value),
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              widget.carData.picturePath,
              alignment: Alignment.bottomCenter,
              width: cons.maxWidth - 64,
              height: 200,
            ),
          );
        },
      );
    });
  }

  Widget buildYears() {
    return Builder(builder: (context) {
      final textColor =
          DefaultTextStyle.of(context).style.color ?? Colors.white;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.carData.yearStart.toString(),
              // textHeightBehavior: TextHeightBehavior,
              style: GoogleFonts.urbanist(
                height: 1,
                fontSize: 64,
                letterSpacing: -4,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "- ${widget.carData.yearEnd.toString()}",
              style: GoogleFonts.urbanist(
                height: 1,
                fontSize: 40,
                letterSpacing: -2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = textColor,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class CustomTween<T> extends Animatable<T> {
  const CustomTween(this.customTransform);

  final T Function(double t) customTransform;

  @override
  T transform(double t) {
    return customTransform(t);
  }
}
