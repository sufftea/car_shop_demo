import 'dart:math';
import 'dart:ui';

import 'package:car_shop/screens/car_list/data/year_provider.dart';
import 'package:car_shop/screens/car_list/widgets/car_card_content.dart';
import 'package:car_shop/screens/car_list/widgets/timeline_widget.dart';
import 'package:car_shop/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CarListScreen extends ConsumerStatefulWidget {
  const CarListScreen({
    super.key,
  });

  @override
  ConsumerState<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends ConsumerState<CarListScreen>
    with TickerProviderStateMixin {
  static const cardStackOffset = 32.0;

  // final draggableSheetKey = GlobalKey();

  // DUMMIES
  final dummyDraggableController = DraggableScrollableController();
  final dummyScrollController = ScrollController();
  late final dummyAnimation = AnimationController(vsync: this);
  // REGULAR STUFF
  final draggableController = DraggableScrollableController();
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

  double cardFraction = 0.0;

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

    dummyAnimation.dispose();
    dummyDraggableController.dispose();
    dummyScrollController.dispose();
  }

  void onDraggableUpdate() {
    final maxSize = draggableController.sizeToPixels(1);

    if (maxSize.isFinite && draggableController.pixels >= maxSize.floor()) {
      cardContentCtrl.forward();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        cardOpenedNotifier.value = true;
      });
    } else if (!cardContentCtrl.isDismissed) {
      final t = remap(
        cardFraction,
        1,
        0,
        1,
        draggableController.isAttached
            ? draggableController.size
            : cardFraction,
      );

      cardContentCtrl.value = t;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        cardOpenedNotifier.value = false;
      });
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: LayoutBuilder(builder: (context, cons) {
          cardFraction = CarCardWidget.contentHeight / cons.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              buildTimeline(cons),
              ...buildCardStack(cons),
              buildFrontCard(cons),
              AnimatedBuilder(
                animation: swipeCtrl,
                builder: (context, child) {
                  final t = swipeCtrl.value;
                  if (t <= 0) {
                    return const SizedBox();
                  }

                  return buildSlidingCard(
                    cons: cons,
                    t: t - 1,
                    child: Consumer(builder: (context, ref, child) {
                      final year = ref.watch(yearProvider) - 1;
                      return CarCardWidget(
                        scrollController: dummyScrollController,
                        draggableController: draggableController,
                        contentAnim: dummyAnimation,
                        cardFraction: cardFraction,
                        year: year,
                      );
                    }),
                  );
                },
              ),
              buildGestureDetector(cons),
            ],
          );
        }),
      ),
    );
  }

  Positioned buildGestureDetector(BoxConstraints cons) {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      height: CarCardWidget.contentHeight,
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
      ),
    );
  }

  Widget buildSlidingCard({
    required BoxConstraints cons,
    required double t,
    required Widget child,
  }) {
    final plusHeight = lerpDouble(
      0.0,
      300.0,
      t.abs(),
    )!;

    return Positioned(
      bottom: -plusHeight,
      left: cons.maxWidth * t,
      width: cons.maxWidth,
      height: CarCardWidget.contentHeight + plusHeight,
      child: Transform.rotate(
        angle: pi / 8 * t,
        origin: const Offset(0, 500),
        child: child,
      ),
    );
  }

  Widget buildFrontCard(BoxConstraints cons) {
    return AnimatedBuilder(
      animation: swipeCtrl,
      builder: (context, child) {
        double t = swipeCtrl.value;

        if (t == 0) {
          return Positioned.fill(
            child: child!,
          );
        }

        debugPrint('t = $t');
        if (t > 0) {
          return buildCardInStack(
            cons: cons,
            t: 1 - t / 3,
            child: Consumer(builder: (context, ref, _) {
              final year = ref.watch(yearProvider);
              debugPrint('rebuilding front card');
              return CarCardWidget(
                scrollController: dummyScrollController,
                draggableController: dummyDraggableController,
                contentAnim: dummyAnimation,
                cardFraction: cardFraction,
                year: year,
              );
            }),
          );
        }
        return buildSlidingCard(
          cons: cons,
          t: t,
          child: Consumer(builder: (context, ref, _) {
            final year = ref.watch(yearProvider);

            return CarCardWidget(
              scrollController: dummyScrollController,
              draggableController: dummyDraggableController,
              contentAnim: dummyAnimation,
              cardFraction: cardFraction,
              year: year,
            );
          }),
        );
      },
      child: DraggableScrollableSheet(
        // key: draggableSheetKey,
        expand: false,
        snap: true,
        minChildSize: cardFraction,
        initialChildSize: cardFraction,
        snapAnimationDuration: const Duration(milliseconds: 200),
        controller: draggableController,
        builder: (context, scrollController) {
          return Consumer(builder: (context, ref, child) {
            final year = ref.watch(yearProvider);

            return CarCardWidget(
              scrollController: scrollController,
              draggableController: draggableController,
              contentAnim: cardContentCtrl,
              cardFraction: cardFraction,
              year: year,
            );
          });
        },
      ),
    );
  }

  Widget buildCardInStack({
    required BoxConstraints cons,
    required double t,
    required Widget child,
  }) {
    final offset = lerpDouble(cardStackOffset, 0, t)!;
    final scale = lerpDouble(0.8, 1.0, t)!;
    final height = cons.maxHeight * cardFraction + offset;
    // adjustment for the scale transformation
    final heightAdjustment = height / scale - height;

    return Positioned(
      height: height + heightAdjustment,
      left: 0,
      right: 0,
      bottom: -heightAdjustment,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  List<Widget> buildCardStack(BoxConstraints cons) {
    return [
      for (int i = 0; i < 3; ++i)
        AnimatedBuilder(
          animation: swipeCtrl,
          builder: (context, child) {
            double t =
                swipeCtrl.value > 0 ? 1 - swipeCtrl.value : -swipeCtrl.value;
            t = (t + i) / 3;

            return buildCardInStack(
              cons: cons,
              t: t,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                      Colors.white, Colors.black, Curves.easeOut.transform(t)),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: AnimatedBuilder(
                    animation: swipeCtrl,
                    builder: (context, _) {
                      return switch (i) {
                        2 when swipeCtrl.value != 0 =>
                          Consumer(builder: (context, ref, child) {
                            final year = ref.watch(yearProvider) + 1;

                            return Stack(
                              children: [
                                CarCardWidget(
                                  scrollController: dummyScrollController,
                                  draggableController: dummyDraggableController,
                                  contentAnim: dummyAnimation,
                                  cardFraction: cardFraction,
                                  year: year,
                                ),
                                Container(
                                  color: Colors.white.withOpacity(1 - t),
                                ),
                              ],
                            );
                          }),
                        _ => const SizedBox.shrink(),
                      };
                    }),
              ),
            );
          },
        ),
    ];
  }

  Widget buildTimeline(BoxConstraints cons) {
    return Consumer(builder: (context, ref, _) {
      final year = ref.watch(yearProvider);

      return AnimatedBuilder(
        animation: draggableController,
        builder: (context, child) {
          final height =
              cons.maxHeight - CarCardWidget.contentHeight - cardStackOffset;
          final t = remap(
            cardFraction,
            1,
            0,
            1,
            draggableController.isAttached
                ? draggableController.size
                : cardFraction,
          );

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
