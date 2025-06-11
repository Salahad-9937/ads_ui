import 'package:flutter/material.dart';

/// Контейнер для боковой панели с анимацией открытия и закрытия.
///
/// [isLeftPanel] - Флаг, указывающий, является ли панель левой.
/// [child] - Виджет, отображаемый внутри панели.
class PanelContainer extends StatefulWidget {
  final bool isLeftPanel;
  final Widget child;

  const PanelContainer({
    super.key,
    required this.isLeftPanel,
    required this.child,
  });

  @override
  PanelContainerState createState() => PanelContainerState();
}

/// Состояние контейнера панели, управляющее анимацией открытия и закрытия.
class PanelContainerState extends State<PanelContainer>
    with SingleTickerProviderStateMixin {
  bool isPanelOpen = false;
  late AnimationController _controller;
  late Animation<Offset> _panelAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimation = Tween<Offset>(
      begin:
          widget.isLeftPanel ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _widthAnimation = Tween<double>(
      begin: 30.0,
      end: 280.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Переключает состояние панели между открытым и закрытым.
  void _togglePanel() {
    setState(() {
      isPanelOpen = !isPanelOpen;
      if (isPanelOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return SizedBox(
          width: _widthAnimation.value,
          child: ClipRect(
            child: Row(
              children: [
                if (widget.isLeftPanel && _widthAnimation.value > 250)
                  Expanded(
                    child: SlideTransition(
                      position: _panelAnimation,
                      child: SizedBox(
                        width: _widthAnimation.value - 30,
                        child: Drawer(child: widget.child),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 30,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTap: _togglePanel,
                        child: Container(
                          height: constraints.maxHeight,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              isPanelOpen
                                  ? (widget.isLeftPanel
                                      ? Icons.chevron_left
                                      : Icons.chevron_right)
                                  : (widget.isLeftPanel
                                      ? Icons.chevron_right
                                      : Icons.chevron_left),
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!widget.isLeftPanel && _widthAnimation.value > 250)
                  Expanded(
                    child: SlideTransition(
                      position: _panelAnimation,
                      child: SizedBox(
                        width: _widthAnimation.value - 30,
                        child: Drawer(child: widget.child),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
