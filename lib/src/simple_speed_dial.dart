import 'package:flutter/material.dart';

import 'simple_speed_dial_child.dart';

class SpeedDial extends StatefulWidget {
  const SpeedDial({
    Key? key,
    this.fabKey,
    this.child,
    this.speedDialChildren,
    this.labelsStyle,
    this.controller,
    this.closedForegroundColor,
    this.openForegroundColor,
    this.closedBackgroundColor,
    this.openBackgroundColor,
    this.onOpen,
    this.onClose,
    this.onCancel,
    this.openedChild,
    this.direction = SpeedDialDirection.UP,
    this.isExtended = false,
    this.extendedLabel,
  }) : super(key: key);

  final Widget? child;
  final Widget? extendedLabel;
  final Widget? openedChild;
  final Key? fabKey;
  final SpeedDialDirection direction;
  final bool isExtended;

  final List<SpeedDialChild>? speedDialChildren;

  final TextStyle? labelsStyle;

  final AnimationController? controller;

  final Color? closedForegroundColor;

  final Color? openForegroundColor;

  final Color? closedBackgroundColor;

  final Color? openBackgroundColor;

  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final VoidCallback? onCancel;

  @override
  State<StatefulWidget> createState() {
    return _SpeedDialState();
  }
}

class _SpeedDialState extends State<SpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _foregroundColorAnimation;
  final List<Animation<double>> _speedDialChildAnimations =
      <Animation<double>>[];

  @override
  void initState() {
    _animationController = widget.controller ??
        AnimationController(
            vsync: this, duration: const Duration(milliseconds: 450));
    _animationController.addListener(() {
      if (_animationController.isCompleted) {
        widget.onOpen?.call();
      }
      if (_animationController.isDismissed) {
        widget.onClose?.call();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _backgroundColorAnimation = ColorTween(
      begin: widget.closedBackgroundColor,
      end: widget.openBackgroundColor,
    ).animate(_animationController);

    _foregroundColorAnimation = ColorTween(
      begin: widget.closedForegroundColor,
      end: widget.openForegroundColor,
    ).animate(_animationController);

    final double fractionOfOneSpeedDialChild =
        1.0 / widget.speedDialChildren!.length;
    for (int speedDialChildIndex = 0;
        speedDialChildIndex < widget.speedDialChildren!.length;
        ++speedDialChildIndex) {
      final List<TweenSequenceItem<double>> tweenSequenceItems =
          <TweenSequenceItem<double>>[];

      final double firstWeight =
          fractionOfOneSpeedDialChild * speedDialChildIndex;
      if (firstWeight > 0.0) {
        tweenSequenceItems.add(TweenSequenceItem<double>(
          tween: ConstantTween<double>(0.0),
          weight: firstWeight,
        ));
      }

      tweenSequenceItems.add(TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: fractionOfOneSpeedDialChild,
      ));

      final double lastWeight = fractionOfOneSpeedDialChild *
          (widget.speedDialChildren!.length - 1 - speedDialChildIndex);
      if (lastWeight > 0.0) {
        tweenSequenceItems.add(TweenSequenceItem<double>(
            tween: ConstantTween<double>(1.0), weight: lastWeight));
      }

      _speedDialChildAnimations.insert(
          0,
          TweenSequence<double>(tweenSequenceItems)
              .animate(_animationController));
    }

    super.initState();
  }

  void onChildPressed(SpeedDialChild speedDialChild) {
    speedDialChild.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    int speedDialChildAnimationIndex = 0;

    Widget _buildContent() {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: widget.speedDialChildren
                  ?.map<Widget>((SpeedDialChild speedDialChild) {
                final Widget speedDialChildWidget = Opacity(
                  opacity:
                      _speedDialChildAnimations[speedDialChildAnimationIndex]
                          .value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0 - 4.0),
                          child: Card(
                            margin: const EdgeInsets.only(left: 16.0 - 4.0),
                            elevation: 6.0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top: 8.0,
                                bottom: 8.0,
                              ),
                              child: Text(
                                speedDialChild.label!,
                                style: widget.labelsStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _speedDialChildAnimations[
                            speedDialChildAnimationIndex],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: FloatingActionButton(
                            heroTag: speedDialChildAnimationIndex,
                            mini: true,
                            child: speedDialChild.child,
                            foregroundColor: speedDialChild.foregroundColor,
                            backgroundColor: speedDialChild.backgroundColor,
                            onPressed: () {
                              if (speedDialChild.closeSpeedDialOnPressed) {
                                _animationController.reverse();
                              }
                              onChildPressed(speedDialChild);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                speedDialChildAnimationIndex++;
                return speedDialChildWidget;
              }).toList() ??
              <Widget>[],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (widget.direction == SpeedDialDirection.UP)
          if (!_animationController.isDismissed) _buildContent(),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: widget.isExtended && !_animationController.isCompleted
              ? FloatingActionButton.extended(
                  heroTag: widget.fabKey,
                  label: widget.extendedLabel!,
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: _animationController.isCompleted
                        ? widget.openedChild
                        : widget.child,
                  ),
                  foregroundColor: _foregroundColorAnimation.value,
                  backgroundColor: _backgroundColorAnimation.value,
                  onPressed: () {
                    if (_animationController.isDismissed) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                      widget.onCancel?.call();
                    }
                  },
                )
              : FloatingActionButton(
                  heroTag: widget.fabKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: _animationController.isCompleted
                        ? widget.openedChild
                        : widget.child,
                  ),
                  foregroundColor: _foregroundColorAnimation.value,
                  backgroundColor: _backgroundColorAnimation.value,
                  onPressed: () {
                    if (_animationController.isDismissed) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                      widget.onCancel?.call();
                    }
                  },
                ),
        ),
        if (widget.direction == SpeedDialDirection.DOWN)
          if (!_animationController.isDismissed) _buildContent(),
      ],
    );
  }
}

enum SpeedDialDirection { UP, DOWN }
