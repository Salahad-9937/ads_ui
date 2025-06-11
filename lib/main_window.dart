import 'package:flutter/material.dart';
import 'dart:typed_data';

class MainWindow extends StatelessWidget {
  final Uint8List? currentImage;
  final String? expandedView;
  final Function(String) toggleView;
  final BoxConstraints constraints;

  const MainWindow({
    super.key,
    required this.currentImage,
    required this.expandedView,
    required this.toggleView,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 40; // Высота заголовка в ViewContainer
    if (expandedView == null) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ViewContainer(
                  title: 'Камера 1',
                  onTap: () => toggleView('camera1'),
                  height: (constraints.maxHeight - headerHeight) / 2,
                  child:
                      currentImage != null
                          ? Image.memory(currentImage!, fit: BoxFit.cover)
                          : const Center(
                            child: Text('Изображение не получено'),
                          ),
                ),
              ),
              Expanded(
                child: ViewContainer(
                  title: 'Камера 2',
                  onTap: () => toggleView('camera2'),
                  height: (constraints.maxHeight - headerHeight) / 2,
                  child: const Center(child: Text('Заглушка Камера 2')),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ViewContainer(
                  title: 'ЛиDAR',
                  onTap: () => toggleView('lidar'),
                  height: (constraints.maxHeight - headerHeight) / 2,
                  child: const Center(child: Text('Заглушка ЛиDAR')),
                ),
              ),
              Expanded(
                child: ViewContainer(
                  title: 'Карта',
                  onTap: () => toggleView('map'),
                  height: (constraints.maxHeight - headerHeight) / 2,
                  child: const Center(child: Text('Заглушка Карта')),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: () => toggleView(expandedView!),
        child: ViewContainer(
          title:
              expandedView == 'camera1'
                  ? 'Камера 1'
                  : expandedView == 'camera2'
                  ? 'Камера 2'
                  : expandedView == 'lidar'
                  ? 'ЛиDAR'
                  : 'Карта',
          height: constraints.maxHeight - headerHeight,
          child:
              expandedView == 'camera1'
                  ? (currentImage != null
                      ? Image.memory(currentImage!, fit: BoxFit.contain)
                      : const Center(child: Text('Изображение не получено')))
                  : Center(
                    child: Text('Заглушка ${expandedView!.toUpperCase()}'),
                  ),
        ),
      );
    }
  }
}

class ViewContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final double height;

  const ViewContainer({
    super.key,
    required this.title,
    required this.child,
    this.onTap,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: ClipRect(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue,
                  width: double.infinity,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
