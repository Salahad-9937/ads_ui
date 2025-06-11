import 'package:flutter/material.dart';
import 'status_panel.dart';

class StatusPanelContainer extends StatefulWidget {
  final Map<String, dynamic> droneStatus;

  const StatusPanelContainer({super.key, required this.droneStatus});

  @override
  StatusPanelContainerState createState() => StatusPanelContainerState();
}

class StatusPanelContainerState extends State<StatusPanelContainer>
    with SingleTickerProviderStateMixin {
  bool isStatusPanelOpen = false;
  late AnimationController _statusController;
  late Animation<Offset> _statusPanelAnimation;
  late Animation<double> _statusWidthAnimation;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statusPanelAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
    );
    _statusWidthAnimation = Tween<double>(begin: 30.0, end: 280.0).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  void _toggleStatusPanel() {
    setState(() {
      isStatusPanelOpen = !isStatusPanelOpen;
      if (isStatusPanelOpen) {
        _statusController.forward();
      } else {
        _statusController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _statusWidthAnimation,
      builder: (context, child) {
        return SizedBox(
          width: _statusWidthAnimation.value,
          child: ClipRect(
            child: Row(
              children: [
                if (_statusWidthAnimation.value > 250)
                  Expanded(
                    child: SlideTransition(
                      position: _statusPanelAnimation,
                      child: SizedBox(
                        width: _statusWidthAnimation.value - 30,
                        child: Drawer(
                          child: StatusPanel(droneStatus: widget.droneStatus),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 30,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTap: _toggleStatusPanel,
                        child: Container(
                          height: constraints.maxHeight,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              isStatusPanelOpen
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
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
