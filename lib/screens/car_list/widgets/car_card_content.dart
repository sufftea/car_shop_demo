import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lorem_ipsum/lorem_ipsum.dart';

final lorem = loremIpsum(paragraphs: 2);

class CarCardContentWidget extends StatelessWidget {
  const CarCardContentWidget({
    required this.year,
    required this.expandProgress,
    required this.topPadding,
    required this.scrollController,
    required this.contentAnim,
    super.key,
  });

  final int year;
  final double expandProgress;
  final double topPadding;
  final ScrollController scrollController;
  final Animation<double> contentAnim;

  double get appBarSize {
    return lerpDouble(
      0,
      topPadding,
      expandProgress,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(builder: (context, cons) {
            return AnimatedBuilder(
              animation: contentAnim,
              builder: (context, child) {
                final t = contentAnim.value;
                final heightFactor = cons.maxHeight / cons.maxWidth;

                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: const [Colors.white, Color(0xff0e0e0e)],
                      stops: [lerpDouble(0, 1, t)!, 0.9],
                      radius: heightFactor * 2 * t,
                      center: const Alignment(0, 1.5),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Positioned.fill(
          child: CustomScrollView(
            primary: false,
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: buildContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildContent() {
    return AnimatedBuilder(
      animation: contentAnim,
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: TextStyle(
            color: Color.lerp(Colors.white, Colors.black, contentAnim.value),
          ),
          child: child!,
        );
      },
      child: Column(
        children: [
          SizedBox(
            height: 32 + appBarSize,
          ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
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
          Text(
            lorem,
            style: const TextStyle(
              fontSize: 18,
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
        'Chevrolet Corvette C3',
        textAlign: TextAlign.start,
        style: GoogleFonts.cormorant(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildCar() {
    return LayoutBuilder(builder: (context, cons) {
      return AnimatedBuilder(
        animation: contentAnim.drive(CurveTween(curve: Curves.easeInOutCubic)),
        builder: (context, child) {
          return Transform.scale(
            scale: lerpDouble(1, 2, contentAnim.value),
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              'assets/hotwheels.png',
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
              year.toString(),
              // textHeightBehavior: TextHeightBehavior,
              style: GoogleFonts.urbanist(
                height: 1,
                fontSize: 64,
                letterSpacing: -4,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "- ${(year + 9)}",
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
