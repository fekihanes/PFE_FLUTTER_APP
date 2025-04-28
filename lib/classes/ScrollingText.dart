import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ScrollingWidgetList extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double velocity; // in pixels/sec
  final double spacing;

  const ScrollingWidgetList({
    Key? key,
    required this.children,
    this.height = 30,
    this.velocity = 40.0,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  _ScrollingWidgetListState createState() => _ScrollingWidgetListState();
}

class _ScrollingWidgetListState extends State<ScrollingWidgetList>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;
  DateTime? _lastTime;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _ticker = createTicker((elapsed) {
      final now = DateTime.now();
      if (_lastTime != null) {
        final delta = (now.millisecondsSinceEpoch - _lastTime!.millisecondsSinceEpoch) / 1000.0;
        final newOffset = _scrollController.offset + widget.velocity * delta;
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (maxScroll > 0) {
          _scrollController.jumpTo(newOffset % maxScroll);
        }
      }
      _lastTime = now;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _ticker.start();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repeated = List<Widget>.generate(
      widget.children.length,
      (index) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.children[index],
          if (index != widget.children.length - 1) SizedBox(width: widget.spacing),
        ],
      ),
    );

    // Generate sufficient copies to ensure content exceeds viewport width
    final duplicated = List<Widget>.generate(
      20, // Generates 20 copies for sufficient length
      (index) => repeated[index % repeated.length],
    );

    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: duplicated.length,
        itemBuilder: (context, index) => duplicated[index],
      ),
    );
  }
}
