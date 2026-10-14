import 'package:flutter/material.dart';
import 'package:before_after/before_after.dart';

class SplitSliderWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;

  const SplitSliderWidget({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
  });

  @override
  State<SplitSliderWidget> createState() => _SplitSliderWidgetState();
}

class _SplitSliderWidgetState extends State<SplitSliderWidget> {
  double _value = 0.5;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BeforeAfter(
        value: _value,
        before: Image.network(
          widget.beforeImageUrl,
          fit: BoxFit.cover,
        ),
        after: Image.network(
          widget.afterImageUrl,
          fit: BoxFit.cover,
        ),
        onValueChanged: (val) {
          setState(() {
            _value = val;
          });
        },
      ),
    );
  }
}