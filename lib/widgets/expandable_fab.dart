import 'package:flutter/material.dart';

class ActionButton {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;

  ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });
}

class ExpandableFab extends StatefulWidget {
  final bool initialOpen;
  final List<ActionButton> children;

  const ExpandableFab({
    super.key,
    this.initialOpen = false,
    required this.children,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open || _controller.isAnimating)
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.children.map((btn) => _ActionButtonRow(
                action: btn,
                progress: _expandAnimation,
                onPressed: () {
                  _toggle();
                  btn.onPressed();
                },
              )).toList(),
            ),
          ),
        _buildTapToCloseFab(),
      ],
    );
  }

  Widget _buildTapToCloseFab() {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.only(top: 16.0),
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        color: const Color(0xFF1967D2),
        child: InkWell(
          onTap: _toggle,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 0.785, // roughly 45 degrees
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtonRow extends StatelessWidget {
  final ActionButton action;
  final VoidCallback onPressed;
  final Animation<double> progress;

  const _ActionButtonRow({
    required this.action,
    required this.onPressed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: progress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    action.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0D253F),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 56, // EXACTLY 56px to perfectly align with the main FAB below it
              child: Center(
                child: SizedBox(
                   width: 44,
                   height: 44,
                   child: Material(
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     color: Colors.white,
                     elevation: 2,
                     child: InkWell(
                       onTap: onPressed,
                       borderRadius: BorderRadius.circular(12),
                       child: Center(
                         child: Theme(
                           data: Theme.of(context).copyWith(
                             iconTheme: const IconThemeData(color: Color(0xFF1967D2), size: 20),
                           ),
                           child: action.icon,
                         ),
                       ),
                     ),
                   ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
