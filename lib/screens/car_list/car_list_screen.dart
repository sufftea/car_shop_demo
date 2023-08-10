import 'dart:math';
import 'dart:ui';

import 'package:car_shop/screens/car_list/utils/providers.dart';
import 'package:car_shop/screens/car_list/widgets/car_card_content.dart';
import 'package:car_shop/screens/car_list/widgets/timeline_widget.dart';
import 'package:car_shop/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const draggableMinSize = 0.6;

class CarListScreen extends ConsumerStatefulWidget {
  const CarListScreen({
    super.key,
  });

  @override
  ConsumerState<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends ConsumerState<CarListScreen>
    with TickerProviderStateMixin {
  // DUMMIES
  final dummyDraggableController = DraggableScrollableController();
  final dummyScrollController = ScrollController();
  late final dummyAnimation = AnimationController(vsync: this);
  // REGULAR STUFF
  final draggableController = DraggableScrollableController();
  ScrollController? cardScrollController;
  late final swipeCtrl = AnimationController(
    lowerBound: -1.0,
    upperBound: 1.0,
    value: 0.0,
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  late final cardContentCtrl = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  final cardOpenedNotifier = ValueNotifier(false);

  final cardKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();

    draggableController.addListener(onDraggableUpdate);
    swipeCtrl.addListener(onSwipeAnimationUpdate);
  }

  @override
  void dispose() {
    super.dispose();

    draggableController.dispose();
    swipeCtrl.dispose();
    cardOpenedNotifier.dispose();
  }

  void onDraggableUpdate() {
    if (draggableController.pixels >=
        draggableController.sizeToPixels(1).floor()) {
      cardContentCtrl.forward();
      cardOpenedNotifier.value = true;
    } else if (!cardContentCtrl.isDismissed) {
      final t = remap(
        draggableMinSize,
        1,
        0,
        1,
        draggableController.isAttached
            ? draggableController.size
            : draggableMinSize,
      );

      cardContentCtrl.value = t;
      cardOpenedNotifier.value = false;
    }
  }

  void onSwipeAnimationUpdate() {
    switch (swipeCtrl.value) {
      case 1.0:
        ref.read(yearProvider.notifier).state--;
        swipeCtrl.value = 0.0;
      case -1.0:
        ref.read(yearProvider.notifier).state++;
        swipeCtrl.value = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, cons) {
        return Stack(
          children: [
            buildTimeline(),
            ...buildCardStack(cons),
            buildFrontCard(cons),
          ],
        );
      }),
    );
  }

  Widget buildFrontCard(BoxConstraints cons) {
    return AnimatedBuilder(
      animation: swipeCtrl,
      builder: (context, child) {
        final plusHeight = lerpDouble(
          0.0,
          300.0,
          swipeCtrl.value.abs(),
        )!;
        return Positioned(
          bottom: -plusHeight * draggableMinSize,
          left: cons.maxWidth * swipeCtrl.value,
          width: cons.maxWidth,
          height: cons.maxHeight + plusHeight,
          child: Transform.rotate(
            angle: -pi / 6 * swipeCtrl.value,
            origin: const Offset(0, 0),
            child: child!,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: cardOpenedNotifier,
        builder: (context, child) {
          final cardOpened = cardOpenedNotifier.value;
          return GestureDetector(
            onHorizontalDragUpdate: cardOpened
                ? null
                : (details) {
                    final delta = details.primaryDelta ?? 0.0;
                    final deltaRatio = delta / cons.maxWidth;

                    swipeCtrl.value += deltaRatio;
                  },
            onHorizontalDragEnd: cardOpened
                ? null
                : (details) async {
                    switch (swipeCtrl.value) {
                      case < -0.3:
                        await swipeCtrl.animateBack(-1);
                      case > 0.3:
                        await swipeCtrl.animateBack(1);
                      default:
                        swipeCtrl.animateBack(0.0);
                    }
                  },
            child: child,
          );
        },
        child: DraggableScrollableSheet(
          expand: false,
          snap: true,
          minChildSize: draggableMinSize,
          initialChildSize: draggableMinSize,
          // snapAnimationDuration: const Duration(milliseconds: 200),
          controller: draggableController,
          builder: (context, scrollController) {
            cardScrollController = scrollController;

            return CarCardWidget(
              scrollController: scrollController,
              draggableController: draggableController,
              contentAnim: cardContentCtrl,
            );
          },
        ),
      ),
    );
  }

  List<Widget> buildCardStack(BoxConstraints cons) {
    return [
      for (int i = 0; i < 3; ++i)
        AnimatedBuilder(
          animation: swipeCtrl,
          builder: (context, child) {
            final t = (swipeCtrl.value.abs() + i) / 3;
            final offset = lerpDouble(30, 0, t)!;
            final scale = lerpDouble(0.8, 1.0, t)!;
            final height = cons.maxHeight * draggableMinSize + offset;
            final heightAdjustment = height / scale - height;

            return Positioned(
              height: height + heightAdjustment,
              left: 0,
              right: 0,
              bottom: -heightAdjustment,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.grey.shade100,
                      Colors.grey.shade400,
                      t,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: switch (i) {
                    2 when swipeCtrl.value != 0 => Opacity(
                        opacity: swipeCtrl.value.abs(),
                        child: CarCardWidget(
                          scrollController: dummyScrollController,
                          draggableController: dummyDraggableController,
                          contentAnim: dummyAnimation,
                        ),
                      ),
                    _ => null,
                  },
                ),
              ),
            );
          },
        ),
    ];
  }

  Widget buildTimeline() {
    return Consumer(builder: (context, ref, child) {
      return AnimatedBuilder(
        animation: draggableController,
        builder: (context, _) {
          const height = 256.0;
          final t = remap(
            draggableMinSize,
            1,
            0,
            1,
            draggableController.isAttached
                ? draggableController.size
                : draggableMinSize,
          );

          final year = ref.watch(yearProvider);
          debugPrint('rebuildingWith year: ${year}');
          return Positioned(
            top: -height * t,
            left: 0,
            right: 0,
            height: height,
            child: TimelineWidget(
              year: year,
              expandProgress: t,
              swipeAnim: swipeCtrl,
            ),
          );
        },
      );
    });
  }
}

class CarCardWidget extends StatefulWidget {
  const CarCardWidget({
    required this.scrollController,
    required this.draggableController,
    required this.contentAnim,
    super.key,
  });

  final ScrollController scrollController;
  final DraggableScrollableController draggableController;
  final Animation<double> contentAnim;

  @override
  State<CarCardWidget> createState() => _CarCardWidgetState();
}

class _CarCardWidgetState extends State<CarCardWidget> {
  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: AnimatedBuilder(
        animation: widget.draggableController,
        builder: (context, child) {
          final progress = remap(
            draggableMinSize,
            1,
            0,
            1,
            widget.draggableController.isAttached
                ? widget.draggableController.size
                : draggableMinSize,
          );

          return CarCardContentWidget(
            year: 1961,
            expandProgress: progress,
            topPadding: padding.top,
            scrollController: widget.scrollController,
            contentAnim: widget.contentAnim,
          );
        },
      ),
    );
  }
}
