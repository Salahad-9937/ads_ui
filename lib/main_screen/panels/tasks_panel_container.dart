import 'package:flutter/material.dart';
import 'tasks_panel.dart';

class TasksPanelContainer extends StatefulWidget {
  const TasksPanelContainer({super.key});

  @override
  TasksPanelContainerState createState() => TasksPanelContainerState();
}

class TasksPanelContainerState extends State<TasksPanelContainer>
    with SingleTickerProviderStateMixin {
  bool isTasksPanelOpen = false;
  late AnimationController _tasksController;
  late Animation<Offset> _tasksPanelAnimation;
  late Animation<double> _tasksWidthAnimation;

  @override
  void initState() {
    super.initState();
    _tasksController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tasksPanelAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _tasksController, curve: Curves.easeInOut),
    );
    _tasksWidthAnimation = Tween<double>(begin: 30.0, end: 280.0).animate(
      CurvedAnimation(parent: _tasksController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tasksController.dispose();
    super.dispose();
  }

  void _toggleTasksPanel() {
    setState(() {
      isTasksPanelOpen = !isTasksPanelOpen;
      if (isTasksPanelOpen) {
        _tasksController.forward();
      } else {
        _tasksController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tasksWidthAnimation,
      builder: (context, child) {
        return SizedBox(
          width: _tasksWidthAnimation.value,
          child: ClipRect(
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTap: _toggleTasksPanel,
                        child: Container(
                          height: constraints.maxHeight,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              isTasksPanelOpen
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_tasksWidthAnimation.value > 250)
                  Expanded(
                    child: SlideTransition(
                      position: _tasksPanelAnimation,
                      child: SizedBox(
                        width: _tasksWidthAnimation.value - 30,
                        child: Drawer(child: TasksPanel()),
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
